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
# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mutt/version"

Gem::Specification.new do |s|
  s.name        = "mutt"
  s.version     = Mutt::VERSION
  s.authors     = ["Marius Mathiesen", "Christian Johansen"]
  s.email       = ["marius@gitorious.com", "christian@gitorious.com"]
  s.homepage    = "http://gitorious.org/gitorious/mutt"
  s.summary     = %q{Git over HTTP for Gitorious}
  s.description = %q{Powered by JRuby/JGit}

  s.files         = `git ls-files`.split("\n") - [".gitignore", "todo.org"]
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib", "vendor"]

  s.add_dependency "activerecord-jdbcmysql-adapter", "~> 1.1"
  s.add_dependency "activerecord", "~> 3.0"
  s.add_dependency "trollop", "~> 1.16"
  s.add_dependency "gitorious-hooks", "~>0.1"

  s.add_development_dependency "minitest", "~> 2.0"
  s.add_development_dependency "mini_shoulda", "~> 0.2"
  s.add_development_dependency "rake", "~> 0.9"
  s.add_development_dependency "rdoc"
end
