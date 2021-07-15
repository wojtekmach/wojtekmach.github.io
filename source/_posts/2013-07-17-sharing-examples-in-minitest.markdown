---
layout: post
title: "Sharing examples in Minitest"
date: 2013-07-17 22:26
comments: true
---

[Last time](/blog/2012/07/17/liskov-principle-and-minitest/) I wrote about enforcing Liskov principle via tests. It was pretty simple to do in Minitest using just class inheritance. Sometimes, however, we can't inherit test methods because the framework forces us to inherit from a test case class like:

* `ActiveSupport::TestCase`
* `ActionDispatch::IntegrationTest`

etc. In these cases we need to find some other way to share behavior and with Minitest's design the answer is pretty simple - modules.

## Example

Let's write a simple data store library inspired by [Moneta](https://github.com/minad/moneta)

``` ruby
class DataStore
  def initialize(adapter)
    @adapter = adapter
  end

  def get(key)
    @adapter.get(key)
  end

  def set(key, value)
    @adapter.set(key, value)
  end
end
```

Now let's write an adapter:

``` ruby
class DataStore::InMemoryAdapter
  def initialize
    @hash = {}
  end

  def get(key)
    @hash[key]
  end

  def set(key, value)
    @hash[key] = value
  end
end
```

Let's write a test for this. Knowing we will later reuse test methods, we start with a module:

``` ruby
module DataStore::AdapterTest
  def test_get_not_found
    assert_equal nil, @adapter.get(:invalid)
  end

  def test_set
    @adapter.set(:foo, 42)
    assert_equal 42, @adapter.get(:foo)
  end
end
```

Now the actual `DataStore::InMemoryAdapter` test (note, I'm using `Minitest::Test` which comes from minitest 5):

``` ruby
class DataStore::InMemoryAdapterTest < Minitest::Test 
  include DataStore::AdapterTest

  def setup
    @adapter = DataStore::InMemoryAdapter.new
  end
end
```

Running this we see that two examples have been "inherited" from the shared module:

``` bash
~% ruby shared.rb
Run options: --seed 18221

# Running:

..

Finished in 0.001126s, 1776.1989 runs/s, 1776.1989 assertions/s.

2 runs, 2 assertions, 0 failures, 0 errors, 0 skips
```

With this foundation it's pretty easy to add new adapters and we don't really have to write new tests. Including shared module in the test is enough to have confidence that an adapter is conforming to an interface.

Let's say we package the data store as a gem. We can ship the `AdapterTest` as an integral part of the gem distribution and let the users write their own application specific adapters. Just as Rails ships with `ActionDsipatch::IntegrationTest`.

## minitest/spec

It's actually pretty easy to use shared modules with minitest/spec. It's simple because minitest/spec is really just a DSL on top of minitest/test (minitest/unit). A `describe` block creates a new `Minitest::Test` class, an `it` block defines a new `test_` method. With this in mind we can start with our custom DSL like this:

``` ruby
module DataStore::AdapterSpec
  it "returns nil for an invalid key" do
    @adapter.get(:invalid).must_equal nil
  end

  it "can set a value" do
    @adapter.set(:foo, 42)
    @adapter.get(:foo).must_equal 42
  end
end
```

And the spec:

``` ruby
describe DataStore::InMemoryAdapter do
  include DataStore::AdapterSpec

  before do
    @adapter = DataStore::InMemoryAdapter.new
  end
end
```

Running this will result in error like:

``` bash
<module:AdapterSpec>: undefined method 'it' for DataStore::AdapterSpec:Module (NoMethodError)
```

Let's fix this; we basically have to implement `Module#it` for it to work:

``` ruby
class Module
  def it(description, &block)
    define_method "test_#{description}", &block
  end
end
```

Tests should be passing now.

I mentioned before that minitest/spec is just a DSL. In fact, there's literally a [Minitest::Spec::DSL module](https://github.com/seattlerb/minitest/blob/363ff3fe7c0144f6d02d04dabad9ceee5d252fa7/lib/minitest/spec.rb#L96) that `Minitest::Spec` is including. The DSL module is so good in fact that it can be included both in classes and in other modules:

``` ruby
class Module
  include Minitest::Spec::DSL
end
```

and it just works! We now can do stuff like:

``` ruby
module SomeTest
  before { "..." }
  after { "..." }

  let(:foo) { "..." }

  it "returns this" do
  end

  it "returns that" do
  end
end
```

etc.

The way `Minitest::Spec::DSL` is implemented is actually pretty simple. It doesn't do anything special; it just defines a bunch of methods like `setup`, `teardown`, `foo`, `test_returns_this` etc. It means that after the "DSL" phase we end up with just a ruby module that we can include (or not), and nothing is evaluated until the module is included somewhere.

## Conclusion

Minitest's simple design allows us to extend it with standard tools we use in day to day ruby programming. We can use the same exact constructs like classes, modules, inheritance & mixins for both the production & test code. As a consequence of this design writing minitest extensions is imho pretty easy too!
