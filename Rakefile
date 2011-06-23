require "rake/testtask"
require "bundler/gem_tasks"

Rake::TestTask.new("test") do |test|
  test.libs << "test"
  test.libs << 'vendor'
  test.pattern = "test/**/*_test.rb"
  test.verbose = true

  if !ENV["GITORIOUS_ROOT"]
    $stderr.puts "You need to define GITORIOUS_ROOT to run mutt tests"
  end
end

task :default => :test
