module mud.serialization;

import std.meta : Filter, AliasSeq;
import std.traits;

/**
 * A UDA for marking fields as serializable.
 *
 * Use on any field to mark it as serializable to JSON. Only fields and getters/setters can
 * be marked as `serializeable`.
 */
struct serializable
{
    /**
     * Constructs new `serializable`
     *
     * Params
     *     n = field name in json
     */
    this(string n) @safe nothrow
    {
        name = n;
    }

    /**
     * Controls the field name in serialized object.
     *
     * If set to "" (default), the field name is the same as in D code.
     */
    string name;
}

template serializableFields(T)
{
    alias serializableFields = getSymbolsByUDA!(T, serializable);

    // Compile-time errors generation
    static foreach(alias prop; getSymbolsByUDA!(T, serializable))
    {
        static assert(getUDAs!(prop, serializable).length == 1,
            "Only 1 `serializable` UDA is allowed per property. See field `" ~ fullyQualifiedName!prop ~ "`.");
        static if(isFunction!prop)
        {
            static assert(isGetterFunction!(FunctionTypeOf!prop) || isSetterFunction!(FunctionTypeOf!prop),
                "Function `" ~ fullyQualifiedName!prop ~ "` is not a getter or setter");
        }
    }
}

/// Retreive all writeable serializables. This includes properties and setters
template serializablesWriteable(T)
{
    alias serializableWriteable = Filter!(isSerializableWriteable, serializableFields!T);
}
///
@safe unittest
{
    struct A
    {
        @serializable int a;
        @serializable void foo(int s);
    }

    import std.stdio : writeln;
    static foreach(aaa; serializableFields!A)
        writeln(fullyQualifiedName!aaa);

        writeln();

    writeln(isSerializableWriteable!(A.a));
    writeln(isSerializableWriteable!(A.foo));

    /*static foreach(aaa; serializablesReadable!A)
        writeln(fullyQualifiedName!aaa);

        writeln();

    static foreach(aaa; serializablesWriteable!A)
        writeln(fullyQualifiedName!aaa);*/
}

/// Retreive all readable serializables. This includes properties and getters
template serializablesReadable(T)
{
    alias serializableWriteable = Filter!(isSerializableReadable, serializableFields!T);
}

private template isSerializableReadable(alias T)
{
    static if(isFunction!T)
        enum bool isSerializableReadable = isGetterFunction!T;
    else
        enum bool isSerializableReadable = true;
}

private template isSerializableWriteable(alias T)
{
    static if(isFunction!T)
        enum bool isSerializableWriteable = isSetterFunction!T;
    else
        enum bool isSerializableWriteable = true;
}

template getSerializableName(alias prop)
{
    static if(is(getUDAs!(prop, serializable)[0] == struct))
        enum getSerializableName = serializable("");
    else
        enum getSerializableName = getUDAs!(prop, serializable)[0];
}

/*private*/ template isSetterFunction(alias T)
{
    enum bool isSetterFunction = isFunction!T && ((Parameters!T).length == 1) && is(ReturnType!T == void);
}
///
@safe @nogc unittest
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

/*private*/ template isGetterFunction(alias T)
{
    enum bool isGetterFunction = isFunction!T && ((Parameters!T).length == 0) && !is(ReturnType!T == void);
}
///
@safe @nogc unittest
{
    void foo(int b) { }
    int fee() { return 0; }
    int bar(int b) { return b; }
    void baz(int a, int b) { }
    struct Test
    {
        int bar() { return 1; }
        void baz() { }
    }
    assert(isGetterFunction!(FunctionTypeOf!fee));
    assert(isGetterFunction!(Test.bar));
    assert(!isGetterFunction!(Test.baz));
    assert(!isGetterFunction!(FunctionTypeOf!foo));
    assert(!isGetterFunction!(FunctionTypeOf!bar));
    assert(!isGetterFunction!(FunctionTypeOf!baz));
}