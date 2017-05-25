require("my-defines")
require("my-gui")

local evs = defines.events


script.on_init(function()
  global.sinks = {}
  my_gui.create_for_all_players()
end)

script.on_load(function()
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

local setup_entity_data = function (target_array, entity)
  local en = entity
  -- TODO: document this structure and how the consume function works
  target_array[en.unit_number] = {
    entity = en,
    consumed = 0,
    next_history_entry = 0,
    history = make_empty(0, my_defines.history_length - 1), -- zero based!
    sums = make_empty(1, my_defines.sum_interval_count),
  }
  return target_array[en.unit_number]
end

script.on_event({evs.on_built_entity, evs.on_robot_built_entity}, function(e)
  local en = e.created_entity
  if en.name == "fluid-infinite-sink" then
    local info = setup_entity_data(global.sinks, en)
    info.finite = false
  elseif en.name == "fluid-defined-sink" then
    local info = setup_entity_data(global.sinks, en)
    info.finite = true
    info.consume_per_sec = 60
  end
end)

local consume = function(info, amount)
  info.consumed = info.consumed + amount
  local nh = info.next_history_entry
  for index, interval in pairs(my_defines.sum_intervals) do
    local oldest_consumed = (nh + my_defines.history_length - (interval * 60)) % my_defines.history_length
    info.sums[index] = info.sums[index] + amount - info.history[oldest_consumed]
  end
  info.history[nh] = amount
  info.next_history_entry = (info.next_history_entry + 1) % my_defines.history_length
end

script.on_event(evs.on_tick, function(e)
  if e.tick % 60 == 0 then
    my_gui.update_for_all_players()
  end
  for uid, sink_info in pairs(global.sinks) do
    local fb = sink_info.entity.fluidbox[1]
    if not fb then fb = { amount = 0 } end
    if sink_info.entity.active then
      if sink_info.finite then
        local limit = sink_info.consume_per_sec/60.0
        if fb.amount < limit then
          consume(sink_info, fb.amount)
          sink_info.entity.fluidbox[1] = nil
        else
          consume(sink_info, limit)
          fb.amount = fb.amount - limit
          sink_info.entity.fluidbox[1] = fb
        end
      else
        consume(sink_info, fb.amount)
        sink_info.entity.fluidbox[1] = nil
      end
    end
  end
end)

script.on_event(evs.on_selected_entity_changed, function(e)
  local player = game.players[e.player_index]
  local entity = player.selected
  if not entity then return end
  local sink_info = nil
  if entity.name == "fluid-infinite-sink" or entity.name == "fluid-defined-sink" then
    sink_info = global.sinks[entity.unit_number]
  else
    return
  end
  if not sink_info then
    -- this is a bug if it shows up
    -- TODO: localize
    player.print("ERROR: unit number = " .. entity.unit_number .. ", no consumption data")
    return
  end
  
  my_gui.select_sink(player.index, sink_info)
end)

script.on_event(
  {evs.on_player_mined_entity, evs.on_robot_mined_entity, evs.on_entity_died},
  function(e)
    local entity = e.entity
    local list = nil
    if entity.name ~= "fluid-infinite-sink" and entity.name ~= "fluid-defined-sink" then
      return
    end
    my_gui.deselect_sink(entity)
    global.sinks[entity.unit_number] = nil
  end)

script.on_event(evs.on_entity_settings_pasted, function(e)
  if e.source.name == "fluid-defined-sink" and e.destination.name == "fluid-defined-sink" then
    local source_info = global.sinks[e.source.unit_number]
    local dest_info = global.sinks[e.destination.unit_number]
    dest_info.consume_per_sec = source_info.consume_per_sec
  end
end)

-- next steps:
-- test save/load support
-- better graphics
-- multiplayer testing
