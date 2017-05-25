my_defines = {}
my_defines.sum_intervals = {1, 5, 10, 60} -- in seconds
my_defines.sum_interval_count = 4
local max_sum_interval = my_defines.sum_intervals[my_defines.sum_interval_count]
my_defines.history_length = max_sum_interval * 60
