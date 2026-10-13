# media — audio, video, and images

This agent cannot hear audio or watch video. Gemini is natively multimodal, so
delegate the perception and keep the judgment here. Read
[invariants.md](invariants.md) first.

## 1. Resolve the input

First argument is the path. Anything else that is not a flag is the focus
question. If no file was given, ask which one — do not guess.

## 2. Delegate, with the transcript going to a file

    agy --add-dir "$(dirname "<file>")" --model gemini-3.8-flash-high \
        -p='Transcribe and analyse <file>. Write the FULL transcript to
        <file>.transcript.md. Then output ONLY a digest: one-paragraph summary,
        timestamped outline, key points, notable quotes, action items, and an
        explicit list of anything unclear or uncertain (names, numbers, garbled
        audio). Do not output the full transcript.'

`flash` (high) is the default and the only Gemini tier above `lo` today (no
`pro` tier — see [invariants.md](invariants.md) § Tiers). Ask for timestamps and
speaker separation explicitly and flag anything uncertain; verify names/numbers.

Do not pass `--print-timeout` for long media. In agy 1.3.3 the default is
`0s` (no limit), which is what a long transcription needs. If you do set a
limit and it expires, agy returns **partial output with exit 0** and prints
`print timeout after` on stderr: a transcript can be silently cut short.
Capture stderr, and treat that line as a failure, never as success — discard
the partial transcript and digest, then split the file into ~30-minute chunks
and run them separately. See [invariants.md](invariants.md) § Real flags.

Voice memos are often `.m4a` or `.aiff`, which agy handles unreliably. Convert
first if it fails:

    afconvert -f WAVE -d LEI16 in.m4a out.wav   # macOS
    ffmpeg -i in.m4a out.wav                    # elsewhere

## 3. Ingest the digest only

**Do not read the transcript file into context.** A one-hour recording is
roughly 10k words, and re-reading it every turn is precisely the cost blow-up
this skill exists to prevent. The file is there so you can grep slices:

    grep -n '\[12:3' <file>.transcript.md

## 4. Verify before relying on it

Transcription is not ground truth.

- Confirm the transcript file actually exists and is non-empty, and that
  stderr has no `print timeout after` line (that means it is truncated).
- The digest lists what was unclear — treat every item on that list as
  unverified.
- For any load-bearing figure, name, or quote, read that timestamp's slice from
  the transcript rather than trusting the summary.
- Say plainly which claims you confirmed and which remain the model's guess.
