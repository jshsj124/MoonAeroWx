///|
fn json_escape(text : String) -> String {
  text.replace_all(old="\\", new="\\\\").replace_all(old="\"", new="\\\"")
}

///|
fn quote(text : String) -> String {
  "\"\{json_escape(text)}\""
}

///|
fn opt_int_json(value : Int?) -> String {
  match value {
    Some(number) => "\{number}"
    None => "null"
  }
}

///|
fn opt_int_text(value : Int?) -> String {
  match value {
    Some(number) => "\{number}"
    None => ""
  }
}

///|
fn weather_description_json(weather : Array[Weather]) -> String {
  let mut out = "["
  let mut first = true
  for item in weather {
    if first {
      first = false
    } else {
      out = out + ","
    }
    out = out + quote(item.description.replace_all(old=" ", new="_"))
  }
  out + "]"
}

///|
fn cloud_coverage_text(coverage : CloudCoverage) -> String {
  match coverage {
    Few => "few"
    Scattered => "scattered"
    Broken => "broken"
    Overcast => "overcast"
    SkyClear => "sky_clear"
    NoSignificantCloud => "no_significant_cloud"
    NoCloudDetected => "no_cloud_detected"
  }
}

///|
fn clouds_json(clouds : Array[CloudLayer]) -> String {
  let mut out = "["
  let mut first = true
  for cloud in clouds {
    if first {
      first = false
    } else {
      out = out + ","
    }
    out = out +
      "{\"coverage\":" +
      quote(cloud_coverage_text(cloud.coverage)) +
      ",\"height_feet\":" +
      opt_int_json(cloud.height_feet) +
      "}"
  }
  out + "]"
}

///|
fn wind_json(wind : Wind) -> String {
  let unit = match wind.unit {
    Knots => "kt"
    MetersPerSecond => "mps"
  }
  "{\"direction_degrees\":\{opt_int_json(wind.direction_degrees)},\"variable\":\{wind.variable_direction},\"speed\":\{wind.speed},\"gust\":\{opt_int_json(wind.gust)},\"unit\":\{quote(unit)}}"
}

///|
fn visibility_json(visibility : Visibility) -> String {
  let unit = match visibility.unit {
    Meters => "meters"
    StatuteMiles => "sm"
  }
  "{\"value\":\{visibility.value},\"unit\":\{quote(unit)},\"greater_than\":\{visibility.greater_than}}"
}

///|
fn rvr_trend_text(trend : RvrTrend) -> String {
  match trend {
    RvrIncreasing => "increasing"
    RvrDecreasing => "decreasing"
    RvrNoChange => "no_change"
  }
}

///|
fn rvr_json_item(rvr : RunwayVisualRange) -> String {
  let maximum = opt_int_json(rvr.maximum_meters)
  let trend = match rvr.trend {
    Some(value) => quote(rvr_trend_text(value))
    None => "null"
  }
  "{\"runway\":\{quote(rvr.runway)},\"minimum_meters\":\{rvr.minimum_meters},\"maximum_meters\":\{maximum},\"above_maximum\":\{rvr.above_maximum},\"below_minimum\":\{rvr.below_minimum},\"trend\":\{trend}}"
}

///|
fn rvr_json(rvr_items : Array[RunwayVisualRange]) -> String {
  let mut out = "["
  let mut first = true
  for rvr in rvr_items {
    if first {
      first = false
    } else {
      out = out + ","
    }
    out = out + rvr_json_item(rvr)
  }
  out + "]"
}

///|
fn rvr_summary_item(rvr : RunwayVisualRange) -> String {
  let prefix = if rvr.below_minimum {
    "<"
  } else if rvr.above_maximum {
    ">"
  } else {
    ""
  }
  let value = match rvr.maximum_meters {
    Some(maximum) => "\{rvr.minimum_meters}-\{maximum}"
    None => prefix + "\{rvr.minimum_meters}"
  }
  let trend = match rvr.trend {
    Some(value) => " " + rvr_trend_text(value)
    None => ""
  }
  "R\{rvr.runway} \{value} m\{trend}"
}

