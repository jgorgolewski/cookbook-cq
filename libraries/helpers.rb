#
# Cookbook Name:: cq
# Libraries:: helpers
#
# Copyright (C) 2014 Jakub Wadolowski
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Get filename from given URI
# -----------------------------------------------------------------------------
def cq_jarfile(uri)
  require 'pathname'
  require 'uri'
  Pathname.new(URI.parse(uri).path).basename.to_s
end

# Get CQ instance home for given mode (author/publish)
# -----------------------------------------------------------------------------
def cq_instance_home(home_dir, mode)
  "#{home_dir}/#{mode}"
end

# Get CQ conf dir
# -----------------------------------------------------------------------------
def cq_instance_conf_dir(home_dir, mode)
  "#{cq_instance_home(home_dir, mode)}/conf"
end

# Get different form of given CQ version
# -----------------------------------------------------------------------------
def cq_version(type)
  case type
  when 'short'
    # Example: 5.6.1 => 5.6
    node[:cq][:version].to_s.delete('^0-9')[0, 3]
  when 'short_squeezed'
    # Example: 5.6.1 => 56
    node[:cq][:version].to_s.delete('^0-9')[0, 2]
  end
end

# Create deamon name for given CQ instance type
# -----------------------------------------------------------------------------
def cq_daemon_name(mode)
  "cq#{cq_version('short_squeezed')}-#{mode}"
end

# Wait until CQ instance is up and running
def cq_start_guard(mode)
  require 'net/http'
  require 'uri'

  # Pick proper resource to verify CQ instance full start
  case node[:cq][:version]
  when Chef::VersionConstraint.new('~> 5.6.0').include?(node[:cq][:version])
    uri = URI.parse("http://localhost:#{node[:cq][mode][:port]}"\
                    "/libs/granite/core/content/login.html")
  when Chef::VersionConstraint.new('~> 5.5.0').include?(node[:cq][:version])
    uri = URI.parse("http://localhost:#{node[:cq][mode][:port]}"\
                    "/libs/cq/core/content/login.html")
  end

  response = '-1'
  start_time = Time.now
  time_diff = 0

  while response != '200' || time_diff < 300
    response = Net::HTTP.get_response(uri).code
    sleep(5)
    time_diff = Time.now - start_time
  end

  abort "Aborting since #{cq_daemon_name(mode)}"\
        " start took more than 5 minutes!" if time_diff > 300
end
