%% @author Paweł Banasiak <banasiak@banasiak.net>

-module(extended_calendar).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-export([
		 date_add/3
		]).

-type time_unit() :: year | quarter | month | day | hour | minute | second.

%% ====================================================================
%% API functions
%% ====================================================================

-spec date_add(calendar:datetime(), integer(), time_unit()) -> calendar:datetime().
date_add(DateTime, 0, _) ->
	DateTime;

date_add({Date, {H, I, S}}, Value, second) ->
	date_add_second_helper({Date, {H, I, S + Value}});

date_add({Date, {H, I, S}}, Value, minute) ->
	date_add_minute_helper({Date, {H, I + Value, S}});

date_add({Date, {H, I, S}}, Value, hour) ->
	date_add_hour_helper({Date, {H + Value, I, S}});

date_add({Date, Time}, Value, day) ->
	{calendar:gregorian_days_to_date(calendar:date_to_gregorian_days(Date) + Value), Time};

date_add(DateTime, Value, week) ->
	date_add(DateTime, Value * 7, day);

date_add({{Y, M, D}, Time}, Value, month) ->
	Months = Y * 12 + M - 1 + Value,
	Year = Months div 12,
	Month = Months - Year * 12 + 1,
	fix_day({{Year, Month, D}, Time});

date_add(DateTime, Value, quarter) ->
	date_add(DateTime, Value * 3, month);

date_add({{Y, M, D}, Time}, Value, year) ->
	fix_day({{Y + Value, M, D}, Time}).

%% ====================================================================
%% Internal functions
%% ====================================================================

date_add_second_helper({Date, {H, I, S}}) when S > 59 ->
	Minutes = S div 60,
	Second = S - Minutes * 60,
	date_add({Date, {H, I, Second}}, Minutes, minute);
date_add_second_helper({Date, {H, I, S}}) when S < 0 ->
	Minutes = (59 - S) div -60,
	Second = S - Minutes * 60,
	date_add({Date, {H, I, Second}}, Minutes, minute);
date_add_second_helper(DateTime) ->
	DateTime.

date_add_minute_helper({Date, {H, I, S}}) when I > 59 ->
	Hours = I div 60,
	Minute = I - Hours * 60,
	date_add({Date, {H, Minute, S}}, Hours, hour);
date_add_minute_helper({Date, {H, I, S}}) when I < 0 ->
	Hours = (59 - I) div -60,
	Minute = I - Hours * 60,
	date_add({Date, {H, Minute, S}}, Hours, hour);
date_add_minute_helper(DateTime) ->
	DateTime.

date_add_hour_helper({Date, {H, I, S}}) when H > 23 ->
	Days = H div 24,
	Hour = H - Days * 24,
	date_add({Date, {Hour, I, S}}, Days, day);
date_add_hour_helper({Date, {H, I, S}}) when H < 0 ->
	Days = (23 - H) div -24,
	Hour = H - Days * 24,
	date_add({Date, {Hour, I, S}}, Days, day);
date_add_hour_helper(DateTime) ->
	DateTime.

fix_day({{Y, 2, D}, Time}) when D > 28 ->
	case calendar:is_leap_year(Y) of
		true -> {{Y, 2, 29}, Time};
		false -> {{Y, 2, 28}, Time}
	end;
fix_day({{Y, 4, 31}, Time}) -> {{Y, 4, 30}, Time};
fix_day({{Y, 6, 31}, Time}) -> {{Y, 6, 30}, Time};
fix_day({{Y, 9, 31}, Time}) -> {{Y, 9, 30}, Time};
fix_day({{Y, 11, 31}, Time}) -> {{Y, 11, 30}, Time};
fix_day(DateTime) ->
	DateTime.

-ifdef(EUNIT).

date_add_year_test_() ->
	[
	 ?_assertEqual({{2312, 2, 29}, {15, 20, 24}}, date_add({{2012, 2, 29}, {15, 20, 24}}, 300, year)),
	 ?_assertEqual({{2013, 2, 28}, {15, 20, 24}}, date_add({{2012, 2, 29}, {15, 20, 24}}, 1, year)),
	 ?_assertEqual({{2016, 2, 29}, {15, 20, 24}}, date_add({{2012, 2, 29}, {15, 20, 24}}, 4, year)),
	 ?_assertEqual({{2012, 2, 29}, {15, 20, 24}}, date_add({{2016, 2, 29}, {15, 20, 24}}, -4, year)),
	 ?_assertEqual({{1412, 2, 29}, {15, 20, 24}}, date_add({{2012, 2, 29}, {15, 20, 24}}, -600, year))
	].

