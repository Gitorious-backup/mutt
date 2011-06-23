# coding: utf-8
raise 'You need to run this with JRuby' unless defined?(JRUBY_VERSION)

require 'servlet-api'
require 'org.eclipse.jgit'

require 'jetty-util'
require 'jetty'
require 'java'
require 'logger'

require "rubygems"
require "bundler/setup"

require 'mutt/gitorious/config'
require 'mutt/gitorious/servlet'
require 'mutt/git/basic_auth_handler'
require 'mutt/gitorious/authenticator'

java_import 'org.eclipse.jgit.http.server.GitServlet'


path = File.join(ENV['GITORIOUS_ROOT'], 'config', 'gitorious.yml')

configuration = Mutt::Gitorious::Config.new(path, ENV['RAILS_ENV'] || 'production')

jetty_port = (ENV['JETTY_PORT'] || '8080').to_i

# Embedding Jetty
server = org.mortbay.jetty.Server.new(jetty_port)
root = org.mortbay.jetty.servlet.Context.new(server, '/', org.mortbay.jetty.servlet.Context::SESSIONS)
servlet = Mutt::Gitorious::Servlet.new(configuration)
holder = org.mortbay.jetty.servlet.ServletHolder.new(servlet)

# Attach GitoriousServlet to anything
root.add_servlet(holder, '/*')

root.security_handler = Mutt::Git::BasicAuthHandler.new(Mutt::Gitorious::Authenticator.new(configuration.db_config), "Gitorious")

server.start

PIDFILE = File.join(File.dirname(__FILE__), 'pids', 'git_http.pid')
File.open(PIDFILE,'w') {|f| f.write(Process.pid.to_s)}

#trap ('SIGINT') {
#  puts 'Cleaning up'
#  File.unlink(PIDFILE)
#  exit!
#}
#trap ('SIGTERM') {
#  puts 'Cleaning up'
#  File.unlink(PIDFILE)
#  exit!
#}
