#
# Cookbook:: cq
# Libraries:: OsgiComponentHelper
#
# Copyright:: (C) 2018 Jakub Wadolowski
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

module Cq
  module OsgiComponentHelper
    include Cq::HealthcheckHelper
    include Cq::HttpHelper

    def component_list(addr, user, password)
      json_to_hash(
          http_get(addr, '/system/console/components/.json', user, password).body
      )
    end

    def component_get(addr, user, password, pid)
      json_to_hash(
          http_get(addr, "/system/console/components/#{pid}.json", user, password).body
      )
    end

    # pid is unique, hence filtering using .detect
    def component_info(list, pid)
      list['data'].detect { |c| c['pid'] == pid }
    end

    # Executes defined operation on given component
    #
    # Allowed actions:
    # * enable (requires pid)
    # * disable (requires id)
    def component_op(addr, user, password, id, op)
      req_path = "/system/console/components/#{id}"
      payload = { 'action' => op }

      http_post(addr, req_path, user, password, payload)
    end

    # Component operation returns complete list of OSGi components. It needs to
    # be filtered
    def valid_component_op?(addr, user, password, http_resp, expected_state, pid)
      # Check if first API call returned 200
      return false if http_resp.code != '200'

      # Call API again to validate component status
      (1..3).each do |i|
        sleep 2

        Chef::Log.warning(
            "Retrying, #{i}/3 attempts!"
        ) if i > 1

        data = component_get(addr, user, password, pid)
        info = component_info(data, pid)
        Chef::Log.debug("Post-action component information: #{info}")

        return true if info['state'] == expected_state
      end
      false
    end

    def osgi_component_stability(addr, user, pass, hc_params)
      stability_check(
        addr, '/system/console/components/.json', user, pass, hc_params
      )
    end
  end
end
