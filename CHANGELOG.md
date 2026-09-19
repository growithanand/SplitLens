# Changelog

This file records the completed SplitLens release checkpoints.

## 0.1.0 - 2026-09-19

Initial local-first Android MVP checkpoint.

### Receipt workflow

- Capture a receipt with the Android camera or select an image from the gallery.
- Recognize Latin-script receipt text on-device with Google ML Kit.
- Propose merchant, date, EUR currency, and total from English and German
  receipt text.
- Preserve the receipt image and raw OCR output for review.
- Require the user to review and confirm every receipt field before splitting.

### Expense splitting and storage

- Add participants, select the payer, and calculate an exact equal split.
- Represent currency as integer cents and distribute remainder cents
  deterministically.
- Save the expense, participants, allocations, and OCR text transactionally,
  with the receipt image retained in private application storage.
- Browse and search local expense history by merchant or participant.
- Inspect saved allocations and receipt evidence.
- Delete an expense with confirmation and remove its locally stored receipt.

### Engineering checkpoint

- Organize code by feature with separate presentation, application, domain,
  and data responsibilities.
- Cover money handling, receipt parsing, controllers, persistence, and key UI
  flows with automated tests.
- Verify formatting, static analysis, tests, Drift schema output, and an Android
  debug build in GitHub Actions.
- Track the Drift schema version 1 snapshot for future migration validation.
- Support locally configured, non-debug signing for Android release bundles.
