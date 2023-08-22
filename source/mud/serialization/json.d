module mud.serialization.json;

import std.traits;
import std.conv : to;

import std.exception : assertThrown, assertNotThrown;
import std.json;

import mud.serialization;

/**
 * A UDA to mark a JSON field as required for deserialization
 *
 * When applied to a field, deserialization will throw if field is not found in json,
 * and serialization will produce `null` for `null` fields
 */
struct jsonRequired { }

/**
 * Serializes an object to a $(LREF JSONValue). To make this work, use $(LREF serializable) UDA on
 * any fields that you want to be serializable. Automatically maps marked fields to
 * corresponding JSON types. Any field not marked with $(LREF serializable) is not serialized.
 */
JSONValue serializeJSON(T)(auto ref T obj)
{
    static if(isPointer!T)
        return serializeJSON!(PointerTarget!T)(*obj);
    else
    {
        JSONValue ret;
        foreach(alias prop; serializablesReadable!T)
        {
            enum name = getSerializableName!prop;
            auto value = __traits(child, obj, prop);
            static if(isArray!(typeof(prop)))
            {
                if(value.length > 0)
                    ret[name] = serializeAutoObj(value);
                else if(isJSONRequired!prop)
                    ret[name] = JSONValue(null);
            }
            else ret[name] = serializeAutoObj(value);
        }
        return ret;
    }
}
///
@safe unittest
{
    struct Test
    {
        @serializable int test = 43;
        @serializable string other = "Hello, world";

        @serializable int foo() { return inaccessible; }
        @serializable void foo(int val) { inaccessible = val; }
    private:
        int inaccessible = 32;
    }

    auto val = serializeJSON(Test());
    assert(val["test"].get!int == 43);
    assert(val["other"].get!string == "Hello, world");
    assert(val["foo"].get!int == 32);
}

/**
 * Serialize `T` into a JSON string
 */
string serializeToJSONString(T)(auto ref T obj)
{
    auto val = serializeJSON(obj);
    return toJSON(val);
}
///
@safe unittest
{
    struct Test
    {
        @serializable int test = 43;
        @serializable string other = "Hello, world";

        @serializable int foo() { return inaccessible; }
        @serializable void foo(int val) { inaccessible = val; }
    private:
        int inaccessible = 32;
    }

    assert(serializeToJSONString(Test()) == `{"foo":32,"other":"Hello, world","test":43}`);
}
/**
 * Deserializes a $(LREF JSONValue) to `T`
 *
 * Throws: $(LREF Exception) if fails to create an instance of any class
 *         $(LREF Exception) if a required $(LREF jsonField) is missing
 */
T deserializeJSON(T)(auto ref JSONValue root)
{
    import std.stdio : writeln;
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
    foreach(alias prop; serializablesWriteable!T)
    {
        enum name = getSerializableName!prop;
        static if(isJSONRequired!prop)
        {
            if((name in root) is null && isJSONRequired!prop)
                throw new Exception("Missing required field \"" ~ name ~ "\" in JSON!");
        }
        if(name in root)
        {
            static if(isFunction!prop)
                __traits(child, ret, prop) = deserializeAutoObj!(Parameters!prop[0])(root[name]);
            else
                __traits(child, ret, prop) = deserializeAutoObj!(typeof(prop))(root[name]);
        }
    }
    return ret;
}
///
@safe unittest
{
    immutable json = `{"a": 123, "b": "Hello"}`;

    struct Test
    {
        @serializable int a;
        @serializable string b;
    }

    immutable test = deserializeJSON!Test(parseJSON(json));
    assert(test.a == 123 && test.b == "Hello");
}

/**
 * Deserialize a JSON string into `T`
 */
T deserializeJSONFromString(T)(string json)
{
    return deserializeJSON!T(parseJSON(json));
}
///
@safe unittest
{
    immutable json = `{"a": 123, "b": "Hello"}`;

    struct Test
    {
        @serializable int a;
        @serializable string b;
    }

    immutable test = deserializeJSONFromString!Test(json);
    assert(test.a == 123 && test.b == "Hello");
}

@safe unittest
{
    immutable json = `{"a": 123}`;
    struct A { @serializable("b") @jsonRequired int b; }
    struct B { @serializable int a; }

    auto res = parseJSON(json);
    assertThrown(deserializeJSON!A(res));
    assertNotThrown(deserializeJSON!B(res));
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

private template isJSONRequired(alias T)
{
    enum bool isJSONRequired = getUDAs!(T, jsonRequired).length > 0;
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
@safe unittest
{
    assert(isJSONString!string && isJSONString!wstring && isJSONString!dstring);
}

// For UT purposes. Declaring those in a unittest causes frame pointer errors
version(unittest)
{
    private struct TestStruct
    {
        @serializable int a;
        @serializable string b;

        @serializable void foo(int val) @safe { inaccessible = val; }
        @serializable int foo() @safe const { return inaccessible; }
    private:
        int inaccessible;
    }

    private class Test
    {
        @serializable int a;
        @serializable string b;
    }
}

// Test case for deserialization with getters
@safe unittest
{
    string json = `{"a": 123, "b": "Hello", "foo": 345}`;
    auto t = deserializeJSON!TestStruct(parseJSON(json));
    assert(t.a == 123 && t.b == "Hello" && t.foo == 345);
}

// Test case for deserializing classes
@safe unittest
{
    string json = `{"a": 123, "b": "Hello"}`;
    auto t = deserializeJSON!Test(parseJSON(json));
    assert(t.a == 123 && t.b == "Hello");
}

// Global unittest for everything
unittest
{
    struct Other
    {
        @serializable
        string name;

        @serializable
        int id;
    }

    static class TTT
    {
        @serializable string o = "o";
    }

    struct Foo
    {
        // Works with or without brackets
        @serializable int a = 123;
        @serializable() double floating = 123;
        @serializable int[3] arr = [1, 2, 3];
        @serializable string name = "Hello";
        @serializable("flag") bool check = true;
        @serializable() Other object;
        @serializable Other[3] arrayOfObjects;
        @serializable Other* nullable = null;
        @serializable Other* structField = new Other("t", 1);
        @serializable Test classField = new Test();
    }

    auto orig = Foo();
    auto val = serializeJSON(Foo());
    string res = toJSON(val);
    auto back = deserializeJSON!Foo(parseJSON(res));
    assert(back.a == orig.a);
    assert(back.floating == orig.floating);
    assert(back.structField.id == orig.structField.id);
}

// Special tests to check compile-time messages
unittest
{
    struct TooMany
    {
        @serializable @serializable int a;
    }

    struct NotSetter
    {
        @serializable void b(int a, int b);
    }

    TooMany a;
    NotSetter b;

    assert(!__traits(compiles, serializeJSON(a))); // Error: Only 1 UDA is allowed per property
    assert(!__traits(compiles, serializeJSON(b))); // Error: not a getter or a setter
}

// Test for using return value
@safe unittest
{
    struct A
    {
        @serializable int a;
    }

    A a = deserializeJSON!A(parseJSON("{\"a\": 123}"));
}
