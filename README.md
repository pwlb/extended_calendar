# extended_calendar

## Usage:

```erlang
1> extended_calendar:date_add({{2015, 8, 12}, {22, 00, 00}}, 60, second).
{{2015,8,12},{22,1,0}}
2> extended_calendar:date_add({{2015, 8, 12}, {22, 00, 00}}, -24, hour).
{{2015,8,11},{22,0,0}}