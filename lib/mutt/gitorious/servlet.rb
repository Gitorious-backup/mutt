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
require "org.eclipse.jgit"
require "mutt/gitorious/service"
require "mutt/gitorious/repository_router"
require "mutt/gitorious/resolver"
require "mutt/gitorious/receive_pack_factory"

java_import "org.eclipse.jgit.http.server.GitServlet"

module Mutt
  module Gitorious
    class Servlet < GitServlet
      attr_reader :configuration

      def initialize(configuration)
        super()
        @configuration = configuration
      end

      def init(servlet_config)
        service = Mutt::Gitorious::Service.new(configuration.host, configuration.port)
        router = Mutt::Gitorious::RepositoryRouter.new(service, configuration.repo_root)
        resolver = Mutt::Gitorious::Resolver.new(router)
        self.repository_resolver = resolver
        self.receive_pack_factory = Mutt::Gitorious::ReceivePackFactory.new(service, router)
        super
      end
    end
  end
end
