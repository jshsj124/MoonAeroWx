# MoonAeroWx CLI Guide

MoonAeroWx ships a small command line entry under `cmd/aerowx` for quick local checks and demo output.
All commands can be launched from the module root with `moon run cmd/aerowx -- <command> <text>`.

## Commands

| Command | Input | Output |
| --- | --- | --- |
| `decode` | one METAR/SPECI report | readable text summary plus diagnostics |
| `decode-json` | one METAR/SPECI report | compact JSON for scripts |
| `decode-csv` | one METAR/SPECI report | CSV header plus one data row |
| `decode-md` | one METAR/SPECI report | Markdown summary card |
| `validate` | one METAR/SPECI report | diagnostics followed by `valid` or `invalid` |
| `timeline` | one TAF report | expanded text timeline |
| `batch` / `batch-md` | newline-delimited METAR/SPECI reports | Markdown aggregate table |
| `batch-csv` | newline-delimited METAR/SPECI reports | single-row CSV aggregate table |

## METAR examples

```bash
moon run cmd/aerowx -- decode "ZBAA 171200Z 12008MPS 8000 -RA SCT020 BKN040 18/16 Q1008 NOSIG"
moon run cmd/aerowx -- decode-json "METAR KLAX 171253Z 25008KT 10SM FEW015 SCT250 21/16 A2992"
moon run cmd/aerowx -- decode-md "ZBAA 171200Z 12008MPS 0600 R18/P1500U FG OVC004 16/15 Q1008"
moon run cmd/aerowx -- validate "ZBAA 171200Z 99908MPS 8000"
```

## TAF example

```bash
moon run cmd/aerowx -- timeline "TAF ZBAA 171100Z 1712/1812 12008MPS 8000 SCT020 TEMPO 1715/1718 0600 R18/0400V0800D FG OVC004 FM180000 20012MPS 9999 NSW SCT030"
```

## Batch example

PowerShell users can pass embedded newlines with a here-string or by reading a file:

```powershell
$reports = @"
ZBAA 171200Z 12008MPS 9999 SCT020 18/16 Q1008
ZGGG 171300Z VRB03KT 0600 FG OVC004 26/25 Q1004
"@
moon run cmd/aerowx -- batch-csv $reports
```

For shell scripts, prefer `decode-json`, `decode-csv`, and `batch-csv`; for reports and README snippets, prefer `decode-md` and `batch`.
