///|
fn taf_error_at(
  token : Token,
  code : DiagnosticCode,
  message : String,
) -> Diagnostic {
  Diagnostic::new(Error, code, message, token.span, token=token.lexeme)
}

///|
fn taf_warning_at(
  token : Token,
  code : DiagnosticCode,
  message : String,
) -> Diagnostic {
  Diagnostic::new(Warning, code, message, token.span, token=token.lexeme)
}

///|
fn default_taf_time() -> TafTime {
  { day: 1, hour: 0, minute: 0 }
}

///|
fn empty_conditions() -> TafConditions {
  {
    wind: None,
    variable_wind: None,
    visibility: None,
    rvr: [],
    cavok: false,
    weather: [],
    clouds: [],
    raw_tokens: [],
  }
}

///|
fn parse_taf_time4(text : StringView) -> TafTime? {
  if text.length() != 4 || !is_digits(text) {
    None
  } else {
    let day = parse_unsigned(text.sub(end=2)).unwrap()
    let hour = parse_unsigned(text.sub(start=2)).unwrap()
    if day >= 1 && day <= 31 && hour >= 0 && hour <= 24 {
      Some({ day, hour, minute: 0 })
    } else {
      None
    }
  }
}

///|
fn parse_taf_time6(text : StringView) -> TafTime? {
  if text.length() != 6 || !is_digits(text) {
    None
  } else {
    let day = parse_unsigned(text.sub(end=2)).unwrap()
    let hour = parse_unsigned(text.sub(start=2, end=4)).unwrap()
    let minute = parse_unsigned(text.sub(start=4)).unwrap()
    if day >= 1 &&
      day <= 31 &&
      hour >= 0 &&
      hour <= 23 &&
      minute >= 0 &&
      minute <= 59 {
      Some({ day, hour, minute })
    } else {
      None
    }
  }
}

///|
fn parse_taf_period_token(token : Token) -> Result[TafPeriod, Diagnostic] {
  match token.lexeme.split_once("/") {
    Some((start_text, end_text)) =>
      match (parse_taf_time4(start_text), parse_taf_time4(end_text)) {
        (Some(start), Some(end)) => Ok({ start, end })
        _ =>
          Err(
            taf_error_at(
              token,
              InvalidTafPeriod,
              "TAF period must use DDHH/DDHH with valid day and hour",
            ),
          )
      }
    None =>
      Err(
        taf_error_at(token, InvalidTafPeriod, "TAF period must use DDHH/DDHH"),
      )
  }
}

///|
fn parse_fm_token(token : Token) -> Result[TafTime, Diagnostic] {
  if token.lexeme.has_prefix("FM") {
    match parse_taf_time6(token.lexeme.sub(start=2)) {
      Some(value) => Ok(value)
      None =>
        Err(
          taf_error_at(
            token,
            InvalidTafChange,
            "FM change group must use FMDDHHMM",
          ),
        )
    }
  } else {
    Err(taf_error_at(token, InvalidTafChange, "expected FMDDHHMM"))
  }
}

///|
fn parse_probability_token(token : Token) -> Int? {
  if token.lexeme.has_prefix("PROB") && token.lexeme.length() == 6 {
    match parse_unsigned(token.lexeme.sub(start=4)) {
      Some(value) => if value >= 0 && value <= 99 { Some(value) } else { None }
      None => None
    }
  } else {
    None
  }
}

///|
fn is_taf_change_marker(token : Token) -> Bool {
  token.lexeme.has_prefix("FM") ||
  token.lexeme == "BECMG" ||
  token.lexeme == "TEMPO" ||
  parse_probability_token(token) is Some(_)
}

///|
fn find_next_taf_change(tokens : Array[Token], start : Int) -> Int {
  let mut index = start
  while index < tokens.length() && !is_taf_change_marker(tokens[index]) {
    index += 1
  }
  index
}

