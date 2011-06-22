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
require "mutt/gitorious_receive_pack_factory"

class GitoriousReceivePackFactoryTest < MiniTest::Spec
  setup do
    @repository = Mutt::Test::Repository.new("gitorious.git")
    @router = Object.new
    def @router.resolve_path(url); "aaa/bbb/ccc.git"; end
  end

  should "raise not authorized for anonymous user" do
    request = Mutt::Test::Request.new
    factory = Mutt::GitoriousReceivePackFactory.new(nil, @router)

    assert_raises ServiceNotAuthorizedException do
      factory.create(request, @repository)
    end
  end

  should "raise if user is not authorized to push" do
    service = Object.new
    def service.push_allowed_by?(repo, user); false; end
    request = Mutt::Test::Request.new(:remote_user => "bill")
    factory = Mutt::GitoriousReceivePackFactory.new(service, @router)

    assert_raises ServiceNotAuthorizedException do
      factory.create(request, @repository)
    end
  end

  should "not raise if user is authorized to push" do
    service = Object.new
    def service.push_allowed_by?(repo, user); true; end
    request = Mutt::Test::Request.new(:remote_user => "bill")
    factory = Mutt::GitoriousReceivePackFactory.new(service, @router)

    begin
      factory.create(request, @repository)
    rescue ServiceNotAuthorizedException
      assert false, "Expected not to raise #{exception_class}"
    rescue TypeError
      # JRuby will throw a funky native error because repository is nil
    end
  end
end
