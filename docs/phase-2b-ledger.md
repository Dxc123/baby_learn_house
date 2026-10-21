# 2B execution ledger

Plan: docs/superpowers/plans/2026-10-20-learning-phase-2b.md

- Executing inline; final fresh review required by executing-plans skill.
- Ruling: work in this project directly; Git root is the user's home, so no parent Git operations or branch creation.
- Interfaces checked: catalog IDs -> stroke repository -> practice/PDF; geometry shared by screen and SVG PDF; practice has no store dependency. No interface conflicts found.
- Task 1 started: add 60-character catalog and explicit annotated words, preserve existing IDs/state.
- Task 1 complete: canonical production sources, deterministic build/check, 60 characters and two annotated words each; legacy defaults retained. Invalid word/pinyin/group/stroke source inputs rejected before output replacement.
- Tasks 2/3 complete: 60 pinned stroke assets, upright transform, lifecycle-safe playback and ephemeral normalized tracing. Ruling: download the fixed 60-file corpus as one batch, validate original-six rendering plus all-60 structural checks; no runtime CDN.
- Task 4/5 complete: original verified LXGW WenKai v1.530, true vector A4 PDFs, shared bytes for preview/share/print, provenance hashes and licenses. Actual six/default PDF 2 pages, sixty/four-row PDF 30 pages.
- Dependency ruling: pdf 3.12 requires archive <4.1; image 4.11 uses unavailable decodeLazy with archive 4.0.9. Pin image 4.5.4 compatible with Dart 3.11.4; no SDK upgrade.
- Download cleanup: a parallel legacy curl appended 422 bytes after verified download; cancelled transfer ended, truncated only verified blob length, revalidated exact Git blob and SHA-256 before final builds.
- Fresh independent review: three findings (drawing scroll conflict, incomplete builder schema, missing stroke references); each reproduced RED, fixed, and verified GREEN. Guard stale async loads additionally. Native print/share buttons now carry explicit accessible labels.
- Task 6: 49 Flutter tests passed; 3 Python tests passed; resource/check passed; final static analysis clean. Android APK and iOS simulator builds passed. iOS six/max previews opened, share cancelled successfully; no Android AVD available, so native Android preview remains unverified. More detailed evidence in phase-2b-status.md.
- Final consistency fix: annotated words now obey the existing global pinyin toggle (RED -> GREEN); list footer updated to describe implemented capabilities. No source changes after final verification beyond these fixes and formatting.
