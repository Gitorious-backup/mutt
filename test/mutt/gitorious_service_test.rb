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
  class Repository
    def directory
      Directory.new
    end
  end

  class Directory
    def absolute_path
      '/local/filesystem/path.git'
    end
  end

  setup do
    @service = Mutt::GitoriousService.new('gitorious.here', '80')
  end

  context "resolving repository paths" do
    should "return real path from remote config" do
      def @service.open(uri)
        Mutt::Test::Response.new("real_path:#{uri}")
      end

      path = @service.fetch_path_from_server('/gitorious/mainline.git')
      assert_equal 'http://gitorious.here:80/gitorious/mainline/config', path
    end

    should "raise understandable error" do
      def @service.open(uri)
        res = Mutt::Test::Response.new("real_path:#{uri}")
        def res.read; raise Errno::ECONNREFUSED.new; end
        res
      end

      assert_raises Mutt::GitoriousService::ConnectionRefused do
        @service.fetch_path_from_server('/gitorious/mainline.git')
      end
    end
  end

  context "caching of repositories" do
    should "cache url -> path lookups" do
      def @service.open(uri)
        Mutt::Test::Response.new("real_path:the/real/path.git")
      end

      path = @service.fetch_path_from_server('/gitorious/mainline.git')
      assert_equal '/gitorious/mainline', @service.resolve_path('the/real/path.git')
    end

    should "cache server lookups" do
      def @service.open(uri)
        raise "Oh no you don't"
      end

      @service.cache_url('/gitorious/mainline', 'the/real/path.git')
      assert_equal 'the/real/path.git', @service.resolve_url('/gitorious/mainline.git')
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
      @repository = Repository.new
      @service.cache_url('/path/to/repo.git', '/local/filesystem/path.git')
    end

    should "grant an authorized user push access" do
      assert @service.push_allowed_by?(Mutt::User.new('bill'), @repository)      
    end

    should "deny an unauthorized user push access" do
      refute @service.push_allowed_by?(Mutt::User.new('evil_hacker'), @repository)      
    end

    should "deny authorized user when repository path is not cached" do
      service = Mutt::GitoriousService.new("gitorious.here", 3000)
      refute service.push_allowed_by?(Mutt::User.new('bill'), @repository)
    end
  end    
end
