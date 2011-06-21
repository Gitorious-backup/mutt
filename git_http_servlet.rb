# coding: utf-8
raise 'You need to run this with JRuby' unless defined?(JRUBY_VERSION)

require 'servlet-api-2.5'
require 'org.eclipse.jgit-0.9.3'

require 'jetty-util-6.1.26'
require 'jetty-6.1.26'
require 'java'
require 'logger'

require "rubygems"
require "bundler/setup"

require 'mutt/gitorious_config'
require 'mutt/gitorious_service'
require 'mutt/gitorious_resolver'
require 'mutt/basic_auth_handler'
require 'mutt/gitorious_authenticator'

java_import 'org.eclipse.jgit.http.server.GitServlet'
java_import 'org.eclipse.jgit.transport.ReceivePack'
java_import 'org.eclipse.jgit.http.server.resolver.ServiceNotAuthorizedException'

class GitoriousReceivePackFactory
  def create(request, repository)
    user = request.remote_user
    if user.nil?
      raise org.eclipse.jgit.http.server.resolver.ServiceNotAuthorizedException.new
    else
      ReceivePack.new(repository)
    end
  end

  def authenticated?(user)
    !user.nil?
  end

  def authorized?(user, repository)
    # Ask the Gitorious server if user should be granted access
    # This is basically a matter of querying /<repo_url>/writable_by?username=<username>
    true
  end
end

# Our servlet, based on JGit's GitServlet
# Attaches a custom resolver, otherwise all normal
class GitoriousServlet < GitServlet
  attr_reader :gitorious_configuration
  
  def init(servlet_config)
    path = File.join(ENV['GITORIOUS_ROOT'], 'config', 'gitorious.yml')
    @gitorious_configuration = Mutt::GitoriousConfig.new(path, ENV['RAILS_ENV'] || 'production')
    service = Mutt::GitoriousService.new(gitorious_configuration.host, gitorious_configuration.port)
    resolver = Mutt::GitoriousResolver.new(service, gitorious_configuration.repo_root)
    setRepositoryResolver(resolver)
    setReceivePackFactory(GitoriousReceivePackFactory.new)
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
