require 'spec_helper'

require 'beanstalk_spec'

describe 'RSpec' do
  before do
    @beanstalk = Beanstalk::MockPool.new ['localhost:11300']
  end

  it 'should match empty tube size' do
    @beanstalk.should have_tube_size_of(0)
  end

  it 'should match queue size' do
    @beanstalk.use 'oath'
    @beanstalk.yput :foo => 'bar'
    @beanstalk.should have_tube_size_of(1).for('oath')
  end
end
