require("my-defines")
require("my-gui")

local evs = defines.events

-- global.sinks(table) - sink unit_number -> SinkInfo(table):
--   * entity(LuaEntity): for a sink on the map of either type
--   * consumed(number): total fluid consumed by the sink since it was built
--   * finite(boolean): true if the sink is a "defined" sink
--   * consume_per_sec(number or nil): consumption rate limit of this sink if
--       finite is true
--   * sums(array): fluid consumed in the last N seconds, for each N in
--       my_defines.sum_intervals.
--   * history(array): zero-based circular buffer of amount consumed each tick
--       for the last my_defines.history_length ticks.
--   * next_history_entry(number): index of the next entry in history to be
--       filled in. The last tick's consumption is in next_history_entry-1,
--       and the history wraps around the beginning of the history array so
--       that the value currently in "next_history_entry" is the oldest we
--       remember at any given time.

-- (Implementation note: we use the fancy ring-buffer history so that we don't
-- ever need to move values around in the history table for a given sink during
-- our per-tick event handler.)

script.on_init(function()
  global.sinks = {}
  global.sources = {}
  my_gui.create_for_all_players()
end)

-- Make an "array" table containing all zeroes indexed from start to stop
--   inclusive.
local make_empty = function(start, stop)
  local result = {}
  for i = start, stop do
    result[i] = 0
  end
  return result
end

-- Set up the common parts of SinkInfo table for a given sink entity. Stores
-- the data in global.sinks and returns the new entry.
-- * entity(LuaEntity): newly-constructed sink to set up info for.
local setup_sink_info = function (entity)
  global.sinks[entity.unit_number] = {
    entity = entity,
    consumed = 0,
    sums = make_empty(1, my_defines.sum_interval_count),
    history = make_empty(0, my_defines.history_length - 1), -- zero based!
    next_history_entry = 0,
  }
  return global.sinks[entity.unit_number]
end

-- Handler for when things are added to the map. Looks for new sinks and
-- adds them to global.sinks as needed.
script.on_event({evs.on_built_entity, evs.on_robot_built_entity}, function(e)
  local en = e.created_entity
  if en.name == "fluid-infinite-sink" then
    local info = setup_sink_info(en)
    info.finite = false
  elseif en.name == "fluid-defined-sink" then
    local info = setup_sink_info(en)
    info.finite = true
    info.consume_per_sec = my_defines.default_consume_per_sec
  elseif en.name == "fluid-source" then
    global.sources[en.unit_number] = {
      entity = en,
      -- more to come here later
    }
  end
end)

-- Adds a tick's worth of consumption data to a sink, adjusting all the tracked
-- averages as needed.
-- * info(SinkInfo): SinkInfo table for the sink doing the consumption.
-- * amount(number): amount of fluid that the sink consumed in the last tick.
local consume = function(info, amount)
  -- First, we just update the "total ever consumed" value, easy enough:
  info.consumed = info.consumed + amount
  local nh = info.next_history_entry
  local hl = my_defines.history_length
  -- Then we update the amount consumed in the last 1s/5s/10s/60s:
  for index, interval in pairs(my_defines.sum_intervals) do
    -- For each interval, we're sliding the "window" the sum covers ahead a tick.
    -- To do this, we want to subtract the consumption from the oldest tick
    -- currently included in the sum, and then add the consumption for the
    -- current tick.

    -- This line finds the index of the "expiring" tick, looping around the
    -- start of the history array as needed:
    local oldest_consumed = (nh + hl - (interval * 60)) % hl

    -- This then does the actual adjustment of the sum:
    info.sums[index] = info.sums[index] + amount - info.history[oldest_consumed]
  end

  -- Now all the consumption data is up to date, so we just need to update the
  -- history array and next_history_entry index for next time:
  info.history[nh] = amount
  info.next_history_entry = (info.next_history_entry + 1) % hl
end

-- Per-tick event handler, consumes fluid in every sink on the map.
script.on_event(evs.on_tick, function(e)
  if e.tick % 60 == 0 then
    -- Once per second, update the numbers in the GUI for any player who's
    -- looking at a sink's GUI:
    my_gui.update_for_all_players()
  end
  for uid, sink_info in pairs(global.sinks) do
    -- I *think* entities become inactive when scheduled for desconstruction,
    -- so we only process "active" sinks:
    if sink_info.entity.active then
      local fb = sink_info.entity.fluidbox[1]
      -- fluid box tables are nil if empty, but its easier to always have an
      -- amount value here, so we pretend:
      if not fb then fb = { amount = 0 } end

      if sink_info.finite then
        local limit = sink_info.consume_per_sec/60.0
        if fb.amount < limit then
          consume(sink_info, fb.amount)
          -- below limit; consume all the fluid, resulting in a nil fluidbox:
          sink_info.entity.fluidbox[1] = nil
        else
          consume(sink_info, limit)
          -- need to leave some fluid, adjust the fb table and write it back:
          fb.amount = fb.amount - limit
          sink_info.entity.fluidbox[1] = fb
        end
      else
        consume(sink_info, fb.amount)
        -- infinite sink, just empty the fluid box completelye:
        sink_info.entity.fluidbox[1] = nil
      end
    end
  end
  for uid, source_info in pairs(global.sources) do
    local e = source_info.entity
    local cap = e.fluidbox.get_capacity(1)
    e.fluidbox[1] = {type="water", amount=cap}
  end
end)

-- Event handler that watches for players to mouse over one of our sinks.
-- We show sink info in the GUI for the last sink that the mouse cursor touched.
script.on_event(evs.on_selected_entity_changed, function(e)
  local player = game.players[e.player_index]
  local entity = player.selected
  if not entity then return end
  if entity.name == "fluid-infinite-sink" or entity.name == "fluid-defined-sink" then
    local sink_info = global.sinks[entity.unit_number]
    my_gui.select_sink(player.index, sink_info)
  end
end)

-- Event handler for when entities are removed from the map.
-- If a sink is mined/deconstructed/blown up, we need to remove its SinkInfo
-- from global.sinks:
script.on_event(
  {evs.on_player_mined_entity, evs.on_robot_mined_entity, evs.on_entity_died},
  function(e)
    local entity = e.entity
    local list = nil
    if entity.name == "fluid-infinite-sink" or entity.name ~= "fluid-defined-sink" then
      my_gui.deselect_sink(entity)
      global.sinks[entity.unit_number] = nil
    end
    if entity.name == "fluid-source" then
      global.sources[entity.unit_number] = nil
    end
  end)

-- Paste handler. This lets users copy-paste fluid consumption limits across
-- defined sinks. (In fact, the reason defined sinks need power is so that the
-- game considers them to have copy-paste capability at all.)
script.on_event(evs.on_entity_settings_pasted, function(e)
  if e.source.name == "fluid-defined-sink" and e.destination.name == "fluid-defined-sink" then
    local source_info = global.sinks[e.source.unit_number]
    local dest_info = global.sinks[e.destination.unit_number]
    dest_info.consume_per_sec = source_info.consume_per_sec
  end
end)

-- next steps:
-- GUI and configurability for fluid source
-- multiplayer testing
