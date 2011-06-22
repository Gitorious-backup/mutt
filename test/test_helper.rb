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
      attr_reader :auth_string, :remote_user, :query_string

      def initialize(options = {})
        @auth_string = options[:auth_string]
        @remote_user = options[:remote_user]
        @query_string = options[:query_string]
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

    class Repository
      def initialize(path)
        @path = path
      end

      def directory
        Directory.new(@path)
      end
    end

    class Directory
      attr_reader :absolute_path

      def initialize(path)
        @absolute_path = path
      end
    end

    class FakeAuthenticator
      attr_reader :valid_username, :valid_password
      
      def initialize(valid_username, valid_password)
        @valid_username = valid_username
        @valid_password = valid_password
      end
      
      def authenticate(username, password)
        valid_username == username && valid_password == password
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
