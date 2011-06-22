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
  end

  should "rescue and throw on service error" do
    def @router.resolve_url(url)
      raise Mutt::Gitorious::Service::ServiceError.new("gitorious.here", "80")
    end

    capture_stderr do
      assert_raises RepositoryNotFoundException do
        @resolver.open(nil, nil)
      end
    end
  end
end
