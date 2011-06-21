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
