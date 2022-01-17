module mud.memory.memstream;

private import mud.container.growing;
private import std.exception : assertThrown;
private import core.exception : AssertError;

/// Output memory stream. Convenient for accessing elements in a byte array
struct OMemStream
{
    /// Check if the stream had ended
    @property bool eof() @nogc @safe nothrow { return pos >= data.length; }
    ///
    @safe unittest
    {
        ubyte[1] data = [13];
        auto stream = OMemStream(data);
        stream.read!ubyte;
        assert(stream.eof);
    }

    /// Constructs new output memory stream from `data`
    @safe @nogc this(ubyte[] data) nothrow
    {
        this.data = data;
    }
    ///
    @safe unittest
    {
        ubyte[4] data = [0, 0, 0, 0];
        const stream = OMemStream(data);
    }

    /// Read `size` bytes from the stream
    ubyte[] read(size_t size) @safe @nogc nothrow
    in(!eof)
    {
        if(pos + size > data.length)
            size = data.length - pos;

        ubyte[] ret = data[pos .. pos+size];
        pos += size;
        return ret;
    }
    ///
    @trusted unittest
    {
        ubyte[4] data = [0, 1, 2, 3];
        auto stream = OMemStream(data);
        const res = stream.read(4);
        assert(res == data);
        assertThrown!AssertError(stream.read(1));
    }

    /// Read an element from stream. If there are no elements, returns default constructed `T`
    T read(T)() @trusted @nogc nothrow
    {
        if(pos + T.sizeof > data.length)
            return T();
        T val = *cast(T*)(data.ptr + pos);
        pos += T.sizeof;
        return val;
    }
    ///
    @safe unittest
    {
        ubyte[1] data = [13];
        auto stream = OMemStream(data);
        assert(stream.read!ubyte == 13);
        assert(stream.read!ubyte == ubyte.init);
    }

private:
    size_t pos;
    ubyte[] data;
}

@safe unittest
{
    ubyte[7] check = [10, 11, 0, 14, 0, 0, 0];
    auto os = OMemStream(check);
    immutable a = os.read!ubyte;
    immutable b = os.read!short;
    immutable c = os.read!int;
    assert(a == 10);
    assert(b == 11);
    assert(c == 14);
    assert(os.eof);
}

// Unittest for reading more data than there is
@safe unittest
{
    ubyte[7] check = [10, 11, 0, 14, 0, 0, 0];
    auto os = OMemStream(check);
    const r = os.read(10);
    assert(r.length == 7);
    assert(os.eof);
}

/// Input memory stream. Convenient for storing elements in a byte array
struct IMemStream
{
    /// Returns a copy of underlying bytes
    @property ubyte[] getBytes() @safe nothrow
    {
        ubyte[] ret = new ubyte[sz];
        ret[0 .. sz] = bytes.get[0 .. sz];
        return ret;
    }
    ///
    @safe unittest
    {
        immutable ubyte[1] check = [13];
        IMemStream m;
        m.put!ubyte(13);
        assert(check == m.getBytes);
    }

    /// Returns underlying bytes. MAY LEAK REFERENCES
    @property ubyte[] peekBytes() @safe @nogc nothrow { return bytes.get[0 .. sz]; }
    ///
    @safe unittest
    {
        immutable ubyte[1] check = [13];
        IMemStream m;
        m.put!ubyte(13);
        assert(check == m.peekBytes);
    }

    /// Put an element of type `T` into the stream
    void put(T)(T val) @trusted nothrow
    {
        ubyte *back = cast(ubyte*)&val;
        foreach(e; back[0 .. T.sizeof])
            bytes.put(e);
        sz += T.sizeof;
    }
    ///
   @safe  unittest
    {
        IMemStream m;
        m.put!ubyte(13);
        m.put!int(1_333_333);
        m.put!double(0.31);
    }

    /// Put a string into the stream
    void put(T : string)(T data) @safe @nogc nothrow
    {
        foreach(c; data)
        {
            bytes.put(cast(ubyte)c);
            sz++;
        }
    }
    ///
    @safe unittest
    {
        string test = "Hello, world!";
        IMemStream stream;
        stream.put(test);
        for(int i=0; i<test.length; i++)
            assert(stream.getBytes[i] == test[i]);
    }

    /// Put a byte array into the stream
    void put(T : ubyte[])(T data) @safe @nogc nothrow
    {
        foreach(e; data)
            bytes.put(e);
        sz += data.length;
    }
    ///
    @safe unittest
    {
        ubyte[4] data = [10, 11, 12, 13];
        IMemStream stream;
        stream.put(data);
        for(int i=0; i<4; i++)
            assert(stream.getBytes[i] == data[i]);
    }
    /// ditto
    void put(T : const(ubyte[]))(T val) @safe @nogc nothrow
    {
        foreach(e; val)
            bytes.put(e);
        sz += val.length;
    }
    /// ditto
    void put(T : byte[])(T val) @safe @nogc nothrow
    {
        foreach(e; val)
            bytes.put(e);
        sz += val.length;
    }
    ///
    void put(T : void[])(T val) @trusted @nogc nothrow
    {
        put(cast(ubyte[])val);
    }
    ///
    void put(T : const(void[]))(T val) @trusted @nogc nothrow
    {
        put(cast(const(ubyte[]))val);
    }

private:
    size_t sz = 0;
    GrowingContainer!ubyte bytes;
}
///
@safe unittest
{
    IMemStream m;
    m.put!ubyte(10);
    m.put!short(11);
    m.put!int(14);
    auto res = m.getBytes;
    assert(res.length == 7);
    assert(res[0] == 10);
    assert(res[1] == 11);
    assert(res[2] == 0);
    assert(res[3] == 14);
    assert(res[4] == 0);
    assert(res[5] == 0);
    assert(res[6] == 0);
}