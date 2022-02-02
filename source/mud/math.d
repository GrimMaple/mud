/**
 * This module contains various math-related functions
 */

module mud.math;

import std.meta;
import std.math : PI;

/**
 * Logistic sigmoid function, useful for neural networks.
 *
 * Returns: 1 / (1 + e^(-t))
 */
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

/**
 * Converts an angle value in $(HTTP en.wikipedia.org/wiki/Radian, radians) to degrees
 *
 * Params:
 *      deg = angle in degrees
 * Returns:
 *      angle in radians
 */
pragma(inline, true)
real toRadians(real deg) @safe @nogc nothrow pure
{
    return (PI * deg)/180;
}
///ditto
pragma(inline, true)
double toRadians(double deg) @safe @nogc nothrow pure
{
    return cast(double)toRadians(cast(real)deg);
}
///ditto
pragma(inline, true)
float toRadians(float deg) @safe @nogc nothrow pure
{
    return cast(float)toRadians(cast(real)deg);
}
///
@safe @nogc unittest
{
    import std.math : isClose;
    assert(isClose(toRadians(180.0), PI));
    assert(isClose(toRadians(0.0), 0));
    assert(isClose(toRadians(90.0), PI / 2));
}

/**
 * Converts an angle value in degrees to $(HTTP en.wikipedia.org/wiki/Radian, radians)
 *
 * Params:
 *      rads = angle in radians
 * Returns:
 *      angle in degrees
 */
pragma(inline, true)
real toDegrees(real rads) @safe @nogc nothrow pure
{
    return (rads * 180) / PI;
}
///ditto
pragma(inline, true)
double toDegrees(double rads) @safe @nogc nothrow pure
{
    return cast(double)toDegrees(cast(real)rads);
}
///ditto
pragma(inline, true)
float toDegrees(float rads) @safe @nogc nothrow pure
{
    return cast(float)toDegrees(cast(real)rads);
}
///
@safe @nogc unittest
{
    import std.math : isClose;
    assert(isClose(toDegrees(PI), 180));
    assert(isClose(toDegrees(0.0), 0));
    assert(isClose(toDegrees(PI / 2), 90));
}
