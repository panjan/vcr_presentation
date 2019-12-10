title: VCR
subtitle: War Stories
description: VCR War Stories
author: Jan Zdráhal
theme: black

# What's VCR?

![Video Cassette Recorder](vcr.jpg)

<aside class="notes">
  I'm a user of the Ruby Gem VCR which I'll be talking about today. But first, younger people in the audience might need reminding what VCR is. It stands for video cassette recorder and it's the thing in the picture.

  But it's also a ruby gem...
</aside>

# What's VCR?

- records your test suite's HTTP interactions and replays them during future test runs for fast, deterministic, accurate tests
- [https://github.com/vcr/vcr](https://github.com/vcr/vcr)

<aside class="notes">
    The VCR gem records your HTTP requests made during tests so that you can "replay" them later for fast and deterministic tests. This is very useful for testing integration with third-party services. I'd like to talk about how VCR helped my team to a fast and stable continuous integration build. But also about some problems I've encountered and when it's better to use something else.

    Q: I'll start with a question. Who has used VCR before?
</aside>

# Example

``` ruby
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = { :record => :new_episodes }
end

describe "VCR", :vcr do
  it 'records an http request' do
    5.times do
      puts Net::HTTP.get_response('localhost', '/', 4567).body
    end
  end
end
```

<aside class="notes">
    I prepared a small example of a test that uses VCR. The first block contains all the necessary VCR-related configuration. The second block is an RSpec test which makes 5 HTTP GETs to a local server. Note the :vcr symbol which goes to `describe` as a parameter - it tells VCR to record this test.
</aside>

# Example Server

``` ruby
require 'sinatra'

get '/' do
  sleep 1
  'Hello Ruby Stories!'
end
```

<aside class="notes">
    Here's code for the server. It's a lazy server because it sleeps 1 second before returning the string "Hello Ruby Stories!".

    Questions?

    Now let's spin up the tape recorder and capture some requests.
</aside>

# Demo

<video src="vcr_demo.mov"></video>

<aside class="notes">
    I recorded a little demo so that you can see how VCR looks in action.

    1) First we run the test we saw earlier...
    2) run test again - fast and deterministic this time
    3) git status & explain ./cassettes
    4) test.rb: 5.times -> 6.times and run test again

    Questions?
</aside>

# How it works?

- checks HTTP method, URI, host, path, body and headers
- matchers for nondeterministic URIs

``` ruby
random_id_matcher = lambda do |actual, recorded|
  random_id_regex = %r{/uploads/.+}
  actual.parsed_uri.path.match random_id_regex
end
```

<aside class="notes">
    The comparison of recorded vs actual requests is done by comparing the HTTP method and URI. There are also built-in matchers for host, path, body and headers.

    You may wonder what happens when you're testing some resource with a random element like a timestamp in the url. That's where custom matchers come into play.

    Questions?
</aside>

# Why we used it?

<aside class="notes">
    Now for the promised war stories. :-) In my last job I was fortunate to be the maintainer of a ruby sdk which led me to finding about and using VCR. And here's why I used it.
</aside>

## 45 Minute CI Build
![slow build](slow_build.png)
- caused by a lot of integration tests
- ran on every PR
- 45 minutes to find out your code is broken
- every glitch of the staging server fails the build
- high load on the staging server
- hitting request limits

<aside class="notes">
    An sdk obviously makes a lot of requests and we ended up with a 45 minute CI build which ran on every PR. With very little mocked unit tests, development was starting to get sluggish. Imagine you make a PR and after 45 minutes you learn the testing server was down and have to rerun the build.

    Q: Who has a shorter/longer CI build?

    With so many integration tests we were causing trouble not only to ourselves but also to others by putting high load on the staging server, often hitting request limits.

    So we decided to act...
</aside>

## Solution Attempt #1

- running unit tests with every PR and integration tests only once a day
- too many bugs getting to the develop branch
- we would learn about our bugs the next day (after switching context)

## The Solution

> With VCR, the same test suite finishes in under 5 minutes. That's 88% faster!
![fast build](fast_build.png)

