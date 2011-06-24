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
require "mutt/gitorious/server"

class GitoriousServerTest < MiniTest::Spec
  class FakeContext
    attr_accessor :security_handler
  end

  def create_server(config)
    def @config.db_config; {}; end
    Mutt::Gitorious::Server.new(@config)
  end

  context "public mode" do
    setup do
      @config = Mutt::Gitorious::Config.new({ "public_mode" => true })
      @server = create_server(@config)
    end

    should "not add security handler when not supporting push" do
      context = FakeContext.new
      @server.configure_security(context, :pull_only => true)
      assert_nil context.security_handler
    end

    should "add security handler when supporting push" do
      context = FakeContext.new
      @server.configure_security(context, :pull_only => false)
      refute_nil context.security_handler
    end

    should "use Git::BasicAuthHandler when supporting push" do
      context = FakeContext.new
      @server.configure_security(context, :pull_only => false)
      assert Mutt::Git::BasicAuthHandler === context.security_handler
    end
  end

  context "private mode" do
    setup do
      @config = Mutt::Gitorious::Config.new({ "public_mode" => false })
      @server = create_server(@config)
    end

    context "with push disabled" do
      setup do
        @context = FakeContext.new
        @server.configure_security(@context, :pull_only => true)
      end
        
      should "add security handler" do
        refute_nil @context.security_handler
      end

      should "use BasicAuthHandler" do
        assert Mutt::BasicAuth::Handler == @context.security_handler.class
      end
    end

    context "with push enabled" do
      setup do
        @context = FakeContext.new
        @server.configure_security(@context, :pull_only => false)
      end

      should "add security handler when supporting push" do
        refute_nil @context.security_handler
      end

      should "use BasicAuthHandler when supporting push" do
        assert Mutt::BasicAuth::Handler == @context.security_handler.class
      end
    end
  end
end
