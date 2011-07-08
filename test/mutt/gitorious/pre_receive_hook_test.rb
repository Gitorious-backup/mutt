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
      @command.type = org.eclipse.jgit.transport.ReceiveCommand::Type::DELETE
      assert @jgit_command.action_delete?
    end

    should "recognize non-fast-forwards" do
      @command.type = org.eclipse.jgit.transport.ReceiveCommand::Type::UPDATE_NONFASTFORWARD
      assert @jgit_command.non_fast_forward?
    end
  end

  context "No access" do

    setup do
      @receive_pack = FakeReceivePack.new
      @hook = Mutt::Gitorious::PreReceiveHook.new
    end
    
    should "fail appropriately when merge request updates are denied" do
      command = JGitCommand.new
      command.ref_name = "refs/merge-requests/123"
      @hook.on_pre_receive(@receive_pack, [command])
      assert_equal org.eclipse.jgit.transport.ReceiveCommand::Result::REJECTED_OTHER_REASON, command.result
      refute_nil @receive_pack.error
    end

    should "fail appropriately when deletion is denied" do
    end

    should "fail appropriately when force pushing is denied" do
    end

    should "fail appropriately when access denied" do
    end

    should "fail appropriately when server is down" do
    end
  end

  context "Access" do
    should "silently accept authorized pushes" do
    end
  end
end
