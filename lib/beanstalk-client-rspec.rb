require "beanstalk-client-rspec/version"
require "beanstalk-client-rspec/spec"
require 'beanstalk-client'

module Beanstalk
  class MockConnection < Beanstalk::Connection
    def initialize(addr, default_tube=nil)
      super
      @id_mutex = Mutex.new
      @tube_mutex = Mutex.new
      @tubes = {}
      @id = 0
    end

    # Tests use this to rest stuff
    def flush!
      initialize(nil, @default_tube)
    end

    def connect
      # We don't want to actually connect to anything
    end

    # TODO Put on to reservation queue and deal with bury etc
    def reserve(timeout=nil)
      job = nil
      @watch_list.each do |tube_name|
        begin
          job = @tubes[tube_name]['ready'].pop(false)
        rescue ThreadError
          next
        end

        job['reserves'] += 1
        (@tubes[tube_name]['reserved'] ||= []).push job
      end

      if job.nil?
        if timeout
          return nil
        else
          raise Beanstalk::TimedOut if job.nil?
        end
      end

      Job.new(self, job['id'], job['body'])
    end

    private
    def interact(cmd, rfmt)
      case cmd
      when /^watch/
        [@watch_list.size]
      when /^ignore/
        [@watch_list.size]
      when /^use (\S+)/
        [$1]
      when /^list-tubes-watched/
        @watch_list
      when /^put (\d+) (\d+) (\d+) \d+\r\n(.*)\r\n/
        pri = $1
        delay = $2
        ttr = $3
        body = $4

        id = @id_mutex.synchronize { @id += 1 }
        job = {
          'id'         => id,
          'pri'        => pri,
          'delay'      => delay,
          'ttr'        => ttr,
          'body'       => body.to_s,
          'created_at' => Time.now,
          'file'       => 0,
          'reserves'   => 0,
          'timeouts'   => 0,
          'releases'   => 0,
          'buries'     => 0,
          'kicks'      => 0,
          }
        @tubes[@last_used] ||= {}
        (@tubes[@last_used]['ready'] ||= Queue.new) << job
        [id]
      when /^delete (\d+)/
        id = $1
        @tubes.each_pair do |tube_name, states|
          states['reserved'].delete_if {|job| job[:id] == id }
        end
      when /^stats-job (\d+)/
        id = $1
        @tubes.each_pair do |tube_name, states|
          job = states['reserved'].find {|job| job[:id] == id }
          if job
            return job.merge(
              'state'     => 'reserved',
              'age'       => (Time.now - job[:created_at]),
              'file'      => 0,
              'time-left' => 1,
            )
          end
        end
      when /^release (\d+) (\d+) (\d+)/
        id = $1
        @tubes.each_pair do |tube_name, states|
          job = states['reserved'].delete_if {|job| job[:id] == id }.first
          if job
            job['releases'] += 1
            (@tubes[tube_name]['ready'] ||= Queue.new) << job
          end
        end
      else
        raise "Need to define #{cmd} #{rfmt} for interact"
      end
    end
  end

  class MockPool < Pool
    def connect
      @connections ||= {}
      @addrs.each do |addr|
        if !@connections.include?(addr)
          @connections[addr] = MockConnection.new(addr, @default_tube)
          prev_watched = @connections[addr].list_tubes_watched()
          to_ignore = prev_watched - @watch_list
          @watch_list.each{|tube| @connections[addr].watch(tube)}
          to_ignore.each{|tube| @connections[addr].ignore(tube)}
        end
      end
      @connections.size
    end
  end
end

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

