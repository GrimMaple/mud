module mud.decimal;

import std.bigint;
import std.conv : to;
import std.math : pow, floor;
import std.traits : isIntegral;
import std.array : appender;
import std.format : format;

/// A big Decimal. Literally, a Big Int with a fixed point
struct BigDec(int prec) if(prec > 0)
{
@safe:
    alias value this;

    auto opBinary(string op)(const BigDec rhs) const
    {
        static if(op == "*")
        {
            return BigDec!prec((value * rhs.value) / denom);
        }
        else static if(op == "/")
        {
            BigInt s = value * bigDenom;
            return BigDec!prec(s / rhs.value);
        }
        else
            return BigDec!prec(value.opBinary!(op)(rhs.value));
    }
    ///
    auto opBinary(string op, R)(const R rhs) const if(isIntegral!R)
    {
        return BigDec!prec(rhs * denom + value);
    }

    auto opUnary(string op)() @safe const
    {
        return BigDec!prec(-value);
    }

    auto opOpAssign(string op, T)(T value)
    {
        BigDec!prec tmp = this.opBinary!(to!string(op[0]))(value);
        this.value = tmp.value;
        return this;
    }

    int opCmp(R)(const R other) const @safe
    {
        static if(is(R == BigDec!prec) || is(R == BigInt))
            return value.opCmp(other.value);
        else
            return value.opCmp(other);
    }

    string toString() const @safe
    {
        auto app = appender!string;
        app ~= to!string(value / bigDenom);
        app ~= ".";
        app ~= to!string(format("%0" ~ prec.to!string ~ "d", value % denom));
        return app[];
    }

    this(T)(T t)
    {
        value = BigDec!prec(cast(long)floor(cast(real)(t * denom)) + BigInt());
    }

@safe private:
    this(BigInt inter)
    {
        value = inter;
    }

    BigInt value;
    enum denom = pow(10, prec);
    enum bigDenom = BigInt(denom.to!string);
}

@safe unittest
{
    import std.stdio : writeln;
    alias Number = BigDec!2;
    Number a = 100;
    Number b = 200;
    assert(a + b == Number(300));
    assert(a * Number(2.5) == Number(250));
    assert(a / Number(25) == Number(4));
    assert(a / b == Number(0.5));
    assert(a / Number(2.5) == Number(40));
    assert(a > 0);
    a += Number(100);
    assert(a == b);
    assert(to!string(Number(0.1)) == "0.10");
    assert(to!string(Number(0.01)) == "0.01");
}
