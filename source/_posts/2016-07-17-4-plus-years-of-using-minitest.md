---
layout: post
title: "4+ Years of Using Minitest"
date: 2016-07-17 19:21
comments: true
categories: 
---

In the [last](/blog/2015/07/17/testing-shape-of-data) [few](/blog/2014/07/17/integration-testing-on-different-levels/) [blog](/blog/2013/07/17/sharing-examples-in-minitest/) [posts](/blog/2012/07/17/liskov-principle-and-minitest/) I wrote about my experiments with Minitest in the last few years.
For today's blog post I thought I'd write how some of Minitest's design decision affected how I write tests these days and in general how my approach to testing have changed.

## Test cases

As I wrote in [Sharing Examples in Minitest](/blog/2013/07/17/sharing-examples-in-minitest/), in Minitest we usually write test cases by inheriting from base classes like `Minitest::Test`, `ActionController::TestCase` etc.

In my projects I often needed to add some customizations to the tests, e.g. using a Minitest plugin or custom assertions. I used to add these extensions to `test/test_helper.rb` like this:

```ruby
# my_project/test/test_helper.rb

class Minitest::Test
  include MyCustomAssertions
end

class ActionDispatch::IntegrationTest
  include Capybara::DSL
end
```

These days I'd usually write custom test cases instead:

```ruby
# my_project/test/test_helper.rb

class MyProjectTest < Minitest::Test
  include MyCustomAssertions
end

class AcceptanceTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
end
```

This has a few benefits:

- no monkey patching.
- better code organization. By creating an actual class for each test _type_ it's pretty natural to eventually move it to a separate file (with the name corresponding to the class, somwhere in `test/support/`) if it grows to be too big.
- `ctags` friendliness.
- encourages to have even more custom test cases. It's very useful when there's a specific subsystem of the app that deserves it's own test case (e.g. `BillingTest`) that contains helper methods, custom assertions & perhaps extra docs. Again, `ctags` friendliness really helps here.

## Stubbing & Mocking

I'm speculating here, but I wouldn't be suprised if there would be as many resources praising stubbing (or more broadly, _test isolation_) as critizing it.

For me, the biggest problems with stubbing are as follows:

- "stubbing at a distance" in a `setup/before` block _somewhere_ in base test case/mixin can lead to very unexpected and hard to track bugs.
- "stub leaking", when stubbing global objects, can too lead to unexpected and hard to track bugs.
- depending on testing/mocking framework it's sometimes very _easy_ to stub multiple things at once, leading to complex and coupled tests that are hard to maintain.

Note, none of the issues above is intrisic to a particular testing/mocking library - it boils down to how it's being used.

Minitest ships with a mocking/stubbing support in the `minitest/mock` package. Here's an example of stubbing from the docs:

```ruby
def test_stale_eh
  obj_under_test = Something.new

  refute obj_under_test.stale?

  Time.stub :now, Time.at(0) do   # stub goes away once the block is done
    assert obj_under_test.stale?
  end
end
```

Note the comment, "stub goes away once the block is done".
This is really important and it actually solves, or rather provides a constraint, for all of the problems I listed above.
Since the stubbing happens locally, within the given block, we solve the problem of "stubbing at a distance" as well as "leaking".
In order stub multiple things at once we'd need to nest calls to stub which really stands out (as it should) and actually looks pretty terrible. That was the "aha" moment for me.
This one time, I needed to stub a couple of dependencies and started nesting calls to `stub` but looking at it, "listening to the tests", gave me a pause and I reconsidered my design to have at most one stub in that test and thus having it be more decoupled. In fact, I think I ended up with no stubs at all in that case.

As a matter of fact, I seldom write stubs these days. I tend to prefer writing a "fake" object instead:

```ruby
class PaymentGateway
  def initialize(@adapter)
    @adapter = adapter
  end

  def pay(description, amount)
    @adapter.pay(description, amount)
  end
end

class PaymentGateway::Payment < Struct.new :reference, :amount, :status
end

class PaymentGateway::Stripe
  def self.pay(description, amount)
    # ...
  end
end

class PaymentGateway::Fake
  def self.pay(description, amount)
    if description =~ /failure/
      Payment.new(description, amount, :failure)
    else
      Payment.new(description, amount, :success)
    end
  end
end
```

What's great about this is that I can re-use the fake in many tests as well as in development. I can make the fake more real (but not too real!) by handling important edge case which I can then trivially invoke in, again, both tests & development.

As far as mocking, I seldom do mocking nowadays. Instead of expecting that some object (usually at the boundary of the system) received some message, I'd inspect how the (deterministic) return value of my fake object is being used.
In other cases, especially in larger methods when there's some data being calculated and then sent over to an object, I'd split the method in two: 1 method that does the calculation (unit tested) and the 2nd method that invokes some other object (usually untested, integration tested instead).

## Tooling & Practices

I'm constantly impressed how Minitest community is pushing for better tooling and practices. Perhaps the tools/ideas below have not originated in Minitest, but it's where I first heard about them. For each item I added the year when it was added/considered in Minitest:

- [heckle](https://github.com/seattlerb/heckle) - mutation testing library. (2006)
- Randomize tests by default. (2008)
- [assert_nothing_tested](http://www.zenspider.com/ruby/2012/01/assert_nothing_tested.html) - Minitest doesn't have `assert_nothing_raised`. Instead of asserting that nothing failed, we should assert what the code is actually doing. (2012)
- [minitest-bisect](https://github.com/seattlerb/minitest-bisect) - finds the smallest amount of tests to run (in a particular order) to reproduce an order-dependant test failure. (2014)
- [minitest-proveit](https://github.com/seattlerb/minitest-proveit) - forces all tests to prove success (via at least one assertion) rather than rely on the absence of failure. (2016)
- [`assert_equal` should not allow `nil` for "expected"](https://github.com/seattlerb/minitest/pull/626) - if your code expects a `nil` then explicitly use `assert_nil`, otherwise you might have a `nil` value and not even know about it. (2016)


## Updates

- updated "Tooling & Practices" section by adding description, mentioning heckle, and a link to `minitest-proveit` (thanks @splattael!)
