# mud  
Maple's Utility for D  
Utility code I use in my projects  
Mostly gists and bits, but contains a few things you may consider useful

## Featured
*mud/memory/smartpointers.d*  
Provides basic smartpointers for d:
```d
class A {}
immutable auto unique = newUnique!A();
```

```d
class A {}
const auto sptr = newShared!A();
```

*mud/config.d*  
Provides basic configuration storing/restoring via UDAs:
```d
struct A
{
    @ConfigProperty() int a;
    @ConfigProperty() float b;
    @ConfigProperty() string someString;
}
auto a = A(12, 42.0, "Some Text");
serializeConfig(a, "test.cfg");
deserializeConfig(a, "test.cfg");
```

*mud/functional/event.d*  
C#-like events!
```d
void f(int) {}
Event!(int) evt;
evt ~= &f;
evt(123);
```
