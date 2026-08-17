///|
fn print_usage() -> Unit {
  println("MoonAeroWx - aviation weather report parser")
  println("")
  println("Usage:")
  println("  aerowx decode <METAR text>")
  println("  aerowx decode-json <METAR text>")
  println("  aerowx decode-csv <METAR text>")
  println("  aerowx decode-md <METAR text>")
  println("  aerowx validate <METAR text>")
  println("  aerowx timeline <TAF text>")
  println("  aerowx batch <newline-delimited METAR text>")
  println("  aerowx batch-csv <newline-delimited METAR text>")
}

///|
fn[T] print_diagnostics(result : @lib.ParseResult[T]) -> Unit {
  for diagnostic in result.diagnostics {
    println(diagnostic.to_string())
  }
}

///|
fn main {
  let args = @env.args()
  if args.length() < 2 {
    print_usage()
    return
  }
  match args[1] {
    "help" | "--help" | "-h" => print_usage()
    "decode" => {
      if args.length() < 3 {
        println("error: expected METAR text")
        return
      }
      let result = @lib.parse_metar(args[2])
      print_diagnostics(result)
      match result.value {
        Some(report) => println(@lib.metar_to_summary(report))
        None => ()
      }
    }
    "decode-json" => {
      if args.length() < 3 {
        println("error: expected METAR text")
        return
      }
      let result = @lib.parse_metar(args[2])
      if result.has_errors() {
        print_diagnostics(result)
      }
      match result.value {
        Some(report) => println(@lib.metar_to_json(report))
        None => ()
      }
    }
    "decode-csv" => {
      if args.length() < 3 {
        println("error: expected METAR text")
        return
      }
      let result = @lib.parse_metar(args[2])
      if result.has_errors() {
        print_diagnostics(result)
      }
      match result.value {
        Some(report) => println(@lib.metar_to_csv(report))
        None => ()
      }
    }
    "decode-md" => {
      if args.length() < 3 {
        println("error: expected METAR text")
        return
      }
      let result = @lib.parse_metar(args[2])
      if result.has_errors() {
        print_diagnostics(result)
      }
      match result.value {
        Some(report) => println(@lib.metar_to_markdown(report))
        None => ()
      }
    }
    "timeline" => {
      if args.length() < 3 {
        println("error: expected TAF text")
        return
      }
      let result = @lib.parse_taf(args[2])
      print_diagnostics(result)
      match result.value {
        Some(report) => println(@lib.taf_timeline_to_summary(report))
        None => ()
      }
    }
    "batch" | "batch-md" => {
      if args.length() < 3 {
        println("error: expected newline-delimited METAR text")
        return
      }
      println(@lib.metar_batch_to_markdown(args[2]))
    }
    "batch-csv" => {
      if args.length() < 3 {
        println("error: expected newline-delimited METAR text")
        return
      }
      println(@lib.metar_batch_to_csv(args[2]))
    }
    "validate" => {
      if args.length() < 3 {
        println("error: expected METAR text")
        return
      }
      let result = @lib.parse_metar(args[2])
      print_diagnostics(result)
      if result.has_errors() {
        println("invalid")
      } else {
        println("valid")
      }
    }
    command => {
      println("error: unknown command '\{command}'")
      print_usage()
    }
  }
}
