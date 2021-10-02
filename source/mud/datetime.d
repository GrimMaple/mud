module mud.datetime;

import std.datetime;

/// Acquire current time as a `DateTime`
DateTime currentDateTime() @safe
{
    return cast(DateTime)Clock.currTime();
}
///
@safe unittest
{
    assert((cast(SysTime)currentDateTime()).toUnixTime() == Clock.currTime().toUnixTime());
}

/// Returns a whole year span for this `dt`
auto wholeYear(DateTime dt)
{
    immutable start = DateTime(dt.year, 1, 1);
    DateTime end = start;
    end.roll!"years"(1);
    end = end - seconds(1);
    return TimeSpan(start, end);
}
///
@safe unittest
{
    immutable s = DateTime(2000, 2, 13);
    assert(s.wholeYear.begin == DateTime(2000, 1, 1));
    assert(s.wholeYear.end == DateTime(2000, 12, 31, 23, 59, 59));
}

/// Returns a whole month span for this `dt`
auto wholeMonth(DateTime dt)
{
    immutable start = DateTime(dt.year, dt.month, 1);
    DateTime end = start;
    end.roll!"months"(1);
    end = end - seconds(1);
    return TimeSpan(start, end);
}
///
@safe unittest
{
    immutable s = DateTime(2000, 2, 13);
    assert(s.wholeMonth.begin == DateTime(2000, 2, 1));
    assert(s.wholeMonth.end == DateTime(2000, 2, 29, 23, 59, 59));
}

/// Returns a whole day span for this `dt`
auto wholeDay(DateTime dt)
{
    immutable start = DateTime(dt.year, dt.month, dt.day, 0, 0, 0);
    DateTime end = start;
    end.roll!"days"(1);
    end = end - seconds(1);
    return TimeSpan(start, end);
}
///
@safe unittest
{
    immutable s = DateTime(2000, 2, 13, 15, 11, 13);
    assert(s.wholeDay.begin == DateTime(2000, 2, 13));
    assert(s.wholeDay.end == DateTime(2000, 2, 13, 23, 59, 59));
}

/// Returns a whole hour span for this `dt`
auto wholeHour(DateTime dt)
{
    immutable start = DateTime(dt.year, dt.month, dt.day, dt.hour, 0, 0);
    DateTime end = start;
    end.roll!"hours"(1);
    end = end - seconds(1);
    return TimeSpan(start, end);
}
///
@safe unittest
{
    immutable s = DateTime(2000, 2, 13, 15, 11);
    assert(s.wholeHour.begin == DateTime(2000, 2, 13, 15, 0));
    assert(s.wholeHour.end == DateTime(2000, 2, 13, 15, 59, 59));
}

/// Represents a span in time
struct TimeSpan
{
    /// Retrieve the begin of this time span
    @property DateTime begin() @nogc @safe nothrow const
    {
        return _begin;
    }
    ///
    @safe unittest
    {
        immutable ts = TimeSpan(DateTime(2000, 1, 1), DateTime(2000, 2, 1));
        assert(ts.begin == DateTime(2000, 1, 1));
    }

    /// Retrieve the end of this time span
    @property DateTime end() @nogc @safe nothrow const
    {
        return _end;
    }
    ///
    @safe unittest
    {
        immutable ts = TimeSpan(DateTime(2000, 1, 1), DateTime(2000, 2, 1));
        assert(ts.end == DateTime(2000, 2, 1));
    }

    /// Does this time span contain `dt`
    bool contains(DateTime dt) @nogc @safe nothrow const
    {
        return dt >= _begin && dt <= _end;
    }
    ///
    @safe unittest
    {
        immutable ts = TimeSpan(DateTime(2000, 1, 1), DateTime(2000, 2, 1));
        assert(ts.contains(DateTime(2000, 1, 1, 20)));
        assert(ts.contains(DateTime(2000, 1, 1)));
        assert(ts.contains(DateTime(2000, 2, 1)));
        assert(!ts.contains(DateTime(1990, 1, 1)));
    }

private:
    DateTime _begin;
    DateTime _end;
}
