module source.mud.functional.event;

import std.container.array;
import mud.container.growing;

/// C#-like events!
struct Event(Args...)
{
    alias delegateType = void delegate(Args);

    /// Convenienve subscription overload
    void opOpAssign(string s)(delegateType deleg) @safe @nogc nothrow if(s == "~")
    {
        subscribe(deleg);
    }
    ///
    unittest
    {
        void f(int) {}
        Event!(int) evt;
        evt ~= &f;
    }

    /// Subscribe to event
    void subscribe(delegateType deleg) @trusted @nogc nothrow
    {
        delegates.insert(deleg);
    }
    ///
    unittest
    {
        int d = 0;
        void local(int t)
        {
            d += t;
        }
        Event!(int) evt;
        evt.subscribe(&local);
        evt(10);
        assert(d == 10);
    }

    /// Remove a subscriber
    void remove(delegateType deleg) @trusted @nogc nothrow
    {
        for(int i=0; i<delegates.length; i++)
        {
            if(delegates[i].ptr == deleg.ptr)
            {
                Array!delegateType n;
                n.reserve(delegates.length - 1);
                n ~= delegates[0 .. i];
                n ~= delegates[i+1 .. $];
                delegates = n;
                return;
            }
        }
    }
    ///
    unittest
    {
        int z = 0;
        void local(int a) { z = a; }
        Event!(int) evt;
        evt.subscribe(&local);
        evt.remove(&local);
        evt(10);
        assert(z == 0);
    }

    /// Call the event
    void opCall(Args args) @trusted
    {
        foreach(deleg; delegates)
            deleg(args);
    }

    ~this() @safe @nogc nothrow {}
private:
    Array!delegateType delegates;// = new delegateType[0];
}
///
unittest
{
    class Base
    {
        Event!(int, int) someEvent;

        void doAction()
        {
            someEvent(10, 20);
        }
    }

    class D
    {
        int val = 0;

        void cbk(int a, int b)
        {
            val = a + b;
        }
    }

    auto b = new Base();
    auto d = new D();
    b.someEvent ~= &d.cbk;
    b.doAction();
    assert(d.val == 30);
    b.someEvent.remove(&d.cbk);
    b.doAction(); // Removes delegate
    assert(d.val == 30); // No value change is expected
}

unittest
{
    void f(int a) {}
    Event!int evt;
    evt(10);
    evt.remove(&f);
}