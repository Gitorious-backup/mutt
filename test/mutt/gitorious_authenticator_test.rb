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
require "mutt/gitorious_authenticator"

class GitoriousAuthenticatorTest < MiniTest::Spec
  def setup
    @authenticator = Mutt::GitoriousAuthenticator.new(db_config)
  end

  should "authenticate valid user" do
    assert @authenticator.authenticate("johan", "test")
  end

  should "not authenticate invalid user" do
    refute @authenticator.authenticate("johan", "test!!!")
  end

  should "not authenticate non existent user" do
    refute @authenticator.authenticate("johanjohan", "test!!!")
  end
end
