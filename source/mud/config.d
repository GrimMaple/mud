module mud.config;

/// UDA to describe a config property
struct ConfigProperty
{
    /// What the saved entity's name should be
    string name = "";
}

/// Serialize `T` into a `string`
string serializeConfigString(T)(auto ref T t) @safe
{
    import std.traits : getSymbolsByUDA, getUDAs;
    import std.conv : to;
    import std.array : appender;

    auto w = appender!string;

    static foreach(i; getSymbolsByUDA!(T, ConfigProperty))
    {
        static if(getUDAs!(i, ConfigProperty)[0].name == "")
        {
            w.put(i.stringof ~ " = " ~ to!string(__traits(child, t, i)));
        }
        else
        {
            w.put(getUDAs!(i, ConfigProperty)[0].name ~ " = " ~ to!string(__traits(child, t, i)));
        }
        version(Windows)
        {
            w.put("\r\n");
        }
        else
        {
            w.put("\n");
        }
    }
    return w[];
}

/// Serialize `T` into file `path`
void serializeConfig(T)(auto ref T t, string path) @safe
{
    import std.file : write;
    write(path, serializeConfigString(t));
}
///
@safe unittest
{
    struct A
    {
        @ConfigProperty() int a;
        @ConfigProperty() float b;
        @ConfigProperty() string someString;
    }
    import std.stdio : writeln;
    import std.file : remove;
    auto a = A(12, 42.0, "I shall contain=====stuff .123.123.1.23.");
    serializeConfig(a, "test.cfg");
    A test;
    deserializeConfig(test, "test.cfg");
    assert(test.a == a.a);
    assert(test.b == a.b);
    assert(test.someString == a.someString);
    remove("test.cfg");
}

/// Deserialize `T` from string `config`
void deserializeConfigString(T)(auto ref T t, string config) @safe
{
    import std.traits : getSymbolsByUDA, getUDAs;
    import std.conv : to;
    import std.algorithm : startsWith, findSplit, map, each, strip, filter;
    import std.array : split, replace;
    import std.stdio : writeln;
    import mud.functional : unpack;

    auto strings = config.replace("\r", "").split("\n").filter!(x => x != "");
    string[string] values;

    foreach(x; strings)
    {
        if(x.startsWith("#"))
            continue;
        auto parts = x.findSplit("=").unpack.map!(z => z.strip(' '));
        assert(parts.length == 3);
        values[parts[0]] = parts[2];
    }

    static foreach(i; getSymbolsByUDA!(T, ConfigProperty))
    {
        static if(getUDAs!(i, ConfigProperty)[0].name == "")
        {
            if(i.stringof in values)
                __traits(child, t, i) = to!(typeof(i))(values[i.stringof]);
        }
        else
        {
            if(getUDAs!(i, ConfigProperty)[0].name in values)
                __traits(child, t, i) = to!(typeof(i))(values[getUDAs!(i, ConfigProperty)[0].name]);
        }
    }
}

/// Deserialize `T` from file `path`
void deserializeConfig(T)(auto ref T t, string path) @safe
{
    import std.file : readText;
    deserializeConfigString(t, readText(path));
}
///
@safe unittest
{
    struct A
    {
        @ConfigProperty("kek") int a;
        @ConfigProperty() float b;
        string c;
    }
    import std.file : write, remove;
    write("test.cfg", "#this is a comment\r\nkek = 42\r\nb=12.0\r\n");
    A a = A(42, 12.0, "test");
    deserializeConfig(a, "test.cfg");
    assert(a.a == 42);
    assert(a.b == 12.0);
    assert(a.c == "test");
    remove("test.cfg");
}
