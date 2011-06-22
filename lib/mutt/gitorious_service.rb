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
require "open-uri"

module Mutt
  class GitoriousService
    attr_reader :host, :port

    def initialize(host, port)
      @host = host
      @port = port
      @cache = {}
    end

    def resolve_url(url)
      @cache[url.split('.git').first] || fetch_path_from_server(url)
    end

    def resolve_path(path)
      (@cache.find { |u, p| p == path } || []).first
    end

    def cache_url(url, path)
      @cache ||= {}
      @cache[url] = path
    end

    def fetch_path_from_server(url)
      repo_url = url.split('.git').first

      service_request(repo_url, 'config') do |data|
        cache_url(repo_url, data.scan(/^real_path:(.*)$/).flatten.first)
      end
    end

    def push_allowed_by?(user, repository)
      repo_url = resolve_path(repository.directory.absolute_path)
      return false if repo_url.nil?

      service_request(repo_url, "writable_by?username=#{user.name}") do |data|
        data == 'true'
      end
    end

    class ServiceError < StandardError
    end

    class ConnectionRefused < ServiceError
      def initialize(host, port)
        super("Unable to reach Gitorious on http://#{host}:#{port} - is it running?")
      end
    end

    private
    def service_request(*args)
      request_uri = File.join("http://#{host}:#{port}", *args)

      begin
        yield open(request_uri).read
      rescue Errno::ECONNREFUSED
        raise ConnectionRefused.new(host, port)
      rescue OpenURI::HTTPError => e
        raise ServiceError.new(e.message)
      end
    end
  end
end
