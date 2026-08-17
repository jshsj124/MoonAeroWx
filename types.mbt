///|
pub(all) enum ReportKind {
  Metar
  Speci
  UnspecifiedReport
} derive(Eq, Debug)

///|
pub(all) struct ObservationTime {
  day : Int
  hour : Int
  minute : Int
} derive(Eq, Debug)

///|
pub fn ObservationTime::to_string(self : ObservationTime) -> String {
  "day \{self.day}, \{pad2(self.hour)}:\{pad2(self.minute)} UTC"
}

///|
pub(all) enum WindUnit {
  Knots
  MetersPerSecond
} derive(Eq, Debug)

///|
pub fn WindUnit::to_string(self : WindUnit) -> String {
  match self {
    Knots => "kt"
    MetersPerSecond => "m/s"
  }
}

///|
pub(all) struct Wind {
  direction_degrees : Int?
  variable_direction : Bool
  speed : Int
  gust : Int?
  unit : WindUnit
} derive(Eq, Debug)

///|
pub(all) struct VariableWindDirection {
  from_degrees : Int
  to_degrees : Int
} derive(Eq, Debug)

///|
pub(all) enum VisibilityUnit {
  Meters
  StatuteMiles
} derive(Eq, Debug)

///|
pub(all) struct Visibility {
  value : Int
  unit : VisibilityUnit
  greater_than : Bool
} derive(Eq, Debug)

///|
pub(all) enum WeatherIntensity {
  Light
  Moderate
  Heavy
} derive(Eq, Debug)

///|
pub(all) struct Weather {
  raw : String
  intensity : WeatherIntensity
  description : String
} derive(Eq, Debug)

///|
pub(all) enum CloudCoverage {
  Few
  Scattered
  Broken
  Overcast
  SkyClear
  NoSignificantCloud
  NoCloudDetected
} derive(Eq, Debug)

///|
pub(all) struct CloudLayer {
  coverage : CloudCoverage
  height_feet : Int?
  cumulonimbus : Bool
  towering_cumulus : Bool
} derive(Eq, Debug)

///|
pub(all) struct Temperature {
  air_celsius : Int
  dew_point_celsius : Int
} derive(Eq, Debug)

///|
pub(all) enum PressureUnit {
  HectoPascal
  InchesHgHundredths
} derive(Eq, Debug)

///|
pub(all) struct Pressure {
  value : Int
  unit : PressureUnit
} derive(Eq, Debug)

///|
pub(all) enum RvrTrend {
  RvrIncreasing
  RvrDecreasing
  RvrNoChange
} derive(Eq, Debug)

///|
pub(all) struct RunwayVisualRange {
  runway : String
  minimum_meters : Int
  maximum_meters : Int?
  above_maximum : Bool
  below_minimum : Bool
  trend : RvrTrend?
} derive(Eq, Debug)

///|
pub(all) enum Trend {
  NoSignificantChange
} derive(Eq, Debug)

///|
pub(all) struct MetarReport {
  kind : ReportKind
  station : String
  observation_time : ObservationTime
  automated : Bool
  correction : Bool
  wind : Wind?
  variable_wind : VariableWindDirection?
  visibility : Visibility?
  rvr : Array[RunwayVisualRange]
  cavok : Bool
  weather : Array[Weather]
  clouds : Array[CloudLayer]
  temperature : Temperature?
  pressure : Pressure?
  trend : Trend?
  remarks : Array[String]
} derive(Eq, Debug)

///|
/// Parser result that can carry a partial value plus warnings/errors.
pub(all) struct ParseResult[T] {
  value : T?
  diagnostics : Array[Diagnostic]
} derive(Eq, Debug)

///|
pub fn[T] ParseResult::has_errors(self : ParseResult[T]) -> Bool {
  self.diagnostics.any(fn(diagnostic) { diagnostic.is_error() })
}

///|
pub fn[T] ParseResult::unwrap(self : ParseResult[T]) -> T {
  match self.value {
    Some(value) => value
    None => abort("ParseResult has no value")
  }
}

///|
pub(all) enum FlightCategory {
  VFR
  MVFR
  IFR
  LIFR
  UnknownCategory
} derive(Eq, Debug)

///|
pub(all) struct FlightCategoryRules {
  mvfr_visibility_meters : Int
  ifr_visibility_meters : Int
  lifr_visibility_meters : Int
  mvfr_ceiling_feet : Int
  ifr_ceiling_feet : Int
  lifr_ceiling_feet : Int
} derive(Eq, Debug)

///|
pub(all) struct BatchReport {
  total_reports : Int
  parsed_reports : Int
  error_reports : Int
  warning_reports : Int
  diagnostics_count : Int
  vfr_count : Int
  mvfr_count : Int
  ifr_count : Int
  lifr_count : Int
  unknown_category_count : Int
  low_visibility_events : Int
  low_ceiling_events : Int
} derive(Eq, Debug)

///|
pub fn standard_rules() -> FlightCategoryRules {
  {
    mvfr_visibility_meters: 8047,
    ifr_visibility_meters: 4828,
    lifr_visibility_meters: 1609,
    mvfr_ceiling_feet: 3000,
    ifr_ceiling_feet: 1000,
    lifr_ceiling_feet: 500,
  }
}

///|
fn pad2(value : Int) -> String {
  if value < 10 {
    "0\{value}"
  } else {
    "\{value}"
  }
}

///|
pub(all) struct TafTime {
  day : Int
  hour : Int
  minute : Int
} derive(Eq, Compare, Debug)

///|
pub fn TafTime::to_string(self : TafTime) -> String {
  "day \{self.day}, \{pad2(self.hour)}:\{pad2(self.minute)} UTC"
}

///|
pub(all) struct TafPeriod {
  start : TafTime
  end : TafTime
} derive(Eq, Debug)

///|
pub fn TafPeriod::to_string(self : TafPeriod) -> String {
  "\{self.start.to_string()} to \{self.end.to_string()}"
}

///|
pub(all) struct TafConditions {
  wind : Wind?
  variable_wind : VariableWindDirection?
  visibility : Visibility?
  rvr : Array[RunwayVisualRange]
  cavok : Bool
  weather : Array[Weather]
  clouds : Array[CloudLayer]
  raw_tokens : Array[String]
} derive(Eq, Debug)

///|
pub(all) enum TafChangeKind {
  From
  Becoming
  Temporary
  Probability
  ProbabilityTemporary
} derive(Eq, Debug)

///|
pub(all) struct TafChangeGroup {
  kind : TafChangeKind
  period : TafPeriod?
  from_time : TafTime?
  probability_percent : Int?
  conditions : TafConditions
} derive(Eq, Debug)

///|
pub(all) struct TafTimelineEntry {
  label : String
  period : TafPeriod?
  conditions : TafConditions
  probability_percent : Int?
} derive(Eq, Debug)

///|
pub(all) struct TafReport {
  station : String
  issue_time : ObservationTime?
  valid_period : TafPeriod
  initial : TafConditions
  changes : Array[TafChangeGroup]
  raw : String
} derive(Eq, Debug)