///|
fn parse_taf_condition_tokens(
  tokens : Array[Token],
  start : Int,
  end : Int,
  diagnostics : Array[Diagnostic],
) -> TafConditions {
  let mut conditions = empty_conditions()
  let mut index = start
  while index < end {
    let token = tokens[index]
    let raw = conditions.raw_tokens.copy()
    raw.push(token.lexeme)
    conditions = { ..conditions, raw_tokens: raw }
    if looks_like_wind(token.lexeme) {
      match parse_wind_token(token) {
        Ok(wind) => conditions = { ..conditions, wind: Some(wind) }
        Err(diagnostic) => diagnostics.push(diagnostic)
      }
    } else {
      match parse_variable_wind_token(token) {
        Some(variable_wind) =>
          conditions = { ..conditions, variable_wind: Some(variable_wind) }
        None =>
          match parse_visibility_token(token) {
            Some(visibility) =>
              conditions = {
                ..conditions,
                visibility: Some(visibility),
                cavok: token.lexeme == "CAVOK",
              }
            None =>
              if looks_like_rvr(token.lexeme) {
                match parse_rvr_token(token) {
                  Ok(rvr) => {
                    let rvr_items = conditions.rvr.copy()
                    rvr_items.push(rvr)
                    conditions = { ..conditions, rvr: rvr_items }
                  }
                  Err(diagnostic) => diagnostics.push(diagnostic)
                }
              } else {
                match parse_weather_token(token) {
                  Some(weather) => {
                    let weather_items = conditions.weather.copy()
                    weather_items.push(weather)
                    conditions = { ..conditions, weather: weather_items }
                  }
                  None =>
                    match parse_cloud_token(token) {
                      Some(cloud) => {
                        let cloud_items = conditions.clouds.copy()
                        cloud_items.push(cloud)
                        conditions = { ..conditions, clouds: cloud_items }
                      }
                      None =>
                        diagnostics.push(
                          taf_warning_at(
                            token,
                            UnknownToken,
                            "unrecognized TAF condition token",
                          ),
                        )
                    }
                }
              }
          }
      }
    }
    index += 1
  }
  conditions
}

///|
fn label_for_taf_change(kind : TafChangeKind) -> String {
  match kind {
    From => "FM"
    Becoming => "BECMG"
    Temporary => "TEMPO"
    Probability => "PROB"
    ProbabilityTemporary => "PROB TEMPO"
  }
}

///|
fn next_from_time_after(
  changes : Array[TafChangeGroup],
  start_index : Int,
) -> TafTime? {
  let mut index = start_index + 1
  let mut found : TafTime? = None
  while index < changes.length() && found is None {
    match changes[index].from_time {
      Some(time) => found = Some(time)
      None => ()
    }
    index += 1
  }
  found
}

///|
fn push_taf_change(
  changes : Array[TafChangeGroup],
  kind : TafChangeKind,
  period : TafPeriod?,
  from_time : TafTime?,
  probability_percent : Int?,
  conditions : TafConditions,
) -> Unit {
  changes.push({ kind, period, from_time, probability_percent, conditions })
}

