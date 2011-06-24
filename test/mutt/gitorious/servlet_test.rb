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
require "mutt/gitorious/config"
require "mutt/gitorious/servlet"

class GitoriousServletTest < MiniTest::Spec
  def create_servlet_with_config(config_hash = {})
    config = Mutt::Gitorious::Config.new(config_hash)
    servlet = Mutt::Gitorious::Servlet.new(config)
    def servlet.receive_pack_factory=(rpf); @rpf = rpf; end
    def servlet.receive_pack_factory; @rpf; end
    def servlet.repository_resolver=(rs); @rs = rs; end
    def servlet.repository_resolver; @rs; end
    servlet.receive_pack_factory = :default
    servlet
  end

  should "have a receive pack factory by default" do
    servlet = create_servlet_with_config
    servlet.configure
    refute_nil servlet.receive_pack_factory
  end

  should "support pull-only configuration" do
    servlet = create_servlet_with_config
    servlet.pull_only = true
    servlet.configure
    assert_nil servlet.receive_pack_factory
  end

  should "configure resolver for private mode" do
    servlet = create_servlet_with_config({ "public_mode" => false })
    servlet.configure
    refute servlet.repository_resolver.public_mode?
  end

  should "configure resolver for public mode" do
    servlet = create_servlet_with_config({ "public_mode" => true })
    servlet.configure
    assert servlet.repository_resolver.public_mode?
  end
end