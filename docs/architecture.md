# MoonAeroWx Architecture Notes

MoonAeroWx starts with a token-preserving parser pipeline:

1. `tokenize` splits whitespace-delimited aviation weather groups and records source spans.
2. `parse_metar` recognizes common METAR/SPECI groups and emits typed fields.
3. `parse_taf` recognizes TAF issue time, valid period, initial conditions, and `FM` / `BECMG` / `TEMPO` / `PROB` / `PROB TEMPO` change groups.
4. Unrecognized regional or remark-like tokens are retained as raw tokens with warnings instead of being silently discarded.
5. `classify` computes VFR/MVFR/IFR/LIFR from configurable thresholds.
6. `taf_timeline` expands parsed TAF change groups into visualization-friendly entries. `FM` groups become replacement intervals ending at the next `FM` group or at the forecast end; `BECMG`, `TEMPO`, and probability groups remain explicit overlays.
7. `metar_to_json`, `metar_to_summary`, and `taf_timeline_to_summary` provide dependency-free output for native, JS, Wasm, and Wasm-GC targets.

Current scope intentionally covers common METAR/SPECI/TAF groups first. Rare regional extensions, RVR, runway state, wind-shear, sea-state, and richer remarks support are planned as incremental parser modules.
