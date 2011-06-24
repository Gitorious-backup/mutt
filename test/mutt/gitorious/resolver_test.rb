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
require "mutt/gitorious/resolver"

class GitoriousResolverTest < MiniTest::Spec
  def setup
    @router = Object.new
    @resolver = Mutt::Gitorious::Resolver.new(@router)

    def @router.resolve_url(url)
      "/tmp/repositories/aaa/bbb/ccc.git"
    end
  end

  should "rescue and throw on service error" do
    def @router.resolve_url(url)
      raise Mutt::Gitorious::Service::ServiceError.new("gitorious.here", "80")
    end

    capture_stderr do
      assert_raises RepositoryNotFoundException do
        @resolver.open(Mutt::Test::Request.new(:user_principal => "cjohansen"), nil)
      end
    end
  end

  context "private mode" do
    setup do
      @resolver.public_mode = false
    end

    should "raise if user is not authenticated" do
      capture_stderr do
        assert_raises ServiceNotAuthorizedException do
          @resolver.open(Mutt::Test::Request.new(:user_principal => nil), nil)
        end
      end
    end
  end

  context "public mode" do
    setup do
      @resolver.public_mode = true
    end

    should "not raise if user is not authenticated" do
      # We'll get a NativeException when JGit tries to peek inside the
      # non-existent repository. What we want to know here is that we
      # don't see a ServiceNotAuthorizedException
      assert_raises NativeException do
        @resolver.open(Mutt::Test::Request.new(:user_principal => nil), nil)
      end
    end
  end
end
