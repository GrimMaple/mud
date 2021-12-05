module mud.functional;

private import std.typecons : isTuple;
import std.traits : Unqual;
import std.range.primitives : isInputRange, ElementType;

/// Unpack a tuple `T(Args...)` to a slice of `Args[]`. This requires the tuple to contain same types!
auto unpack(T)(auto ref T t) @safe nothrow
if(isTuple!(T))
{
    return [t[]];
}
///
@safe unittest
{
    import std.typecons : tuple;
    immutable tpl = tuple(123, 123, 123);
    assert(tpl.unpack == [123, 123, 123]);
}

/// Returns first element in `inRange` that satisfies the `pred`. If no such element found, returns `init`
auto first(Range, Pred)(Range inRange, Pred pred)
if(isInputRange!(Range))
{
    foreach(e; inRange)
    {
        if(pred(e))
            return e;
    }
    return (ElementType!(Range)).init;
}
///
@safe @nogc unittest
{
    int[6] r = [1, 2, 3, 4, 5, 6];
    assert(first(r[], (int i) { return i % 2 == 0; }) == 2);
    assert(first(r[], (int i) { return 1 > 10; }) == int.init);
}
