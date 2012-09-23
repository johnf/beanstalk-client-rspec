# -*- encoding: utf-8 -*-
require File.expand_path('../lib/beanstalk-client-rspec/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["John Ferlito"]
  gem.email         = ["johnf@inodes.org"]
  gem.summary       = %q{Mock and RSpec for beanstalk-client}
  gem.description   = %q{Provides a fairly complete mock for beanstalk-client by imitating beanstalkd using arrays. Also provides some rspec matchers for testing the state of the system.}
  gem.license       = 'MIT'
  gem.homepage      = "https://github.com/johnf/beanstalk-client-rspec"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "beanstalk-client-rspec"
  gem.require_paths = ["lib"]
  gem.version       = Beanstalk::Client::Rspec::VERSION

  gem.add_dependency('rspec')
  gem.add_dependency('beanstalk-client')

  gem.add_development_dependency('rake')
end
