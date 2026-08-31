#!/usr/bin/env python3
"""Turn collected PR timelines into review-latency and concentration metrics.

A PR counts as *in review* whenever all of these hold at once:
  - a non-bot reviewer is requested, OR a ready label is applied, OR a Slack
    "ready for review" post named it
  - no blocking label is applied
  - it is not a draft, and it is open

The clock accumulates every interval in that state up to the merge. Weekends are
excluded by default: reviewers do not work them, so counting them turns a Friday
afternoon request into a two-day wait that nobody was responsible for.
"""
import argparse, json, os, statistics as st, sys
from collections import Counter
from datetime import datetime, timedelta, timezone

# GitHub fires the human ReviewRequestedEvent at PR creation and the blocking
# label lands a second later. Those phantom windows are always ~1s; a 60s floor
# removes them without touching any real review window.
MIN_INTERVAL_SECONDS = 60


def ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00")) if s else None


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--dir", required=True, help="directory written by collect.sh")
    p.add_argument("--since", required=True, help="window start, ISO-8601 UTC")
    p.add_argument("--until", required=True, help="window end, ISO-8601 UTC")
    p.add_argument("--authors", required=True, help="comma-separated logins")
    p.add_argument("--split-at", default="",
                   help="ISO-8601 UTC boundary between two cycles, for the cycle comparison")
    p.add_argument("--split-names", default="earlier,later")
    p.add_argument("--ready-labels", default="pending code review")
    p.add_argument("--blocking-labels", default="not ready,on hold,blocked")
    p.add_argument("--base-branches", default="main,master")
    p.add_argument("--repo-types", default="Production",
                   help="project-type property values to keep; empty string keeps all")
    p.add_argument("--tz-offset", type=int, default=10, help="hours east of UTC for the weekend calendar")
    p.add_argument("--calendar-days", action="store_true", help="count weekends too")
    p.add_argument("--slack-signals", default="", help="optional JSON of Slack ready-for-review posts")
    p.add_argument("--slow-threshold-days", type=float, default=3.0)
    return p.parse_args()


def load_slack(path):
    """[{"at": iso, "repo": "org/name", "prs": [123, ...]}, ...] -> earliest per PR."""
    out = {}
    if not path:
        return out
    for m in json.load(open(path)):
        for n in m["prs"]:
            k, t = (m["repo"], n), ts(m["at"])
            if k not in out or t < out[k]:
                out[k] = t
    return out


def make_weekday_seconds(tz, calendar_days):
    if calendar_days:
        return lambda a, b: max(0.0, (b - a).total_seconds())

    def weekday_seconds(a, b):
        total, cur = 0.0, a
        while cur < b:
            midnight = (cur.astimezone(tz) + timedelta(days=1)).replace(
                hour=0, minute=0, second=0, microsecond=0)
            nxt = min(b, midnight.astimezone(timezone.utc))
            if cur.astimezone(tz).weekday() < 5:
                total += (nxt - cur).total_seconds()
            cur = nxt
        return total
    return weekday_seconds


def review_intervals(events, merged, started_draft, ready_labels, blocking_labels):
    """Walk the timeline and return every (start, end) the PR spent reviewable."""
    requested, pcr, blocked, closed, slack = set(), False, False, False, False
    draft = started_draft
    intervals, open_start = [], None

    def ready():
        return (bool(requested) or pcr or slack) and not blocked and not draft and not closed

    for at, kind, node in events:
        if at > merged:
            break
        was = ready()
        if kind == "ReviewRequestedEvent":
            rr = node.get("requestedReviewer") or {}
            if rr.get("__typename") != "Bot":
                requested.add(rr.get("login") or rr.get("slug") or "team")
        elif kind == "ReviewRequestRemovedEvent":
            rr = node.get("requestedReviewer") or {}
            requested.discard(rr.get("login") or rr.get("slug") or "team")
        elif kind == "LabeledEvent":
            name = node["label"]["name"]
            if name in blocking_labels:
                blocked = True
            elif name in ready_labels:
                pcr = True
        elif kind == "UnlabeledEvent":
            name = node["label"]["name"]
            if name in blocking_labels:
                blocked = False
            elif name in ready_labels:
                pcr = False
        elif kind == "ReadyForReviewEvent":
            draft = False
        elif kind == "ConvertToDraftEvent":
            draft = True
        elif kind == "ClosedEvent":
            closed = True
        elif kind == "ReopenedEvent":
            closed = False
        elif kind == "SlackReady":
            slack = True
        else:
            continue

        now = ready()
        if not was and now:
            open_start = at
        elif was and not now and open_start:
            if (at - open_start).total_seconds() >= MIN_INTERVAL_SECONDS:
                intervals.append((open_start, at))
            open_start = None

    if open_start and (merged - open_start).total_seconds() >= MIN_INTERVAL_SECONDS:
        intervals.append((open_start, merged))
    return intervals


