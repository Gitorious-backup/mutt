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
require "mutt/gitorious_config"

module YAML
  def self.load_file(path)
    if path =~ /database\.yml/
      {"production" => {
          "adapter" => "mysql",
          "database" => "gitorious",
          "username" => "gitorious",
          "password" => "pass",
          "host" => "localhost",
          "encoding" => "utf8"
        },
        "test" => {
          "adapter" => "mysql",
          "database" => "gitorious_test",
          "username" => "gitorious",
          "password" => "pass",
          "host" => "localhost",
          "encoding" => "utf8"
        }}
    else
      {"production" => {
          "gitorious_client_host" => "gitorious.here",
          "gitorious_client_port" => "3000",
          "repository_base_path" => "/var/www/gitorious/repositories"
        },
        "development" => {
          "gitorious_client_host" => "gitorious.there"
        }
      }
    end
  end
end

class GitoriousConfigTest < MiniTest::Unit::TestCase
  def setup
    @config = Mutt::GitoriousConfig.new(__FILE__)
  end

  def test_should_load_host
    assert_equal "gitorious.here", @config.host
  end

  def test_should_load_port
    assert_equal "3000", @config.port
  end

  def test_should_load_host
    assert_equal "/var/www/gitorious/repositories", @config.repo_root
  end

  def test_should_respect_rails_env
    config = Mutt::GitoriousConfig.new(__FILE__, "development")
    assert_equal "gitorious.there", config.host
  end

  def test_should_raise_on_missing_config_file
    assert_raises Errno::ENOENT do
      config = Mutt::GitoriousConfig.new(__FILE__ + ".invalid")
    end
  end

  def test_should_get_database_configuration
    db_config = @config.db_config

    assert_equal "jdbcmysql", db_config["adapter"]
    assert_equal "gitorious", db_config["database"]
  end

  def test_should_get_environment_specific_database_configuration
    db_config = Mutt::GitoriousConfig.new(__FILE__, "production").db_config
    db_config2 = Mutt::GitoriousConfig.new(__FILE__, "test").db_config

    refute_equal db_config["database"], db_config2["database"]
  end
end
