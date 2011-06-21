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
require 'java'
require 'servlet-api-2.5'
require 'jetty-6.1.26'
require 'jetty-util-6.1.26'

module Mutt
  module BasicAuth
    class Handler < org.mortbay.jetty.security.SecurityHandler
      attr_reader :authenticator

      def initialize(authenticator = DatabaseAuthenticator.new)
        super()
        @authenticator = authenticator
      end

      def handle(target, request, response, dispatch)
        authenticate(request, response)
        handler.handle(target, request, response, dispatch) if handler
      end

      def authenticate(request, response)
        request.auth_type = org.mortbay.jetty.security.Constraint::__BASIC_AUTH
        credentials = Credentials.parse(request.get_header(org.mortbay.jetty.HttpHeaders::AUTHORIZATION))

        if credentials.nil?
          response.set_header('WWW-Authenticate', 'Basic realm=\'Gitorious\'')
        elsif authenticator.authenticate(credentials.username, credentials.password)
          set_user_principal(request, credentials.user)
        end
      end

      def set_user_principal(request, user)
        request.auth_type = org.mortbay.jetty.security.Constraint::__BASIC_AUTH
        request.user_principal = user
      end
    end

    class Credentials
      attr_reader :username, :password
      
      def initialize(username, password)
        @username = username
        @password = password
      end

      def self.parse(auth_string)
        return nil if auth_string.nil?
        username, password = auth_string[6..-1].unpack('m').first.split(':')
        new(username, password)
      end

      def user
        User.new(username)
      end
    end

    class User
      attr_reader :name
      def initialize(username); @name = username; end
      alias to_s name
    end
  end
end
