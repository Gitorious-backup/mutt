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

require "mutt/gitorious/config"
require "mutt/gitorious/server"

module Mutt
  class Cli
    attr_reader :configuration, :port, :pull_only

    def initialize(options = {})
      path = File.join(options[:root], "config", "gitorious.yml")
      @configuration = Mutt::Gitorious::Config.from_file(path, options[:environment])
      @port = options[:port]
      @pull_only = options[:pull_only]
    rescue Errno::ENOENT => err
      raise ConfigurationFileNotFound.new(path)
    end

    def run
      server = Mutt::Gitorious::Server.new(configuration).run(port, :pull_only => pull_only)
    end
  end

  class ConfigurationFileNotFound < StandardError
    def initialize(file)
      super("Configuration file #{file} not found")
    end
  end
end