- live tests [running every day](https://travis-ci.org/gooddata/gooddata-ruby/builds/520872126)

<aside class="notes">
  So we used VCR and suddenly the build shortened from 45 minutes to 5. In order to discover changes/bugs on the server, we still ran the "live" tests every day. Sounds cool, right?
</aside>


# Problems

> Making your tests run under VCR is not a walk in the park.

## Initial Investment

- VCRizing the tests took two weeks (the dev was new to the project and language though)
- all blocks [not recorded by default](https://github.com/gooddata/gooddata-ruby/blob/master/spec/spec_helper.rb#L70)
- [parallelism](https://github.com/gooddata/gooddata-ruby/blob/master/spec/spec_helper.rb#L60)

<aside class="notes">
  There was a substantial initial investment. It took two man-weeks to overcome all problems we encountered. For example, we discovered that the order of requests is important so VCR doesn't go well with parallellism. We had to do little hacks here and there. [click on parallellism] Then we discovered that VCR doesn't record rspec all blocks by default. And there's a good reason for that. Here's a little riddle.
</aside>

## Time for a Riddle

``` ruby
describe 'all block riddle' do
  before(:all) do
    user_id = server.create_user
  end

  it 'does something' do
    server.do_something_with_user user_id
  end

  it 'does something else' do
    server.do_something_else_with_user user_id
  end
end
```

<aside class="notes">
  What do you think will happen when we record the whole test suite (including the before all block) and then we re-record only one of the two examples?
</aside>

## Development Overhead
- re-recording cassettes with every change
- recording cassettes could be automated
- writing matchers cannot be automated
- problems with recording from the middle of the test suite (e.g. [project cache](https://github.com/gooddata/gooddata-ruby/blob/master/spec/vcr_configurer.rb#L65-L71))
- where to store 390M of cassettes?

<aside class="notes">
  After overcoming the initial investment, there's the development overhead. After every change that affects HTTP interactions, you have to re-record the cassettes. Fortunately, IMHO it could be automated but we did manually. What can't be automated is writing matchers. Every time there's some randomness, you write a matcher. The riddle we did was a nice example of problems with re-recording from the middle of the testsuite. The last thing to consider is where to store your cassettes. Our SDK tests produced a tremendous amount of cassette files which totalled to 390MB.
</aside>

## When to Use Something Else

- emulators (e.g. Google Datastore emulator)
- mock libraries (e.g. redis-mock)
- manual mocks

<aside class="notes">
  That being said, I'd like to talk about alternatives we have when it comes to testing third party services. Some of them have standalone emulators which can be run locally (like Google Datastore emulator). Some services have mock-libraries which mimick the real behaviour. And the last option is simply writing manual mocks. So my advice is - every time  you're deciding on how to test HTTP interactions, go through this short list a pick the most suitable option. Also, if you're testing your own server (for example like we did with the SDK), consider avoiding writing integration tests. For example, at my current job, we're generating an SDK from an open-api specification, eliminating the need for extensive testing. Also we're generating mocks from the specification so manual mocking becomes much easier.

  Questions?
</aside>

## Unit Tests?
- it's tempting not to write unit tests
- unit tests are needed for covering edge cases
- if it's hard to write tests, the code is probably too complex
- fortunately test coverage can be checked automatically (e.g. Coveralls)

<aside class="notes">
  After witnessing the power of VCR, it might be tempting to abandon unit tests all together. But I have to advice you against it because unit tests are always needed for covering edge cases, especially in duck-typed languages such as Ruby.
</aside>

# Summary

<aside class="notes">
    To sum up, VCR helped us make our 45 minute CI build run in under 5 minutes. The build is reliable and doesn't produce load on the staging server. Developers are happier and more productive because of the fast turn-around. There was a substantial initial investment and there is some development overhead (recording, writing matchers, troubleshooting). In our case, the benefits significantly outweigh the costs. Hopefully you've learned something new from my presentation. I wish you happy recording.

    Questions?
</aside>

