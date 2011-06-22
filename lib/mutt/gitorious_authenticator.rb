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

require 'active_record'

module Mutt
  class GitoriousAuthenticator
    class User < ActiveRecord::Base
    end

    def initialize(db_config)
      ActiveRecord::Base.establish_connection(db_config)
    end

    def authenticate(username, password)
      !User.find(:first,
                 :conditions => ["login = ? and crypted_password = sha1(concat('--', salt, '--', ?, '--'))",
                                 username, password]).nil?
    end
  end
end
