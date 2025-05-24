# reiter

`reiter` enables Ziglings to effortlessly create their own iterators for their favourite types. Iterators can be made for native Zig types, std/external library types or any other types.

This library takes inspiration and several ideas from the [zig-iter](https://github.com/softprops/zig-iter) library and Rust's [std::iter::Iterator](https://doc.rust-lang.org/std/iter/trait.Iterator.html) trait but does not promise to adhere 100% to any of their implementations.

## Installing reiter

First, fetch the source using this command inside your Zig project:

```bash
zig fetch --save https://github.com/noahpolimon/reiter/archive/refs/heads/main.tar.gz
```
> Recommended for now

or:

```bash
zig fetch --save https://github.com/noahpolimon/reiter/archive/refs/tags/v0.1.0.tar.gz
```

> Please note that reiter is currently not stable. You can replace the "v0.1.0" with any version you want.

Then, add it in your `build.zig` file to the root module of your executable or library:

```diff
// code
+ const reiter = b.dependency("reiter", .{
+     .target = target,
+     .optimize = optimize,
+ }).module("reiter");

const exe = b.addExecutable(.{
    .name = "my_project",
    .root_module = exe_mod,
});

+ exe.root_module.addImport("reiter", reiter);

b.installArtifact(exe);
// code
```

The last step is to run:

```bash
zig build
```

Voila! You may now import and use the reiter library. 

## Methods on Iter

`.next()` 
- This is the main method that pretty much every variation/wrapper of `Iter` uses in this library. It yields the next element from the iterator.

`.sizeHint()` (experimental)
- Returns a tuple containing a lower bound and upper bound of the length of the remaining items in the iterator. A lower bound of value `std.math.maxInt(usize)` or/and an upper bound of value `null` represent an unknown or infinite length.  
- This method, if defined by an implementation, should return correct values.

`.nth(n)`
- Advances the iterator by `n`, then returns the next element. Returns `null` if the iterator is consumed before `n` is reached.

`.count()` 
- Consumes the iterator to count its number of elements.
  
`.any(predicate)`
- Returns `true` on finding the first element for which the predicate is true. 
- Consumes the iterator completely if none of the elements returns `true` for the predicate or if only the last element does.
  
`.all(predicate)`
- Returns `true` if all the elements of the iterator for which the predicate is true, short-circuiting on the first element for which the predicate is false.

`.min()`
- Consumes the iterator to obtain the minimum value from the iterator. Type of `Item` should be comparable.

`.max()`
- Consumes the iterator to obtain the maximum value from the iterator. Type of `Item` should be comparable.

`.forEach(func)` 
- Consumes the iterator and applies the function on each elements. This method does not yield anything.

`.fold(type, acc, func)` 
- Consumes the iterator and folds it into a single value of a specified type by accumulating a value computed by the function.

`.find(func)`
- Finds the first item for which the predicate is true.

`.reduce(func)` 
- Similar to the `.fold()` method but converges to a value the same type or `null` if the iterator is empty, thus not requiring an initial value.

`.last()` 
- Consumes the iterator and returns the last value of the iterator. 

`.enumerate()` 
- Creates an iterator that yields enumerated values in the form of `struct { usize, I.Item }` tuples.

`.filter(predicate)`
- Creates an iterator that yields only values for which the predicate is true.

`.filterMap(type, func)`
- Filters and maps values for which `func` does not return `null` 

`.map(type, func)`
- Transforms values to a specified type using `func` before yielding them. 

`.mapWhile(type, func)`
- Creates an iterator that yields mapped values while `func` does not return a `null`. 

`.take(n)`
- Creates an iterator that yields only its first `n` elements.

`.takeWhile(predicate)`
- Creates an iterator that yields elements for which the predicate is true. 

`.chain(other)`
- Creates an iterator that yields the value of the original iterator and then the value of the chained one. The only constraint is that the two iterators should yield the same value type.

`.zip(other)`
- Creates an iterator that yields paired values in the form of `struct { I.Item, OtherI.Item }` until 1 of the iterators is consumed. 

`.peekable()`
- Creates an iterator that provides the `.peek()` method. It allows retrieving the next value from the iterator without advancing it.

`.cycle()`
- Creates an iterator that loops back to the start instead of yielding `null` when it is consumed.

`.skip(n)`
- Creates an iterator that skips `n` elements before yielding.
  
`.skipWhile(predicate)`
- Creates an iterator that skips elements until the predicate is false.
  
`.skipEvery(n)`
- Creates an iterator that skips `n` elements every time it yields an element.

`.stepBy(n)`
- Simillar to `.skipEvery()`. However the first element of the iterator is yielded, then `n - 1` elements are skipped.

> ...more to come

## "Implementing" Iter

`Iter` is a generic iterator that yields values from some kind of collection, range, indexable, etc... lazily. Iterators should have the following when "implementing" `Iter`:

- `Item` - The `Item` declaration __*should*__ be public and equal to the type of values the iterator yields. 
- `fn next(*@This()) ?Item` - The `next` method __*should*__ be public and have the exact same signature.  

An example implementation would be:

```zig
// Import `Iter` from the lib 
const Iter = @import("reiter").Iter;

// Create the iterator type
const MyIterator = struct {
    const Self = @This();

    // This is necessary so as to allow adapters such as Map, Filter, etc.. 
    // to obtain the type your iterator is yielding.
    pub const Item = u8;

    index: usize = 0,
    buffer: []const u8 = "wxyz",

    pub fn next(self: *Self) ?Item {
        if (self.index >= self.buffer.len) 
            return null;

        const ret = self.buffer[self.index];
        self.index += 1;
        return ret;
    }

    pub fn sizeHint(self: Self) struct { usize, ?usize } {
        const s = self.buffer.len - self.index;
        return .{ s, s };
    }

    // This is just an example. You may choose to use an `init` or `from`
    // method or any other way. However, any equivalent method/function to the 
    // one below should return `Iter(@This())`.
    pub fn iter(self: Self) Iter(Self) {
        return .{ .wrapped = self };
    }
};
```

After creating an iterator it is possible to use and chain methods like any Rust iterators.

```zig
const my_iterator = MyIterator{};

var x = my_iterator.iter()
    .stepBy(1)
    .enumerate()
    .take(2)
    .map(u32, struct {
    fn call(i: struct { usize, u8 }) u32 {
        const j: u32 = @intCast(i.@"0");
        return j + i.@"1";
    }
}.call);
```

Apart from this minor detail :/

```zig
struct {
    fn call(i: struct { usize, u8 }) u32 {
        const j: u32 = @intCast(i.@"0");
        return j + i.@"1";
    }
}.call
```

Zig does not (and i think most likely will not) support closures. In the case it does in the future, this library will 
be updated to align with it.

## Examples

More examples are found in the `examples` directory. 

## Initializers

Initializers are pre-made functions that can be used to create iterators for a particular Zig type or use case.

`empty(type)`
- Creates an iterator that does not yield anything.

    ```zig
    var i = reiter.empty(u32);

    _ = i.next(); // null
    ```

`once(type, item)`
- Creates an iterator that yields `item` only once.

    ```zig
    var i = reiter.once(u32, 50);

    _ = i.next(); // 50
    _ = i.next(); // null
    ```

`lazyOnce(type, func)`
- Creates an iterator that yields the return value of `func` once.

    ```zig
    var i = reiter.lazyOnce(u32, struct {
        fn call() u32 {
            return 50;
        }
    }.call);

    _ = i.next(); // 50
    _ = i.next(); // null
    ```

`repeat(type, item)`
- Creates an iterator that yields `item` repeatedly. This is the equivalent of using `once(type, item).cycle()`.

    ```zig
    var i = reiter.repeat(u32, 50);
    
    for (0..1_000_000) |_| {
        _ = i.next(); // always returns 50
    }
    ```

`repeatN(type, item, n)`
- Creates an iterator that yields `item` `n` times. This is the equivalent of using `once(type, item).cycle().take(n)`.

    ```zig
    const n: usize = 3;
    var i = reiter.repeatN(u32, 50, n);
    
    for (0..n) |_| {
        _ = i.next(); // 50
    }

    _ = i.next(); // null
    ```

`lazyRepeat(type, item)`
- Creates an iterator that yields the return value of `func` repeatedly.

    ```zig
    var i = reiter.lazyRepeat(u32, struct {
        fn call() u32 {
            return 50;
        }
    }.call);
    
    for (0..1_000_000) |_| {
        _ = i.next(); // always returns 50
    }
    ```

`fromSlice(type, slice)`
- Creates an iterator that yields elements of a slice.

    ```zig
    const arr = [_]u32{ 0, 1, 2};
    var i = reiter.fromSlice(u32, &arr);
    
    _ = i.next(); // 0
    _ = i.next(); // 1
    _ = i.next(); // 2
    _ = i.next(); // null
    ```

`fromRange(type, start, end)`
- Creates an iterator from an integer range. The end value is exclusive.

    ```zig
    var i = reiter.fromRange(u32, 0, 2);
    
    _ = i.next(); // 0
    _ = i.next(); // 1
    _ = i.next(); // null
    ```

`fromRangeStep(type, start, end, step)`
- Similar to `fromRange()`. However, the step can be modified. Negative step is possible as long as start > end, which is not possible with `.stepBy()`. 

    ```zig
    var i = reiter.fromRangeStep(u32, 0, 5, 2);
    
    _ = i.next(); // 0
    _ = i.next(); // 2
    _ = i.next(); // 4
    _ = i.next(); // null
    ```

`recurse(type, init, func)`
- Computes the value of the next iteration from the last yielded value. `init` is yielded first then the next value is computed from it.

    ```zig
    var i = reiter.recurse(u32, 0, struct {
        fn call(x: u32) ?u32 {
            if (x >= 5) return null;
            return x + 1;
        }
    }.call);
    
    _ = i.next(); // 0
    _ = i.next(); // 1
    _ = i.next(); // 2
    _ = i.next(); // 3
    _ = i.next(); // 4
    _ = i.next(); // null
    ```

## Project Particulars

* Not using features of Zig that have an uncertain future, e.g, `usingnamespace` (see [zig#20663](https://github.com/ziglang/zig/issues/20663))
* Avoid using `anytype` wherever possible unless: 
  1. The type would be long to type or not easy to find out if used as function parameter, e.g, `Iter(Enumerate(Take(FilterMap(Chain(Once(...), ...)))))`
  2. The type could really be of any type, e.g, struct fields.
* Does not redundantly include "zig" in the name. (see [zig -o- 236fb91](http://github.com/ziglang/zig/commit/236fb915cc1c3b59b47e609125b680743c9c1ec0))

## License

This project is licensed under the [MIT License](LICENSE).
