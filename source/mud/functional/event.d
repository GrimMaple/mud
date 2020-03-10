module source.mud.functional.event;

/// C#-like events!
struct Event(Args...)
{
    alias delegateType = void delegate(Args);

    /// Convenienve subscription overload
    void opOpAssign(string s)(delegateType deleg) if(s == "~")
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
    void subscribe(delegateType deleg)
    {
        delegates ~= [deleg];
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
    void remove(delegateType deleg)
    {
        import std.algorithm : remove;
        delegates = delegates.remove!(a => a.ptr == deleg.ptr);
    }
    ///
    unittest
    {
        void local(int a) {}
        Event!(int) evt;
        evt.subscribe(&local);
        evt.remove(&local);
    }

    /// Call the event
    void opCall(Args args)
    {
        foreach(deleg; delegates)
            deleg(args);
    }
private:
    delegateType[] delegates = new delegateType[0];
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