module mud.memory.smartpointers;

import std.experimental.allocator.mallocator;
import std.conv : emplace;
import std.functional : forward;

@safe @nogc
{

/// Create a new unique pointer of class type `T`, using allocator `Allocator`.
/// `T` will be created by using constructor that accepts `Args`.
/// The default allocator is `Mallocator`.
auto newUnique(T, Allocator=Mallocator, Args...)(Args args) @trusted
if(is(T==class))
{
    auto mem = Allocator.instance.allocate(__traits(classInstanceSize, T));
    auto unused = emplace(cast(T)mem.ptr, forward!args);
    return UPtr!(T, Allocator)(mem);
}
///
@safe unittest
{
    class A {}
    immutable auto unique = newUnique!A();
}

/// Create a new shared pointer of type `T*`, using allocator `Allocator`.
/// `T` will be creating by using constructor that accepts `Args`, or by
/// implicitly stating `*newMem = args[0]`.
auto newUnique(T, Allocator=Mallocator, Args...)(Args args) @trusted
if(!is(T==class))
{
    import std.conv : emplace;
    auto mem = Allocator.instance.allocate(T.sizeof);
    static if(__traits(hasMember, T, "__ctor"))
        auto unused = emplace(cast(T*)mem.ptr, forward!args);
    else static if(args.length == 1)
        (*cast(T*)mem.ptr) = args[0];
    return UPtr!(T*, Allocator)(mem);
}
///
@safe unittest
{
    auto unique = newUnique!int(42);
    assert((*unique.ptr) == 42);
}

/// Unique pointer of type `T`, using allocator `Allocator`.
/// The default allocator is `Mallocator`.
struct UPtr(T, Allocator=Mallocator)
{
    /// Get the underlying pointer `T`
    @property @trusted T ptr() { return cast(T)_ptr.ptr; }

    static if(!is(T == class))
    {
        /// Provides dereferencing for pointers that are not `class`
        auto opUnary(string s)() if (s == "*")
        {
            return *ptr;
        }
        ///
        unittest
        {
            class A {}
            auto unique = newUnique!int(42);
            assert(*unique == 42);
            immutable auto classPtr = newUnique!A();
            assert(!__traits(compiles, *classPtr));
        }
    }

    ~this() @trusted
    {
        Allocator.instance.deallocate(_ptr);
    }

    /// Assigning to is disabled
    void opAssign(UPtr!(T, Allocator) rhs) @disable;

    /// Copying is disabled
    this(UPtr!(T, Allocator) rhs) @disable;
    ///
    unittest
    {
        const auto uniuque = newUnique!int();
        assert(!__traits(compiles, unique = newUnique!int()));
        assert(!__traits(compiles, unique2 = unique));
    }
private:
    this(void[] ptr)
    {
        _ptr = ptr;
    }
    void[] _ptr;
}
nothrow unittest
{
    @nogc @safe class A
    {
        this(int val)
        {
            s = val;
        }
        int foo() @nogc nothrow { return s; }
    private:
        int s = 0;
    }

    auto unique = newUnique!A(42);
    assert(unique.ptr.foo() == 42);
}


/// Create a new shared pointer of class type `T`, using allocator `Allocator`.
/// `T` will be created by using constructor that accepts `Args`.
/// The default allocator is `Mallocator`.
auto newShared(T, Allocator=Mallocator, Args...)(Args args) @trusted
if(is(T == class))
{
    import std.conv : emplace;
    auto mem = Allocator.instance.allocate(__traits(classInstanceSize, T));
    auto unused = emplace(cast(T)mem.ptr, forward!args);
    return SPtr!(T,Allocator)(mem);
}
///
@safe unittest
{
    class A {}
    const auto sptr = newShared!A();
}

/// Create a new shared pointer of type `T*`, using allocator `Allocator`.
/// `T` will be creating by using constructor that accepts `Args`, or by
/// implicitly stating `*newMem = args[0]`.
/// The default allocator is `Mallocator`.
auto newShared(T, Allocator=Mallocator, Args...)(Args args) @trusted
if(!is(T==class))
{
    import std.conv : emplace;
    auto mem = Allocator.instance.allocate(T.sizeof);
    static if(__traits(hasMember, T, "__ctor"))
        auto unused = emplace(cast(T*)mem.ptr, forward!args);
    else static if(args.length == 1)
        (*cast(T*)mem.ptr) = args[0];
    return SPtr!(T*, Allocator)(mem);
}
///
@safe unittest
{
    auto sptr = newShared!int(42);
    assert((*sptr.ptr) == 42);
}

/// Shared Pointer of type `T`, using allocator `Allocator`.
/// The default allocator is `Mallocator`.
struct SPtr(T, Allocator=Mallocator)
{
    /// Get the underlying pointer `T`
    @property @trusted T ptr()
    {
        return cast(T)(cast(void*)_ptr.ptr);
    }

    static if(!is(T == class))
    {
        /// Provides dereferencing for pointers that are not `class`
        auto opUnary(string s)() if (s == "*")
        {
            return *ptr;
        }
        ///
        unittest
        {
            class A {}
            auto sptr = newShared!int(42);
            assert(*sptr == 42);
            const auto classPtr = newShared!A();
            assert(!__traits(compiles, *classPtr));
        }
    }

    /// Copy from null
    this(typeof(null))
    {
        decreaseCount();
        reset();
    }
    ///
    unittest
    {
        SPtr!(int*) otherPtr = null;
        assert(otherPtr.ptr == null);
        otherPtr = newShared!int(42);
        assert(*otherPtr == 42);
    }

    /// Assign null
    void opAssign(typeof(null))
    {
        decreaseCount();
        reset();
    }

    /// Copy another `SPtr!(T, Allocator)`
    this(ref SPtr!(T, Allocator) rhs) @trusted
    {
        if(rhs.ptr is null)
        {
            decreaseCount();
            reset();
        }
        else synchronized
        {
            _count = rhs._count;
            (*count)++;
            _ptr = rhs._ptr;
        }
    }

    ~this() @trusted
    {
        if(_ptr == null)
            return;

        decreaseCount();
    }

    alias ptr this;
private:
    @property @trusted size_t* count() { return cast(size_t*)_count.ptr; }

    void reset()
    {
        _ptr = null;
        _count = null;
    }

    void decreaseCount() @trusted
    {
        if(_ptr != null)
            synchronized
            {
                (*count)--;
                if((*count) == 0)
                {
                    static if(__traits(hasMember, T, "__xdtor"))
                        ptr.__xdtor();
                    Allocator.instance.deallocate(_ptr);
                    Allocator.instance.deallocate(_count);
                }
            }
    }

    this(void[] ptr)
    {
        _ptr = ptr;
        _count = Allocator.instance.allocate(size_t.sizeof);
        (*count) = 1;
    }

    void[] _ptr = null;
    void[] _count = null;
}

} // @safe @nogc nothrow

@safe unittest
{
    import std.stdio : writeln;
    @nogc @safe class A
    {
        ~this() @nogc @trusted
        {
        }

        int p() @nogc @trusted
        {
            return t;
        }
    private:
        int t = 7;
    }

    void doStuff(A a)
    {
        if(a is null)
            throw new Exception("a was null");
        assert(a.p() == 7);
    }

    void doStuffShared(SPtr!A sptr)
    {
        doStuff(sptr);
    }

    import std.exception : assertThrown;
    auto res = newShared!A();
    auto another = res;
    doStuff(res);
    res = null;
    doStuff(another);
    assertThrown(doStuffShared(res));
    doStuffShared(another);
}
