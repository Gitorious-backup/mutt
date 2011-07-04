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
require "open-uri"
require "gitorious_hooks/pre_receive_guard"
require "gitorious_hooks/pre_receive_result"

java_import "org.eclipse.jgit.transport.ReceivePack"
java_import "org.eclipse.jgit.http.server.resolver.ServiceNotAuthorizedException"

module Mutt
  class Command
    def initialize(jgit_command)
      @jgit_command = jgit_command
    end

    def merge_request?
      false
    end

    def action_delete?
      @jgit_command.type == org.eclipse.jgit.transport.ReceiveCommand::Type::DELETE
    end

    def non_fast_forward?
      @jgit_command.type == org.eclipse.jgit.transport.ReceiveCommand::Type::UPDATE_NONFASTFORWARD
    end

    def ref
      @jgit_command.ref_name
    end
  end
  
  class H
    def on_pre_receive(receive_pack, commands)
      commands.each do |cmd|
        c = Command.new(cmd)
        guard = ::Gitorious::PreReceiveGuard.new(c, {
            :is_local => false,
            :writable_by_url => "http://gitorious.here:3000/gitorioux/gitorioux/writable_by?username=mariuz",
            :deny_nonfastforward => true
          })
        result = guard.result
        if result.allow?
        else
          receive_pack.send_error("Oh no you don't (got a #{result.class.name} back")
        end
      end
    end
  end
  
  module Gitorious
    class ReceivePackFactory
      attr_reader :service, :router

      def initialize(service, router)
        @service = service
        @router = router
      end

      def create(request, repository)
        user = request.remote_user
        repo_url = router.resolve_path(repository.directory.absolute_path)

        if !service.push_allowed_by?(user, repo_url)
          raise ServiceNotAuthorizedException.new
        else
          result = ReceivePack.new(repository)
          result.pre_receive_hook = H.new
          result
        end
      end
    end
  end
end
