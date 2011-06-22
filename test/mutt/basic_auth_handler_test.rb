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
require "mutt/basic_auth_handler"

class BasicAuthHandlerTest < MiniTest::Spec
  def setup
    @authenticator = Mutt::Test::FakeAuthenticator.new("bill", "bob")
    @handler = Mutt::BasicAuth::Handler.new(@authenticator, "Gitorious")
  end

  should "authenticate request with valid user" do
    request = Mutt::Test::Request.new(:auth_string => "Basic:YmlsbDpib2I=")
    response = Mutt::Test::Response.new
    @handler.authenticate(request, response)
    assert_equal "bill", request.user_principal.name
  end

  should "reject request with invalid user" do
    request = Mutt::Test::Request.new(:auth_string => "Basic:dXNlcjpwYXNz")
    response = Mutt::Test::Response.new
    @handler.authenticate(request, response)
    assert_nil request.user_principal
  end

  should "set authenticate header for missing credentials" do
    request = Mutt::Test::Request.new(:auth_string => nil)
    response = Mutt::Test::Response.new
    @handler.authenticate(request, response)
    assert_equal "Basic realm='Gitorious'", response.headers["WWW-Authenticate"]
  end
end
