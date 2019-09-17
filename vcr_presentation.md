title: VCR
subtitle: War Stories
description: VCR War Stories
author: Jan Zdráhal
theme: black

# What's VCR?

![Video Cassette Recorder](vcr.jpg)

# What's VCR?

- records your test suite's HTTP interactions and replays them during future test runs for fast, deterministic, accurate tests
- [https://github.com/vcr/vcr](https://github.com/vcr/vcr)

<aside class="notes">
    Artikulovat, zrychlit, rozkliknout odkazy. Go into detail about/better explain problems - like project. Zaver v odrazkach. Other langs. why - usually 3rd party services. code generation. photo of a vcr

    I'm a user of the Ruby Gem VCR which records your HTTP requests made during tests so that you can "replay" them later for fast and deterministic tests. I'd like to talk about how VCR helped my team to a fast and stable continuous integration build. But also about some problems I've encountered and when it's better to use something else.

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
    Now for the war stories. :-)
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
    We had a 45 minute CI build which ran on every PR. This wasn't your ordinary Rails app, but an SDK which makes a lot of HTTP requests. With very little mocked unit tests, development was starting to get sluggish. Imagine you make a PR and after 45 minutes you learn the testing server was down and have to rerun the build.

    Also we were causing trouble to others by putting high load on the staging server, often hitting request limits.

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

# Problems

> Making your tests run under VCR is not a walk in the park.

## Initial Investment

- VCRizing the tests took two weeks (the dev was new to the project and language though)
- all blocks (not recorded by default)(https://github.com/gooddata/gooddata-ruby/blob/master/spec/spec_helper.rb#L70)
- [parallelism](https://github.com/gooddata/gooddata-ruby/blob/master/spec/spec_helper.rb#L60)

<aside class="notes">
    well isolated tests needed
</aside>

## Development Overhead
- re-recording cassettes with every change
- recording cassettes could be automated
- writing matchers cannot be automated
- problems with recording from the middle of the test suite (e.g. [project cache](https://github.com/gooddata/gooddata-ruby/blob/master/spec/vcr_configurer.rb#L65-L71))
- where to store 390M of cassettes?

## When to Use Something Else

- emulators (e.g. Google Datastore emulator)
- mock libraries (e.g. redis-mock)
- manual mocks

## Unit Tests?
- it's tempting not to write unit tests
- unit tests are needed for covering edge cases
- if it's hard to write tests, the code is probably too complex
- fortunately test coverage can be checked automatically (e.g. Coveralls)

# Summary

<aside class="notes">
    To sum up, VCR helped us make our 45 minute CI build run in under 5 minutes. The build is reliable and doesn't produce load on the staging server. Developers are happier and more productive because of the fast turn-around. There was a substantial initial investment and there is some development overhead (recording, writing matchers, troubleshooting). In our case, the benefits significantly outweigh the costs.
</aside>