///|
fn rvr_summary(rvr_items : Array[RunwayVisualRange]) -> String {
  rvr_items.map(fn(item) { rvr_summary_item(item) }).join(", ")
}

///|
fn pressure_json(pressure : Pressure) -> String {
  let unit = match pressure.unit {
    HectoPascal => "hpa"
    InchesHgHundredths => "inhg_hundredths"
  }
  "{\"value\":\{pressure.value},\"unit\":\{quote(unit)}}"
}

///|
fn report_kind_text(kind : ReportKind) -> String {
  match kind {
    Metar => "METAR"
    Speci => "SPECI"
    UnspecifiedReport => "UNSPECIFIED"
  }
}

///|
/// Convert a parsed METAR/SPECI report to compact JSON without external runtime
/// dependencies. This keeps the MVP portable across native, JS and Wasm targets.
pub fn metar_to_json(report : MetarReport) -> String {
  let wind = match report.wind {
    Some(value) => wind_json(value)
    None => "null"
  }
  let visibility = match report.visibility {
    Some(value) => visibility_json(value)
    None => "null"
  }
  let temperature = match report.temperature {
    Some(value) =>
      "{\"air_celsius\":\{value.air_celsius},\"dew_point_celsius\":\{value.dew_point_celsius}}"
    None => "null"
  }
  let pressure = match report.pressure {
    Some(value) => pressure_json(value)
    None => "null"
  }
  let trend = match report.trend {
    Some(NoSignificantChange) => quote("no_significant_change")
    None => "null"
  }
  "{\"kind\":\{quote(report_kind_text(report.kind))},\"station\":\{quote(report.station)},\"observation_time\":{\"day\":\{report.observation_time.day},\"hour\":\{report.observation_time.hour},\"minute\":\{report.observation_time.minute}},\"automated\":\{report.automated},\"correction\":\{report.correction},\"wind\":\{wind},\"visibility\":\{visibility},\"rvr\":\{rvr_json(report.rvr)},\"weather\":\{weather_description_json(report.weather)},\"clouds\":\{clouds_json(report.clouds)},\"temperature\":\{temperature},\"pressure\":\{pressure},\"trend\":\{trend}}"
}

///|
pub fn metar_to_summary(report : MetarReport) -> String {
  let mut out = "Station: \{report.station}\nTime: \{report.observation_time.to_string()}"
  match report.wind {
    Some(wind) => {
      let direction = match wind.direction_degrees {
        Some(value) => "\{value} deg"
        None => "VRB"
      }
      out = out +
        "\nWind: \{direction} at \{wind.speed} \{wind.unit.to_string()}"
    }
    None => ()
  }
  match report.visibility {
    Some(visibility) => {
      let unit = match visibility.unit {
        Meters => "m"
        StatuteMiles => "SM"
      }
      out = out + "\nVisibility: \{visibility.value} \{unit}"
    }
    None => ()
  }
  if report.rvr.length() > 0 {
    out = out + "\nRVR: " + rvr_summary(report.rvr)
  }
  if report.weather.length() > 0 {
    out = out +
      "\nWeather: " +
      report.weather.map(fn(item) { item.description }).join(", ")
  }
  if report.clouds.length() > 0 {
    out = out +
      "\nClouds: " +
      report.clouds
      .map(fn(cloud) {
        match cloud.height_feet {
          Some(height) => "\{cloud_coverage_text(cloud.coverage)} \{height} ft"
          None => cloud_coverage_text(cloud.coverage)
        }
      })
      .join(", ")
  }
  match report.temperature {
    Some(temp) =>
      out = out +
        "\nTemperature: \{temp.air_celsius} C / Dew point: \{temp.dew_point_celsius} C"
    None => ()
  }
  match report.pressure {
    Some(pressure) => {
      let unit = match pressure.unit {
        HectoPascal => "hPa"
        InchesHgHundredths => "inHg/100"
      }
      out = out + "\nPressure: \{pressure.value} \{unit}"
    }
    None => ()
  }
  out
}

