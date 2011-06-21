# -*- coding: utf-8 -*-
raise 'You need to run this with JRuby' unless RUBY_PLATFORM == 'java'

require 'servlet-api-2.5'
require 'org.eclipse.jgit-0.9.3'

require 'jetty-util-6.1.26'
require 'jetty-6.1.26'
require 'java'
require 'logger'

require 'mutt/gitorious_config'
require 'mutt/gitorious_service'
require 'mutt/gitorious_resolver'
require 'mutt/basic_auth_handler'

java_import 'org.eclipse.jgit.http.server.GitServlet'
java_import 'org.mortbay.jetty.handler.AbstractHandler'
java_import 'javax.servlet.http.HttpServletResponse'
java_import 'org.mortbay.jetty.Server'
java_import 'org.mortbay.jetty.servlet.Context'
java_import 'org.mortbay.jetty.servlet.ServletHolder'

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
    puts "User authenticated? #{user} #{!user.nil?}"
    !user.nil?
  end

  def authorized?(user, repository)
    # Sjekke med Gitorious om brukeren har tilgang på repo
    true
  end
end

# Our servlet, based on JGit's GitServlet
# Attaches a custom resolver, otherwise all normal
class GitoriousServlet < GitServlet
  def init(servlet_config)
    path = File.join(ENV['GITORIOUS_ROOT'], 'config', 'gitorious.yml')
    config = Mutt::GitoriousConfig.new(path, ENV['RAILS_ENV'] || 'production')
    service = Mutt::GitoriousService.new(config.host, config.port)
    resolver = Mutt::GitoriousResolver.new(service, config.repo_root)
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
server = Server.new(jetty_port)
root = Context.new(server, '/', Context::SESSIONS)
holder = ServletHolder.new(GitoriousServlet.new)

# Attach GitoriousServlet to anything
root.add_servlet(holder, '/*')
root.security_handler = Mutt::BasicAuth::Handler.new(StaticAuthenticator.new)

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
