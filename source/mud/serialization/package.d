module mud.serialization;

import std.meta : Filter, AliasSeq;
import std.traits;

/**
 * A UDA for marking fields as serializable.
 *
 * Use on any field to mark it as serializable. Only fields and getters/setters can
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

/**
 * Retreive all fields of type `T` that are $(LREF serializable)
 */
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
unittest
{
    struct A
    {
        @serializable int a;
        @serializable int foo() { return 1; }
        @serializable void bar(int a) { b = a; }
        int b;
    }
}

template isSerializable(alias T)
{
    enum bool isSerializable = getUDAs!(T, serializable).length == 1;
}
unittest
{
    struct A
    {
        @serializable int a;
        int b;
    }

    assert(isSerializable!(A.a));
    assert(!isSerializable!(A.b));
}

/// Retreive all writeable serializables for `T`. This includes properties and setters.
template serializablesWriteable(alias T)
{
    alias serializablesWriteable = Filter!(isSerializableWriteable, serializableFields!T);
}
///
@safe unittest
{
    static struct A
    {
        @serializable void a(int value) { _a = value; }
        @serializable int b;
        private int _a;
    }
}
///
@safe unittest
{
    struct A
    {
        @serializable int a;
        @serializable void foo(int s);
    }
}

/// Retreive all readable serializables. This includes properties and getters
template serializablesReadable(alias T)
{
    alias serializablesReadable = Filter!(isSerializableReadable, serializableFields!T);
}
///
@safe unittest
{
    static struct A
    {
        @serializable void a(int value) { _a = value; }
        @serializable int b;
        private int _a;
    }
}

template isSerializableReadable(alias T) if(isSerializable!T)
{
    static if (isFunction!T)
        enum bool isSerializableReadable = isGetterFunction!T;
    else
        enum bool isSerializableReadable = true;
}
@safe @nogc unittest
{
    struct A
    {
        @serializable void foo(int a) { }
        @serializable int bar() { return 1; }
        @serializable int a;
        int b;
    }

    assert(isSerializableReadable!(A.a));
    assert(isSerializableReadable!(A.bar));
    assert(!isSerializableReadable!(A.foo));
}



template isSerializableWriteable(alias T) if(isSerializable!T)
{
    static if(isFunction!T)
        enum bool isSerializableWriteable = isSetterFunction!T;
    else
        enum bool isSerializableWriteable = true;
}

template getSerializableName(alias prop)
{
    static if(is(getUDAs!(prop, serializable)[0] == struct))
        enum string getSerializableName = __traits(identifier, prop);
    else
        enum string getSerializableName = getUDAs!(prop, serializable)[0].name == "" ? __traits(identifier, prop) : getUDAs!(prop, serializable)[0].name ;
}

template isSetterFunction(alias T)
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
