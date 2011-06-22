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
require 'mutt/git_basic_auth_handler'

class GitBasicAuthHandlerTest < MiniTest::Spec
  context 'path filtering' do
    setup do
      @authenticator = Mutt::Test::FakeAuthenticator.new('bill','bob')
      @handler = Mutt::GitBasicAuthHandler.new(@authenticator)
    end

    should 'not require authentication for non-push access' do
      request = Mutt::Test::Request.new
      refute @handler.authentication_required?(request)
    end

    should 'require authentication for push access' do
      request = Mutt::Test::Request.new(:query_string => '?service=git-receive-pack')
      assert @handler.authentication_required?(request)
    end

    should 'authenticate when authentication is required' do
      def @handler.authenticate(request, response)
        @authenticated = true
      end
      def @handler.authenticated?
        @authenticated
      end
      request = Mutt::Test::Request.new(:query_string => '?service=git-receive-pack')
      @handler.handle(nil, request, nil, nil)
      assert @handler.authenticated?
    end
  end
end
