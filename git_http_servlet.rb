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

require 'mutt/gitorious_config'
require 'mutt/gitorious_service'
require 'mutt/gitorious_resolver'
require 'mutt/basic_auth_handler'
require 'mutt/gitorious_authenticator'
require 'mutt/gitorious_receive_pack_factory'
require 'mutt/gitorious_repository_router'

java_import 'org.eclipse.jgit.http.server.GitServlet'

# Our servlet, based on JGit's GitServlet
# Attaches a custom resolver, otherwise all normal
class GitoriousServlet < GitServlet
  def init(servlet_config)
    path = File.join(ENV['GITORIOUS_ROOT'], 'config', 'gitorious.yml')
    configuration = Mutt::GitoriousConfig.new(path, ENV['RAILS_ENV'] || 'production')
    service = Mutt::GitoriousService.new(configuration.host, configuration.port)
    router = Mutt::GitoriousRepositoryRouter.new(service, configuration.repo_root)
    resolver = Mutt::GitoriousResolver.new(router)
    self.repository_resolver = resolver
    self.receive_pack_factory = Mutt::GitoriousReceivePackFactory.new(service, router)
    super
  end
end

class StaticAuthenticator
  def authenticate(username, password)
    username == "marius"
  end
end

jetty_port = (ENV['JETTY_PORT'] || '8080').to_i

# Embedding Jetty
server = org.mortbay.jetty.Server.new(jetty_port)
root = org.mortbay.jetty.servlet.Context.new(server, '/', org.mortbay.jetty.servlet.Context::SESSIONS)
servlet = GitoriousServlet.new
holder = org.mortbay.jetty.servlet.ServletHolder.new(servlet)

# Attach GitoriousServlet to anything
root.add_servlet(holder, '/*')

# TODO: Remove duplication
path = File.join(ENV['GITORIOUS_ROOT'], 'config', 'gitorious.yml')
config = Mutt::GitoriousConfig.new(path, ENV['RAILS_ENV'] || 'production')

root.security_handler = Mutt::BasicAuth::Handler.new(Mutt::GitoriousAuthenticator.new(config.db_config))

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
