# Beanstalk::Client::Rspec

Allows easy mocking of Beanstalk::Client

## Installation

Add this line to your application's Gemfile:

    gem 'beanstalk-client-rspec'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install beanstalk-client-rspec

## Usage

TODO: Write usage instructions here

## Caveats

* No timeout logic is implemented. i.e. jobs stay reserved forever

## TODO

* Write more tests
* Implement job delay
* Implement job priority
* Implement
  - bury
  - touch
  - peek
  - peek-ready
  - peek-delayed
  - peek-buried
  - kick
  - stats-tube
  - stats
  - list-tubes
  - list-tubes-used
  - quit
  - pause-tube 

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
