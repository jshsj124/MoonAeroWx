///|
fn empty_span() -> Span {
  Span::new(0, 0)
}

///|
fn error_at(
  token : Token,
  code : DiagnosticCode,
  message : String,
) -> Diagnostic {
  Diagnostic::new(Error, code, message, token.span, token=token.lexeme)
}

///|
fn warning_at(
  token : Token,
  code : DiagnosticCode,
  message : String,
) -> Diagnostic {
  Diagnostic::new(Warning, code, message, token.span, token=token.lexeme)
}

///|
fn parse_observation_time_token(
  token : Token,
) -> Result[ObservationTime, Diagnostic] {
  let text = token.lexeme
  if text.length() != 7 || !text.has_suffix("Z") || !is_digits(text.sub(end=6)) {
    return Err(
      error_at(token, InvalidTime, "observation time must use DDHHMMZ"),
    )
  }
  let day = parse_unsigned(text.sub(end=2)).unwrap()
  let hour = parse_unsigned(text.sub(start=2, end=4)).unwrap()
  let minute = parse_unsigned(text.sub(start=4, end=6)).unwrap()
  if day < 1 || day > 31 || hour < 0 || hour > 23 || minute < 0 || minute > 59 {
    Err(error_at(token, InvalidTime, "observation time is out of range"))
  } else {
    Ok({ day, hour, minute })
  }
}

///|
fn strip_wind_unit(text : String) -> (StringView, WindUnit)? {
  match text.strip_suffix("MPS") {
    Some(body) => Some((body, MetersPerSecond))
    None =>
      match text.strip_suffix("KT") {
        Some(body) => Some((body, Knots))
        None => None
      }
  }
}

///|
fn parse_wind_token(token : Token) -> Result[Wind, Diagnostic] {
  let text = token.lexeme
  match strip_wind_unit(text) {
    None =>
      Err(error_at(token, InvalidWind, "wind group must end with KT or MPS"))
    Some((body, unit)) => {
      let (direction, variable, rest) = if body.has_prefix("VRB") {
        (None, true, body.sub(start=3))
      } else if body.length() >= 5 && is_digits(body.sub(end=3)) {
        let dir = parse_unsigned(body.sub(end=3)).unwrap()
        if dir > 360 {
          return Err(
            error_at(
              token,
              InvalidWind,
              "wind direction must be 000..360 or VRB",
            ),
          )
        }
        (Some(dir), false, body.sub(start=3))
      } else {
        return Err(
          error_at(token, InvalidWind, "wind direction must be 000..360 or VRB"),
        )
      }
      let (speed_text, gust_text) = match rest.split_once("G") {
        Some((speed, gust)) => (speed, Some(gust))
        None => (rest, None)
      }
      if !is_digits(speed_text) {
        return Err(error_at(token, InvalidWind, "wind speed must be digits"))
      }
      let speed = parse_unsigned(speed_text).unwrap()
      let gust = match gust_text {
        Some(gust_digits) => {
          if !is_digits(gust_digits) {
            return Err(error_at(token, InvalidWind, "wind gust must be digits"))
          }
          Some(parse_unsigned(gust_digits).unwrap())
        }
        None => None
      }
      Ok({
        direction_degrees: direction,
        variable_direction: variable,
        speed,
        gust,
        unit,
      })
    }
  }
}

///|
fn looks_like_wind(text : String) -> Bool {
  text.has_suffix("KT") || text.has_suffix("MPS")
}

///|
fn parse_variable_wind_token(token : Token) -> VariableWindDirection? {
  let text = token.lexeme
  if text.length() == 7 &&
    text.sub(start=3, end=4).equal("V") &&
    is_digits(text.sub(end=3)) &&
    is_digits(text.sub(start=4)) {
    let from_degrees = parse_unsigned(text.sub(end=3)).unwrap()
    let to_degrees = parse_unsigned(text.sub(start=4)).unwrap()
    if from_degrees <= 360 && to_degrees <= 360 {
      Some({ from_degrees, to_degrees })
    } else {
      None
    }
  } else {
    None
  }
}

///|
fn parse_visibility_token(token : Token) -> Visibility? {
  let text = token.lexeme
  if text == "CAVOK" {
    Some({ value: 10000, unit: Meters, greater_than: true })
  } else if text == "P6SM" {
    Some({ value: 6, unit: StatuteMiles, greater_than: true })
  } else if text.has_suffix("SM") {
    let body = text.sub(end=text.length() - 2)
    match parse_unsigned(body) {
      Some(value) => Some({ value, unit: StatuteMiles, greater_than: false })
      None => None
    }
  } else if text.length() == 4 && is_digits(text) {
    let value = parse_unsigned(text).unwrap()
    Some({ value, unit: Meters, greater_than: value == 9999 })
  } else {
    None
  }
}

