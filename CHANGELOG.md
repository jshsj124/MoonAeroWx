# Changelog

All notable changes to MoonAeroWx are documented here.

## Unreleased

### Added

- Pure MoonBit tokenizer and tolerant METAR/SPECI parser.
- Structured diagnostics with source spans and severity levels.
- VFR/MVFR/IFR/LIFR classification with configurable thresholds.
- TAF parsing for base conditions plus `FM`, `BECMG`, `TEMPO`, `PROB`, and `PROB TEMPO` change groups.
- Timeline expansion for visualization-friendly TAF summaries.
- Runway visual range decoding for fixed, bounded, below-minimum, above-maximum, and trend forms.
- JSON, Markdown, CSV, and plain-text METAR/SPECI renderers.
- Newline-delimited batch parsing with aggregate Markdown and CSV reports.
- Command line entry point under `cmd/aerowx`.
- Added empty-input, unknown-condition, SPECI wrapper, and PROB TEMPO regression tests.
- Added month-boundary preservation coverage for TAF timelines.

### Safety

- Added explicit non-operational safety notice for aviation use.
- Parser preserves unrecognized tokens as raw remarks/warnings instead of silently discarding them.

### Documentation

- Added CLI usage guide, batch workflow notes, diagnostics reference, and expanded architecture notes.
- Added quick-start and release-status sections to the README, plus refreshed coverage notes.
- Clarified TAF month-boundary limits in the documentation and development log.