///|
fn taf_wind_summary(wind : Wind) -> String {
  let direction = match wind.direction_degrees {
    Some(value) => "\{value} deg"
    None => "VRB"
  }
  "wind \{direction} at \{wind.speed} \{wind.unit.to_string()}"
}

///|
fn taf_visibility_summary(visibility : Visibility) -> String {
  let unit = match visibility.unit {
    Meters => "m"
    StatuteMiles => "SM"
  }
  "visibility \{visibility.value} \{unit}"
}

///|
fn taf_conditions_summary(conditions : TafConditions) -> String {
  let parts : Array[String] = []
  match conditions.wind {
    Some(wind) => parts.push(taf_wind_summary(wind))
    None => ()
  }
  match conditions.visibility {
    Some(visibility) => parts.push(taf_visibility_summary(visibility))
    None => ()
  }
  if conditions.rvr.length() > 0 {
    parts.push("RVR " + rvr_summary(conditions.rvr))
  }
  if conditions.weather.length() > 0 {
    parts.push(
      "weather " +
      conditions.weather.map(fn(item) { item.description }).join(", "),
    )
  }
  if conditions.clouds.length() > 0 {
    parts.push(
      "clouds " +
      conditions.clouds
      .map(fn(cloud) {
        match cloud.height_feet {
          Some(height) => "\{cloud_coverage_text(cloud.coverage)} \{height} ft"
          None => cloud_coverage_text(cloud.coverage)
        }
      })
      .join(", "),
    )
  }
  if parts.length() == 0 {
    if conditions.raw_tokens.length() == 0 {
      "no decoded conditions"
    } else {
      "raw " + conditions.raw_tokens.join(" ")
    }
  } else {
    parts.join("; ")
  }
}

///|
fn taf_entry_period_summary(period : TafPeriod?) -> String {
  match period {
    Some(value) =>
      if value.end.day < value.start.day {
        value.to_string() + " (crosses month boundary)"
      } else {
        value.to_string()
      }
    None => "period unavailable"
  }
}

///|
/// Render a parsed TAF timeline as a compact text block for CLI demos and docs.
pub fn taf_timeline_to_summary(report : TafReport) -> String {
  let mut out = "TAF " +
    report.station +
    "\nValid: " +
    taf_entry_period_summary(Some(report.valid_period))
  match report.issue_time {
    Some(time) => out = out + "\nIssued: " + time.to_string()
    None => ()
  }
  for entry in taf_timeline(report) {
    let probability = match entry.probability_percent {
      Some(value) => " PROB\{value}"
      None => ""
    }
    out = out +
      "\n" +
      entry.label +
      probability +
      " " +
      taf_entry_period_summary(entry.period) +
      " -> " +
      taf_conditions_summary(entry.conditions)
  }
  out
}

///|
fn csv_quote(text : String) -> String {
  quote(text.replace_all(old="\n", new=" "))
}

///|
fn metar_csv_header() -> String {
  "station,kind,category,day,hour,minute,wind_speed,visibility,rvr_count,ceiling_feet,weather,temperature_c,dew_point_c,pressure"
}

///|
fn metar_csv_row(report : MetarReport) -> String {
  let category = flight_category_to_string(classify(report))
  let wind_speed = match report.wind {
    Some(wind) => "\{wind.speed}"
    None => ""
  }
  let visibility = match report.visibility {
    Some(value) => "\{value.value}"
    None => ""
  }
  let ceiling = opt_int_text(ceiling_feet(report))
  let weather = report.weather.map(fn(item) { item.description }).join("; ")
  let temperature = match report.temperature {
    Some(value) => "\{value.air_celsius}"
    None => ""
  }
  let dew_point = match report.temperature {
    Some(value) => "\{value.dew_point_celsius}"
    None => ""
  }
  let pressure = match report.pressure {
    Some(value) => "\{value.value}"
    None => ""
  }
  [
    csv_quote(report.station),
    csv_quote(report_kind_text(report.kind)),
    csv_quote(category),
    "\{report.observation_time.day}",
    "\{report.observation_time.hour}",
    "\{report.observation_time.minute}",
    wind_speed,
    visibility,
    "\{report.rvr.length()}",
    ceiling,
    csv_quote(weather),
    temperature,
    dew_point,
    pressure,
  ].join(",")
}

