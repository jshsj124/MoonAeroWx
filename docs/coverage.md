# Feature Coverage Matrix

This document summarizes the current MoonAeroWx MVP coverage for reviewers and downstream users.

## Report parsing

| Area | Status | Notes |
| --- | --- | --- |
| Whitespace tokenization | Supported | Preserves start/end offsets plus line/column for diagnostics. |
| METAR | Supported | Accepts explicit `METAR` and omitted report kind. |
| SPECI | Supported | Accepts explicit `SPECI`. |
| Station | Supported | Four-letter ICAO-style station identifiers. |
| Observation time | Supported | `DDHHMMZ` with range validation. |
| Wind | Supported | `KT` and `MPS`, variable wind, and gusts. |
| Visibility | Supported | Metric values, `9999`, `CAVOK`, `SM`, and `P6SM`. |
| Weather | Partial | Common groups such as rain, mist, fog, thunderstorm, showers, and `NSW`. |
| Clouds | Supported | `FEW`, `SCT`, `BKN`, `OVC`, `SKC`, `NSC`, `NCD`, with CB/TCU suffixes. |
| Temperature/dew point | Supported | Positive and `M` negative values, including consistency warnings. |
| Pressure | Supported | `Q1008` and `A2992` forms. |
| RVR | Supported | Fixed values, variable ranges, `P`/`M` limits, and `U`/`D`/`N` trends. |
| Trends | Partial | `NOSIG` is decoded. Other regional trend groups are preserved as raw tokens. |
| Remarks | Partial | Unsupported trailing tokens are preserved instead of discarded. |

## TAF parsing

| Area | Status | Notes |
| --- | --- | --- |
| TAF header | Supported | Station, optional issue time, and validity period. |
| Base conditions | Supported | Reuses wind/visibility/RVR/weather/cloud condition parsing. |
| `FM` groups | Supported | Expanded into replacement intervals for timelines. |
| `BECMG` groups | Supported | Preserved as timeline overlays. |
| `TEMPO` groups | Supported | Preserved as timeline overlays. |
| `PROB` groups | Supported | Supports probability percentage. |
| `PROB TEMPO` groups | Supported | Combines probability and temporary period semantics. |
| Month-boundary semantics | Planned | Current timeline is day/hour/minute based and intentionally lightweight. |

## Output and integration

| Capability | Status | Entry points |
| --- | --- | --- |
| Text summary | Supported | `metar_to_summary`, CLI `decode` |
| JSON | Supported | `metar_to_json`, CLI `decode-json` |
| Markdown | Supported | `metar_to_markdown`, `batch_to_markdown`, CLI `decode-md`, `batch` |
| CSV | Supported | `metar_to_csv`, `batch_to_csv`, CLI `decode-csv`, `batch-csv` |
| Batch statistics | Supported | `parse_metar_batch`, `metar_batch_to_markdown`, `metar_batch_to_csv` |
| Flight category | Supported | `classify`, `flight_category_to_string`, configurable `FlightCategoryRules` |
| Multi-backend portability | Targeted | No external runtime dependency in the core formatter/parser path. |

## Test coverage snapshot

The current suite covers token spans, METAR/SPECI decoding, US-style visibility and altimeter groups, diagnostics, TAF changes, TAF timelines, RVR parsing, Markdown/CSV/JSON output, batch aggregation, empty-input handling, SPECI wrapper parity, PROB TEMPO overlays, month-boundary preservation, and CRLF/blank-line batch handling.
