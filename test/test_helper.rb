require 'rubygems'
require 'bundler/setup'
require 'stringio'
require 'yaml'

Bundler.require(:default, :test)

module Mutt
  module Test
    def db_config
      if !@config
        config = File.read(File.join(ENV["GITORIOUS_ROOT"], "config/database.yml"))
        @config = YAML::load(config)["test"]
      end

      @config
    end

    class Request
      attr_accessor :auth_type, :user_principal
      attr_reader :auth_string

      def initialize(auth_string)
        @auth_string = auth_string
      end

      def get_header(name)
        auth_string
      end
    end

    class Response
      attr_reader :headers

      def initialize(body = nil)
        @body = body
        @headers = {}
      end

      def read
        @body
      end

      def set_header(name, value)
        headers[name] = value
      end
    end
  end
end

class MiniTest::Unit::TestCase
  include Mutt::Test

  def capture_stderr
    stderr = $stderr
    $stderr = StringIO.new
    yield
    result, $stderr = [$stderr, stderr]
    result
  end
end
