<div align="center">

# ⚡reiter  

[![Zig Version](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fgithub.com%2Fnoahpolimon%2Freiter%2Fblob%2Fmain%2Fbuild.zig.zon&search=.minimum_zig_version%20%3D%20%5C%5C%22(%5Cd*%5C.%5Cd*%5C.%5Cd*)%5C%5C%22%2C&replace=v%241&style=flat&logo=zig&label=zig)](https://ziglang.org/documentation/master/)
[![Release Version](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fgithub.com%2Fnoahpolimon%2Freiter%2Fblob%2Fmain%2Fbuild.zig.zon&search=.version%20%3D%20%5C%5C%22(%5Cd*%5C.%5Cd*%5C.%5Cd*)%5C%5C%22%2C&replace=v%241&style=flat&logo=semanticrelease&label=reiter)](https://github.com/noahpolimon/reiter/releases)
[![GitHub License](https://img.shields.io/github/license/noahpolimon/reiter)](/LICENSE)
</div>

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

## "Implementing" Iter

`Iter` is a generic iterator that yields values from some kind of collection, range, indexable, etc... lazily. Iterators should have the following when "implementing" `Iter`:

- `Item` - The `Item` declaration __*should*__ be public and equal to the type of values the iterator yields. 
- `fn next(*@This()) ?Item` - The `next` method __*should*__ be public and have the exact same signature.  
- `fn <method_name>(@This()) Iter(@This())` - A public method that returns the wrapped iterator. 

A simple implementation would look like the example below:

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

    // This is just an example. You may choose to use an `init` or `from`
    // method or any other way. However, any equivalent method/function to the 
    // one below should return `Iter(@This())`.
    pub fn iter(self: Self) Iter(Self) {
        return .{ .wrapped = self };
    }
};
```

After creating an iterator it is possible to use and chain methods like so:

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

## Methods on Iter

See [here](/docs/METHODS-ON-ITER.md) to know which methods can be used on iterators.

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
