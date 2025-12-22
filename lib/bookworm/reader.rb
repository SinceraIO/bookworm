# frozen_string_literal: true

require "concurrent-ruby"

module Bookworm
  class Reader
    RELOAD_INTERVAL = 30 * 60 # 30 minutes

    attr_reader :stream_name, :positions

    def initialize(stream_name, persistence)
      @persistence = persistence
      @stream_name = stream_name
      @reloading = false
      load_positions
      @task = Concurrent::TimerTask.new(execution_interval: RELOAD_INTERVAL) { reload_shards }
    end

    def subscribe(&block)
      @block = block
      @task.execute
      subscribe_all
    end

    private

    def client
      @client ||= Aws::Kinesis::Client.new(
        region: "us-east-1",
        access_key_id: ENV.fetch("AWS_EC2_PUBLIC_KEY", nil),
        secret_access_key: ENV.fetch("AWS_EC2_SECRET_KEY", nil),
        logger: Logger.instance
      )
    end

    def shards
      @shards ||= get_shards
    end

    def get_shards
      client.describe_stream(stream_name: stream_name)
            .stream_description.shards
            .map { |s| Shard.new(s.shard_id, stream_name, positions[s.shard_id], client) }
    end

    def reload_shards
      Logger.info "Reloading Kinesis shards for stream: #{stream_name}"
      @reloading = true
      wait_for_idle
      @shards = nil
      load_positions
      @reloading = false
      Logger.info "Re-subscribing Kinesis shards for stream: #{stream_name}"
      subscribe_all
    end

    def subscribe_all
      Logger.info "Reading Kinesis shards for stream: #{stream_name}"
      shards.each { |shard| pool.post(shard) { |s| fetch_records(s, @block) } }
    end

    def fetch_records(shard, block)
      loop do
        break if @reloading

        shard.records { |shard_id, records| block.call(shard_id, records) }
        break if @reloading
      end
    end

    def wait_for_idle
      Logger.debug "Waiting for pool to become idle. Starting"
      loop do
        if pool.active_count.zero?
          Logger.debug "Pool is idling. Done"
          return
        end
        Logger.debug "Pool is not idling yet, size: #{pool.active_count}"
        sleep 1
      end
      Logger.debug "Waiting for pool to become idle. Finished"
    end

    def load_positions
      @positions = @persistence.load_positions
    end

    def pool
      @pool ||= Concurrent::CachedThreadPool.new(min_threads: 10)
    end
  end
end
