require 'spec_helper'

require 'beanstalk-client-rspec'

describe Beanstalk::MockPool do

  before do
    @beanstalk = Beanstalk::MockPool.new ['127.0.0.1:11300']
  end

  it 'should accept objects on the default' do
    @beanstalk.put 'cow'
    job = @beanstalk.reserve
    job.body.should == 'cow'
  end

  it 'should accept objects on a named tube' do
    @beanstalk.use 'moo'
    @beanstalk.put 'cow'

    @beanstalk.ignore 'default'
    @beanstalk.watch 'moo'
    job = @beanstalk.reserve
    job.body.should == 'cow'
  end
end
