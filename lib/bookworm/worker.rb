# frozen_string_literal: true

module Bookworm
  class Worker
    delegate :start, to: :@reader

    def self.start
      new.tap(&:subscribe)
    end

    def initialize
      @persistence = Persistence.new(stream_name)
      @reader = Reader.new(stream_name, @persistence)
    end

    def subscribe
      @reader.subscribe do |shard_id, records|
        sequence_number, timestamp = records_info(records)

        if defined?(ActiveRecord::Base)
          ActiveRecord::Base.with_connection { |_| safe_perform(records) }
        else
          safe_perform(records)
        end

        @persistence.store_position(shard_id, sequence_number, timestamp)
      end
    end

    private

    def safe_perform(records)
      perform(records)
    rescue StandardError => e
      ::Bookworm::Logger.error <<~TEXT
        ===============================================
        Error #{e.class} processing records: #{e.message}
        #{e.backtrace.join("\n")}
        #{records.inspect}
        -----------------------------------------------
      TEXT
    end

    def logger
      ::Bookworm::Logger
    end

    def stream_name
      raise NotImplementedError
    end

    def records_info(records)
      last_record = records.last
      [last_record.sequence_number, last_record.timestamp]
    end
  end
end
