///|
/// A whitespace-delimited token with source position. METAR/TAF syntax is mostly
/// token based, so the first lexer keeps raw groups while preserving spans for
/// diagnostics.
pub(all) struct Token {
  lexeme : String
  span : Span
} derive(Eq, Debug)

///|
pub fn Token::to_string(self : Token) -> String {
  self.lexeme
}

///|
pub fn tokenize(source : String) -> Array[Token] {
  let tokens : Array[Token] = []
  source
  .split(" ")
  .filter(part => !part.is_empty())
  .each(part => {
    let start = part.start_offset()
    let text = part.to_owned()
    tokens.push({
      lexeme: text,
      span: Span::new(start, start + text.length(), line=1, column=start + 1),
    })
  })
  tokens
}

///|
fn is_ascii_upper(ch : Char) -> Bool {
  ch >= 'A' && ch <= 'Z'
}

///|
fn is_ascii_digit(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
}

///|
fn is_station_char(ch : Char) -> Bool {
  is_ascii_upper(ch) || is_ascii_digit(ch)
}

///|
fn is_station_code(text : String) -> Bool {
  text.length() == 4 && text.all(is_station_char)
}

///|
fn is_digits(text : StringView) -> Bool {
  !text.is_empty() && text.all(is_ascii_digit)
}

///|
fn parse_unsigned(text : StringView) -> Int? {
  if text.is_empty() {
    return None
  }
  let mut value = 0
  let mut valid = true
  text
  .iter()
  .each(ch => {
    if is_ascii_digit(ch) {
      value = value * 10 + (ch.to_int() - '0'.to_int())
    } else {
      valid = false
    }
  })
  if valid {
    Some(value)
  } else {
    None
  }
}

///|
fn parse_signed_metar_int(text : StringView) -> Int? {
  if text.is_empty() {
    return None
  }
  match text.strip_prefix("M") {
    Some(rest) =>
      match parse_unsigned(rest) {
        Some(value) => Some(-value)
        None => None
      }
    None => parse_unsigned(text)
  }
}