///|
fn looks_like_rvr(text : String) -> Bool {
  text.has_prefix("R") && text.contains("/")
}

///|
fn parse_rvr_trend(text : StringView) -> (StringView, RvrTrend?) {
  if text.has_suffix("U") {
    (text.sub(end=text.length() - 1), Some(RvrIncreasing))
  } else if text.has_suffix("D") {
    (text.sub(end=text.length() - 1), Some(RvrDecreasing))
  } else if text.has_suffix("N") {
    (text.sub(end=text.length() - 1), Some(RvrNoChange))
  } else {
    (text, None)
  }
}

///|
fn parse_rvr_value(text : StringView) -> (Int, Bool, Bool)? {
  let (body, above, below) = match text.strip_prefix("P") {
    Some(rest) => (rest, true, false)
    None =>
      match text.strip_prefix("M") {
        Some(rest) => (rest, false, true)
        None => (text, false, false)
      }
  }
  if body.length() == 4 && is_digits(body) {
    Some((parse_unsigned(body).unwrap(), above, below))
  } else {
    None
  }
}

///|
fn is_valid_runway_designator(text : StringView) -> Bool {
  if text.length() == 2 && is_digits(text) {
    true
  } else if text.length() == 3 && is_digits(text.sub(end=2)) {
    let suffix = text.sub(start=2)
    suffix == "L" || suffix == "R" || suffix == "C"
  } else {
    false
  }
}

///|
fn parse_rvr_token(token : Token) -> Result[RunwayVisualRange, Diagnostic] {
  match token.lexeme.split_once("/") {
    Some((runway_text, body_text)) => {
      let runway_body = runway_text.sub(start=1)
      if !runway_text.has_prefix("R") ||
        !is_valid_runway_designator(runway_body) {
        return Err(
          error_at(
            token,
            InvalidRunwayVisualRange,
            "RVR group must start with runway designator such as R27/ or R09L/",
          ),
        )
      }
      let runway = runway_body.to_owned()
      let (body, trend) = parse_rvr_trend(body_text)
      match body.split_once("V") {
        Some((minimum_text, maximum_text)) =>
          match (parse_rvr_value(minimum_text), parse_rvr_value(maximum_text)) {
            (
              Some((minimum_meters, above1, below1)),
              Some((maximum_meters, above2, below2)),
            ) =>
              Ok({
                runway,
                minimum_meters,
                maximum_meters: Some(maximum_meters),
                above_maximum: above1 || above2,
                below_minimum: below1 || below2,
                trend,
              })
            _ =>
              Err(
                error_at(
                  token,
                  InvalidRunwayVisualRange,
                  "RVR variable range must use four digit meter values",
                ),
              )
          }
        None =>
          match parse_rvr_value(body) {
            Some((minimum_meters, above, below)) =>
              Ok({
                runway,
                minimum_meters,
                maximum_meters: None,
                above_maximum: above,
                below_minimum: below,
                trend,
              })
            None =>
              Err(
                error_at(
                  token,
                  InvalidRunwayVisualRange,
                  "RVR value must use four digit meters, optionally prefixed by P or M",
                ),
              )
          }
      }
    }
    None =>
      Err(
        error_at(
          token,
          InvalidRunwayVisualRange,
          "RVR group must contain a runway/value separator '/'",
        ),
      )
  }
}

///|
fn decode_weather(text : String) -> String? {
  match text {
    "RA" => Some("rain")
    "-RA" => Some("light rain")
    "+RA" => Some("heavy rain")
    "BR" => Some("mist")
    "FG" => Some("fog")
    "TS" => Some("thunderstorm")
    "TSRA" => Some("thunderstorm rain")
    "-TSRA" => Some("light thunderstorm rain")
    "+TSRA" => Some("heavy thunderstorm rain")
    "SHRA" => Some("rain shower")
    "-SHRA" => Some("light rain shower")
    "+SHRA" => Some("heavy rain shower")
    "DZ" => Some("drizzle")
    "SN" => Some("snow")
    "HZ" => Some("haze")
    "NSW" => Some("no significant weather")
    _ => None
  }
}

