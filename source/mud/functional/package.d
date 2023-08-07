/**
 * This module contains various helpers for functional style programming
 */

module mud.functional;

import std.typecons : isTuple;
import std.traits : Unqual, BaseClassesTuple;
import std.range.primitives : isInputRange, ElementType;

import mud.meta.traits;

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

/// Returns first element in `inRange`. If no elements found, returns `init`
auto firstOrInit(Range)(Range inRange)
if(isInputRange!Range)
{
    foreach(e; inRange)
        return e;
    return (ElementType!(Range)).init;
}
///
@safe @nogc unittest
{
    int[6] r = [1, 2, 3, 4, 5, 6];
    assert(firstOrInit(r[]) == 1);
}

/// Functional style cast of `InType` to `OutType` for classes.
/// Performs compile-time checks that `InType` can be cast to `OutType`
OutType as(OutType, InType)(InType input) @safe @nogc pure nothrow
//if(isSubclassOf!(InType, OutType))
{
    enum isInClass = isClass!InType;
    enum isOutClass = isClass!OutType;
    static assert(isInClass, "Source type must be a `class`, but it's `" ~ InType.stringof~ "`");
    static assert(isOutClass, "Destination type must be a `class`, but it's `" ~ OutType.stringof ~ "`");

    enum isSubclass = isSubclassOf!(InType, OutType);
    static assert(isSubclass, "`" ~ InType.stringof ~ "` must be a subclass of `" ~ OutType.stringof ~ "`");
    return cast(OutType)input;
}
///
@safe @nogc unittest
{
    class A { }
    class B : A { }
    class C { }
    scope B b = new B;
    assert(b.as!A !is null);
    static assert(!__traits(compiles, 10.as!double == 10));
    static assert(!__traits(compiles, (new C).as!A));
    assert(b.as!Object !is null);

    // Compile-time error: `C` must be a subclass of `A`
    // scope C c = new C;
    // A a = c.as!A;
}
