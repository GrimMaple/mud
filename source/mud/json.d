module mud.json;

import std.json;
import std.traits : getSymbolsByUDA, getUDAs, isPointer, isArray, PointerTarget, fullyQualifiedName;
import std.conv : to;

/**
 * A UDA for JSON serialization. 
 * 
 * Use on any field to mark them as serializable to JSON.
 *
 * Note: Class type fields cannot be marked as a JSONField
 */
struct JSONField
{
    ///
    this(string n)
    {
        name = n;
    }

    /// Controls the resulting field name in JSON
    string name;
}

/**
 * Serializes an object to a `JSONValue`. To make this work, use `JSONField` UDA on 
 * any fields that you want to be serializable. Automatically maps marked fields to 
 * corresponding JSON types. Any field not marked with `JSONField` is not serialized.
 */
JSONValue serializeJSON(T)(auto ref T obj)
{
    static if(isPointer!T)
        return serializeJSON!(PointerTarget!T)(*obj);
    else
    {
        JSONValue ret;
        static foreach(prop; getSymbolsByUDA!(T, JSONField))
        {{
            static assert(getUDAs!(prop, JSONField).length == 1, "Only 1 JSONField UDA is allowed per property");
            static if(is(getUDAs!(prop, JSONField)[0] == struct))
                enum uda = JSONField("");
            else
                enum uda = JSONField(getUDAs!(prop, JSONField)[0].name);
            string name = uda.name == "" ? prop.stringof : uda.name;
            auto value = __traits(child, obj, prop);
            static if(isArray!(typeof(prop)))
            {
                if(value.length > 0)
                    ret[name] = serializeAutoObj(value);
            }
            else ret[name] = serializeAutoObj(value);
        }}
        return ret;
    }
}
///
@safe unittest
{
    struct Test
    {
        @JSONField int test = 43;
        @JSONField string other = "Hello, world";
    }

    auto val = serializeJSON(Test());
    assert(val["test"].get!int == 43);
    assert(val["other"].get!string == "Hello, world");
}

/** 
 * Deserializes a `JSONValue` to `T`
 *
 * Throws: $(LREF Exception) if fails to create an instance of any class
 */
T deserializeJSON(T)(JSONValue root)
{
    static if(is(T == class) || isPointer!T)
    {
        if(root.isNull)
            return null;
    }
    T ret;
    static if(is(T == class))
    {
        ret = new T();
        if(ret is null)
            throw new Exception("Could not create an instance of " ~ fullyQualifiedName!T);
    }
    static foreach(prop; getSymbolsByUDA!(T, JSONField))
    {{
        static assert(getUDAs!(prop, JSONField).length == 1, "Only 1 JSONField UDA is allowed per property");
        static if(is(getUDAs!(prop, JSONField)[0] == struct))
            enum uda = JSONField("");
        else
            enum uda = JSONField(getUDAs!(prop, JSONField)[0].name);

        string name = uda.name == "" ? prop.stringof : uda.name;
        if(name in root)
            __traits(child, ret, prop) = deserializeAutoObj!(typeof(prop))(root[name]);
    }}
    return ret;
}
///
@safe unittest
{
    string json = `{"a": 123, "b": "Hello"}`;
    struct Test
    {
        @JSONField int a;
        @JSONField string b;
    }

    immutable test = deserializeJSON!Test(parseJSON(json));
    assert(test.a == 123 && test.b == "Hello");
}

private JSONValue serializeAutoObj(T)(auto ref T obj)
{
    static if(isJSONNumber!T || isJSONString!T || is(T == bool))
        return JSONValue(obj);
    else static if(is(T == struct))
        return serializeJSON(obj);
    else static if(is(T == class))
        return serializeJSON(obj);
    else static if(isPointer!T && is(PointerTarget!T == struct))
        return obj is null ? JSONValue(null) : serializeJSON(obj);
    else static if(isArray!T)
        return serializeJSONArray(obj);
    else static assert(false, "Cannot serialize type " ~ T.stringof);

}

private JSONValue serializeJSONArray(T)(auto ref T obj)
{
    JSONValue v = JSONValue(new JSONValue[0]);
    foreach(i; obj)
        v.array ~= serializeAutoObj(i);
    return v;
}

private T deserializeAutoObj(T)(auto ref JSONValue value)
{
    static if(is(T == struct))
        return deserializeJSON!T(value);
    else static if(isPointer!T && is(PointerTarget!T == struct))
    {
        if(value.isNull)
            return null;
        alias underlying = PointerTarget!T;
        underlying* ret = new underlying;
        *ret = deserializeAutoObj!underlying(value);
        return ret;
    }
    else static if(is(T == class))
    {
        return deserializeJSON!T(value);
    }
    else static if(isJSONString!T)
        return value.get!T;
    else static if(isArray!T)
        return deserializeJSONArray!T(value);
    else return value.get!T;
}

private T deserializeJSONArray(T)(auto ref JSONValue value)
{
    T ret;
    static if(!__traits(isStaticArray, T))
        ret = new T(value.arrayNoRef.length);
    foreach(i, val; value.arrayNoRef)
        ret[i] = deserializeAutoObj!(typeof(ret[0]))(val);
    return ret;
}

private template isJSONNumber(T)
{
    enum bool isJSONNumber = __traits(isScalar, T) && !isPointer!T && !is(T == bool);
}
///
unittest
{
    assert(isJSONNumber!int);
    assert(isJSONNumber!float);
    assert(!isJSONNumber!bool);
    assert(!isJSONNumber!string);
}

private template isJSONString(T)
{
    enum bool isJSONString = is(T == string) || is(T == wstring) || is(T == dstring);
}
///
@safe @nogc unittest
{
    assert(isJSONString!string && isJSONString!wstring && isJSONString!dstring);
}

/// For UT purposes
private class Test
{
    @JSONField int a;
    @JSONField string b;
}

// Test case for deserializing classes
@safe unittest
{
    string json = `{"a": 123, "b": "Hello"}`;
    auto t = deserializeJSON!Test(parseJSON(json));
    assert(t.a == 123 && t.b == "Hello");
}

unittest
{
    struct other
    {
        @JSONField
        string name;

        @JSONField
        int id;
    }

    static class TTT
    {
        @JSONField string o = "o";
    }

    struct foo
    {
        // Works with or without brackets
        @JSONField int a = 123;
        @JSONField() double floating = 123;
        @JSONField int[3] arr = [1, 2, 3];
        @JSONField string name = "Hello";
        @JSONField("flag") bool check = true;
        @JSONField() other object;
        @JSONField other[3] arrayOfObjects;
        @JSONField other* nullable = null;
        @JSONField other* structField = new other("t", 1);
        @JSONField Test classField = new Test();
    }

    import std.stdio : writeln;
    foo orig = foo();
    auto val = serializeJSON(foo());
    string res = toJSON(val);
    writeln(res);
    foo back = deserializeJSON!foo(parseJSON(res));
    assert(back.a == orig.a);
    assert(back.floating == orig.floating);
    assert(back.structField.id == orig.structField.id);
}
