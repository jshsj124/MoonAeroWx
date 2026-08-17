///|
fn report_lines(source : String) -> Array[String] {
  let lines : Array[String] = []
  source
  .split("\n")
  .each(line_view => {
    let text = match line_view.strip_suffix("\r") {
      Some(value) => value.to_owned()
      None => line_view.to_owned()
    }
    if tokenize(text).length() > 0 {
      lines.push(text)
    }
  })
  lines
}

///|
fn has_warning(diagnostics : Array[Diagnostic]) -> Bool {
  diagnostics.any(fn(diagnostic) { diagnostic.severity == Warning })
}

///|
fn count_category(
  category : FlightCategory,
  report : BatchReport,
) -> BatchReport {
  match category {
    VFR => { ..report, vfr_count: report.vfr_count + 1 }
    MVFR => { ..report, mvfr_count: report.mvfr_count + 1 }
    IFR => { ..report, ifr_count: report.ifr_count + 1 }
    LIFR => { ..report, lifr_count: report.lifr_count + 1 }
    UnknownCategory =>
      { ..report, unknown_category_count: report.unknown_category_count + 1 }
  }
}

///|
fn has_low_visibility(
  report : MetarReport,
  rules : FlightCategoryRules,
) -> Bool {
  match report.visibility {
    Some(value) =>
      match visibility_to_meters(value) {
        Some(meters) => meters < rules.mvfr_visibility_meters
        None => false
      }
    None => false
  }
}

///|
fn has_low_ceiling(report : MetarReport, rules : FlightCategoryRules) -> Bool {
  match ceiling_feet(report) {
    Some(feet) => feet < rules.mvfr_ceiling_feet
    None => false
  }
}

///|
fn empty_batch_report(total_reports : Int) -> BatchReport {
  {
    total_reports,
    parsed_reports: 0,
    error_reports: 0,
    warning_reports: 0,
    diagnostics_count: 0,
    vfr_count: 0,
    mvfr_count: 0,
    ifr_count: 0,
    lifr_count: 0,
    unknown_category_count: 0,
    low_visibility_events: 0,
    low_ceiling_events: 0,
  }
}

///|
/// Parse newline-delimited METAR/SPECI text and return aggregate statistics.
pub fn parse_metar_batch(
  source : String,
  rules? : FlightCategoryRules = standard_rules(),
) -> BatchReport {
  let lines = report_lines(source)
  let mut batch = empty_batch_report(lines.length())
  for line in lines {
    let result = parse_metar(line)
    batch = {
      ..batch,
      diagnostics_count: batch.diagnostics_count + result.diagnostics.length(),
    }
    if result.has_errors() {
      batch = { ..batch, error_reports: batch.error_reports + 1 }
    }
    if has_warning(result.diagnostics) {
      batch = { ..batch, warning_reports: batch.warning_reports + 1 }
    }
    match result.value {
      Some(report) => {
        batch = { ..batch, parsed_reports: batch.parsed_reports + 1 }
        batch = count_category(classify(report, rules~), batch)
        if has_low_visibility(report, rules) {
          batch = {
            ..batch,
            low_visibility_events: batch.low_visibility_events + 1,
          }
        }
        if has_low_ceiling(report, rules) {
          batch = { ..batch, low_ceiling_events: batch.low_ceiling_events + 1 }
        }
      }
      None => ()
    }
  }
  batch
}

///|
/// Summarize newline-delimited METAR/SPECI text directly as Markdown.
pub fn metar_batch_to_markdown(
  source : String,
  rules? : FlightCategoryRules = standard_rules(),
) -> String {
  batch_to_markdown(parse_metar_batch(source, rules~))
}

///|
/// Summarize newline-delimited METAR/SPECI text directly as CSV.
pub fn metar_batch_to_csv(
  source : String,
  rules? : FlightCategoryRules = standard_rules(),
) -> String {
  batch_to_csv(parse_metar_batch(source, rules~))
}
