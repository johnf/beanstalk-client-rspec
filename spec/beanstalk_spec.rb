require 'spec_helper'

require 'beanstalk-client-rspec'

describe Beanstalk::MockPool do
  before do
    @beanstalk = Beanstalk::MockPool.new ['127.0.0.1:11301']
  end

  it 'should accept objects on the default' do
    @beanstalk.put 'cow'
    job = @beanstalk.reserve
    job.body.should == 'cow'

    job.release

    job = @beanstalk.reserve
    job.body.should == 'cow'

    job.delete
  end

  it 'should accept objects on a named tube' do
    @beanstalk.use 'moo'
    @beanstalk.put 'cow'

    @beanstalk.watch 'moo'
    @beanstalk.ignore 'default'
    job = @beanstalk.reserve
    job.body.should == 'cow'
  end

  it 'should deal with on_tube' do
    @beanstalk.on_tube 'foo' do |c|
      c.put 'cow'
    end

    @beanstalk.watch 'foo'
    @beanstalk.ignore 'default'
    job = @beanstalk.reserve
    job.body.should == 'cow'
  end

  describe 'reset!' do

    it 'should empty tubes' do
      @beanstalk.put 'cow'
      @beanstalk.should have_tube_size_of(1).for('default')
      @beanstalk.reset!
      @beanstalk.should have_tube_size_of(0).for('default')
    end

    it 'should not be watching anything' do
      @beanstalk.list_tubes_watched.values.flatten.should == ['default']
      @beanstalk.watch 'foo'
      @beanstalk.list_tubes_watched.values.flatten.should == ['default', 'foo']
      @beanstalk.reset!
      @beanstalk.list_tubes_watched.values.flatten.should == ['default']
    end
  end

end
