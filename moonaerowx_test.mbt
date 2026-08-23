///|
test "tokenizer preserves token spans" {
  let tokens = @moonaerowx.tokenize("ZBAA 171200Z 12008MPS")
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].lexeme, "ZBAA")
  assert_eq(tokens[0].span.column, 1)
  assert_eq(tokens[1].span.column, 6)
  assert_eq(tokens[2].span.column, 14)
}

///|
test "parse synthetic Chinese METAR with MPS wind" {
  let result = @moonaerowx.parse_metar(
    "ZBAA 171200Z 12008MPS 8000 -RA SCT020 BKN040 18/16 Q1008 NOSIG",
  )
  assert_false(result.has_errors())
  let report = result.unwrap()
  assert_eq(report.station, "ZBAA")
  assert_eq(report.observation_time.day, 17)
  assert_eq(report.observation_time.hour, 12)
  assert_eq(report.wind.unwrap().direction_degrees, Some(120))
  assert_eq(report.wind.unwrap().speed, 8)
  assert_eq(report.visibility.unwrap().value, 8000)
  assert_eq(report.weather.length(), 1)
  assert_eq(report.weather[0].description, "light rain")
  assert_eq(report.clouds.length(), 2)
  assert_eq(report.clouds[0].height_feet, Some(2000))
  assert_eq(report.temperature.unwrap().air_celsius, 18)
  assert_eq(report.temperature.unwrap().dew_point_celsius, 16)
  assert_eq(report.pressure.unwrap().value, 1008)
  assert_eq(report.trend, Some(NoSignificantChange))
}

///|
test "parse SPECI with variable wind and low ceiling" {
  let result = @moonaerowx.parse_metar(
    "SPECI ZGGG 171300Z VRB03KT 4000 BR BKN008 26/25 Q1004",
  )
  assert_false(result.has_errors())
  let report = result.unwrap()
  assert_eq(report.kind, Speci)
  assert_true(report.wind.unwrap().variable_direction)
  assert_eq(@moonaerowx.classify(report), IFR)
}

///|
test "parse US-style visibility and altimeter" {
  let result = @moonaerowx.parse_metar(
    "METAR KLAX 171253Z 25008KT 10SM FEW015 SCT250 21/16 A2992",
  )
  assert_false(result.has_errors())
  let report = result.unwrap()
  assert_eq(report.kind, Metar)
  assert_eq(report.visibility.unwrap().unit, StatuteMiles)
  assert_eq(report.pressure.unwrap().unit, InchesHgHundredths)
  assert_eq(@moonaerowx.classify(report), VFR)
}

///|
test "invalid wind direction produces an error with position" {
  let result = @moonaerowx.parse_metar("ZBAA 171200Z 99908MPS 8000")
  assert_true(result.has_errors())
  let diagnostic = result.diagnostics[0]
  assert_eq(diagnostic.code, InvalidWind)
  assert_eq(diagnostic.span.column, 14)
}

///|
test "JSON output contains key decoded fields" {
  let report = @moonaerowx.parse_metar(
    "ZBAA 171200Z 12008MPS 8000 -RA SCT020 18/16 Q1008",
  ).unwrap()
  let json = @moonaerowx.metar_to_json(report)
  assert_true(json.contains("\"station\":\"ZBAA\""))
  assert_true(json.contains("\"weather\":[\"light_rain\"]"))
  assert_true(json.contains("\"pressure\":{\"value\":1008"))
}

///|
test "semantic validation reports non-fatal warnings" {
  let result = @moonaerowx.parse_metar(
    "ZBAA 171200Z 12008MPS 8000 BKN040 BKN020 16/18 Q1008",
  )
  assert_false(result.has_errors())
  assert_eq(result.diagnostics.length(), 2)
  assert_eq(result.diagnostics[0].severity, Warning)
  assert_eq(result.diagnostics[0].code, InvalidTemperature)
  assert_eq(result.diagnostics[1].code, InvalidCloud)
}

