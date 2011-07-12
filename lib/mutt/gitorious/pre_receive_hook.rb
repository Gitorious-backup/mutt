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
java_import "org.eclipse.jgit.transport.ReceiveCommand"

module Mutt
  module Gitorious
    class PreReceiveHook
      attr_reader :pre_receive_guard, :repository_url, :user, :host

      def initialize(options)
        @repository_url = options[:repository_url]
        @user = options[:user]
        @host = options[:host]
      end

      def writable_by_query_url
        local_uri = File.join(host, repository_url, "writable_by?username=#{user}")
        "http://#{local_uri}"
      end
        
      def on_pre_receive(receive_pack, commands)
        commands.each do |cmd|
          handle_command(receive_pack, cmd)
        end
      end
      
      def handle_command(receive_pack, cmd)
        c = Command.new(cmd)
        guard = ::Gitorious::PreReceiveGuard.new(c, {
            :is_local => false,
            :writable_by_url => writable_by_query_url,
            :deny_nonfastforward => true
          })
        
        result = fetch_result(guard)
        case result
        when ::Gitorious::PreReceive::PushGranted
          cmd.result = ReceiveCommand::Result::OK
        when ::Gitorious::PreReceive::MergeRequestUpdateDenied
          cmd.result = ReceiveCommand::Result::REJECTED_OTHER_REASON
          receive_pack.send_error result.message
        when ::Gitorious::PreReceive::DeleteRefDenied
          cmd.result = ReceiveCommand::Result::REJECTED_NODELETE
          receive_pack.send_error result.message
        when ::Gitorious::PreReceive::ForcePushDenied
          cmd.result = ReceiveCommand::Result::REJECTED_NONFASTFORWARD
          receive_pack.send_error result.message
        when ::Gitorious::PreReceive::AccessDenied
          cmd.result = ReceiveCommand::Result::REJECTED_OTHER_REASON
          receive_pack.send_error result.message
        when ::Gitorious::PreReceive::ServerDown
          cmd.result = ReceiveCommand::Result::REJECTED_OTHER_REASON
          receive_pack.send_error result.message          
        end
      end

      def fetch_result(guard)
        guard.result
      end
    
      class Command
        attr_reader :jgit_command
        def initialize(jgit_command)
          @jgit_command = jgit_command
        end

        def merge_request?
          jgit_command.ref_name =~ /refs\/merge-requests\/\d*$/
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

    end
  end
end
