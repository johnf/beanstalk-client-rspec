require 'spec_helper'

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

  it 'should match gt queue size' do
    @beanstalk.use 'oath'
    @beanstalk.yput :foo => 'bar'
    @beanstalk.yput :foo => 'bar'
    @beanstalk.yput :foo => 'bar'
    @beanstalk.should have_tube_size_of_gt(2).for('oath')
  end
end
