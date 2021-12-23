module mud.math;

import std.meta;
import std.math : PI;

/// Logistic sigmoid function, useful for neural networks.
/// Returns 1 / (1 + e^(-t))
T logisticSigmoid(T)(T t) @safe @nogc nothrow pure
if(__traits(isArithmetic, T))
{
    import std.math : exp;
    return cast(T)(1.0 / (1 + exp(cast(double)-t)));
}
///
@safe unittest
{
    assert(logisticSigmoid(1000.0) == 1.0);
    assert(logisticSigmoid(-1000.0) == 0.0);
    assert(logisticSigmoid(1000) == 1);
    assert(logisticSigmoid(-1000) == 0);
}

/// Is `t` odd
bool isOdd(T)(T t) @safe @nogc nothrow pure
if(__traits(isArithmetic, T))
{
    return t % 2 != 0;
}
///
@safe unittest
{
    assert(isOdd(1));
    assert(!isOdd(2));
}

/// Is `t` even
bool isEven(T)(T t) @safe @nogc nothrow pure
if(__traits(isArithmetic, T))
{
    return t % 2 == 0;
}
///
@safe unittest
{
    assert(!isEven(1));
    assert(isEven(2));
}

/// Converts `deg` in degrees to radians
real toRadians(in real deg) @safe @nogc nothrow pure
{
    return (PI * deg)/180;
}
///
@safe @nogc unittest
{
    assert(toRadians(180) == PI);
    assert(toRadians(0) == 0);
    assert(toRadians(90) == PI / 2);
}

/// Converts `rads` in radians to degrees
real toDegrees(in real rads) @safe @nogc nothrow pure
{
    return (rads * 180) / PI;
}
///
@safe @nogc unittest
{
    assert(toDegrees(PI) == 180);
    assert(toDegrees(0) == 0);
    assert(toDegrees(PI / 2) == 90);
}
