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

module Mutt
  class GitoriousRepositoryRouter
    attr_reader :service, :repository_root, :cache

    def initialize(service, repository_root)
      @service = service
      @repository_root = repository_root
      @cache = {}
    end

    def resolve_url(url)
      cached = cache_get(url)
      return cached if cached

      relative_path = service.resolve_url(url)
      cache_url(url, File.join(repository_root, relative_path))
    end

    def resolve_path(path)
      (@cache.find { |u, p| p == path } || []).first
    end

    private
    def cache_url(url, path)
      @cache[git_url(url)] = path
    end

    def cache_get(url)
      @cache[git_url(url)]
    end

    def git_url(url)
      url.split('.git').first
    end
  end
end
