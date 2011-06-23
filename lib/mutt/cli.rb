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
    attr_reader :configuration, :port
    COMMANDS = %w[run start stop]

    def initialize(options)
      path = File.join(options[:root], "config", "gitorious.yml")
      @configuration = Mutt::Gitorious::Config.new(path, options[:environment])
      @port = options[:port]
    end

    def run
      Mutt::Gitorious::Server.new(configuration).run(port)
    end

    def start
      Mutt::Gitorious::Server.new(configuration).run(port)

      # PIDFILE = File.join(File.dirname(__FILE__), "pids", "git_http.pid")
      # File.open(PIDFILE,"w") {|f| f.write(Process.pid.to_s)}
      #trap ("SIGINT") {
      # stop
      #  exit!
      #}
      #trap ("SIGTERM") {
      #  stop
      #  exit!
      #}
    end

    def stop
      #  puts "Cleaning up"
      #  File.unlink(PIDFILE)
    end
  end
end
