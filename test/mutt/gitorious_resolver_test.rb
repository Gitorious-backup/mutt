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
require 'test_helper'
require 'mutt/gitorious_resolver'

class GitoriousResolverTest < MiniTest::Unit::TestCase
  def setup
    repo_root = '/tmp/repositories'
    @service = Class.new do
      def resolve_url(url)
        'eee/fff/abc.git'
      end
    end.new
    @resolver = Mutt::GitoriousResolver.new(@service, repo_root)
  end

  def test_should_resolve_incoming_url_to_filesystem_path
    assert_equal '/tmp/repositories/eee/fff/abc.git', @resolver.resolve('gitorious/mainline.git')
  end

  def test_should_rescue_and_throw_on_service_error
    def @service.resolve_url(incoming_url)
      raise Mutt::GitoriousService::ServiceError.new('gitorious.here', '80')
    end

    capture_stderr do
      assert_raises RepositoryNotFoundException do
        @resolver.open(nil, nil)
      end
    end
  end
end
