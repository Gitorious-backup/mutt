# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require "java"
require "servlet-api"
require "org.eclipse.jgit"
require "jetty-util"
require "jetty"

require "mutt/gitorious/servlet"
require "mutt/basic_auth_handler"
require "mutt/git/basic_auth_handler"
require "mutt/gitorious/authenticator"

module Mutt
  module Gitorious
    class Server
      attr_reader :configuration

      def initialize(configuration)
        @configuration = configuration
      end

      def run(port, options = {})
        server = org.mortbay.jetty.Server.new(port)
        root = org.mortbay.jetty.servlet.Context.new(server, "/", org.mortbay.jetty.servlet.Context::SESSIONS)
        servlet = Mutt::Gitorious::Servlet.new(configuration)
        servlet.pull_only = options[:pull_only]
        holder = org.mortbay.jetty.servlet.ServletHolder.new(servlet)

        root.add_servlet(holder, "/*")
        configure_security(root, options)

        server.start
      end

      def configure_security(context, options)
        return if options[:pull_only] && configuration.public_mode?
        context.security_handler = security_implementation
      end

      def security_implementation
        authenticator = Gitorious::Authenticator.new(configuration.db_config)
        klass = configuration.public_mode? ? Git::BasicAuthHandler : BasicAuth::Handler
        klass.new(authenticator, "Gitorious")
      end
    end
  end
end
