# Demo Output

These examples show what reviewers can expect from the CLI without needing to inspect internal data structures.

## METAR text summary

Command:

```bash
moon run cmd/aerowx -- decode "ZBAA 171200Z 12008MPS 8000 -RA SCT020 BKN040 18/16 Q1008 NOSIG"
```

Output:

```text
Station: ZBAA
Time: day 17, 12:00 UTC
Wind: 120 deg at 8 m/s
Visibility: 8000 m
Weather: light rain
Clouds: scattered 2000 ft, broken 4000 ft
Temperature: 18 C / Dew point: 16 C
Pressure: 1008 hPa
```

## METAR JSON

Command:

```bash
moon run cmd/aerowx -- decode-json "METAR KLAX 171253Z 25008KT 10SM FEW015 SCT250 21/16 A2992"
```

Output:

```json
{"kind":"METAR","station":"KLAX","observation_time":{"day":17,"hour":12,"minute":53},"automated":false,"correction":false,"wind":{"direction_degrees":250,"variable":false,"speed":8,"gust":null,"unit":"kt"},"visibility":{"value":10,"unit":"sm","greater_than":false},"rvr":[],"weather":[],"clouds":[{"coverage":"few","height_feet":1500},{"coverage":"scattered","height_feet":25000}],"temperature":{"air_celsius":21,"dew_point_celsius":16},"pressure":{"value":2992,"unit":"inhg_hundredths"},"trend":null}
```

## TAF timeline with RVR overlay

Command:

```bash
moon run cmd/aerowx -- timeline "TAF ZBAA 171100Z 1712/1812 12008MPS 8000 SCT020 TEMPO 1715/1718 0600 R18/0400V0800D FG OVC004 FM180000 20012MPS 9999 NSW SCT030"
```

Output:

```text
TAF ZBAA
Valid: day 17, 12:00 UTC to day 18, 12:00 UTC
Issued: day 17, 11:00 UTC
BASE day 17, 12:00 UTC to day 18, 12:00 UTC -> wind 120 deg at 8 m/s; visibility 8000 m; clouds scattered 2000 ft
TEMPO day 17, 15:00 UTC to day 17, 18:00 UTC -> visibility 600 m; RVR R18 400-800 m decreasing; weather fog; clouds overcast 400 ft
FM day 18, 00:00 UTC to day 18, 12:00 UTC -> wind 200 deg at 12 m/s; visibility 9999 m; weather no significant weather; clouds scattered 3000 ft
```

## Batch CSV summary

Command:

```bash
moon run cmd/aerowx -- batch-csv "ZBAA 171200Z 12008MPS 9999 SCT020 18/16 Q1008
ZGGG 171300Z VRB03KT 0600 FG OVC004 26/25 Q1004"
```

Output:

```csv
total_reports,parsed_reports,error_reports,warning_reports,diagnostics_count,vfr_count,mvfr_count,ifr_count,lifr_count,unknown_category_count,low_visibility_events,low_ceiling_events
2,2,0,0,0,1,0,0,1,0,1,1
```
