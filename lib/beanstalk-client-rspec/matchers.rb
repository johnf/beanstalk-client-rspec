require 'rspec/expectations'


module TubeHelper
  def self.extended(klass)
    klass.instance_eval do
      chain :for do |tube_name|
        self.tube_name = tube_name
      end
    end
  end

  private

  attr_accessor :tube_name

  def tubes(beanstalk)
    beanstalk.instance_variable_get(:@connections)['default'].instance_variable_get(:@tubes)
  end

  def tube_name
    @tube_name || 'default'
  end

  def tube_size(beanstalk)
    states = tubes(beanstalk)[tube_name] || {}
    (states['ready'] || []).size
  end
end

RSpec::Matchers.define :have_tube_size_of do |size|
  extend TubeHelper
  match do |actual|
    tube_size(actual) == size
  end

  failure_message_for_should do |actual|
    "expected that tube #{actual} would have #{size} jobs, but got #{tube_size(actual)} jobs instead"
  end

  failure_message_for_should_not do |actual|
    "expected that tube #{actual} would not have #{size} jobs, but got #{tube_size(actual)} jobs instead"
  end

  description do
    "have #{size} jobs in tube"
  end
end

RSpec::Matchers.define :have_tube_size_of_gt do |size|
  extend TubeHelper
  match do |actual|
    tube_size(actual) > size
  end

  failure_message_for_should do |actual|
    "expected that tube #{actual} would have greater than #{size} jobs, but got #{tube_size(actual)} jobs instead"
  end

  failure_message_for_should_not do |actual|
    "expected that tube #{actual} would not have greater than #{size} jobs, but got #{tube_size(actual)} jobs instead"
  end

  description do
    "have greater than #{size} jobs in tube"
  end
end