///|
fn parse_weather_token(token : Token) -> Weather? {
  match decode_weather(token.lexeme) {
    Some(description) => {
      let intensity = if token.lexeme.has_prefix("-") {
        Light
      } else if token.lexeme.has_prefix("+") {
        Heavy
      } else {
        Moderate
      }
      Some({ raw: token.lexeme, intensity, description })
    }
    None => None
  }
}

///|
fn coverage_from_prefix(prefix : StringView) -> CloudCoverage? {
  match prefix {
    "FEW" => Some(Few)
    "SCT" => Some(Scattered)
    "BKN" => Some(Broken)
    "OVC" => Some(Overcast)
    _ => None
  }
}

///|
fn parse_cloud_token(token : Token) -> CloudLayer? {
  let text = token.lexeme
  match text {
    "SKC" | "CLR" =>
      Some({
        coverage: SkyClear,
        height_feet: None,
        cumulonimbus: false,
        towering_cumulus: false,
      })
    "NSC" =>
      Some({
        coverage: NoSignificantCloud,
        height_feet: None,
        cumulonimbus: false,
        towering_cumulus: false,
      })
    "NCD" =>
      Some({
        coverage: NoCloudDetected,
        height_feet: None,
        cumulonimbus: false,
        towering_cumulus: false,
      })
    _ => {
      if text.length() < 6 {
        return None
      }
      match coverage_from_prefix(text.sub(end=3)) {
        Some(coverage) => {
          let height_text = text.sub(start=3, end=6)
          if !is_digits(height_text) {
            return None
          }
          let suffix = text.sub(start=6)
          let cumulonimbus = suffix.equal("CB")
          let towering_cumulus = suffix.equal("TCU")
          if !suffix.is_empty() && !cumulonimbus && !towering_cumulus {
            return None
          }
          Some({
            coverage,
            height_feet: Some(parse_unsigned(height_text).unwrap() * 100),
            cumulonimbus,
            towering_cumulus,
          })
        }
        None => None
      }
    }
  }
}

///|
fn parse_temperature_token(token : Token) -> Temperature? {
  match token.lexeme.split_once("/") {
    Some((air, dew)) =>
      match (parse_signed_metar_int(air), parse_signed_metar_int(dew)) {
        (Some(air_celsius), Some(dew_point_celsius)) =>
          Some({ air_celsius, dew_point_celsius })
        _ => None
      }
    None => None
  }
}

///|
fn parse_pressure_token(token : Token) -> Pressure? {
  let text = token.lexeme
  if text.length() == 5 && text.has_prefix("Q") && is_digits(text.sub(start=1)) {
    Some({
      value: parse_unsigned(text.sub(start=1)).unwrap(),
      unit: HectoPascal,
    })
  } else if text.length() == 5 &&
    text.has_prefix("A") &&
    is_digits(text.sub(start=1)) {
    Some({
      value: parse_unsigned(text.sub(start=1)).unwrap(),
      unit: InchesHgHundredths,
    })
  } else {
    None
  }
}

///|
fn default_time() -> ObservationTime {
  { day: 1, hour: 0, minute: 0 }
}

///|
fn classify_token(
  token : Token,
  report : MetarReport,
  diagnostics : Array[Diagnostic],
) -> MetarReport {
  if token.lexeme == "AUTO" {
    return { ..report, automated: true }
  }
  if token.lexeme == "COR" {
    return { ..report, correction: true }
  }
  if token.lexeme == "NOSIG" {
    return { ..report, trend: Some(NoSignificantChange) }
  }
  if looks_like_wind(token.lexeme) {
    match parse_wind_token(token) {
      Ok(wind) => return { ..report, wind: Some(wind) }
      Err(diagnostic) => {
        diagnostics.push(diagnostic)
        return report
      }
    }
  }
  match parse_variable_wind_token(token) {
    Some(variable_wind) =>
      return { ..report, variable_wind: Some(variable_wind) }
    None => ()
  }
  match parse_visibility_token(token) {
    Some(visibility) =>
      return {
        ..report,
        visibility: Some(visibility),
        cavok: token.lexeme == "CAVOK",
      }
    None => ()
  }
  if looks_like_rvr(token.lexeme) {
    match parse_rvr_token(token) {
      Ok(rvr) => {
        let rvr_items = report.rvr.copy()
        rvr_items.push(rvr)
        return { ..report, rvr: rvr_items }
      }
      Err(diagnostic) => {
        diagnostics.push(diagnostic)
        return report
      }
    }
  }
  match parse_weather_token(token) {
    Some(weather) => {
      let items = report.weather.copy()
      items.push(weather)
      return { ..report, weather: items }
    }
    None => ()
  }
  match parse_cloud_token(token) {
    Some(cloud) => {
      let clouds = report.clouds.copy()
      clouds.push(cloud)
      return { ..report, clouds, }
    }
    None => ()
  }
  match parse_temperature_token(token) {
    Some(temperature) => return { ..report, temperature: Some(temperature) }
    None => ()
  }
  match parse_pressure_token(token) {
    Some(pressure) => return { ..report, pressure: Some(pressure) }
    None => ()
  }
  diagnostics.push(warning_at(token, UnknownToken, "unrecognized METAR token"))
  let remarks = report.remarks.copy()
  remarks.push(token.lexeme)
  { ..report, remarks, }
}

