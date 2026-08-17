# Diagnostics Reference

MoonAeroWx parsers are tolerant: they try to return a partial structured report while preserving every warning and error with source position information.

## Severity levels

| Severity | Meaning |
| --- | --- |
| `Error` | The token or required grammar element is invalid. `ParseResult::has_errors()` returns `true`. |
| `Warning` | The report is parseable, but the content is suspicious or unsupported. |
| `Info` | Reserved for future non-problem annotations. |

## Current diagnostic codes

| Code | Typical trigger |
| --- | --- |
| `EmptyInput` | no non-whitespace report text |
| `MissingStation` | station group is absent |
| `MissingObservationTime` | observation or issue time is absent |
| `InvalidStation` | station does not look like a four-letter ICAO code |
| `InvalidTime` | `DDHHMMZ` value is malformed or out of range |
| `InvalidWind` | wind direction, speed, gust, or unit is malformed |
| `InvalidVisibility` | visibility group is malformed |
| `InvalidWeather` | weather token is malformed or unsupported |
| `InvalidCloud` | cloud layer is malformed or cloud order looks suspicious |
| `InvalidTemperature` | temperature/dew point token is malformed or internally inconsistent |
| `InvalidPressure` | QNH or altimeter token is malformed |
| `InvalidTafPeriod` | TAF validity or change period is malformed |
| `InvalidTafChange` | TAF change group is missing required timing or conditions |
| `InvalidRunwayVisualRange` | RVR runway/value/range syntax is malformed |
| `UnknownToken` | token is preserved as raw data because no parser recognized it |

## Handling pattern

```moonbit nocheck
///|
test "check diagnostics" {
  let result = @moonaerowx.parse_metar("ZBAA 171200Z 99908MPS 8000")
  if result.has_errors() {
    let message = result.diagnostics[0].to_string()
    assert_true(message.contains("error:"))
  }
}
```

Diagnostic spans are one-based for line and column display, which makes CLI output suitable for direct user feedback.
