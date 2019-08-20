title: VCR
subtitle: War Stories
description: VCR War Stories
author: Jan Zdráhal
theme: black

# What's VCR?

- stands for Video Cassette Recorder
- records your test suite's HTTP interactions and replays them during future test runs for fast, deterministic, accurate tests
- [https://github.com/vcr/vcr](https://github.com/vcr/vcr)

# How it works?

- checks HTTP method and URI (and optionally body)
- matchers for nondeterministic URIs

# Time for a Demo

<aside class="notes">
    Explain server.rb, test.rb.
</aside>

# Why we used it?

## 45 Minute CI Build
![slow build](slow_build.png)
- caused by a lot of integration tests
- ran on every PR
- 45 minutes to find out your code is broken
- every glitch of the staging server fails the build
- high load on the staging server
- hitting request limits

## Solution Attempt #1

- running unit tests with every PR and integration tests only once a day
- too many bugs getting to the develop branch
- we would learn about our bugs the next day (after switching context)

## The Solution

> With VCR, the same test suite finishes in under 5 minutes. That's 88% faster!
![fast build](fast_build.png)

## VCR Setup

- live tests [running every day](https://travis-ci.org/gooddata/gooddata-ruby/builds/520872126)

# Problems

> Making your tests run under VCR is not a walk in the park.

## Initial Investment

- VCRizing the tests took weeks (the dev was new to the project and language though)
- all blocks (not recorded by default)(https://github.com/gooddata/gooddata-ruby/blob/master/spec/spec_helper.rb#L70)
- [parallelism](https://github.com/gooddata/gooddata-ruby/blob/master/spec/spec_helper.rb#L60)

## Development Overhead
- re-recording cassettes with almost every change
- recording cassettes could be automated
- writing matchers cannot be automated
- problems with recording from the middle of the test suite (e.g. [project cache](https://github.com/gooddata/gooddata-ruby/blob/master/spec/vcr_configurer.rb#L65-L71))
- where to store 390M of cassettes?

## Unit Tests?
- it's tempting not to write unit tests
- unit tests are needed for covering edge cases
- if it's hard to write tests, the code is probably too complex
- fortunately test coverage can be checked automatically (e.g. Coveralls)

# Summary
> VCR helped us make our 45 minute CI build run in under 5 minutes. The build is reliable and doesn't produce load on the staging server. Developers are happier and more productive because of the fast turn-around. There was a substantial initial investment and there is some development overhead (recording, writing matchers, troubleshooting). In our case, the benefits significantly outweigh the costs.