def quantile(values, p):
    v = sorted(values)
    if not v:
        return None
    k = (len(v) - 1) * p
    f = int(k)
    c = min(f + 1, len(v) - 1)
    return v[f] + (v[c] - v[f]) * (k - f)


def gini(values):
    v = sorted(values)
    n, s = len(v), sum(values)
    if n == 0 or s == 0:
        return 0.0
    return (2 * sum((i + 1) * x for i, x in enumerate(v))) / (n * s) - (n + 1) / n


def lorenz(values, points=90):
    """Cumulative wait share (x) against cumulative PR share (y), slowest first.

    Slowest-first puts the fast, healthy PRs on the right and bows the curve
    below the diagonal, matching a conventional Lorenz reading.
    """
    v = sorted(values, reverse=True)
    total = sum(v)
    if not v or total == 0:
        return [[0.0, 0.0], [100.0, 100.0]]
    pts, run = [(0.0, 0.0)], 0.0
    for i, x in enumerate(v):
        run += x
        pts.append((run / total * 100, (i + 1) / len(v) * 100))
    if len(pts) > points:
        step = len(pts) / points
        idx = sorted({0, len(pts) - 1} | {int(i * step) for i in range(points)})
        pts = [pts[i] for i in idx]
    return [[round(x, 2), round(y, 2)] for x, y in pts]


def is_bot(login):
    if not login:
        return True
    l = login.lower()
    return ("copilot" in l or l.endswith("[bot]")
            or l in {"linear", "github-actions", "dependabot", "renovate"})


def summarise(rows, slow_hours):
    measurable = [r for r in rows if not r["unmeasurable"]]
    waits = [r["wait"] for r in measurable]
    if not waits:
        return {"n": 0}
    slow = [r for r in measurable if r["wait"] > slow_hours]
    return {
        "n": len(measurable),
        "median_h": round(st.median(waits), 2),
        "p75_h": round(quantile(waits, .75), 2),
        "p90_h": round(quantile(waits, .90), 2),
        "total_days": round(sum(waits) / 24, 1),
        "first_review_median_h": round(st.median([r["to_first_review"] for r in measurable
                                                  if r["to_first_review"] is not None]), 2)
        if any(r["to_first_review"] is not None for r in measurable) else None,
        "first_approval_median_h": round(st.median([r["to_first_approval"] for r in measurable
                                                    if r["to_first_approval"] is not None]), 2)
        if any(r["to_first_approval"] is not None for r in measurable) else None,
        "over_threshold": len(slow),
        "over_threshold_days": round(sum(r["wait"] for r in slow) / 24, 1),
        "mean_review_rounds": round(st.mean([r["rounds"] for r in measurable]), 2),
        "gini": round(gini(waits), 3),
        "lorenz": lorenz(waits),
        "never_reviewed": [f'{r["repo"]}#{r["number"]}' for r in measurable if not r["reviewed"]],
    }


