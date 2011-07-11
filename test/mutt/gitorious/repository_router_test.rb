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
require "mutt/gitorious/repository_router"
require "mutt/gitorious/service"

class GitoriousRepositoryRouterTest < MiniTest::Spec
  def setup
    repo_root = "/tmp/repositories"
    @service = Mutt::Test::FakeService.new
    @router = Mutt::Gitorious::RepositoryRouter.new(@service, repo_root)
  end

  context "resolving urls" do
    should "resolve incoming url to filesystem path" do
      @service.path = "eee/fff/abc.git"
      assert_equal "/tmp/repositories/eee/fff/abc.git", @router.resolve_url("gitorious/mainline.git")
    end
  end

  context "caching urls and repo paths" do
    should "cache url -> path lookups" do
      @service.path = "the/real/path.git"
      path = @router.resolve_url("/gitorious/mainline.git")

      assert_equal "/gitorious/mainline", @router.resolve_path("/tmp/repositories/the/real/path.git")
    end

    should "cache server lookups" do
      @service.path = "the/real/path.git"
      @router.resolve_url("/gitorious/mainline")

      def @service.resolve_url(uri)
        raise "Oh no you don't"
      end

      @router.resolve_url("/gitorious/mainline")
      assert_equal "/tmp/repositories/the/real/path.git", @router.resolve_url("/gitorious/mainline.git")
    end
  end
end
