/**
 * This module contains JSON serialization and deserialization functionality
 */

module mud.json;

import std.json;
import std.traits;
import std.conv : to;

import std.exception : assertThrown, assertNotThrown;

/**
 * A UDA for JSON serialization.
 *
 * Use on any field to mark it as serializable to JSON. Only fields and getters/setters can
 * be marked as `jsonField`s.
 */
struct jsonField
{
    /**
     * Constructs new `jsonField`
     *
     * Params
     *     n = field name in json
     */
    this(string n) @safe nothrow
    {
        name = n;
    }

    /**
     * Controls the field name in JSON.
     *
     * If set to "" (default), the field name is the same as in D code.
     */
    string name;
}

/**
 * A UDA to mark a JSON field as required for deserialization
 *
 * When applied to a field, deserialization will throw if field is not found in json,
 * and serialization will produce `null` for `null` fields
 */
struct jsonRequired { }

/**
 * Serializes an object to a $(LREF JSONValue). To make this work, use $(LREF jsonField) UDA on
 * any fields that you want to be serializable. Automatically maps marked fields to
 * corresponding JSON types. Any field not marked with `jsonField` is not serialized.
 */
JSONValue serializeJSON(T)(auto ref T obj)
{
    static if(isPointer!T)
        return serializeJSON!(PointerTarget!T)(*obj);
    else
    {
        JSONValue ret;
        static foreach(prop; getSymbolsByUDA!(T, jsonField))
        {{
            // Sanity checks
            static assert(getUDAs!(prop, jsonField).length == 1,
                "Only 1 jsonField UDA is allowed per property See " ~ prop.stringof ~ ".");
            static assert(getUDAs!(prop, jsonRequired).length < 2,
                "Only 1 jsonRequired UDA is allowed per property. See " ~ prop.stringof ~ ".");
            static assert(!isFunction!prop ||
                (isGetterFunction!(FunctionTypeOf!prop) || isSetterFunction!(FunctionTypeOf!prop)),
                "Function " ~ prop.stringof ~ " is not a getter or a setter");
            static if(is(getUDAs!(prop, jsonField)[0] == struct))
                enum uda = jsonField("");
            else
                enum uda = getUDAs!(prop, jsonField)[0];

            static if(!isFunction!prop || isGetterFunction!(FunctionTypeOf!prop))
            {
                enum bool required = getUDAs!(prop, jsonRequired).length == 1;
                enum name = uda.name == "" ? __traits(identifier, prop) : uda.name;
                auto value = __traits(child, obj, prop);
                static if(isArray!(typeof(prop)))
                {
                    if(value.length > 0)
                        ret[name] = serializeAutoObj(value);
                    else if(required)
                        ret[name] = JSONValue(null);
                }
                else ret[name] = serializeAutoObj(value);
            }
        }}
        return ret;
    }
}
///
@safe unittest
{
    struct Test
    {
        @jsonField int test = 43;
        @jsonField string other = "Hello, world";

        @jsonField int foo() { return inaccessible; }
        @jsonField void foo(int val) { inaccessible = val; }
    private:
        int inaccessible = 32;
    }

    auto val = serializeJSON(Test());
    assert(val["test"].get!int == 43);
    assert(val["other"].get!string == "Hello, world");
    assert(val["foo"].get!int == 32);
}

/**
 * Deserializes a `JSONValue` to `T`
 *
 * Throws: $(LREF Exception) if fails to create an instance of any class
 *         $(LREF Exception) if a required $(LREF jsonField) is missing
 */
