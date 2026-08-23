# Limitations and Safety Boundary

MoonAeroWx is a developer-oriented parser and analysis toolkit. It is not an operational aviation product.

## Safety boundary

- Do not use MoonAeroWx for real flight dispatch, flight planning, in-flight decisions, alternate selection, or safety-critical alerting.
- Always verify weather information against official and certified aviation weather sources.
- Treat parser output as best-effort structured data, especially when reports contain regional extensions or free-form remarks.
- The project does not provide regulatory interpretation, pilot briefing, or airport operating minima guidance.

## Current parser limitations

| Area | Current boundary |
| --- | --- |
| Regional METAR extensions | Unsupported tokens are preserved as raw remarks or warnings, but not fully decoded. |
| Runway state | Not yet decoded. Planned as a separate parser module. |
| Wind shear | Not yet decoded. Planned after core METAR/TAF grammar hardening. |
| Sea state / runway contamination | Not yet decoded. |
| Rich `RMK` sections | Preserved but not semantically expanded. |
| Complex weather combinations | Common groups are decoded first; rare combinations may become `UnknownToken`. |
| TAF month boundary | Not yet fully calendar-aware; summaries annotate likely month-boundary crossings, but internal periods still preserve literal DDHH/DDHH day values. |
| Localization | Public output strings are currently English-oriented for stable fixtures and CLI scripts. |

## Design choices

MoonAeroWx intentionally favors transparent partial parsing over rejecting the entire report. When the parser sees unsupported content, it should:

1. keep recognized structured fields available;
2. attach diagnostics with source spans;
3. preserve raw tokens for later inspection;
4. avoid silently inventing meaning for unsupported regional syntax.

This behavior makes the library useful for education, demos, offline data cleaning, and test fixtures while keeping the safety boundary explicit.

## Validation expectation

Before publishing or submitting a new revision, run:

```bash
moon fmt
moon check --warn-list +unnecessary_annotation
moon test
moon info
```

The generated interface file should be reviewed whenever public types or functions change.
