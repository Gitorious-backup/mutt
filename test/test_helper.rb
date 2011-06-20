require "rubygems"
require "bundler/setup"
require "stringio"

Bundler.require(:default, :test)

class MiniTest::Unit::TestCase
  def capture_stderr
    stderr = $stderr
    $stderr = StringIO.new
    yield
    result, $stderr = [$stderr, stderr]
    result
  end
end