///|
/// Convert one parsed METAR/SPECI report into a one-row CSV document.
pub fn metar_to_csv(report : MetarReport) -> String {
  metar_csv_header() + "\n" + metar_csv_row(report)
}

///|
/// Convert one parsed METAR/SPECI report into a Markdown summary card.
pub fn metar_to_markdown(report : MetarReport) -> String {
  let mut out = "## " + report_kind_text(report.kind) + " " + report.station
  out = out + "\n\n| Field | Value |\n| --- | --- |"
  out = out +
    "\n| Category | " +
    flight_category_to_string(classify(report)) +
    " |"
  out = out + "\n| Time | " + report.observation_time.to_string() + " |"
  match report.wind {
    Some(wind) => out = out + "\n| Wind | " + taf_wind_summary(wind) + " |"
    None => ()
  }
  match report.visibility {
    Some(visibility) =>
      out = out +
        "\n| Visibility | " +
        taf_visibility_summary(visibility) +
        " |"
    None => ()
  }
  if report.rvr.length() > 0 {
    out = out + "\n| RVR | " + rvr_summary(report.rvr) + " |"
  }
  if report.weather.length() > 0 {
    out = out +
      "\n| Weather | " +
      report.weather.map(fn(item) { item.description }).join(", ") +
      " |"
  }
  if report.clouds.length() > 0 {
    out = out +
      "\n| Clouds | " +
      report.clouds
      .map(fn(cloud) {
        match cloud.height_feet {
          Some(height) => "\{cloud_coverage_text(cloud.coverage)} \{height} ft"
          None => cloud_coverage_text(cloud.coverage)
        }
      })
      .join(", ") +
      " |"
  }
  match report.temperature {
    Some(temp) =>
      out = out +
        "\n| Temperature | \{temp.air_celsius} C / dew point \{temp.dew_point_celsius} C |"
    None => ()
  }
  match report.pressure {
    Some(pressure) => out = out + "\n| Pressure | \{pressure.value} |"
    None => ()
  }
  out
}

///|
fn batch_metric_row(name : String, value : Int) -> String {
  "| " + name + " | \{value} |"
}

///|
/// Render aggregate batch statistics as a Markdown table.
pub fn batch_to_markdown(batch : BatchReport) -> String {
  [
    "## METAR batch summary",
    "",
    "| Metric | Value |",
    "| --- | ---: |",
    batch_metric_row("Total reports", batch.total_reports),
    batch_metric_row("Parsed reports", batch.parsed_reports),
    batch_metric_row("Reports with errors", batch.error_reports),
    batch_metric_row("Reports with warnings", batch.warning_reports),
    batch_metric_row("Diagnostics", batch.diagnostics_count),
    batch_metric_row("VFR", batch.vfr_count),
    batch_metric_row("MVFR", batch.mvfr_count),
    batch_metric_row("IFR", batch.ifr_count),
    batch_metric_row("LIFR", batch.lifr_count),
    batch_metric_row("Unknown category", batch.unknown_category_count),
    batch_metric_row("Low visibility events", batch.low_visibility_events),
    batch_metric_row("Low ceiling events", batch.low_ceiling_events),
  ].join("\n")
}

///|
/// Render aggregate batch statistics as a single-row CSV document.
pub fn batch_to_csv(batch : BatchReport) -> String {
  "total_reports,parsed_reports,error_reports,warning_reports,diagnostics_count,vfr_count,mvfr_count,ifr_count,lifr_count,unknown_category_count,low_visibility_events,low_ceiling_events\n" +
  "\{batch.total_reports},\{batch.parsed_reports},\{batch.error_reports},\{batch.warning_reports},\{batch.diagnostics_count},\{batch.vfr_count},\{batch.mvfr_count},\{batch.ifr_count},\{batch.lifr_count},\{batch.unknown_category_count},\{batch.low_visibility_events},\{batch.low_ceiling_events}"
}
