module source.mud.math;

private import std.meta;

/// Logistic sigmoid function, useful for neural networks.
/// Returns 1 / (1 + e^(-t))
T logisticSigmoid(T)(T t) @safe @nogc nothrow pure
if(__traits(isArithmetic, T))
{
    import std.math : exp;
    return cast(T)(1.0 / (1 + exp(cast(double)-t)));
}
///
unittest
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
