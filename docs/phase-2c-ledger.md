# 2C execution ledger

Plan: docs/superpowers/plans/2026-10-20-learning-phase-2c.md

- User confirmed implementation plan; execute inline, one final independent review.
- Ruling: current project is the isolated scope; parent home Git must not be operated on. No commit or worktree helpers against parent Git.
- Preflight: catalog -> reading references/revision -> repository -> controller/UI; AudioCue decouples reading models from audio; setCursors preserves v1 state. No conflicting signatures found.
- Task 1 started: schema, lazy repository and backwards compatibility; RED before production changes.
- Task 1 initial GREEN: annotation, lazy repository retry/revision, duplicate line/resource tests pass. Task 2 catalog created: 241 items, 21 passages, 92 lines; Python paired-write rollback test GREEN. Existing 209 IDs saved as fixture.
- Task 3 initial GREEN: tagged completion isolates old sequence, single playback, stop/background; missing clip blocks at current cue; previous audio tests preserved. Real adapter uses new player identity per playback.
- Task 4 initial GREEN: progress/restart/storage failure, 320px/2x layout and classic deep-link mark only target sentence. Widget tests must pump once then runAsync asset I/O before pumpAndSettle (spinner otherwise times out).
- Content source verification: direct urllib fetches returned403; web primary pages readable. Followed disambiguation pages to author-specific poems, corrected book URLs to actual chapter editions. Simplified text and authored explanations; pronunciation drafts corrected for polyphones/neutral tones, professional teaching review remains pending.
- Task 5 in progress: failure-safe staged demo generator and complete provenance audit; no runtime TTS or new app dependencies.
- Task 5 initial GREEN: 92 staged demo WAVs generated via system speech; sandbox speech initially produced silence, then permitted system service access succeeded. No source/WAV overwritten by failed first run. Full PCM/hash/provenance audit passes; old 98 demo/111 missing unchanged.
- Final independent review reported two important findings. Both reproduced RED: external route/background cancellation while cursor write waits; generator accepts invalid annotations before publication. Fixed with audio request-generation guard and shared validate_source before synthesis. Own stop-pending regression and stale decoder-error tests also added.
- Ruling: poetry uses author-specific source URLs, 三字经 source uses ancient lines within 三字经易解 (modern explanations excluded). 悯农 uses common 餐/cān with explicit edition note that linked ancient page has 飧; no claim of facsimile transcription.
- Final GREEN: 63 Flutter tests, 8 Python tests, clean static analysis, catalog --check and combined resource audit. Android debug and iOS simulator builds succeeded.
- Native: poem completion advanced to final line without marking learned; story text/explanations opened; classic line 12 restored visibly, marking changed only 1/12. Relaunch retained home 2/241 and classic line 12 marked learned. Lazy-list last-line visibility failure reproduced and fixed with eagerly built bounded passage rows; visibility regression passes.
- Delivery: README, roadmap, source lists, screenshots and phase-2c-status.md updated. Teaching listening review, Android runtime and listed supplemental manual checks remain open; no parent Git operation.
