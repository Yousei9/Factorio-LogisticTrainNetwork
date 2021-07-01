--[[ Copyright (c) 2017 Optera
 * Part of Logistics Train Network
 *
 * See LICENSE.md in the project directory for license information.
--]]

data:extend({
  {
    type = "bool-setting",
    name = "ltn-dispatcher-enabled",
    order = "aa",
    setting_type = "runtime-global",
    default_value = true
  },
  {
    type = "int-setting",
    name = "ltn-dispatcher-nth_tick",
    order = "ab",
    setting_type = "runtime-global",
    default_value = 2,
    minimum_value = 1,
    maximum_value = 60, -- one stop per second
  },
  {
    type = "int-setting",
    name = "ltn-dispatcher-updates-per-tick",
    order = "ac",
    setting_type = "runtime-global",
    default_value = 1,
    minimum_value = 1,
    maximum_value = 100, -- processing too many stops/requests per tick will produce lag spikes
  },
  {
    type = "string-setting",
    name = "ltn-interface-console-level",
    order = "ad",
    setting_type = "runtime-global",
    default_value = "2",
    allowed_values = {"0", "1", "2", "3"}
  },
  {
    type = "int-setting",
    name = "ltn-interface-message-filter-age",
    order = "ae",
    setting_type = "runtime-global",
    default_value = 18000,
    minimum_value = 0,
    maximum_value = 2147483647, -- prevent 32bit signed overflow
  },
  {
    type = "bool-setting",
    name = "ltn-interface-message-gps",
    order = "af",
    setting_type = "runtime-global",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ltn-interface-factorio-alerts",
    order = "ag",
    setting_type = "runtime-per-user",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ltn-interface-debug-logfile",
    order = "ah",
    setting_type = "runtime-global",
    default_value = false
  },
  {
    type = "int-setting",
    name = "ltn-dispatcher-requester-threshold",
    order = "ba",
    setting_type = "runtime-global",
    default_value = 1000,
    minimum_value = 1,
    maximum_value = 2147483647, -- prevent 32bit signed overflow
  },
  {
    type = "int-setting",
    name = "ltn-dispatcher-provider-threshold",
    order = "bb",
    setting_type = "runtime-global",
    default_value = 1000,
    minimum_value = 1,
    maximum_value = 2147483647, -- prevent 32bit signed overflow
  },
  {
    type = "bool-setting",
    name = "ltn-dispatcher-schedule-circuit-control",
    order = "ca",
    setting_type = "runtime-global",
    default_value = false
  },
  {
    type = "int-setting",
    name = "ltn-dispatcher-depot-inactivity(s)",
    order = "cb",
    setting_type = "runtime-global",
    default_value = 5, --5s
    minimum_value = 1, --1s
    maximum_value = 36000, -- 10h
  },
  {
    type = "int-setting",
    name = "ltn-dispatcher-stop-timeout(s)",
    order = "cc",
    setting_type = "runtime-global",
    default_value = 120, --2min
    minimum_value = 0, --0:off
    maximum_value = 36000, -- 10h
  },
  {
    type = "int-setting",
    name = "ltn-dispatcher-delivery-timeout(s)",
    order = "cd",
    setting_type = "runtime-global",
    default_value = 600, --10min
    minimum_value = 60, -- 1min
    maximum_value = 36000, -- 10h
  },
  {
    type = "bool-setting",
    name = "ltn-dispatcher-requester-delivery-reset",
    order = "ce",
    setting_type = "runtime-global",
    default_value = false
  },
  {
    type = "bool-setting",
    name = "ltn-dispatcher-finish-loading",
    order = "cf",
    setting_type = "runtime-global",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ltn-dispatcher-create-temporary-stops",
    order = "cg",
    setting_type = "runtime-global",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ltn-depot-reset-filters",
    order = "da",
    setting_type = "runtime-global",
    default_value = true
  },
  {
    type = "double-setting",
    name = "ltn-depot-fluid-cleaning",
    order = "db",
    setting_type = "runtime-global",
    default_value = 0,
    minimum_value = 0
  },
  {
    type = "int-setting",
    name = "ltn-stop-default-network",
    order = "ea",
    setting_type = "runtime-global",
    default_value = -1, -- any
  },
})