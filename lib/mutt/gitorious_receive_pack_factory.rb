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

require 'java'
require 'org.eclipse.jgit'
require 'org.eclipse.jgit.http.server'

java_import 'org.eclipse.jgit.transport.ReceivePack'
java_import 'org.eclipse.jgit.http.server.resolver.ServiceNotAuthorizedException'

module Mutt
  class GitoriousReceivePackFactory
    def initialize(service)
    end

    

    def create(request, repository)
      puts repository.directory.absolute_path.inspect

      user = request.remote_user
      if user.nil? # || !service.can_push?(repository, user)
        raise ServiceNotAuthorizedException.new
      else
        ReceivePack.new(repository)
      end
    end

    def authorized?(user, repository)
      # Ask the Gitorious server if user should be granted access
      # This is basically a matter of querying /<repo_url>/writable_by?username=<username>
      true
    end
  end
end
