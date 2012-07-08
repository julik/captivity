require 'helper'
require "stringio"

ENV['RACK_ENV'] = 'test'

class TestCaptivity < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    @app
  end
  
  def test_captivity_logs_request_with_io
    stream = StringIO.new
    
    @app = Rack::Builder.app do
       use Captivity, stream
       run lambda { |env| [200, {'Content-Type' => 'text/plain'}, 'OK'] }
    end
    
    get '/boom'
    assert_match /GET \/boom/, stream.string
  end
  
  def test_captivity_logs_request_with_logger_object
    stream = StringIO.new
    
    @app = Rack::Builder.app do
       use Captivity, Logger.new(stream)
       run lambda { |env| [200, {'Content-Type' => 'text/plain'}, 'OK'] }
    end
    
    get '/boom'
    assert_match /GET \/boom/, stream.string
  end
  
end
