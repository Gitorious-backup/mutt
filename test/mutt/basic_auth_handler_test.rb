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
require 'mutt/basic_auth_handler'

class FakeAuthenticator
  attr_reader :valid_username, :valid_password
  
  def initialize(valid_username, valid_password)
    @valid_username = valid_username
    @valid_password = valid_password
  end
  
  def authenticate(username, password)
    valid_username == username && valid_password == password
  end
end

class FakeRequest
  attr_accessor :auth_type, :user_principal
  attr_reader :auth_string

  def initialize(auth_string)
    @auth_string = auth_string
  end

  def get_header(name)
    auth_string
  end
end

class FakeResponse
  attr_reader :headers

  def initialize
    @headers = {}
  end

  def set_header(name, value)
    headers[name] = value
  end
end

class BasicAuthHandlerTest < MiniTest::Unit::TestCase
  def setup
    @authenticator = FakeAuthenticator.new('bill', 'bob')
    @handler = Mutt::BasicAuth::Handler.new(@authenticator)
  end

  def test_should_authenticate_request_with_valid_user
    request = FakeRequest.new('Basic:YmlsbDpib2I=')
    response = FakeResponse.new
    @handler.authenticate(request, response)
    assert_equal 'bill', request.user_principal.name
  end

  def test_should_reject_request_with_invalid_user
    request = FakeRequest.new('Basic:dXNlcjpwYXNz')
    response = FakeResponse.new
    @handler.authenticate(request, response)
    assert_nil request.user_principal
  end

  def test_should_set_authenticate_header_for_missing_credentials
    request = FakeRequest.new(nil)
    response = FakeResponse.new
    @handler.authenticate(request, response)
    assert_equal 'Basic realm=\'Gitorious\'', response.headers['WWW-Authenticate']
  end
end
