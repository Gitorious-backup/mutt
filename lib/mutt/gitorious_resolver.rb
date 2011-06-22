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
require "java"
require "org.eclipse.jgit.http.server-0.9.3"
require "org.eclipse.jgit-0.9.3"

java_import "org.eclipse.jgit.util.FS"
java_import "org.eclipse.jgit.lib.RepositoryCache"
java_import "org.eclipse.jgit.errors.RepositoryNotFoundException"

module Mutt
  class GitoriousResolver
    attr_reader :service, :repository_root

    def initialize(service, repository_root)
      @service = service
      @repository_root = repository_root
    end

    def resolve(incoming_url)
      relative_path = service.resolve_url(incoming_url)
      File.join(repository_root, relative_path)
    rescue Mutt::GitoriousService::ServiceError => e
      log "Unable to map repository at #{incoming_url}, error is '#{e.message.strip}'"
      raise RepositoryNotFoundException.new(e.message)
    end

    def open(request, name)
      git_dir = java.io.File.new(resolve(name))
      RepositoryCache.open(RepositoryCache::FileKey.lenient(git_dir, FS::DETECTED), true)
    end

    def log(message)
      $stderr.puts message
    end
  end
end