def main():
    a = parse_args()
    tz = timezone(timedelta(hours=a.tz_offset))
    since, until = ts(a.since), ts(a.until)
    split = ts(a.split_at) if a.split_at else None
    names = a.split_names.split(",")
    authors = {x.strip() for x in a.authors.split(",") if x.strip()}
    ready_labels = {x.strip() for x in a.ready_labels.split(",") if x.strip()}
    blocking_labels = {x.strip() for x in a.blocking_labels.split(",") if x.strip()}
    bases = {x.strip() for x in a.base_branches.split(",") if x.strip()}
    keep_types = {x.strip() for x in a.repo_types.split(",") if x.strip()}
    elapsed_of = make_weekday_seconds(tz, a.calendar_days)
    slack = load_slack(a.slack_signals)

    props = json.load(open(os.path.join(a.dir, "repo_props.json")))
    base_of = {}
    for line in open(os.path.join(a.dir, "baserefs.ndjson")):
        b = json.loads(line)
        base_of[(b["repository"]["nameWithOwner"], b["number"])] = b["baseRefName"]

    rows, excluded = [], Counter()
    for line in open(os.path.join(a.dir, "raw.ndjson")):
        pr = json.loads(line)
        author = (pr.get("author") or {}).get("login")
        if author not in authors:
            continue
        merged = ts(pr.get("mergedAt"))
        if not merged or not (since <= merged < until):
            continue
        repo, num = pr["repository"]["nameWithOwner"], pr["number"]

        if keep_types and props.get(repo.split("/", 1)[1], "Production") not in keep_types:
            excluded["repo_type"] += 1
            continue
        if bases and base_of.get((repo, num)) not in bases:
            excluded["not_trunk"] += 1
            continue

        events = sorted(
            [(ts(n["createdAt"]), n["__typename"], n) for n in pr["timelineItems"]["nodes"]
             if n.get("createdAt")], key=lambda x: x[0])

        started_draft = False
        for _, kind, _ in events:
            if kind == "ReadyForReviewEvent":
                started_draft = True
                break
            if kind == "ConvertToDraftEvent":
                break

        sig = slack.get((repo, num))
        if sig:
            events = sorted(events + [(sig, "SlackReady", {})], key=lambda x: x[0])

        intervals = review_intervals(events, merged, started_draft, ready_labels, blocking_labels)
        base = dict(repo=repo, number=num, url=pr["url"], title=pr["title"], author=author,
                    merged_at=merged.isoformat(), used_slack=(repo, num) in slack)
        if not intervals:
            rows.append({**base, "unmeasurable": True})
            continue

        first_ready = intervals[0][0]
        first_response = first_review = first_approval = None
        for at, kind, node in events:
            if at < first_ready or at > merged:
                continue
            who = (node.get("author") or {}).get("login")
            if not who or who == author or is_bot(who):
                continue
            if kind in ("PullRequestReview", "IssueComment") and first_response is None:
                first_response = at
            if kind == "PullRequestReview":
                if first_review is None:
                    first_review = at
                if first_approval is None and node.get("state") == "APPROVED":
                    first_approval = at

        wait = sum(elapsed_of(s, e) for s, e in intervals) / 3600
        rows.append({
            **base,
            "unmeasurable": False,
            "first_ready": first_ready.isoformat(),
            "rounds": len(intervals),
            "wait": round(wait, 3),
            "elapsed": round(elapsed_of(first_ready, merged) / 3600, 3),
            "to_first_response": round(elapsed_of(first_ready, first_response) / 3600, 3) if first_response else None,
            "to_first_review": round(elapsed_of(first_ready, first_review) / 3600, 3) if first_review else None,
            "to_first_approval": round(elapsed_of(first_ready, first_approval) / 3600, 3) if first_approval else None,
            "reviewed": first_review is not None,
            "cycle": (names[0] if split and merged < split else names[-1]) if split else "all",
        })

    slow_hours = a.slow_threshold_days * 24
    measurable = [r for r in rows if not r["unmeasurable"]]

    # reviewer load, counting each reviewer once per PR
    load, pairs = Counter(), Counter()
    keep = {(r["repo"], r["number"]) for r in rows}
    for line in open(os.path.join(a.dir, "raw.ndjson")):
        pr = json.loads(line)
        author = (pr.get("author") or {}).get("login")
        if (pr["repository"]["nameWithOwner"], pr["number"]) not in keep:
            continue
        seen = set()
        for n in pr["timelineItems"]["nodes"]:
            if n["__typename"] != "PullRequestReview":
                continue
            who = (n.get("author") or {}).get("login")
            if is_bot(who) or who == author or who in seen:
                continue
            seen.add(who)
            load[who] += 1
            pairs[f"{author} -> {who}"] += 1

    def cut(pred):
        return summarise([r for r in rows if pred(r)], slow_hours)

    out = {
        "window": {"since": a.since, "until": a.until, "split_at": a.split_at,
                   "clock": "calendar" if a.calendar_days else f"weekdays (UTC+{a.tz_offset})",
                   "slow_threshold_days": a.slow_threshold_days,
                   "slack_signals_used": bool(slack)},
        "population": {"merged_in_window": len(rows) + sum(excluded.values()),
                       "kept": len(rows), "measurable": len(measurable),
                       "excluded": dict(excluded),
                       "unmeasurable": [f'{r["repo"]}#{r["number"]}' for r in rows if r["unmeasurable"]]},
        "overall": summarise(rows, slow_hours),
        "by_author": {x: cut(lambda r, x=x: r["author"] == x) for x in sorted(authors)},
        "by_repo": {x: cut(lambda r, x=x: r["repo"] == x)
                    for x in sorted({r["repo"] for r in rows})},
        "reviewer_load": dict(load.most_common()),
        "review_pairs": dict(pairs.most_common(20)),
        "slowest": [{k: r[k] for k in ("repo", "number", "url", "title", "author", "wait", "to_first_review")}
                    for r in sorted(measurable, key=lambda r: -r["wait"])[:15]],
        "counterfactual_cap_days": round(
            sum(min(r["wait"], slow_hours) for r in measurable) / 24, 1) if measurable else 0,
    }
    if split:
        out["by_cycle"] = {n: cut(lambda r, n=n: r.get("cycle") == n) for n in names}

    json.dump(rows, open(os.path.join(a.dir, "rows.json"), "w"), indent=1)
    json.dump(out, open(os.path.join(a.dir, "summary.json"), "w"), indent=1)

    def h(x):
        return "n/a" if x is None else (f"{x/24:.1f}d" if x >= 24 else f"{x:.1f}h")
    o = out["overall"]
    p = out["population"]
    print(f"# PR review latency  {a.since[:10]} → {a.until[:10]}  ({out['window']['clock']})\n")
    print(f"{p['merged_in_window']} merged, {p['kept']} kept, {p['measurable']} measurable"
          f"  (excluded: {p['excluded'] or 'none'})")
    print(f"median {h(o['median_h'])} · p75 {h(o['p75_h'])} · p90 {h(o['p90_h'])} · "
          f"total {o['total_days']} PR-days · Gini {o['gini']}")
    print(f"over {a.slow_threshold_days}d: {o['over_threshold']} PRs holding "
          f"{o['over_threshold_days']} PR-days · capping them → {out['counterfactual_cap_days']} PR-days\n")
    hdr = f"{'':<20}{'PRs':>5}{'median':>9}{'p90':>9}{'1stRev':>9}{'>thr':>6}{'days':>8}{'Gini':>7}"
    for label, group in (("author", out["by_author"]), ("repo", out["by_repo"]),
                         ("cycle", out.get("by_cycle", {}))):
        if not group:
            continue
        print(f"## by {label}\n{hdr}\n{'-'*len(hdr)}")
        for k, s in sorted(group.items(), key=lambda kv: -(kv[1].get("total_days") or 0)):
            if not s.get("n"):
                continue
            print(f"{k.replace('machship/',''):<20}{s['n']:>5}{h(s['median_h']):>9}{h(s['p90_h']):>9}"
                  f"{h(s['first_review_median_h']):>9}{s['over_threshold']:>6}"
                  f"{s['total_days']:>8}{s['gini']:>7}")
        print()
    print(f"summary.json and rows.json written to {a.dir}", file=sys.stderr)


if __name__ == "__main__":
    main()
