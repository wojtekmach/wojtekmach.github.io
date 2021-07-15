---
layout: post
title: "Liskov Principle & MiniTest"
date: 2012-07-17 22:26
comments: true
---

## What is Liskov Principle?

In layman’s terms Liskov Substitution Principle says that if class `Foo` inherits from class `Bar`, then you should be able to use (_substitute_) derived class in every place that the base class is used. For a better definition and further references check out [The Liskov Substitution Principle](http://www.objectmentor.com/resources/articles/lsp.pdf) by Uncle Bob.

## Testing LSP with MiniTest

MiniTest has a really simple design. A test case is a class and an example is a method of that class. After requiring minitest/autorun every subclass of `MiniTest::Unit::TestCase` is instantiated and test methods are executed one by one.

One very nice result of this design, which is kind of obvious when you think about it, is that you can not only inherit helper methods (eg. you subclass `ActionController::TestCase` to have get, post etc) but you may as well inherit whole examples! This is a perfect way to test LSP because, again, you should be able to substitute base class with a derived class.

## Example

Let’s re-implement Ruby’s built-in `Set` class. I’ll write a test first:

``` ruby
require 'minitest/autorun'

class SetTest < MiniTest::Unit::TestCase
  def setup
    @set = Set.new
  end

  def test_size
    assert_equal 0, @set.size
    @set.add 42
    assert_equal 1, @set.size
  end

  def test_include?
    refute @set.include? 42
    @set.add 42
    assert @set.include? 42
  end

  def test_add
    @set.add 13
    @set.add 13
    assert_equal 1, @set.size
  end

  def test_to_a
    @set.add 1
    @set.add 4
    @set.add 2

    ary = @set.to_a

    assert_equal 3, ary.size
    assert ary.include? 1
    assert ary.include? 2
    assert ary.include? 4
  end
end
```

Note I didn’t write the exact result of `Set#to_a` because a cannonical set is unordered. A Ruby 1.9 built-in Set is actually ordered, it simply preserves the order of insertion.

A basic implementation is very easy using Hash like this:

``` ruby
class Set
  include Enumerable

  def initialize
    @hash = {}
  end

  def size
    @hash.size
  end

  def add(obj)
    @hash[obj] = true
  end

  def include?(obj)
    @hash.include? obj
  end

  def each(&block)
    @hash.keys.each(&block)
  end
end
```

Let’s run it:

``` bash
~% ruby set.rb
Run options: --seed 59316

# Running tests:

....

Finished tests in 0.000589s, 6791.1715 tests/s, 15280.1358 assertions/s.

4 tests, 9 assertions, 0 failures, 0 errors, 0 skips
```

Now, let’s write a `SortedSet` that will keep values sorted. Again let’s write a test and run it first:

``` ruby
class SortedSetTest < SetTest
end
```

``` bash
~% ruby set.rb
Run options: --seed 54235

# Running tests:

........

Finished tests in 0.000944s, 8474.5763 tests/s, 19067.7966 assertions/s.

8 tests, 18 assertions, 0 failures, 0 errors, 0 skips
```

We now have exactly twice assertions because all test methods have been inherited. Let’s now build a simple `SortedSet` class and adjust the test, so that we actually use the derived class:

``` ruby
class SortedSetTest < SetTest
  def setup
    @set = SortedSet.new
  end
end

class SortedSet < Set
  def each(&block)
    @hash.keys.sort.each(&block)
  end
end
```

Sure enough all tests passes and we’re now certain that a `Set` object can be substituted with a `SortedSet` object.

Let’s also test the unique behaviour of the SortedSet. We won’t just define `test_to_a` method, because we would overwrite assertions from the base test. We’ll pick a different name instead:

``` ruby
class SortedSetTest < SetTest
  def setup
    @set = SortedSet.new
  end

  def test_to_a_sorted
    @set.add 1
    @set.add 4
    @set.add 2

    assert_equal [1, 2, 4], @set.to_a
  end
end
```

Now, we could stop it right here, but you propably noticed some duplication between `test_to_a` and `test_to_a_sorted`. Again, because we’re using just classes and methods, we can actually write:

``` ruby
class SortedSetTest < SetTest
  def setup
    @set = SortedSet.new
  end

  def test_to_a
    super
    assert_equal [1, 2, 4], @set.to_a
  end
end
```

I’m not sure if it’s that useful and you should use it, but you must agree it’s pretty neat!
