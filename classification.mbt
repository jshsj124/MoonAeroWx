///|
fn visibility_to_meters(visibility : Visibility) -> Int? {
  match visibility.unit {
    Meters => Some(visibility.value)
    StatuteMiles => Some(visibility.value * 1609)
  }
}

///|
fn ceiling_feet(report : MetarReport) -> Int? {
  let mut best : Int? = None
  for cloud in report.clouds {
    match (cloud.coverage, cloud.height_feet) {
      (Broken | Overcast, Some(height)) =>
        match best {
          Some(current) => if height < current { best = Some(height) }
          None => best = Some(height)
        }
      _ => ()
    }
  }
  best
}

///|
pub fn flight_category_to_string(category : FlightCategory) -> String {
  match category {
    VFR => "VFR"
    MVFR => "MVFR"
    IFR => "IFR"
    LIFR => "LIFR"
    UnknownCategory => "UNKNOWN"
  }
}

///|
/// Classify a report using configurable visibility and ceiling thresholds.
pub fn classify(
  report : MetarReport,
  rules? : FlightCategoryRules = standard_rules(),
) -> FlightCategory {
  let visibility = match report.visibility {
    Some(value) => visibility_to_meters(value)
    None => None
  }
  let ceiling = ceiling_feet(report)
  match (visibility, ceiling) {
    (None, None) => UnknownCategory
    _ => {
      let low_visibility = match visibility {
        Some(value) => value
        None => 999999
      }
      let low_ceiling = match ceiling {
        Some(value) => value
        None => 999999
      }
      if low_visibility < rules.lifr_visibility_meters ||
        low_ceiling < rules.lifr_ceiling_feet {
        LIFR
      } else if low_visibility < rules.ifr_visibility_meters ||
        low_ceiling < rules.ifr_ceiling_feet {
        IFR
      } else if low_visibility < rules.mvfr_visibility_meters ||
        low_ceiling < rules.mvfr_ceiling_feet {
        MVFR
      } else {
        VFR
      }
    }
  }
}
