# -*- coding: utf-8 -*-
raise "You need to run this with JRuby" unless RUBY_PLATFORM == "java"

$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require "servlet-api-2.5"
require "org.eclipse.jgit-0.9.3"
require "org.eclipse.jgit.http.server-0.9.3"
require "jetty-util-6.1.26"
require "jetty-6.1.26"
require "java"
require "yaml"
require "open-uri"
require "logger"

java_import "org.eclipse.jgit.http.server.GitServlet"
java_import "org.mortbay.jetty.handler.AbstractHandler"
java_import "javax.servlet.http.HttpServletResponse"
java_import "org.mortbay.jetty.Server"
java_import "org.mortbay.jetty.servlet.Context"
java_import "org.mortbay.jetty.servlet.ServletHolder"
java_import "org.mortbay.jetty.security.SecurityHandler"
java_import "org.eclipse.jgit.lib.RepositoryCache"
java_import "org.eclipse.jgit.util.FS"
java_import "org.eclipse.jgit.errors.RepositoryNotFoundException"
java_import "org.eclipse.jgit.transport.ReceivePack"
java_import "org.eclipse.jgit.http.server.resolver.ServiceNotAuthorizedException"

# Wrap the Gitorious configuration in a class
class GitoriousConfig
  class << self
    def configuration
      @configuration ||= load_configuration
    end

    def load_configuration
      gitorious_root = ENV["GITORIOUS_ROOT"] || "/home/marius/Projects/gitorious/gitorious"
      rails_env = ENV["RAILS_ENV"] || "production"
      path = File.join(gitorious_root, "config", "gitorious.yml")
      raise "gitorious.yml not found" unless File.file?(path)
      YAML::load_file(path)[rails_env]
    end

    def host
      @host ||= configuration["gitorious_client_host"]
    end

    def port
      @port ||= configuration["gitorious_client_port"]
    end

    def repo_root
      @repo_root ||= configuration["repository_base_path"]
    end
  end
end

# Wrap the running Gitorious server, which we will use to fetch repository
# configuration data
class GitoriousService

  # Connect to the Gitorious server and return the path for a given repository
  def fetch_path_from_server(given)
    host = GitoriousConfig.host
    port = GitoriousConfig.port
    server_root = "http://#{host}:#{port}"
    repo_path = given.split(".git").first
    request_uri = File.join(server_root, repo_path, "config")
    begin
      data = open(request_uri).read
      data.scan(/^real_path:(.*)$/).flatten.first
    rescue OpenURI::HTTPError, Errno::ECONNREFUSED
      nil
    end
  end
end

# A class that resolves an incoming path (eg. "/gitorious/mainline.git")
# to a JGit repository instance usable in the servlet
class GitoriousResolver

  # Resolve +name+ to a repository in the file system
  def open(request, name)
    self.class.logger.debug("Looking for #{name}")
    relative_path = GitoriousService.new.fetch_path_from_server(name)
    if relative_path.nil?
      self.class.logger.error("Could not resolve #{name}")
      raise RepositoryNotFoundException.new(name)
    end
    self.class.logger.debug("Resolved to #{relative_path}")
    full_path = File.join(GitoriousConfig.repo_root, relative_path)
    git_dir = java.io.File.new(full_path)
    RepositoryCache.open(RepositoryCache::FileKey.lenient(git_dir, FS::DETECTED), true)
  end

  def self.logger
    @logger ||= Logger.new("resolver.log")
  end
end

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
  def init(config)
    resolver = GitoriousResolver.new
    setRepositoryResolver(resolver)
    setReceivePackFactory(GitoriousReceivePackFactory.new)
    super
  end
end


# Since we don't have a web.xml, we'll provide the settings
# loaded from GitServlet's init() method so it won't choke on
# missing configuration
class GServletHolder < ServletHolder

  # ServletConfig equivalent. We'll hijack what we're interested in, and
  # leave the rest to super
  def getInitParameter(name)
    if name == "base-path"
      return GitoriousConfig.repo_root
    elsif name == "export-all"
      return "true"
    else
      super.getInitParameter(name)
    end
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
holder = GServletHolder.new(GitoriousServlet.new)

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
