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
require 'mutt/user'

class GitoriousServiceTest < MiniTest::Spec
  setup do
    @service = Mutt::GitoriousService.new('gitorious.here', '80')
  end

  context "resolving repository paths" do
    should "return real path from remote config" do
      def @service.open(uri)
        Mutt::Test::Response.new("real_path:#{uri}")
      end

      path = @service.resolve_url('/gitorious/mainline.git')
      assert_equal 'http://gitorious.here:80/gitorious/mainline/config', path
    end

    should "raise understandable error" do
      def @service.open(uri)
        res = Mutt::Test::Response.new("real_path:#{uri}")
        def res.read; raise Errno::ECONNREFUSED.new; end
        res
      end

      assert_raises Mutt::GitoriousService::ConnectionRefused do
        @service.resolve_url('/gitorious/mainline.git')
      end
    end
  end

  context "authorizing users for push" do
    setup do
      def @service.open(uri)
        if uri =~ /username=bill/
          Mutt::Test::Response.new('true')
        else
          Mutt::Test::Response.new('false')
        end
      end
      @repository = '/local/filesystem/path.git'
    end

    should "grant an authorized user push access" do
      assert @service.push_allowed_by?(Mutt::User.new('bill'), @repository)      
    end

    should "deny an unauthorized user push access" do
      refute @service.push_allowed_by?(Mutt::User.new('evil_hacker'), @repository)      
    end
  end    
end
