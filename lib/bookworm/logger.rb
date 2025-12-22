# frozen_string_literal: true

module Bookworm
  module Logger
    module_function

    def info(...) = instance.info(...)
    def error(...) = instance.error(...)
    def debug(...) = instance.debug(...)
    def warn(...) = instance.warn(...)
    def fatal(...) = instance.fatal(...)

    def instance
      @instance ||= begin
        logger = ::Logger.new($stdout)
        original_formatter = ::Logger::Formatter.new
        logger.formatter = proc do |severity, datetime, progname, msg|
          tid = (Thread.current.object_id ^ ::Process.pid).to_s(36)
          original_formatter.call(severity, datetime, "pid=#{::Process.pid} tid=#{tid} #{progname}".strip, msg)
        end
        logger
      end
    end
  end
end
