# frozen_string_literal: true

require "json"

module Bookworm
  class Shard
    STREAM_CHUNK = 500

    Record = Data.define(:data, :sequence_number, :timestamp)

    attr_reader :id, :iterator

    def initialize(id, stream_name, last_sequence_number, client)
      @id = id
      @client = client
      @last_sequence_number = last_sequence_number
      @iterator = @client.get_shard_iterator(shard_id: id, stream_name:, **position).shard_iterator
    end

    def records(&)
      Logger.info "Processing records for shard: #{id}, iterator: #{iterator}"
      response = @client.get_records(shard_iterator: iterator, limit: STREAM_CHUNK)

      if response.records.empty?
        Logger.info "Shard: #{id}, iterator: #{iterator} returned 0 records"
        slow_down
      else
        process_records(response.records, &)
      end

      @iterator = response.next_shard_iterator
    end

    private

    def process_records(records)
      parsed_records = records.filter_map { |r| parse_record(r) }
      yield id, parsed_records
      @last_sequence_number = parsed_records.last.sequence_number
    end

    def parse_record(record)
      parsed = parse(record.data)
      return unless parsed

      Record[parsed, record.sequence_number, record.approximate_arrival_timestamp]
    end

    def parse(data, attempt: 1)
      JSON.parse(data)
    rescue JSON::ParserError
      return if attempt >= 2

      parse(data.gsub(/\bNaN\b/, "null"), attempt: attempt + 1)
    end

    def position
      return { shard_iterator_type: "TRIM_HORIZON" } unless @last_sequence_number

      { shard_iterator_type: "AFTER_SEQUENCE_NUMBER", starting_sequence_number: @last_sequence_number }
    end

    def slow_down
      sleep 30
    end
  end
end
