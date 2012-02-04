require "beanstalk-client-rspec/version"

module Beanstalk
  class MockPool < Pool
    def connect
    end

    def initialize(addr, default_tube=nil)
      super
      @id_mutex = Mutex.new
      @tube_mutex = Mutex.new
      flush!
    end

    def interact(cmd, rfmt)
    end

    # Tests use this to rest stuff
    def flush!
      @last_used = 'default'
      @watch_list = ['default']
      @watch_list = [@default_tube] if @default_tube
      @tubes = {}
      @id = 1
    end

    def put(body, pri=65536, delay=0, ttr=120)
      (@tubes[@last_used] ||= Queue.new) << {
        :id    => @id,
        :pri   => pri,
        :delay => delay,
        :ttr   => ttr,
        :body  => body.to_s
      }
      @mutex_id.synchronize { @id += 1 }

      return @id
    end

    def on_tube(tube, &block)
      @tube_mutex.lock
      use tube
      yield self
    ensure
      @tube_mutex.unlock
    end

    # TODO Put on to reservation queue and deal with bury etc
    def reserve(timeout=nil)
      job = nil
      @watch_list.each do |tube|
        begin
          job = tube.pop(false)
        rescue ThreadError
          next
        end
      end

      if job.nil?
        if timeout
          return nil
        else
          raise Beanstalk::TimedOut if job.nil?
        end
      end

      Job.new(self, job[:id], job[:body])
    end

  end
end

    #def initialize(addr, default_tube=nil)
    #  @default_tube = default_tube
    #  flush!
    #end


#def job_stats(id)
#      job = nil
#      @watch_list.each do |tube|
#        job = @tubes[tube].find {|j| j[:id] == id}
#        break if job
#      end
#      job
#    end

#    def delete(id)
#      @watch_list.each do |tube|
#        next if @tubes[tube].nil? || @tubes[tube].empty?
#        @tubes[tube] = @tubes[tube].reject {|j| j[:id] == id}
#      end
#      :ok
#    end
#
#    def bury(id, pri)
#      @watch_list.each do |tube|
#        @tubes[tube] = @tubes[tube].reject {|j| j[:id] == id}
#      end
#      :ok
#    end

#
    # Stuff for testing the mock
    #
#    def tube_size(tube=nil)
#      return 0 if ! @tubes[tube || @last_used]
#      @tubes[tube || @last_used].size
#    end
#
#    def current_tube
#      @last_tube
#    end