///|
test "parse TAF with FM TEMPO BECMG and PROB groups" {
  let taf = @moonaerowx.parse_taf(
    "TAF ZBAA 171100Z 1712/1812 12008MPS 8000 SCT020 TEMPO 1715/1718 3000 RA BKN012 BECMG 1720/1722 18010MPS FM180000 20012MPS 9999 NSW SCT030 PROB30 1806/1810 4000 SHRA BKN020",
  )
  assert_false(taf.has_errors())
  let report = taf.unwrap()
  assert_eq(report.station, "ZBAA")
  assert_eq(report.issue_time.unwrap().hour, 11)
  assert_eq(report.valid_period.start.day, 17)
  assert_eq(report.valid_period.end.day, 18)
  assert_eq(report.initial.wind.unwrap().speed, 8)
  assert_eq(report.changes.length(), 4)
  assert_eq(report.changes[0].kind, Temporary)
  assert_eq(report.changes[0].period.unwrap().start.hour, 15)
  assert_eq(report.changes[1].kind, Becoming)
  assert_eq(report.changes[2].kind, From)
  assert_eq(report.changes[2].from_time.unwrap().day, 18)
  assert_eq(report.changes[3].kind, Probability)
  assert_eq(report.changes[3].probability_percent, Some(30))
}

///|
test "TAF timeline expands FM groups to intervals" {
  let report = @moonaerowx.parse_taf(
    "TAF ZSPD 171100Z 1712/1812 09012KT 9999 FEW030 FM171800 12010KT 8000 BKN020 FM180600 18012KT 9999 SCT030",
  ).unwrap()
  let entries = @moonaerowx.taf_timeline(report)
  assert_eq(entries.length(), 3)
  assert_eq(entries[0].label, "BASE")
  assert_eq(entries[1].label, "FM")
  assert_eq(entries[1].period.unwrap().start.hour, 18)
  assert_eq(entries[1].period.unwrap().end.day, 18)
  assert_eq(entries[1].period.unwrap().end.hour, 6)
  assert_eq(entries[2].period.unwrap().end.hour, 12)
}

///|
test "TAF summary includes probability overlays" {
  let report = @moonaerowx.parse_taf(
    "TAF ZGGG 171100Z 1712/1812 VRB03KT 4000 BR BKN008 PROB40 TEMPO 1716/1720 0800 FG OVC004",
  ).unwrap()
  let summary = @moonaerowx.taf_timeline_to_summary(report)
  assert_true(summary.contains("TAF ZGGG"))
  assert_true(summary.contains("PROB TEMPO PROB40"))
  assert_true(summary.contains("fog"))
}

///|
test "invalid TAF period produces structured error" {
  let taf = @moonaerowx.parse_taf("TAF ZBAA 171100Z 1799/1812 12008MPS")
  assert_true(taf.has_errors())
  assert_eq(taf.diagnostics[0].code, InvalidTafPeriod)
}

///|
test "parse METAR RVR groups" {
  let result = @moonaerowx.parse_metar(
    "ZBAA 171200Z 12008MPS 0600 R18/P1500U R19/0400V0800D FG OVC004 16/15 Q1008",
  )
  assert_false(result.has_errors())
  let report = result.unwrap()
  assert_eq(report.rvr.length(), 2)
  assert_eq(report.rvr[0].runway, "18")
  assert_eq(report.rvr[0].minimum_meters, 1500)
  assert_true(report.rvr[0].above_maximum)
  assert_eq(report.rvr[0].trend, Some(RvrIncreasing))
  assert_eq(report.rvr[1].maximum_meters, Some(800))
  assert_eq(@moonaerowx.classify(report), LIFR)
}

///|
test "TAF condition groups preserve RVR" {
  let taf = @moonaerowx.parse_taf(
    "TAF ZBAA 171100Z 1712/1812 12008MPS 8000 SCT020 TEMPO 1715/1718 0600 R18/0400V0800D FG OVC004",
  )
  assert_false(taf.has_errors())
  let report = taf.unwrap()
  assert_eq(report.changes[0].conditions.rvr.length(), 1)
  assert_eq(report.changes[0].conditions.rvr[0].trend, Some(RvrDecreasing))
  let summary = @moonaerowx.taf_timeline_to_summary(report)
  assert_true(summary.contains("RVR R18 400-800 m decreasing"))
}

