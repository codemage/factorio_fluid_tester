my_defines = {}

-- The next few are all related to consumption tracking.
--   sum_intervals(array of number): intervals in seconds to show consumption
--     rates for in the UI.
my_defines.sum_intervals = {1, 5, 10, 60} -- in seconds
--   sum_interval_count, history_length: convenience values used when tracking
--     the consumption history to fill in the averages requested.
my_defines.sum_interval_count = 4 -- length of above list, keep this updated!
local max_sum_interval = my_defines.sum_intervals[my_defines.sum_interval_count]
my_defines.history_length = max_sum_interval * 60

-- default fluid consumption limit for defined sinks
my_defines.default_consume_per_sec = 60
