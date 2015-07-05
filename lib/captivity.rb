require 'delegate'
require 'logger'
require 'rack/commonlogger'

class Captivity
  VERSION = '0.0.3'
  
  # Rack::CommonLogger is so ingeniously put together that
  # it does not honor the standard logger levels, it uses #write.
  # The #write method is not even defined on the standard Logger,
  # so we flee to a delegate which will convert the logs to
  # info messages
  class LoggerWithWriteMethod < SimpleDelegator
    def write(str)
      info(str)
    end
  end
  
  def initialize(app, logger_or_stream = STDERR)
    @logger = configure_logger_or_stream(logger_or_stream)
    @app = Rack::CommonLogger.new(app, @logger)
  end
    
  # Calls the contained application. The application will receive
  # the defined Logger object in the "captivity.logger" of the env hash
  def call(env)
    env["captivity.logger"] = @logger
    env["rack.logger"] = @logger
    set_active_record_logger_if_present!
    @app.call(env)
  rescue StandardError, LoadError, SyntaxError => exception
    log_exception(exception)
    # Reraise to display using Rack
    raise exception
  end
  
  private
  
  def set_active_record_logger_if_present!
    if defined?(ActiveRecord)
      ActiveRecord::Base.logger = @logger
    end
  end
  
  def log_exception(exception)
    @logger.fatal(
      "\t#{exception.class} (#{exception.message}):\n    " +
      exception.backtrace.join("\n\t\t") +
      "\n\n"
    )
  end
  
  def configure_logger_or_stream(logger_or_stream)
    if logger_or_stream.respond_to?(:warn) && logger_or_stream.respond_to?(:write)
      logger_or_stream
    elsif logger_or_stream.respond_to?(:warn)
      LoggerWithWriteMethod.new(logger_or_stream)
    elsif logger_or_stream.respond_to?(:write) # IO-ish
      logger = Logger.new(logger_or_stream)
      logger.level = Logger::DEBUG
      configure_logger_or_stream(logger)
    elsif logger_or_stream.nil?
      configure_logger_or_stream(STDERR)
    end
  end
end