///|
test "METAR markdown and CSV include category and RVR" {
  let report = @moonaerowx.parse_metar(
    "ZBAA 171200Z 12008MPS 0600 R18/M0400N FG OVC004 16/15 Q1008",
  ).unwrap()
  let markdown = @moonaerowx.metar_to_markdown(report)
  assert_true(markdown.contains("| Category | LIFR |"))
  assert_true(markdown.contains("R18 <400 m no_change"))
  let csv = @moonaerowx.metar_to_csv(report)
  assert_true(csv.contains("station,kind,category"))
  assert_true(csv.contains("\"ZBAA\",\"UNSPECIFIED\",\"LIFR\""))
}

///|
test "batch statistics render as Markdown and CSV" {
  let source = "ZBAA 171200Z 12008MPS 9999 SCT020 18/16 Q1008\nZGGG 171300Z VRB03KT 0600 FG OVC004 26/25 Q1004\nZSPD 171400Z 99908KT 9999"
  let batch = @moonaerowx.parse_metar_batch(source)
  assert_eq(batch.total_reports, 3)
  assert_eq(batch.parsed_reports, 3)
  assert_eq(batch.error_reports, 1)
  assert_eq(batch.vfr_count, 2)
  assert_eq(batch.lifr_count, 1)
  assert_eq(batch.low_visibility_events, 1)
  assert_eq(batch.low_ceiling_events, 1)
  let markdown = @moonaerowx.batch_to_markdown(batch)
  assert_true(markdown.contains("| Total reports | 3 |"))
  let csv = @moonaerowx.batch_to_csv(batch)
  assert_true(csv.contains("total_reports,parsed_reports"))
  assert_true(csv.contains("3,3,1"))
}

///|
test "invalid RVR runway emits dedicated diagnostic" {
  let result = @moonaerowx.parse_metar(
    "ZBAA 171200Z 12008MPS 0800 R1/P1500U FG OVC004 16/15 Q1008",
  )
  assert_true(result.has_errors())
  let diagnostic = result.diagnostics[0]
  assert_eq(diagnostic.code, InvalidRunwayVisualRange)
  assert_eq(diagnostic.token, "R1/P1500U")
}

///|
test "invalid RVR variable range emits dedicated diagnostic" {
  let result = @moonaerowx.parse_metar(
    "ZBAA 171200Z 12008MPS 0800 R18/040V0800D FG OVC004 16/15 Q1008",
  )
  assert_true(result.has_errors())
  assert_eq(result.diagnostics[0].code, InvalidRunwayVisualRange)
  assert_true(result.diagnostics[0].message.contains("variable range"))
}

///|
test "RVR JSON and summary expose limit flags" {
  let report = @moonaerowx.parse_metar(
    "ZBAA 171200Z 12008MPS 0600 R18/P1500U R19/M0400N FG OVC004 16/15 Q1008",
  ).unwrap()
  let json = @moonaerowx.metar_to_json(report)
  assert_true(json.contains("\"runway\":\"18\""))
  assert_true(json.contains("\"above_maximum\":true"))
  assert_true(json.contains("\"below_minimum\":true"))
  let summary = @moonaerowx.metar_to_summary(report)
  assert_true(summary.contains("R18 >1500 m increasing"))
  assert_true(summary.contains("R19 <400 m no_change"))
}

///|
test "batch convenience formatters parse and render directly" {
  let source = "ZBAA 171200Z 12008MPS 9999 SCT020 18/16 Q1008\nZGGG 171300Z VRB03KT 0600 FG OVC004 26/25 Q1004"
  let markdown = @moonaerowx.metar_batch_to_markdown(source)
  assert_true(markdown.contains("| Total reports | 2 |"))
  assert_true(markdown.contains("| LIFR | 1 |"))
  let csv = @moonaerowx.metar_batch_to_csv(source)
  assert_true(csv.contains("total_reports,parsed_reports"))
  assert_true(csv.contains("2,2,0"))
}

