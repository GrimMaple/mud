/**
 * This module contains various traits
 */

module mud.meta.traits;

import std.traits;

/// Is `A` a subclass of `B`
template isSubclassOf(A, B) if(isClass!A && isClass!B)
{
    import std.meta : staticIndexOf;
    enum bool isSubclassOf = staticIndexOf!(B, BaseClassesTuple!(A)) != -1;
}
///
@safe unittest
{
    class A {}
    class B {}
    class C : A {}
    class D : C {}
    assert(!isSubclassOf!(A, A));
    assert(!isSubclassOf!(B, A));
    assert(isSubclassOf!(C, A));
    assert(isSubclassOf!(D, A));
}

/// Is `A` a class. I know `is(A == class)` exists, but I feel awkward about it every time, so I made a wrapper
template isClass(A)
{
    enum bool isClass = is(A == class);
}
///
@safe unittest
{
    struct A {}
    enum B { C = 1 }
    assert(!isClass!A);
    assert(!isClass!B);
    assert(isClass!Object);
    assert(!isClass!int);
}
