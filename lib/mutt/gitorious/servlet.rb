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
require "org.eclipse.jgit.http.server"
require "mutt/gitorious/service"
require "mutt/gitorious/repository_router"
require "mutt/gitorious/resolver"
require "mutt/gitorious/receive_pack_factory"

java_import "org.eclipse.jgit.http.server.GitServlet"

module Mutt
  module Gitorious
    class Servlet < GitServlet
      attr_reader :config
      attr_writer :pull_only

      def initialize(config)
        super()
        @config = config
        @pull_only = false
      end

      def init(servlet_config)
        configure
        super(servlet_config)
      end

      def configure
        service = Mutt::Gitorious::Service.new(config.host, config.port)
        router = Mutt::Gitorious::RepositoryRouter.new(service, config.repo_root)
        resolver = Mutt::Gitorious::Resolver.new(router)
        resolver.public_mode = config.public_mode?
        self.repository_resolver = resolver
        rpf = pull_only? ? nil : ReceivePackFactory.new(service, router)
        self.receive_pack_factory = rpf
      end

      def pull_only?
        @pull_only
      end
    end
  end
end