T deserializeJSON(T)(JSONValue root)
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
    static foreach(prop; getSymbolsByUDA!(T, jsonField))
    {{
        // Sanity checks
        static assert(getUDAs!(prop, jsonField).length == 1,
            "Only 1 jsonField UDA is allowed per property See " ~ prop.stringof ~ ".");
        static assert(getUDAs!(prop, jsonRequired).length < 2,
            "Only 1 jsonRequired UDA is allowed per property. See " ~ prop.stringof ~ ".");
        static assert(!isFunction!prop ||
            (isGetterFunction!(FunctionTypeOf!prop) || isSetterFunction!(FunctionTypeOf!prop)),
            "Function " ~ prop.stringof ~ " is not a getter or setter");

        static if(!isFunction!prop || isSetterFunction!(FunctionTypeOf!prop))
        {

            static if(is(getUDAs!(prop, jsonField)[0] == struct))
                enum uda = jsonField("");
            else
                enum uda = getUDAs!(prop, jsonField)[0];

            enum name = uda.name == "" ? __traits(identifier, prop) : uda.name;
            enum bool required = getUDAs!(prop, jsonRequired).length == 1;
            static if(required)
            {
                if((name in root) is null && required)
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
    }}
    return ret;
}
///
@safe unittest
{
    immutable json = `{"a": 123, "b": "Hello"}`;

    struct Test
    {
        @jsonField int a;
        @jsonField string b;
    }

    immutable test = deserializeJSON!Test(parseJSON(json));
    assert(test.a == 123 && test.b == "Hello");
}

@safe unittest
{
    immutable json = `{"a": 123}`;
    struct A { @jsonField("b") @jsonRequired int b; }
    struct B { @jsonField int a; }

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

private template isSetterFunction(T)
{
    enum bool isSetterFunction = isFunction!T && ((Parameters!T).length == 1) && is(ReturnType!T == void);
}
///
@safe unittest
{
    void foo(int b) { }
    int fee() { return 0; }
    int bar(int b) { return b; }
    void baz(int a, int b) { }
    assert(isSetterFunction!(FunctionTypeOf!foo));
    assert(!isSetterFunction!(FunctionTypeOf!fee));
    assert(!isSetterFunction!(FunctionTypeOf!bar));
    assert(!isSetterFunction!(FunctionTypeOf!baz));
}

private template isGetterFunction(T)
{
    enum bool isGetterFunction = isFunction!T && ((Parameters!T).length == 0) && !is(ReturnType!T == void);
}
///
@safe unittest
{
    void foo(int b) { }
    int fee() { return 0; }
    int bar(int b) { return b; }
    void baz(int a, int b) { }
    assert(isGetterFunction!(FunctionTypeOf!fee));
    assert(!isGetterFunction!(FunctionTypeOf!foo));
    assert(!isGetterFunction!(FunctionTypeOf!bar));
    assert(!isGetterFunction!(FunctionTypeOf!baz));
}

// For UT purposes. Declaring those in a unittest causes frame pointer errors
version(unittest)
{
    private struct TestStruct
    {
        @jsonField int a;
        @jsonField string b;

        @jsonField void foo(int val) @safe { inaccessible = val; }
        @jsonField int foo() @safe const { return inaccessible; }
    private:
        int inaccessible;
    }

    private class Test
    {
        @jsonField int a;
        @jsonField string b;
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

unittest
{
    struct Other
    {
        @jsonField
        string name;

        @jsonField
        int id;
    }

    static class TTT
    {
        @jsonField string o = "o";
    }

    struct foo
    {
        // Works with or without brackets
        @jsonField int a = 123;
        @jsonField() double floating = 123;
        @jsonField int[3] arr = [1, 2, 3];
        @jsonField string name = "Hello";
        @jsonField("flag") bool check = true;
        @jsonField() Other object;
        @jsonField Other[3] arrayOfObjects;
        @jsonField Other* nullable = null;
        @jsonField Other* structField = new Other("t", 1);
        @jsonField Test classField = new Test();
    }

    foo orig = foo();
    auto val = serializeJSON(foo());
    string res = toJSON(val);
    foo back = deserializeJSON!foo(parseJSON(res));
    assert(back.a == orig.a);
    assert(back.floating == orig.floating);
    assert(back.structField.id == orig.structField.id);
}
