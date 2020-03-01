module mud.memory.memstream;

import mud.container.growing;

@safe @nogc nothrow:

/// Output memory stream. Convenient for accessing elements in a byte array
struct OMemStream
{
@nogc @safe nothrow:
    /// Check if the stream had ended
    @property bool eof() { return pos >= data.length; }
    ///
    unittest
    {
        ubyte[1] data = [13];
        OMemStream stream = OMemStream(data);
        stream.read!ubyte;
        assert(stream.eof);
    }

    /// Constructs new output memory stream from `data`
    this(ubyte[] data)
    {
        this.data = data; 
    }
    ///
    unittest
    {
        ubyte[4] data = [0, 0, 0, 0];
        OMemStream stream = OMemStream(data);
    }

    /// Read `size` bytes from the stream
    ubyte[] read(size_t size)
    {
        ubyte[] ret = data[pos .. pos+size];
        pos += size;
        return ret;
    }
    ///
    unittest
    {
        ubyte[4] data = [0, 1, 2, 3];
        OMemStream stream = OMemStream(data);
        auto res = stream.read(4);
        assert(res == data);
    }

    /// Read an element from stream. If there are no elements, returns default constructed `T`
    T read(T)() @trusted
    {
        if(pos + T.sizeof > data.length)
            return T();
        T val = *cast(T*)(data.ptr + pos);
        pos += T.sizeof;
        return val;
    }
    ///
    unittest
    {
        ubyte[1] data = [13];
        OMemStream stream = OMemStream(data);
        assert(stream.read!ubyte == 13);
        assert(stream.read!ubyte == ubyte.init);
    }

private:
    size_t pos;
    ubyte[] data;
}

unittest
{
    ubyte[7] check = [10, 11, 0, 14, 0, 0, 0];
    auto os = OMemStream(check);
    ubyte a = os.read!ubyte;
    short b = os.read!short;
    int c = os.read!int;
    assert(a == 10);
    assert(b == 11);
    assert(c == 14);
    assert(os.eof);
}

/// Input memory stream. Convenient for storing elements in a byte array
struct IMemStream
{
@safe @nogc nothrow:
    /// Returns underlying bytes
    @property ubyte[] getBytes() { return bytes.get[0 .. sz]; }
    ///
    unittest
    {
        ubyte[1] check = [13];
        IMemStream m;
        m.put!ubyte(13);
        assert(check == m.getBytes);
    }

    /// Put an element of type `T` into the stream
    void put(T)(T val) @trusted
    {
        ubyte *back = cast(ubyte*)&val;
        foreach(e; back[0 .. T.sizeof])
            bytes.put(e);
        sz += T.sizeof;
    }
    ///
    unittest
    {
        IMemStream m;
        m.put!ubyte(13);
        m.put!int(1_333_333);
        m.put!double(0.31);
    }

    /// Put a string into the stream
    void put(T : string)(T data)
    {
        foreach(c; data)
        {
            bytes.put(cast(ubyte)c);
            sz++;
        }
    }
    ///
    unittest
    {
        string test = "Hello, world!";
        IMemStream stream;
        stream.put(test);
        for(int i=0; i<test.length; i++)
            assert(stream.getBytes[i] == test[i]);
    }

    /// Put a byte array into the stream
    void put(T : ubyte[])(T data)
    {
        foreach(e; data)
            bytes.put(e);
        sz += data.length;
    }
    ///
    unittest
    {
        ubyte[4] data = [10, 11, 12, 13];
        IMemStream stream;
        stream.put(data);
        for(int i=0; i<4; i++)
            assert(stream.getBytes[i] == data[i]);
    }
    /// ditto
    void put(T : const(ubyte[]))(T val)
    {
        foreach(e; val)
            bytes.put(e);
        sz += val.length;
    }

private:
    size_t sz = 0;
    GrowingContainer!ubyte bytes;
}
///
unittest
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