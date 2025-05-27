## Methods on Iter

`.next()` 
- This is the main method that pretty much every variation/wrapper of `Iter` uses in this library. It yields the next element from the iterator.

`.sizeHint()` (experimental)
- Returns a tuple containing a lower bound and upper bound of the length of the remaining items in the iterator. A lower bound of value `std.math.maxInt(usize)` or/and an upper bound of value `null` represent an unknown or infinite length.  

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
