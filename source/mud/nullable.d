module mud.nullable;

struct NotNull(T) if(is(T == class))
{
    alias t this;
    @disable this();
    this(T t)
    {
        assert(t !is null);
        this.t = t;
    }
    this()(typeof(null) a)
    {
        static assert(false, "Can't assign `null` to a `NotNull`");
    }
    this(ref NotNull!T other)
    {
        this.t = other.t;
    }

private:
    T t;
}
///
unittest
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
    auto test = new A();
}

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

@safe unittest
{
    class C { }
    void foo(C c) { }
    NotNull!C c = new C();
    foo(c);
}

@safe unittest
{
    class C
    {
        this()
        {
            foo();
        }

        private void foo()
        {
            o = new Object();
        }

        NotNull!Object o;
    }
}
