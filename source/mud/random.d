module source.mud.random;

import std.random;

/// A common interface for Random Engines
interface IRandom
{
    uint next(uint min, uint max) @safe;
    uint nextInclusive(uint min, uint max) @safe;
}

/// Creates an instance of a common `IRandom` from a selected Random Engine `T`
class RandomEngine(T) if(isUniformRNG!T) : IRandom
{
    this(uint seed) @safe
    {
        engine = T(seed);
    }

    uint next(uint min, uint max) @safe
    {
        return uniform!"[)"(min, max, engine);
    }

    uint nextInclusive(uint min, uint max) @safe
    {
        return uniform!"[]"(min, max, engine);
    }

private:
    T engine;
}
///
@safe unittest
{
    IRandom rng = new RandomEngine!Random(42);
    Random def = Random(42);
    assert(rng.next(0, 100) == uniform!"[)"(0, 100, def));
    assert(rng.nextInclusive(0, 100) == uniform!"[]"(0, 100, def));
}
@safe unittest
{
    IRandom rng = new RandomEngine!Xorshift(42);
    Xorshift def = Xorshift(42);
    assert(rng.next(0, 100) == uniform!"[)"(0, 100, def));
    assert(rng.nextInclusive(0, 100) == uniform!"[]"(0, 100, def));
}
