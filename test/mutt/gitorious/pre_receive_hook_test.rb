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
require "test_helper"
require "mutt/gitorious/pre_receive_hook"

# Fake command used in place of JGit's ReceiveCommands as passed to PreReceiveHooks
class JGitCommand
  attr_accessor :type, :ref_name, :result
end

class FakeReceivePack
  attr_reader :error
  def send_error(e)
    @error = e
  end
end

class PreReceiveHookTest < MiniTest::Spec
  context "Receive command wrapper" do
    setup do
      @command = JGitCommand.new
      @jgit_command = Mutt::Gitorious::PreReceiveHook::Command.new(@command)
    end
    
    should "recognize merge request commands" do
      @command.ref_name = "refs/merge-requests/123"
      assert @jgit_command.merge_request?
    end

    should "recognize deletions" do
      @command.type = ReceiveCommand::Type::DELETE
      assert @jgit_command.action_delete?
    end

    should "recognize non-fast-forwards" do
      @command.type = ReceiveCommand::Type::UPDATE_NONFASTFORWARD
      assert @jgit_command.non_fast_forward?
    end
  end
  
  context "Access control" do

    setup do
      @receive_pack = FakeReceivePack.new
      @hook = Mutt::Gitorious::PreReceiveHook.new({
          :repository_url => "/gitorious/mainline",
          :user => "bill",
          :host => "gitorious.here:3000"})
      @command = JGitCommand.new
    end
    
    should "provide writable_by_url for pre receive guard" do
      assert_equal("http://gitorious.here:3000/gitorious/mainline/writable_by?username=bill",
        @hook.writable_by_query_url)
    end

    should "fail appropriately when merge request updates are denied" do
      def @hook.fetch_result(guard); Gitorious::PreReceive::MergeRequestUpdateDenied.new; end
      @hook.on_pre_receive(@receive_pack, [@command])
      assert_equal ReceiveCommand::Result::REJECTED_OTHER_REASON, @command.result
    end

    should "fail appropriately when deletion is denied" do
      def @hook.fetch_result(guard); Gitorious::PreReceive::DeleteRefDenied.new; end
      @hook.on_pre_receive(@receive_pack, [@command])
      assert_equal ReceiveCommand::Result::REJECTED_NODELETE, @command.result
    end

    should "fail appropriately when force pushing is denied" do
      def @hook.fetch_result(guard); Gitorious::PreReceive::ForcePushDenied.new; end
      @hook.on_pre_receive(@receive_pack, [@command])
      assert_equal ReceiveCommand::Result::REJECTED_NONFASTFORWARD, @command.result
    end

    should "fail appropriately when access denied" do
      def @hook.fetch_result(guard); Gitorious::PreReceive::AccessDenied.new; end
      @hook.on_pre_receive(@receive_pack, [@command])
      assert_equal ReceiveCommand::Result::REJECTED_OTHER_REASON, @command.result
    end

    should "fail appropriately when server is down" do
      def @hook.fetch_result(guard); Gitorious::PreReceive::ServerDown.new; end
      @hook.on_pre_receive(@receive_pack, [@command])
      assert_equal ReceiveCommand::Result::REJECTED_OTHER_REASON, @command.result
    end

    should "silently accept authorized pushes" do
      def @hook.fetch_result(guard); Gitorious::PreReceive::PushGranted.new; end
      @hook.on_pre_receive(@receive_pack, [@command])
      assert_equal ReceiveCommand::Result::OK, @command.result
      assert_nil @receive_pack.error
    end
  end
end