///|
test "CAVOK visibility is recognized as VFR" {
  let result = @moonaerowx.parse_metar(
    "ZBAA 171200Z 12008MPS CAVOK 18/16 Q1008",
  )
  assert_false(result.has_errors())
  let report = result.unwrap()
  assert_true(report.cavok)
  assert_eq(report.visibility.unwrap().value, 10000)
  assert_eq(@moonaerowx.classify(report), VFR)
}

///|
test "unrecognized METAR tokens are preserved as remarks" {
  let result = @moonaerowx.parse_metar(
    "ZBAA 171200Z 12008MPS 8000 SCT020 18/16 Q1008 RMK ABC123",
  )
  assert_false(result.has_errors())
  let report = result.unwrap()
  assert_eq(report.remarks.length(), 1)
  assert_true(report.remarks.contains("ABC123"))
}

///|
test "unknown METAR tokens emit warnings and remain searchable" {
  let result = @moonaerowx.parse_metar(
    "ZBAA 171200Z 12008MPS 8000 SCT020 18/16 Q1008 XYZ",
  )
  assert_false(result.has_errors())
  let report = result.unwrap()
  assert_true(report.remarks.contains("XYZ"))
  assert_true(
    result.diagnostics.any(fn(diagnostic) { diagnostic.code == UnknownToken }),
  )
}

///|
test "parse_speci wrapper preserves explicit report kind" {
  let result = @moonaerowx.parse_speci(
    "SPECI ZGGG 171300Z VRB03KT 4000 BR BKN008 26/25 Q1004",
  )
  assert_false(result.has_errors())
  let report = result.unwrap()
  assert_eq(report.kind, Speci)
  assert_eq(report.station, "ZGGG")
  assert_true(report.wind.unwrap().variable_direction)
  assert_eq(@moonaerowx.classify(report), IFR)
}

///|
test "TAF PROB TEMPO groups retain probability overlays in timeline" {
  let result = @moonaerowx.parse_taf(
    "TAF ZBAA 171100Z 1712/1812 12008MPS 8000 SCT020 PROB40 TEMPO 1715/1718 0600 FG OVC004",
  )
  assert_false(result.has_errors())
  let report = result.unwrap()
  assert_eq(report.changes.length(), 1)
  assert_eq(report.changes[0].kind, ProbabilityTemporary)
  assert_eq(report.changes[0].probability_percent, Some(40))
  let summary = @moonaerowx.taf_timeline_to_summary(report)
  assert_true(summary.contains("PROB TEMPO PROB40"))
  assert_true(summary.contains("visibility 600 m"))
}

///|
test "batch parser ignores blank lines and CRLF endings" {
  let source = "ZBAA 171200Z 12008MPS 9999 SCT020 18/16 Q1008\r\n\r\nZGGG 171300Z VRB03KT 0600 FG OVC004 26/25 Q1004\r\n"
  let batch = @moonaerowx.parse_metar_batch(source)
  assert_eq(batch.total_reports, 2)
  assert_eq(batch.parsed_reports, 2)
  assert_eq(batch.error_reports, 0)
  assert_eq(batch.vfr_count + batch.lifr_count, 2)
}

///|
test "parse_metar rejects empty input" {
  let result = @moonaerowx.parse_metar("")
  assert_true(result.has_errors())
  assert_eq(result.diagnostics[0].code, EmptyInput)
}

///|
test "parse_taf rejects empty input" {
  let result = @moonaerowx.parse_taf("")
  assert_true(result.has_errors())
  assert_eq(result.diagnostics[0].code, EmptyInput)
}

///|
test "parse_taf preserves unknown condition tokens as raw tokens" {
  let result = @moonaerowx.parse_taf(
    "TAF ZBAA 171100Z 1712/1812 12008MPS 8000 SCT020 FOOBAR",
  )
  assert_false(result.has_errors())
  let report = result.unwrap()
  assert_true(report.initial.raw_tokens.contains("FOOBAR"))
  assert_true(
    result.diagnostics.any(fn(diagnostic) { diagnostic.code == UnknownToken }),
  )
  assert_eq(report.changes.length(), 0)
}
