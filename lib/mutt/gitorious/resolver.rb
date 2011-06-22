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
require "mutt/gitorious/service"

java_import "org.eclipse.jgit.util.FS"
java_import "org.eclipse.jgit.lib.RepositoryCache"
java_import "org.eclipse.jgit.errors.RepositoryNotFoundException"

module Mutt
  module Gitorious
    class Resolver
      attr_reader :router

      def initialize(router)
        @router = router
      end

      def open(request, name)
        git_dir = java.io.File.new(router.resolve_url(name))
        RepositoryCache.open(RepositoryCache::FileKey.lenient(git_dir, FS::DETECTED), true)
      rescue Mutt::Gitorious::Service::ServiceError => e
        log "Unable to map repository at #{name}, error is '#{e.message.strip}'"
        raise RepositoryNotFoundException.new(e.message)
      end

      def log(message)
        $stderr.puts message
      end
    end
  end
end
