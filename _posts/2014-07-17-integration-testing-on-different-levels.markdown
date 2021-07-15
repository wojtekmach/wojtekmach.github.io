---
layout: post
title: "Integration testing on different levels"
date: 2014-07-17 23:17
comments: false
permalink: /blog/2014/07/17/integration-testing-on-different-levels/
---

[Last time](/blog/2013/07/17/sharing-examples-in-minitest/) I wrote about sharing examples in Minitest. This time I want to show an idea I had for a long time about reusing the same test to verify system's behavior on different levels.

Let's say we're building a simple signup application. We may end up with a test like this:

(Check out full code here: <https://github.com/wojtekmach/signups>)

```ruby
class SignupWebTest < ActionDispatch::IntegrationTest
  def test_success
    visit "/"
    fill_in "Email", with: "example@gmail.com"
    click_button "Sign up"

    assert page.has_content? "Thanks!"
  end

  def test_failure
    visit "/"
    fill_in "Email", with: "invalid"
    click_button "Sign up"

    assert signup.has_content? "Email" "is invalid"
  end
end
```

Now, let's say we also want to have an API. Often times we are testing the same two scenarios as above, usually with the same test data:

```ruby
class SignupAPITest < ActionDispatch::IntegrationTest
  def test_success
    post '/signup', signup: {email: 'example@gmail.com'}
    assert last_response.succes?
  end

  def test_failure
    post '/signup', signup: {email: 'invalid'}
    refute last_response.succes?
    assert_equal Hash['email' => ['is invalid']], JSON(last_response.body)['errors']
  end
end
```

Finally, we also have the lower level test that's using the application logic directly:

```ruby
class SignupTest < Minitest::Test
  def test_success
    signup = Signup.new(email: 'example@gmail.com')
    signup.submit
    assert signup.valid?
    # assert email was sent etc.
  end

  def test_failure
    signup = Signup.new(email: 'invalid')
    refute signup.valid?
    assert_equal Hash[email: ['is invalid']], signup.errors.messages
  end
end
```

We can extract the common part from all tests into helper methods like this:

```ruby
class SignupWebTest < ActionDispatch::IntegrationTest
  def test_success
    signup(email: 'example@gmail.com')
    assert page.has_content? "Thanks!"
  end

  def test_failure
    signup(email: 'invalid')
    assert signup.has_content? "Email" "is invalid"
  end

  private

  def signup(attributes)
    visit "/"
    fill_in "Email", with: attributes[:email]
    click_button "Sign up"
  end
end

class SignupAPITest < ActionDispatch::IntegrationTest
  def test_success
    signup(email: 'example@gmail.com')
    assert last_response.succes?
  end

  def test_failure
    signup(email: 'invalid')
    assert_equal Hash['email' => ['is invalid']], JSON(last_response.body)['errors']
  end

  private

  def signup(attributes)
    post '/signup', signup: attributes
  end
end
```

As I am writing this, without thinking about it, I was just gonna work on cleaning up the 3rd test but, which is kind of the point of this post, there isn't anything to clean up there. There's no duplication that's worth extracting out or some test/production API quirks worth hiding. Since we fully control the application code we can design it however we want.

This brings us back to the title of this post about reusing the same test on different levels. What I want to do is to design an interface that will behave like the `Signup` class, but under the hood will either call the application logic directly or use Web UI or API. The test must be written in such a way it's easy to inject dependencies.
Here's one approach; I write it as a module that will be later included into concrete test cases.

```ruby
module SignupTests
  def test_success
    signup = @app.signup(email: 'example@gmail.com').submit
    assert signup.valid?
  end

  def test_failure
    signup = @app.signup(email: 'invalid').submit
    assert !signup.valid?
    assert_equal Hash[email: ['is invalid']], signup.error_messages
  end
end
```

What's an `@app`? It's an _object_ that knows how to construct _object_ that can play a role of a `Signup`. Object that can play role of `@app` need only to implement `#signup` _message_. For `Signup` _role_ they need `#submit`, `#valid?` and `#error_messages`. Here are possible implementations:

```ruby
class WebClient
  def signup(attributes)
    Signup.new(attributes)
  end

  class Signup
    include Capybara::DSL

    def initialize(attributes)
      @email = attributes[:email]
    end

    def submit
      visit '/'
      fill_in 'Email', with: @email
    end

    def valid?
      page.has_content? "Thanks!"
    end

    # ...
  end
end

class APIClient
  def initialize(base_uri)
    @base_uri = base_uri
  end

  def signup(attributes)
    Signup.new(self, attributes)
  end

  class Signup
    def initialize(client, attributes)
      @client, @attributes = client, attributes
    end

    def submit
      RestClient.post(@client.base_uri + "/signup", signup: @attributes)
      # ...
    end

    # ...
  end
end

class App
  def signup(attributes)
    Signup.new(attributes)
  end
end
```

Now we can write the remaining concrete test cases:

```ruby
class SignupAppTest < Minitest::Test
  include SignupTests

  def setup
    @app = App.new
  end
end

class SignupAPITest < Minitest::Test
  include SignupTests

  def setup
    WebMock.stub_request(:any, /signup.test/).to_rack(Rails.application.routes)
    @app = APIClient.new('http://signup.test')
  end
end

class SignupWebTest < Minitest::Test
  include SignupTests

  def setup
    Capybara.app = Rails.application
    @app = WebClient.new
  end
end
```

There's a few nice benefits about this design.

For one thing this setup is highly configurable. We can easily switch certain levels on and off. What's more, we can take this configuration further and for the UI & API tests point them to live servers (e.g. staging.example.com) instead of local servers on development machine. This has added benefit that we can find more errors this way, like for example asset pipeline & general deployment issues, DNS etc. Granted, this works extremely well for a simple application as such that's basically stateless but it should still be doable for more complex cases.

This test design also forced us to write mostly production (albeit not used by the production app) code and just a little bit of simple test code. A nice side effect of this is I think you'd generally keep this code more organized if it's not a part of the test suite. More importantly though as a way of testing the app we built client libraries to access API (See <http://robots.thoughtbot.com/how-to-test-sinatra-based-web-services>) and the Web UI. If you're lucky enough to have a dedicated QA team they may appreciate that they can drive the app using quite convenient interface yet still be able to access raw features of capybara etc.

Finally, there's one more thing maybe worth mentioning. If we have 2 instances of the app running on `app1.example.com` and `app2.example.com` it's entirely possible to configure `app1`'s controllers to use `APIClient` (instead of simply `App`) pointed to `app2.example.com` without a single change in the application code. Again, probably not that useful but I think it's pretty cool :-)
