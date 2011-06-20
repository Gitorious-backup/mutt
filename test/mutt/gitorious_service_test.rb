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
require 'mutt/gitorious_service'

module Mutt
  class Response
    def initialize(body); @body = body; end
    def read; @body; end
  end
end

class GitoriousServiceTest < MiniTest::Unit::TestCase
  def setup
    @service = Mutt::GitoriousService.new('gitorious.here', '80')
  end

  def test_should_return_real_path_from_remote_config
    def @service.open(uri)
      Mutt::Response.new("real_path:#{uri}")
    end

    path = @service.fetch_path_from_server('/gitorious/mainline.git')
    assert_equal 'http://gitorious.here:80/gitorious/mainline/config', path
  end

  def test_should_raise_understandable_error
    def @service.open(uri)
      res = Mutt::Response.new("real_path:#{uri}")
      def res.read; raise Errno::ECONNREFUSED.new; end
      res
    end

    assert_raises Mutt::GitoriousService::ConnectionRefused do
      @service.fetch_path_from_server('/gitorious/mainline.git')
    end
  end
end
