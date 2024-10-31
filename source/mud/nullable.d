/+


+/
/++
    This file contains an implementation for compile time and extended runtime null checks.

    It is intended to be used by the compiler itself. Main idea is that code like this:
    ---
    Object o = new Object();
    ---
    
    Is automatically rewritten by the compiler to:
    ---
    NotNull!Object o = new Object();
    ---

    With this approach, this library code can be seamlessly and easily integrated with the compiler code.
    It's probably best to not enable this feature by default, but put it behind a switch, like `--not-null`.

    To allow a class reference to be `null`, code can use $(LREF MaybeNull) like this:
    ---
    MaybeNull!Object o = null;
    ---

    If a null value is used, a $(LREF ValueNullException) is thrown.

+/
module mud.nullable;

import core.attribute;

/**
 * This exception is thrown by $(LREF MaybeNull) when accessing a `null` value
 */
class ValueNullException : Exception
{
    this() @safe
    {
        super("Value was null");
    }
}

/**
 * Provides built-in compile-time guarantees that a class reference is not null.
 * When used, guarantees that underlying value is not null. It cannot be constructed to null,
 * and will cause an error if not properly initialized.
 */
struct NotNull(T) if(is(T == class))
{
    alias get this;
    this()() { static_assert("WUT?"); }

    this(T t) @safe
    {
        assert(t !is null);
        this.t = t;
    }

    this()(typeof(null) a)
    {
        static assert(false, "Can't assign `null` to a `NotNull` value");
    }

    auto opAssign()(typeof(null) a)
    {
        static assert(false, "Can't assign `null` to a `NotNull` value");
    }

    auto opAssign(T t) @safe
    {
        this.t = t;
        return this;
    }

    this(NotNull!T other)
    {
        this.t = other.t;
    }

private:
    T get() @safe @nogc
    {
        return t;
    }

    T t;
}
///
@safe unittest
{
    class A
    {
        this()
        {
            memb = new Object();
        }
        NotNull!Object memb;
    }

    // Error:
    /*class B
    {
        this() { }
        NotNull!Object memb;
    }*/

    // NotNull!Object o; // Error
    // NotNull!Object o = null; // Error
    NotNull!Object a = new Object();
    NotNull!Object b = a;
    NotNull!(Object)[] s = [NotNull!Object(new Object()), NotNull!Object(new Object())];
}

/**
 * Provides support for class references that might be null.
 * If a `null` value is used, throws $(LREF ValueNullException)
 */
struct MaybeNull(T) if(is(T == class))
{
    alias get this;
    this(T t) @safe @nogc
    {
        this.t = t;
    }

    bool opEquals(typeof(null) v) const
    {
        return t == v;
    }

    auto opAssign(T value)
    {
        this.t = value;
        return this;
    }

private:
    T get() @safe
    {
        if(t is null)
            throw new ValueNullException();
        return t;
    }

    T t = null;
}
///
@safe unittest
{
    import std.exception : assertThrown, assertNotThrown;
    void foo(Object t) @safe { }
    MaybeNull!Object o;
    assertThrown!ValueNullException(foo(o));
    assertNotThrown(o == null);
    assert(o == null, "Value should've been null");

    MaybeNull!Object notNull = new Object();
    foo(notNull);
}

// MaybeNull stuff
@safe unittest
{
    MaybeNull!Object[] objects = new MaybeNull!Object[100];

    MaybeNull!Object v = null;
    v = new Object();
    v = null;
}

/**
 * Don't look at this, this is not intended to be used at all :)
 */
struct Nullable(T) if(__traits(isPOD, T) || (__traits(isScalar, T) && !__traits(isPointer, T)))
{
    alias t this;

    this(typeof(null) a)
    {
        isNull = true;
    }

    this(T value)
    {
        isNull = false;
        t = value;
    }

    void opAssign(typeof(null) a)
    {
        isNull = true;
    }

    void opAssign(T value)
    {
        t = value;
    }

    bool opEquals(typeof(null) a) const
    {
        return isNull;
    }

private:
    bool isNull = true;
    T t;
}
///
unittest
{
    Nullable!int a;
    assert(a == null);
    Nullable!int b = 123;
    assert(b != null);
    b = 345;
}

// NotNull assign/construct stuff
@safe unittest
{
    NotNull!Object a = new Object();
    a = new Object();
    // a = null; // Error
    a = NotNull!Object(new Object);

    NotNull!Object b = NotNull!Object(new Object);
}

// NotNull Alias this
@safe unittest
{
    class C { }
    void foo(C c) { }
    NotNull!C c = new C();
    foo(c);
}

// NotNull Implicit stuff
@safe unittest
{
    class C { }
    void foo(NotNull!C c) { }

    // TODO: This should work, but doesn't
    // On the other hand, `new` can return `null` no problem, so this shouldn't actually work
    // foo(new C());
}

// NotNull with subclasses
@safe unittest
{
    class A { }
    class B : A { }

    NotNull!B b = new B();
    NotNull!A a = b;
}

// NotNull with arrays
@safe unittest
{
    NotNull!Object[] objects = [NotNull!Object(new Object()), NotNull!Object(new Object())];
}
