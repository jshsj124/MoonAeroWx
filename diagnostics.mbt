///|
/// Half-open byte span in a source report. Lines are one-based and columns are
/// one-based for user-facing diagnostics.
pub(all) struct Span {
  start : Int
  end : Int
  line : Int
  column : Int
} derive(Eq, Debug)

///|
pub fn Span::new(
  start : Int,
  end : Int,
  line? : Int = 1,
  column? : Int = 1,
) -> Span {
  { start, end, line, column }
}

///|
pub(all) enum Severity {
  Error
  Warning
  Info
} derive(Eq, Debug)

///|
pub(all) enum DiagnosticCode {
  EmptyInput
  MissingStation
  MissingObservationTime
  InvalidStation
  InvalidTime
  InvalidWind
  InvalidVisibility
  InvalidWeather
  InvalidCloud
  InvalidTemperature
  InvalidPressure
  InvalidTafPeriod
  InvalidTafChange
  InvalidRunwayVisualRange
  UnknownToken
} derive(Eq, Debug)

///|
/// Structured diagnostic emitted by parsers and validators.
pub(all) struct Diagnostic {
  severity : Severity
  code : DiagnosticCode
  message : String
  span : Span
  token : String
} derive(Eq, Debug)

///|
pub fn Diagnostic::new(
  severity : Severity,
  code : DiagnosticCode,
  message : String,
  span : Span,
  token? : String = "",
) -> Diagnostic {
  { severity, code, message, span, token }
}

///|
pub fn Diagnostic::is_error(self : Diagnostic) -> Bool {
  self.severity == Error
}

///|
pub fn Diagnostic::to_string(self : Diagnostic) -> String {
  let level = match self.severity {
    Error => "error"
    Warning => "warning"
    Info => "info"
  }
  "\{level}: \{self.message} at \{self.span.line}:\{self.span.column}"
}
