require 'beanstalk-client-rspec/matchers'

module BeanstalkSpec
  extend self
  def tube(tube_name)
    tube_name
  end
end

#config = RSpec.configuration
#config.include BeanstalkSpec::Helpers
#
#World(BeanstalkSpec::Helpers) if defined?(World)



