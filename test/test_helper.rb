# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
require "rubygems"
require "bundler/setup"
require "minitest/autorun"
require "mini_shoulda"
require "stringio"
require "yaml"

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

    class FakeService
      attr_accessor :path
      
      def resolve_url(url)
        path
      end
    end


    class Request
      attr_accessor :auth_type, :user_principal
      attr_reader :auth_string, :remote_user, :query_string, :request_uri

      def initialize(options = {})
        @auth_string = options[:auth_string]
        @remote_user = options[:remote_user]
        @query_string = options[:query_string]
        @request_uri = options[:request_uri]
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
