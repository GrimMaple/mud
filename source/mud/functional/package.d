module mud.functional;

private import std.typecons : isTuple;

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
