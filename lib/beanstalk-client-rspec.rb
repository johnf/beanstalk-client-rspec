require "beanstalk-client-rspec/version"
require "beanstalk-client-rspec/spec"
require 'beanstalk-client'

module Beanstalk
  class MockConnection < Beanstalk::Connection
    def initialize(addr, default_tube=nil)
      super
      @default_tube = default_tube
      reset!
    end

    # Tests use this to rest stuff
    def reset!
      @id_mutex = Mutex.new
      @tube_mutex = Mutex.new
      @tubes = {}
      @id = 0

      # Super reset
      @mutex = Mutex.new
      @tube_mutex = Mutex.new
      @waiting = false
      @last_used = 'default'
      @watch_list = [@last_used]
      self.use(@default_tube) if @default_tube
      self.watch(@default_tube) if @default_tube
    end

    # Tests use this to rest stuff
    def clear!
      @id_mutex = Mutex.new
      @tube_mutex = Mutex.new
      @tubes = {}
      @id = 0

      # Super reset
      @mutex = Mutex.new
      @tube_mutex = Mutex.new
      @waiting = false
    end

    def connect
      # We don't want to actually connect to anything
    end

    # TODO Put on to reservation queue and deal with bury etc
    def reserve(timeout=nil)
      job = nil
      @watch_list.each do |tube_name|
        begin
          if @tubes[tube_name].nil?
            next
          end
          job = @tubes[tube_name]['ready'].pop(true)
        rescue ThreadError
          next
        end

        job['reserves'] += 1
        (@tubes[tube_name]['reserved'] ||= []).push job
      end

      if job.nil?
        if timeout
          raise Beanstalk::TimedOut
        else
          return nil
        end
      end

      Job.new(self, job['id'], job['body'])
    end

    private
    def interact(cmd, rfmt)
      case cmd
      when /^watch (\S+)/
        [@watch_list.size]
      when /^ignore/
        [@watch_list.size]
      when /^use (\S+)/
        [$1]
      when /^list-tubes-watched/
        @watch_list
      when /^put (\d+) (\d+) (\d+) \d+\r\n(.*)\r\n/m
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
      if !@connections.include?('default')
        @connections['default'] = MockConnection.new('default', @default_tube)
      end
      @connections.size
    end

    def reset!
      @connections.values.each do |c|
        c.reset!
      end
    end

    def clear!
      @connections.values.each do |c|
        c.clear!
      end
    end
  end
end
