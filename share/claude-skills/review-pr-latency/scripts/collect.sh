#!/usr/bin/env bash
# Collect PR timelines, base branches and repo properties for a set of authors.
# Usage: collect.sh <outdir> <org> <since-yyyy-mm-dd> <author> [author...]
set -euo pipefail

OUT=${1:?outdir}; ORG=${2:?org}; SINCE=${3:?since}; shift 3
AUTHORS=("$@")
[ ${#AUTHORS[@]} -gt 0 ] || { echo "no authors given" >&2; exit 2; }
mkdir -p "$OUT"
: > "$OUT/raw.ndjson"
: > "$OUT/baserefs.ndjson"

TIMELINE_Q='
query($q:String!,$cursor:String){
  search(query:$q,type:ISSUE,first:25,after:$cursor){
    pageInfo{hasNextPage endCursor}
    nodes{... on PullRequest{
      number url title state isDraft createdAt mergedAt closedAt
      author{login} repository{nameWithOwner}
      timelineItems(first:250, itemTypes:[REVIEW_REQUESTED_EVENT,REVIEW_REQUEST_REMOVED_EVENT,LABELED_EVENT,UNLABELED_EVENT,READY_FOR_REVIEW_EVENT,CONVERT_TO_DRAFT_EVENT,PULL_REQUEST_REVIEW,ISSUE_COMMENT,MERGED_EVENT,CLOSED_EVENT,REOPENED_EVENT]){
        totalCount pageInfo{hasNextPage}
        nodes{
          __typename
          ... on ReviewRequestedEvent{createdAt requestedReviewer{__typename ... on User{login} ... on Team{slug} ... on Bot{login}}}
          ... on ReviewRequestRemovedEvent{createdAt requestedReviewer{__typename ... on User{login} ... on Team{slug} ... on Bot{login}}}
          ... on LabeledEvent{createdAt label{name}}
          ... on UnlabeledEvent{createdAt label{name}}
          ... on ReadyForReviewEvent{createdAt}
          ... on ConvertToDraftEvent{createdAt}
          ... on PullRequestReview{createdAt state author{login}}
          ... on IssueComment{createdAt author{login}}
          ... on MergedEvent{createdAt}
          ... on ClosedEvent{createdAt}
          ... on ReopenedEvent{createdAt}
        }
      }
    }}
  }
}'

BASE_Q='
query($q:String!,$cursor:String){
  search(query:$q,type:ISSUE,first:100,after:$cursor){
    pageInfo{hasNextPage endCursor}
    nodes{... on PullRequest{number baseRefName repository{nameWithOwner}}}
  }
}'

paginate () { # $1=query $2=search-string $3=outfile
  local cur=null resp
  while :; do
    resp=$(gh api graphql -F cursor="$cur" -f q="$2" -f query="$1")
    echo "$resp" | jq -c '.data.search.nodes[]' >> "$3"
    [ "$(echo "$resp" | jq -r '.data.search.pageInfo.hasNextPage')" = true ] || break
    cur=$(echo "$resp" | jq -r '.data.search.pageInfo.endCursor')
  done
}

for U in "${AUTHORS[@]}"; do
  echo "  fetching $U ..." >&2
  paginate "$TIMELINE_Q" "is:pr org:$ORG author:$U updated:>=$SINCE" "$OUT/raw.ndjson"
  paginate "$BASE_Q"     "is:pr org:$ORG author:$U updated:>=$SINCE" "$OUT/baserefs.ndjson"
done

# Warn loudly if any timeline was truncated -- the state machine would silently mis-score it.
TRUNC=$(jq -r 'select(.timelineItems.pageInfo.hasNextPage) | "\(.repository.nameWithOwner)#\(.number)"' "$OUT/raw.ndjson")
if [ -n "$TRUNC" ]; then
  echo "WARNING: truncated timelines (raise the first: limit and re-run):" >&2
  echo "$TRUNC" >&2
fi

# project-type custom property per repo touched. Unset defaults to Production.
jq -r '.repository.nameWithOwner' "$OUT/raw.ndjson" | sort -u | while read -r R; do
  V=$(gh api "repos/$R/properties/values" \
        --jq '[.[]|select(.property_name=="project-type")|.value]|if length==0 then "Production" else .[0] end' 2>/dev/null || echo Production)
  printf '%s\t%s\n' "${R#*/}" "$V"
done | jq -Rn '[inputs|split("\t")|{key:.[0],value:.[1]}]|from_entries' > "$OUT/repo_props.json"

echo "collected $(wc -l < "$OUT/raw.ndjson") PRs into $OUT" >&2
