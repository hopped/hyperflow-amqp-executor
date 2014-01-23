require "amqp"
require 'json'
require 'recursive-open-struct'
require 'open3'
require 'tmpdir'
require 'logger'

require_relative 'hyperflow-amqp-executor/helpers'
require_relative 'hyperflow-amqp-executor/job'
require_relative 'hyperflow-amqp-executor/local_storage'
require_relative 'hyperflow-amqp-executor/s3_storage'

module Executor
  class << self
    attr_accessor  :events_exchange, :id
    
    def logger
      @logger ||= Logger.new($stdout)
    end    
    
    def thread_count
      unless ENV['THREADS'].nil?
        ENV['THREADS']
      else
        begin
          `nproc`
        rescue
          1
        end
      end.to_i
    end
    
    def publish_event(type, payload = {})
      data = payload
      data['timestamp'] = Time.now.utc
      data['type']      = type
      data['worker']    = @id
      EventMachine::next_tick do 
        @events_exchange.publish(JSON.dump(data), content_type: 'application/json', routing_key: type)
      end
    end
  end
end