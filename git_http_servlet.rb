# -*- coding: utf-8 -*-
raise "You need to run this with JRuby" unless RUBY_PLATFORM == "java"

require "servlet-api-2.5"
require "org.eclipse.jgit-0.9.3"

require "jetty-util-6.1.26"
require "jetty-6.1.26"
require "java"
require "logger"

require "mutt/gitorious_config"
require "mutt/gitorious_service"
require "mutt/gitorious_resolver"

java_import "org.eclipse.jgit.http.server.GitServlet"
java_import "org.mortbay.jetty.handler.AbstractHandler"
java_import "javax.servlet.http.HttpServletResponse"
java_import "org.mortbay.jetty.Server"
java_import "org.mortbay.jetty.servlet.Context"
java_import "org.mortbay.jetty.servlet.ServletHolder"
java_import "org.mortbay.jetty.security.SecurityHandler"
java_import "org.eclipse.jgit.transport.ReceivePack"
java_import "org.eclipse.jgit.http.server.resolver.ServiceNotAuthorizedException"

class GitoriousReceivePackFactory
  def create(request, repository)
    user = request.remote_user

    raise ServiceNotAuthorizedException.new if !authenticated?(user)
    raise ServiceNotEnabledException.new if !authorized?(request.remote_user, repository)

    ReceivePack.new(repository)
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
    path = File.join(ENV["GITORIOUS_ROOT"], "config", "gitorious.yml")
    config = Mutt::GitoriousConfig.new(path, ENV["RAILS_ENV"] || "production")
    service = Mutt::GitoriousService.new(config.host, config.port)
    resolver = Mutt::GitoriousResolver.new(service, config.repo_root)
    setRepositoryResolver(resolver)
    setReceivePackFactory(GitoriousReceivePackFactory.new)
    super
  end
end

class GitoriousBasicAuthHandler < SecurityHandler
  def handle(target, request, response, dispatch)
    puts "[handle] #{request.method} #{target}?#{request.query_string}"

    request.header_names.each do |header|
      puts "#{header}: #{request.getHeader(header)}"
    end

    puts ""

    authenticate(request, response)

    if handler
      begin
        handler.handle target, request, response, dispatch
      rescue
        puts "[handle] failed for some reason"
      end
    end
  end

  def authenticate(request, response)
    credentials = extract_credentials(request)

    if credentials.nil?
      puts "[credentials] nil"
      #request.auth_type = org.mortbay.jetty.security.Constraint::__BASIC_AUTH
      response.set_header("WWW-Authenticate", "Basic realm=\"Gitorious\"")
    else
      puts "[credentials] #{credentials.join('/')} (#{credentials[0] == "christian"})"

      if credentials[0] == "christian"
        request.auth_type = org.mortbay.jetty.security.Constraint::__BASIC_AUTH
        request.user_principal = Principal.new(credentials[0])
      end
    end
  end

  def extract_credentials(request)
    credentials = request.getHeader(org.mortbay.jetty.HttpHeaders::AUTHORIZATION)
    return nil if credentials.nil?

    credentials[6..-1].unpack("m").first.split(":")
  end
end

class Principal
  def initialize(name)
    @name = name
  end

  def to_s
    @name
  end

  def name
    @name
  end
end

jetty_port = (ENV["JETTY_PORT"] || "8080").to_i

# Embedding Jetty
server = Server.new(jetty_port)
root = Context.new(server, "/", Context::SESSIONS)
holder = ServletHolder.new(GitoriousServlet.new)

# Attach GitoriousServlet to anything
root.add_servlet(holder, "/*")
root.security_handler = GitoriousBasicAuthHandler.new

server.start

PIDFILE = File.join(File.dirname(__FILE__), "pids", "git_http.pid")
File.open(PIDFILE,"w") {|f| f.write(Process.pid.to_s)}

#trap ("SIGINT") {
#  puts "Cleaning up"
#  File.unlink(PIDFILE)
#  exit!
#}
#trap ("SIGTERM") {
#  puts "Cleaning up"
#  File.unlink(PIDFILE)
#  exit!
#}