date_add_quarter_test_() ->
	[
	 ?_assertEqual({{2018, 4, 30}, {15, 20, 24}}, date_add({{2012, 1, 31}, {15, 20, 24}}, 25, quarter)),
	 ?_assertEqual({{2012, 2, 29}, {15, 20, 24}}, date_add({{2011, 11, 30}, {15, 20, 24}}, 1, quarter)),
	 ?_assertEqual({{2013, 2, 28}, {15, 20, 24}}, date_add({{2012, 2, 29}, {15, 20, 24}}, 4, quarter)),
	 ?_assertEqual({{2015, 2, 28}, {15, 20, 24}}, date_add({{2016, 2, 29}, {15, 20, 24}}, -4, quarter)),
	 ?_assertEqual({{2008, 5, 29}, {15, 20, 24}}, date_add({{2012, 2, 29}, {15, 20, 24}}, -15, quarter))
	].

date_add_month_test_() ->
	[
	 ?_assertEqual({{2077, 11, 29}, {15, 20, 24}}, date_add({{2012, 2, 29}, {15, 20, 24}}, 789, month)),
	 ?_assertEqual({{2012, 3, 29}, {15, 20, 24}}, date_add({{2012, 2, 29}, {15, 20, 24}}, 1, month)),
	 ?_assertEqual({{2012, 2, 29}, {15, 20, 24}}, date_add({{2012, 1, 31}, {15, 20, 24}}, 1, month)),
	 ?_assertEqual({{2012, 2, 29}, {15, 20, 24}}, date_add({{2012, 1, 29}, {15, 20, 24}}, 1, month)),
	 ?_assertEqual({{2011, 2, 28}, {15, 20, 24}}, date_add({{2012, 3, 31}, {15, 20, 24}}, -13, month))
	].

date_add_day_test_() ->
	[
	 ?_assertEqual({{2012, 2, 29}, {15, 20, 24}}, date_add({{2012, 2, 28}, {15, 20, 24}}, 1, day)),
	 ?_assertEqual({{2016, 2, 23}, {15, 20, 24}}, date_add({{2012, 2, 28}, {15, 20, 24}}, 1456, day)),
	 ?_assertEqual({{2012, 2, 29}, {15, 20, 24}}, date_add({{2012, 3, 31}, {15, 20, 24}}, -31, day)),
	 ?_assertEqual({{2012, 2, 29}, {15, 20, 24}}, date_add({{2012, 3, 1}, {15, 20, 24}}, -1, day)),
	 ?_assertEqual({{1999, 8, 10}, {15, 20, 24}}, date_add({{2012, 3, 1}, {15, 20, 24}}, -4587, day))
	].

date_add_hour_test_() ->
	[
	 ?_assertEqual({{2016, 3, 17}, {6, 20, 24}}, date_add({{2012, 2, 28}, {15, 20, 24}}, 35487, hour)),
	 ?_assertEqual({{2012, 4, 29}, {7, 20, 24}}, date_add({{2012, 2, 28}, {15, 20, 24}}, 1456, hour)),
	 ?_assertEqual({{2012, 2, 29}, {15, 20, 24}}, date_add({{2012, 2, 28}, {15, 20, 24}}, 24, hour)),
	 ?_assertEqual({{2011, 4, 7}, {9, 20, 24}}, date_add({{2012, 2, 28}, {15, 20, 24}}, -7854, hour)),
	 ?_assertEqual({{2006, 12, 31}, {16, 20, 24}}, date_add({{2012, 3, 1}, {15, 20, 24}}, -45287, hour))
	].

date_add_minute_test_() ->
	[
	 ?_assertEqual({{2012, 2, 29}, {0, 0, 24}}, date_add({{2012, 2, 28}, {23, 20, 24}}, 40, minute)),
	 ?_assertEqual({{2012, 3, 1}, {0, 0, 24}}, date_add({{2012, 2, 28}, {23, 20, 24}}, 1480, minute)),
	 ?_assertEqual({{2013, 3, 2}, {0, 0, 24}}, date_add({{2013, 2, 28}, {23, 20, 24}}, 1480, minute)),
	 ?_assertEqual({{2099, 7, 4}, {12, 48, 24}}, date_add({{2013, 2, 28}, {23, 20, 24}}, 45412648, minute)),
	 ?_assertEqual({{2013, 2, 20}, {9, 26, 24}}, date_add({{2013, 2, 28}, {23, 20, 24}}, -12354, minute))
	].

date_add_second_test_() ->
	[
	 ?_assertEqual({{2012, 2, 29}, {0, 0, 0}}, date_add({{2012, 2, 28}, {23, 59, 24}}, 36, second)),
	 ?_assertEqual({{2012, 2, 29}, {23, 20, 25}}, date_add({{2012, 2, 28}, {23, 20, 24}}, 86401, second)),
	 ?_assertEqual({{2013, 3, 2}, {23, 20, 27}}, date_add({{2013, 2, 28}, {23, 20, 24}}, 172803, second)),
	 ?_assertEqual({{2026, 3, 26}, {23, 36, 5}}, date_add({{2013, 2, 28}, {23, 20, 24}}, 412474541, second)),
	 ?_assertEqual({{1879, 8, 1}, {8, 54, 35}}, date_add({{2013, 2, 28}, {23, 20, 24}}, -4215421549, second))
	].

-endif.