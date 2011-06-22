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
require "org.eclipse.jgit.http.server"

java_import "org.eclipse.jgit.transport.ReceivePack"
java_import "org.eclipse.jgit.http.server.resolver.ServiceNotAuthorizedException"

module Mutt
  class GitoriousReceivePackFactory
    attr_reader :service, :router

    def initialize(service, router)
      @service = service
      @router = router
    end

    def create(request, repository)
      user = request.remote_user
      repo_url = router.resolve_path(repository.directory.absolute_path)

      if user.nil? || !service.push_allowed_by?(user, repo_url)
        raise ServiceNotAuthorizedException.new
      else
        ReceivePack.new(repository)
      end
    end
  end
end
