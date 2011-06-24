require "rake/testtask"
require "rdoc/task"
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

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

task :default => :test

desc "Clean out generated files and directories"
task :clean do
  `rm -fr {pkg,html}`
end
 
