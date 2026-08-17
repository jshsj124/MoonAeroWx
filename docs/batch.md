# Batch Analysis Workflow

MoonAeroWx can process newline-delimited METAR/SPECI text and return aggregate counts for dashboards, notebooks, or contest demos.

## Input contract

- One report per line.
- Empty and whitespace-only lines are ignored.
- Windows `CRLF` input is normalized before tokenization.
- Each non-empty line is parsed independently, so one bad report does not stop the whole batch.

## Aggregated fields

| Field | Meaning |
| --- | --- |
| `total_reports` | non-empty input lines |
| `parsed_reports` | reports that produced a structured value |
| `error_reports` | reports with at least one error diagnostic |
| `warning_reports` | reports with at least one warning diagnostic |
| `diagnostics_count` | all diagnostics across the batch |
| `vfr_count`, `mvfr_count`, `ifr_count`, `lifr_count` | flight category distribution |
| `unknown_category_count` | reports without enough visibility/ceiling data |
| `low_visibility_events` | reports below MVFR visibility threshold |
| `low_ceiling_events` | reports below MVFR ceiling threshold |

## Library usage

```moonbit nocheck
///|
test "batch statistics" {
  let source = "ZBAA 171200Z 12008MPS 9999 SCT020 18/16 Q1008\nZGGG 171300Z VRB03KT 0600 FG OVC004 26/25 Q1004"
  let batch = @moonaerowx.parse_metar_batch(source)
  assert_eq(batch.total_reports, 2)
  assert_true(@moonaerowx.batch_to_markdown(batch).contains("METAR batch summary"))
}
```

## Output choices

- `batch_to_markdown` is intended for human-readable reports.
- `batch_to_csv` is intended for spreadsheet import and CI artifacts.
- `metar_batch_to_markdown` and `metar_batch_to_csv` combine parsing and formatting for one-call usage.

## Safety note

Batch output is useful for offline quality checks and educational analysis only. It is not a certified aviation briefing product.
