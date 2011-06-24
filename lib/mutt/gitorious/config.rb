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
require "yaml"

module Mutt
  module Gitorious
    class Config
      attr_reader :configuration, :config_path, :environment

      def initialize(config, gitorious_root = nil, environment = "production")
        @environment = environment
        @config_path = gitorious_root
        @configuration = config || {}
      end

      def self.from_file(file, environment = "production")
        raise Errno::ENOENT.new("gitorious.yml not found") unless File.file?(file)
        new(YAML::load_file(file)[environment], File.dirname(file), environment)
      end

      def host
        @host ||= configuration["gitorious_client_host"]
      end

      def port
        @port ||= configuration["gitorious_client_port"]
      end

      def repo_root
        @repo_root ||= configuration["repository_base_path"]
      end

      def db_config
        if !defined?(@db_config)
          yaml = YAML::load_file(File.join(config_path, "database.yml"))
          @db_config = yaml[environment]
          @db_config["adapter"] = "jdbcmysql"
        end

        @db_config
      end
    end
  end
end
