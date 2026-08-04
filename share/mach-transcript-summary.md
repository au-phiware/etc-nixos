---
name: mach-transcript-summary
description: >
  Convert a meeting transcript into a clean, concise summary document. Use this
  skill when the user wants to: clean up a transcript, summarise a meeting
  recording, remove filler words from a transcript, turn a VTT or subtitle file
  into readable notes, or produce meeting minutes from a raw transcript. Also
  trigger when the user mentions: transcript, meeting notes, clean up recording,
  VTT, subtitle file, caption file, meeting summary — even if they don't use
  those exact words. If someone says "make this transcript readable" or
  "summarise this recording", this is the skill to use.
---

# Transcript Summary

You convert raw meeting transcripts into clean, readable summary documents.

## Supported Formats (in preference order)

1. **VTT / WebVTT** (strongly preferred) — plain text, has speaker tags and
   timestamps, directly readable
2. **SRT** — plain text with timestamps but typically no speaker attribution
3. **Plain text / Markdown** — pre-extracted transcript text
4. **DOCX** — binary format, cannot be read directly; ask the user to export as
   VTT or plain text instead

If the user provides a DOCX, tell them you cannot read binary files and ask for
a VTT or text export. Most meeting platforms (Teams, Zoom, Google Meet) offer
VTT download.

## Inputs

The user will provide:

- One or more transcript files (VTT preferred)
- **Required: output mode** — either **transcript** (cleaned full dialogue) or
  **briefing** (concise narrative summary). If not specified, ask before
  proceeding.
- Optional: a time range to cover (e.g. "first 29 minutes")
- Optional: whether to include timestamps (transcript mode only)
- Optional: specific focus areas or topics to emphasise

## Workflow

### Step 1: Read and Assess the Transcript

1. Read the file. For VTT, note the speaker tags (`<v Speaker Name>`) and
   timestamp format.
2. If a time range is specified, find the line boundaries using timestamps.
3. Identify all speakers and note the approximate distribution of speaking time.
4. Scan for transcription artifacts — common patterns:
   - Phonetic manglings of proper nouns, product names, or jargon (e.g.
     "clothing" for "coding", "happen" for "hackathon")
   - Sentence fragments split across multiple subtitle cues
   - Back-channel noise from overlapping speakers ("mm", "yeah", single-word
     interjections on their own cue)

### Step 2: Identify Structure

Meeting transcripts rarely follow a linear structure. Look for:

- **Agenda items or topic shifts** — often signalled by phrases like "moving on",
  "next one", "let's talk about"
- **Someone reading out items** — a facilitator reading post-it notes, tickets,
  or agenda points on behalf of others
- **Discussion vs decision** — separate what was debated from what was concluded
- **Action items** — anything someone committed to doing

Organise the output around topics/themes, not chronologically by speaker turn.

### Step 3: Clean the Content

Remove:

- **Filler words**: um, uh, like (when used as filler), you know, sort of, kind
  of (when not meaningful)
- **False starts and self-corrections**: "I think — well, not think but —"
  becomes the corrected version
- **Back-channel acknowledgements**: standalone "yeah", "mm", "right", "okay"
  that don't add meaning
- **Transcription artifacts**: fix obvious mishearings using context
- **Repetition from overlapping speakers**: when two people talk at once and one
  is just echoing
- **Meta-conversation about the meeting itself**: "can you unmute", "can you hear
  me", "let me share my screen" — unless relevant to the content

Preserve:

- **Speaker attribution** on substantive points — who said what matters
- **Direct quotes** that are distinctive, memorable, or capture something that a
  paraphrase would lose
- **Disagreements and tensions** — don't smooth these over; they're often the
  most valuable part
- **Specific examples, names, numbers, dates** mentioned by participants
- **The emotional register** when it's relevant (e.g. someone expressing
  frustration or surprise)

### Step 4: Output Mode

The user **must** specify which mode they want. If they don't, ask.

#### Transcript Mode

A cleaned-up transcript — everything that was said, in order, but readable.

- Full dialogue preserved, cleaned of filler and artifacts
- Speaker-attributed throughout (`**Speaker:** cleaned statement`)
- Organised by topic/agenda item, not raw chronological cue order
- Minimal editorial intervention — just making it readable
- Roughly 50-60% the length of the raw transcript
- **Timestamps**: optional. If the user wants timestamps, include them at topic
  boundaries or per speaker turn (e.g. `**Sami [12:08]:**`). If not requested,
  omit them.

#### Briefing Mode

A narrative summary that captures all the substance in a fraction of the space.

- Narrative prose organised by topic
- Speaker attribution woven into the text ("Sami identified...", "Tristan pushed
  back on this...")
- Direct quotes only where they're genuinely distinctive — something a paraphrase
  would flatten
- Roughly 20-30% the length of the raw transcript
- Each section has a heading and brief context line
- Disagreements, decisions, and action items are explicitly called out

### Step 5: Write the Document

Output as markdown. Structure:

```
# [Meeting Title] — Summary

**Participants:** [Names and roles if known]

[1-2 sentence context: what this meeting was about and why it was held]

---

## [Topic 1]

*[Brief context: who raised it, which category it fell under]*

[Content per chosen output mode]

## [Topic 2]

...

---

## Action Items

[If any were identified, list them with owners]
```

### Step 6: Final Checks

Before delivering:

1. Every speaker who made a substantive point is attributed.
2. Transcription errors are corrected (note corrections if they're ambiguous).
3. No meaning has been lost — if you cut a point, make sure it's truly redundant
   with something else that's included.
4. The document is useful to someone who wasn't in the meeting.
5. Filler is gone but the speakers' voices and perspectives are still distinct.

## Anti-patterns to Avoid

- **Over-sanitising**: Don't turn five distinct perspectives into one bland
  summary. Preserve who thought what.
- **Inventing structure that wasn't there**: If the meeting was unstructured,
  impose light organisation but don't pretend decisions were made if they weren't.
- **Losing disagreements**: The moment where two people disagreed is usually more
  valuable than the moments where everyone agreed. Don't smooth it out.
- **Attributing back-channel to substance**: "Yeah" from a listener doesn't mean
  they endorsed a position. Only attribute when someone actively contributed a
  point.
- **Correcting without flagging**: If a transcription error is ambiguous (you're
  not sure what was actually said), flag it with [unclear] rather than guessing.

## Output

- The summary document as markdown, written to disk
- If the user provided multiple files or a long recording, note what was and
  wasn't covered