///|
/// Parse a common TAF report with initial conditions and first-class FM, BECMG,
/// TEMPO, PROB and PROB TEMPO change groups.
pub fn parse_taf(source : String) -> ParseResult[TafReport] {
  let diagnostics : Array[Diagnostic] = []
  let tokens = tokenize(source)
  if tokens.length() == 0 {
    diagnostics.push(
      Diagnostic::new(
        Error,
        EmptyInput,
        "TAF report must not be empty",
        Span::new(0, 0),
      ),
    )
    return { value: None, diagnostics }
  }
  let mut index = 0
  if tokens[index].lexeme == "TAF" {
    index += 1
  }
  if index < tokens.length() &&
    (tokens[index].lexeme == "AMD" || tokens[index].lexeme == "COR") {
    index += 1
  }
  if index >= tokens.length() || !is_station_code(tokens[index].lexeme) {
    let anchor = if index < tokens.length() { tokens[index] } else { tokens[0] }
    diagnostics.push(
      taf_error_at(
        anchor,
        InvalidStation,
        "TAF station code must be four uppercase letters/digits",
      ),
    )
    return { value: None, diagnostics }
  }
  let station = tokens[index].lexeme
  index += 1
  let mut issue_time : ObservationTime? = None
  if index < tokens.length() && tokens[index].lexeme.has_suffix("Z") {
    match parse_observation_time_token(tokens[index]) {
      Ok(value) => issue_time = Some(value)
      Err(diagnostic) => diagnostics.push(diagnostic)
    }
    index += 1
  }
  if index >= tokens.length() {
    diagnostics.push(
      Diagnostic::new(
        Error,
        InvalidTafPeriod,
        "TAF valid period is missing",
        Span::new(0, 0),
      ),
    )
    return { value: None, diagnostics }
  }
  let valid_period = match parse_taf_period_token(tokens[index]) {
    Ok(value) => value
    Err(diagnostic) => {
      diagnostics.push(diagnostic)
      { start: default_taf_time(), end: default_taf_time() }
    }
  }
  index += 1
  let initial_end = find_next_taf_change(tokens, index)
  let initial = parse_taf_condition_tokens(
    tokens, index, initial_end, diagnostics,
  )
  index = initial_end
  let changes : Array[TafChangeGroup] = []
  while index < tokens.length() {
    let marker = tokens[index]
    if marker.lexeme.has_prefix("FM") {
      let from_time = match parse_fm_token(marker) {
        Ok(value) => Some(value)
        Err(diagnostic) => {
          diagnostics.push(diagnostic)
          None
        }
      }
      index += 1
      let group_end = find_next_taf_change(tokens, index)
      let conditions = parse_taf_condition_tokens(
        tokens, index, group_end, diagnostics,
      )
      push_taf_change(changes, From, None, from_time, None, conditions)
      index = group_end
    } else if marker.lexeme == "BECMG" || marker.lexeme == "TEMPO" {
      let kind = if marker.lexeme == "BECMG" { Becoming } else { Temporary }
      index += 1
      if index >= tokens.length() {
        diagnostics.push(
          taf_error_at(marker, InvalidTafPeriod, "TAF change period is missing"),
        )
        push_taf_change(changes, kind, None, None, None, empty_conditions())
      } else {
        let period = match parse_taf_period_token(tokens[index]) {
          Ok(value) => Some(value)
          Err(diagnostic) => {
            diagnostics.push(diagnostic)
            None
          }
        }
        index += 1
        let group_end = find_next_taf_change(tokens, index)
        let conditions = parse_taf_condition_tokens(
          tokens, index, group_end, diagnostics,
        )
        push_taf_change(changes, kind, period, None, None, conditions)
        index = group_end
      }
    } else {
      match parse_probability_token(marker) {
        Some(probability) => {
          index += 1
          let mut kind = Probability
          if index < tokens.length() && tokens[index].lexeme == "TEMPO" {
            kind = ProbabilityTemporary
            index += 1
          }
          if index >= tokens.length() {
            diagnostics.push(
              taf_error_at(marker, InvalidTafPeriod, "PROB period is missing"),
            )
            push_taf_change(
              changes,
              kind,
              None,
              None,
              Some(probability),
              empty_conditions(),
            )
          } else {
            let period = match parse_taf_period_token(tokens[index]) {
              Ok(value) => Some(value)
              Err(diagnostic) => {
                diagnostics.push(diagnostic)
                None
              }
            }
            index += 1
            let group_end = find_next_taf_change(tokens, index)
            let conditions = parse_taf_condition_tokens(
              tokens, index, group_end, diagnostics,
            )
            push_taf_change(
              changes,
              kind,
              period,
              None,
              Some(probability),
              conditions,
            )
            index = group_end
          }
        }
        None => {
          diagnostics.push(
            taf_warning_at(
              marker,
              UnknownToken,
              "unrecognized TAF change marker",
            ),
          )
          index += 1
        }
      }
    }
  }
  {
    value: Some({
      station,
      issue_time,
      valid_period,
      initial,
      changes,
      raw: source,
    }),
    diagnostics,
  }
}

///|
/// Expand a parsed TAF into visualization-friendly timeline entries. FM groups
/// become replacement intervals ending at the next FM or the forecast end;
/// BECMG/TEMPO/PROB groups keep their explicit periods as overlays.
pub fn taf_timeline(report : TafReport) -> Array[TafTimelineEntry] {
  let entries : Array[TafTimelineEntry] = []
  entries.push({
    label: "BASE",
    period: Some(report.valid_period),
    conditions: report.initial,
    probability_percent: None,
  })
  let mut index = 0
  while index < report.changes.length() {
    let change = report.changes[index]
    let period = match change.kind {
      From =>
        match change.from_time {
          Some(start) => {
            let end = match next_from_time_after(report.changes, index) {
              Some(value) => value
              None => report.valid_period.end
            }
            Some({ start, end })
          }
          None => None
        }
      _ => change.period
    }
    entries.push({
      label: label_for_taf_change(change.kind),
      period,
      conditions: change.conditions,
      probability_percent: change.probability_percent,
    })
    index += 1
  }
  entries
}
