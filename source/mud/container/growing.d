module mud.container.growing;

import std.experimental.allocator.mallocator;

@safe @nogc nothrow:

/// A container of primitives of type `T` that automatically grows when necessary. 
/// The `size` parameter is the growth size
struct GrowingContainer(T, size_t size = 1000, Allocator = Mallocator)
if(__traits(isPOD, T) || __traits(isArithmetic, T))
{
    /// Accesses element at index `index`
    auto opIndex(size_t index)
    in(index < pos)
    {
        return primitives[index];
    }
    ///
    unittest
    {
        GrowingContainer!int container;
        container.put(10);
        assert(container[0] == 10);
    }

    /// Returns primitives as an array
    @property ref T[] get() { return primitives; }
    ///
    unittest
    {
        GrowingContainer!int container;
        container.put(10);
        assert(container.get[0] == 10);
    }

    /// Returns a slice of `T[]` that only has `count` primitives in it
    @property T[] getPartial() { return primitives[0 .. pos]; }
    ///
    unittest
    {
        GrowingContainer!int container;
        container.put(10);
        assert(container.getPartial.length == 1);
    }

    /// Returns container's internal capacity
    @property size_t capacity() { return sz; }
    ///
    unittest
    {
        GrowingContainer!(int, 10) container;
        assert(container.capacity == 0); // Container allocates lazily
        container.put(10);
        assert(container.capacity == 10); // Allocates in chunks of `size`
    }

    /// Returns count of elements in this container
    @property size_t count() { return pos; }
    ///
    unittest
    {
        GrowingContainer!int container;
        assert(container.count == 0);
        container.put(10);
        assert(container.count == 1);
    }

    /// Assigning to is disabled
    void opAssign(GrowingContainer!(T, size, Allocator) rhs) @disable;

    /// Copying is disabled
    this(GrowingContainer!(T, size, Allocator) rhs) @disable;

    /// Put a new element `val` into the container
    void put(T val) @trusted
    {
        if(pos >= sz)
            grow();
        primitives[pos] = val;
        pos++;
    }
    ///
    unittest
    {
        GrowingContainer!int container;
        container.put(10);
        assert(container[0] == 10);
    }

    /// Reset the current container to zero. Doesn't deallocate memory
    void reset()
    {
        pos = 0;
    }
    ///
    unittest
    {
        GrowingContainer!int container;
        container.put(10);
        assert(container.count != 0);
        container.reset();
        assert(container.count == 0);
    }

    ~this() @trusted
    {
        Allocator.instance.deallocate(primitives);
    }

private:
    void grow() @trusted
    {
        void[] r = cast(void[]) primitives;
        T[] newMem = cast(T[])Allocator.instance.allocate(T.sizeof * (sz + size));
        newMem[0 .. sz] = primitives[0 .. sz];
        Allocator.instance.deallocate(primitives);
        primitives = newMem;
        sz += size;
    }
    size_t pos = 0;
    T[] primitives = null;
    size_t sz = 0;
}
///
@trusted unittest
{
    GrowingContainer!(int, 10) container;
    assert(container.capacity == 0);
    container.put(10);
    assert(container.capacity == 10 && container.count == 1);
    foreach(i; 0 .. 10)
        container.put(i);
    assert(container.capacity == 20 && container.count == 11);
    assert(container[1] == 0 && container[0] == 10);
}