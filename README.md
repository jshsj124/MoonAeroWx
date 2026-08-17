# MoonAeroWx

**MoonBit 航空气象报文解析与趋势分析工具包**

MoonAeroWx is a pure MoonBit toolkit for parsing aviation weather reports. The current milestone focuses on common METAR/SPECI groups, RVR-aware TAF timelines, structured diagnostics, JSON/Markdown/CSV output, batch statistics, and configurable flight-category classification.

> Safety notice: MoonAeroWx is intended for software development, education, and offline data analysis. It is not certified and must not be used for real aviation operational decisions.


## 项目信息

| 字段 | 内容 |
| --- | --- |
| 项目名称 | MoonAeroWx |
| 项目标识 | `jshsj124/moonaerowx` |
| 项目描述 | 基于 MoonBit 的航空气象报文解析与趋势分析工具包，支持 METAR/SPECI/TAF 解析、RVR 识别、飞行类别判定、批量统计以及 JSON/Markdown/CSV 输出。 |
| 仓库地址 | https://github.com/jshsj124/MoonAeroWx |
| 包名 | `jshsj124/moonaerowx` |
| 许可证 | Apache-2.0 |

## 文档导航

- [架构说明](docs/architecture.md)
- [CLI 使用指南](docs/cli.md)
- [批量分析流程](docs/batch.md)
- [功能覆盖矩阵](docs/coverage.md)
- [诊断码参考](docs/diagnostics.md)
- [局限性与安全边界](docs/limitations.md)
- [演示输出](docs/demo-output.md)

## Current MVP

- Whitespace tokenizer with source spans.
- Tolerant METAR/SPECI parser.
- Common groups:
  - report kind: `METAR`, `SPECI`, or omitted;
  - station code;
  - observation time `DDHHMMZ`;
  - wind groups such as `12008MPS`, `25008KT`, `VRB03KT`, `22015G25KT`;
  - visibility groups such as `8000`, `9999`, `10SM`, `P6SM`, `CAVOK`;
  - selected weather groups such as `-RA`, `BR`, `FG`, `TSRA`, `SHRA`, `NSW`;
  - clouds such as `FEW020`, `SCT020`, `BKN040`, `OVC008`, `SKC`, `NSC`;
  - temperature/dew point such as `18/16`, `M02/M05`;
  - pressure `Q1008` and `A2992`;
  - runway visual range such as `R18/P1500U`, `R19/0400V0800D`;
  - `NOSIG` trend;
  - raw remark preservation.
- Compact JSON, Markdown, CSV and plain-text summary formatting.
- Newline-delimited batch statistics with Markdown/CSV reports.
- VFR/MVFR/IFR/LIFR classification with configurable thresholds.
- TAF parser for issue time, valid period, initial forecast, `FM`, `BECMG`, `TEMPO`, `PROB`, and `PROB TEMPO` groups.
- Visualization-friendly TAF timeline expansion and text timeline output.

## Library example

```moonbit nocheck
///|
test "decode a simple METAR" {
  let result = @moonaerowx.parse_metar(
    "ZBAA 171200Z 12008MPS 8000 -RA SCT020 BKN040 18/16 Q1008 NOSIG",
  )
  assert_false(result.has_errors())
  let report = result.unwrap()
  assert_eq(report.station, "ZBAA")
  assert_eq(report.wind.unwrap().speed, 8)
  assert_eq(report.weather[0].description, "light rain")
}
```


## Batch and export example

```moonbit nocheck
///|
test "summarize a batch" {
  let source = "ZBAA 171200Z 12008MPS 9999 SCT020 18/16 Q1008
ZGGG 171300Z VRB03KT 0600 FG OVC004 26/25 Q1004"
  let batch = @moonaerowx.parse_metar_batch(source)
  assert_eq(batch.total_reports, 2)
  assert_eq(batch.lifr_count, 1)
  assert_true(@moonaerowx.batch_to_markdown(batch).contains("METAR batch summary"))
  assert_true(@moonaerowx.batch_to_csv(batch).contains("total_reports"))
}
```

## CLI examples

```bash
moon run cmd/aerowx -- decode "ZBAA 171200Z 12008MPS 8000 -RA SCT020 18/16 Q1008"
moon run cmd/aerowx -- decode-json "METAR KLAX 171253Z 25008KT 10SM FEW015 SCT250 21/16 A2992"
moon run cmd/aerowx -- decode-md "ZBAA 171200Z 12008MPS 0600 R18/P1500U FG OVC004 16/15 Q1008"
moon run cmd/aerowx -- decode-csv "ZBAA 171200Z 12008MPS 8000 -RA SCT020 18/16 Q1008"
moon run cmd/aerowx -- validate "ZBAA 171200Z 99908MPS 8000"
moon run cmd/aerowx -- timeline "TAF ZBAA 171100Z 1712/1812 12008MPS 8000 SCT020 TEMPO 1715/1718 0600 R18/0400V0800D FG OVC004 FM180000 20012MPS 9999 NSW SCT030"
moon run cmd/aerowx -- batch-csv "ZBAA 171200Z 12008MPS 9999 SCT020 18/16 Q1008
ZGGG 171300Z VRB03KT 0600 FG OVC004 26/25 Q1004"
```

## Roadmap

1. Harden remaining METAR grammar and diagnostics.
2. Add runway state, wind-shear, sea-state and richer remarks support.
3. Harden TAF edge cases, nested regional groups, and month-boundary semantics.
4. Add Wasm demo assets and richer batch input adapters.
5. Add multi-backend CI and publishing metadata once the GitHub/GitLink repositories are created.

## License

Apache-2.0.