///|
fn validate_metar_report(
  report : MetarReport,
  diagnostics : Array[Diagnostic],
) -> Unit {
  match report.temperature {
    Some(temp) =>
      if temp.dew_point_celsius > temp.air_celsius {
        diagnostics.push(
          Diagnostic::new(
            Warning,
            InvalidTemperature,
            "dew point is higher than air temperature",
            empty_span(),
          ),
        )
      }
    None => ()
  }
  let mut previous_height : Int? = None
  for cloud in report.clouds {
    match cloud.height_feet {
      Some(height) => {
        match previous_height {
          Some(previous) =>
            if height < previous {
              diagnostics.push(
                Diagnostic::new(
                  Warning,
                  InvalidCloud,
                  "cloud layer heights are not in ascending order",
                  empty_span(),
                ),
              )
            }
          None => ()
        }
        previous_height = Some(height)
      }
      None => ()
    }
  }
}

///|
/// Parse a common METAR or SPECI report. The parser is deliberately tolerant:
/// unknown regional/remark tokens are preserved as remarks with warnings.
pub fn parse_metar(source : String) -> ParseResult[MetarReport] {
  let diagnostics : Array[Diagnostic] = []
  let tokens = tokenize(source)
  if tokens.length() == 0 {
    diagnostics.push(
      Diagnostic::new(
        Error,
        EmptyInput,
        "report must not be empty",
        empty_span(),
      ),
    )
    return { value: None, diagnostics }
  }
  let mut index = 0
  let kind = match tokens[0].lexeme {
    "METAR" => {
      index = 1
      Metar
    }
    "SPECI" => {
      index = 1
      Speci
    }
    _ => UnspecifiedReport
  }
  if index >= tokens.length() {
    diagnostics.push(
      Diagnostic::new(
        Error,
        MissingStation,
        "station code is missing",
        empty_span(),
      ),
    )
    return { value: None, diagnostics }
  }
  let station_token = tokens[index]
  if !is_station_code(station_token.lexeme) {
    diagnostics.push(
      error_at(
        station_token,
        InvalidStation,
        "station code must be four uppercase letters/digits",
      ),
    )
    return { value: None, diagnostics }
  }
  index += 1
  if index >= tokens.length() {
    diagnostics.push(
      Diagnostic::new(
        Error,
        MissingObservationTime,
        "observation time is missing",
        empty_span(),
      ),
    )
    return { value: None, diagnostics }
  }
  let time_token = tokens[index]
  let observation_time = match parse_observation_time_token(time_token) {
    Ok(value) => value
    Err(diagnostic) => {
      diagnostics.push(diagnostic)
      default_time()
    }
  }
  index += 1
  let mut report : MetarReport = {
    kind,
    station: station_token.lexeme,
    observation_time,
    automated: false,
    correction: false,
    wind: None,
    variable_wind: None,
    visibility: None,
    rvr: [],
    cavok: false,
    weather: [],
    clouds: [],
    temperature: None,
    pressure: None,
    trend: None,
    remarks: [],
  }
  let mut in_remarks = false
  while index < tokens.length() {
    let token = tokens[index]
    if in_remarks {
      let remarks = report.remarks.copy()
      remarks.push(token.lexeme)
      report = { ..report, remarks, }
    } else if token.lexeme == "RMK" {
      in_remarks = true
    } else {
      report = classify_token(token, report, diagnostics)
    }
    index += 1
  }
  validate_metar_report(report, diagnostics)
  { value: Some(report), diagnostics }
}

///|
pub fn parse_speci(source : String) -> ParseResult[MetarReport] {
  parse_metar(source)
}
