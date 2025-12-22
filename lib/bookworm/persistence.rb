# frozen_string_literal: true

require "redis"

module Bookworm
  class Persistence
    EXPIRATION = 3 * 24 * 60 * 60 # 3 days

    def initialize(stream_name)
      @stream_name = stream_name
    end

    def load_positions
      Hash(redis.keys(key("*")).to_h { |p| [p.split(":").last, redis.get(p)] })
    end

    def store_position(shard_id, sequence_number, timestamp)
      ::Bookworm::Logger.debug "Storing #{shard_id} position #{sequence_number} at #{timestamp}"
      redis.set(key(shard_id), sequence_number, ex: EXPIRATION)
    end

    private

    def key(shard_id)
      "stream:#{@stream_name}:#{shard_id}"
    end

    def redis
      @redis ||= Redis.new(url: ENV.fetch("REDIS_URL"))
    end
  end
end
