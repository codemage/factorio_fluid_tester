require("mod-gui")

local evs = defines.events

gui_info = {} -- by player index

function create_gui(player)
  mod_gui.get_button_flow(player).add{
    type = "sprite-button",
    name = "fluid-tester-button",
    sprite = "item/pipe-to-ground",
    style = mod_gui.button_style
  }
  local frame = mod_gui.get_frame_flow(player).add{
    type = "frame",
    name = "fluid-tester-frame",
    caption = "Fluid Tester",
    direction = "vertical",
    style = mod_gui.frame_style
  }
  local label = frame.add{
    type = "label",
    name = "fluid-tester-label",
    caption = {"messages.no-sink-selected"},
  }
  gui_info[player.index] = {
    frame = frame,
    label = label,
  }
  return gui_info[player.index]
end

local get_gui_info = function(player_index)
  if gui_info[player_index] then
    return gui_info[player_index]
  else
    return create_gui(game.players[player_index])
  end
end

local setup_all_player_guis = function()
  for index, player in pairs(game.players) do
    create_gui(player)
  end
end

script.on_init(function()
  global.sinks = {}
  setup_all_player_guis()
end)

script.on_load(function()
  setup_all_player_guis()
end)

local make_empty = function(start, stop)
  local result = {}
  for i = start, stop do
    result[i] = 0
  end
  return result
end

local sum_intervals = {1, 5, 10, 60} -- in seconds
local sum_interval_count = 4
local max_sum_interval = sum_intervals[sum_interval_count]
local history_length = max_sum_interval * 60

local setup_entity_data = function (target_array, entity)
  local en = entity
  target_array[en.unit_number] = {
    entity = en,
    consumed = 0,
    next_history_entry = 0,
    history = make_empty(0, history_length - 1), -- zero based!
    sums = make_empty(1, sum_interval_count),
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
  for index, interval in pairs(sum_intervals) do
    local oldest_consumed = (nh + history_length - (interval * 60)) % history_length
    info.sums[index] = info.sums[index] + amount - info.history[oldest_consumed]
  end
  info.history[nh] = amount
  info.next_history_entry = (info.next_history_entry + 1) % history_length
end

local update_player_gui_limit = function(gi, limit, options)
  local has_limit = not not gi.limit -- cast to boolean
  local should_have_limit = not not limit

  if has_limit == should_have_limit then
    if should_have_limit and options.update_limit then
      gi.limit.textfield.text = string.format("%.2f", limit)
    end
    return
  end

  if should_have_limit then
    gi.limit = {}
    gi.limit.flow = gi.frame.add{
      type = "flow",
      name = "fluid-tester-config-flow",
      direction = "horizontal",
    }
    gi.limit.flow.add{
      type = "label",
      name = "fluid-tester-limit-label",
      caption = {"limit-per-second"},
    }
    gi.limit.textfield = gi.limit.flow.add{
      type = "textfield",
      name = "fluid-tester-limit-textfield",
      text = string.format("%.2f", limit),
    }
    -- TODO: listen for clicks to this button
    gi.limit.button = gi.limit.flow.add{
      type = "button",
      name = "fluid-tester-limit-button",
      caption = {"messages.set"},
    }
  else
    gi.limit.flow.destroy()
    gi.limit = nil
  end
end

local update_player_gui = function(player_index, options)
  local gi = get_gui_info(player_index)
  local entity_info = gi.selected
  if entity_info then
    -- this isn't ideal for localisation, but it's the best I can figure out
    -- without a way to manually expand localised message inside Lua
    local consumed_str = string.format("%.2f", entity_info.consumed)
    local rates = ""
    for index, interval in pairs(sum_intervals) do
      local per_second = entity_info.sums[index] / interval
      rates = rates .. string.format(", %ds = %.2f/s", interval, per_second)
    end
    gi.label.caption = {"messages.consumed-msg", consumed_str, rates}
    update_player_gui_limit(gi, entity_info.consume_per_sec, options)
  else
    gi.label.caption = {"messages.no-sink-selected"}
    update_player_gui_limit(gi, nil, options)
  end
end

script.on_event(evs.on_tick, function(e)
  if e.tick % 60 == 0 then
    for player_index in pairs(gui_info) do
      update_player_gui(player_index, {})
    end
  end
  for uid, entity_info in pairs(global.sinks) do
    local fb = entity_info.entity.fluidbox[1]
    if not fb then fb = { amount = 0 } end
    if entity_info.entity.active then
      if entity_info.finite then
        local limit = entity_info.consume_per_sec/60.0
        if fb.amount < limit then
          consume(entity_info, fb.amount)
          entity_info.entity.fluidbox[1] = nil
        else
          consume(entity_info, limit)
          fb.amount = fb.amount - limit
          entity_info.entity.fluidbox[1] = fb
        end
      else
        consume(entity_info, fb.amount)
        entity_info.entity.fluidbox[1] = nil
      end
    end
  end
end)

script.on_event(evs.on_selected_entity_changed, function(e)
  local player = game.players[e.player_index]
  local entity = player.selected
  if not entity then return end
  local entity_info = nil
  if entity.name == "fluid-infinite-sink" or entity.name == "fluid-defined-sink" then
    entity_info = global.sinks[entity.unit_number]
  else
    return
  end
  if not entity_info then
    -- this is a bug if it shows up
    player.print("ERROR: unit number = " .. entity.unit_number .. ", no consumption data")
    return
  end

  get_gui_info(player.index).selected = entity_info
  update_player_gui(player.index, {update_limit=true})
end)

script.on_event(
  {evs.on_player_mined_entity, evs.on_robot_mined_entity, evs.on_entity_died},
  function(e)
    local entity = e.entity
    local list = nil
    if entity.name ~= "fluid-infinite-sink" and entity.name ~= "fluid-defined-sink" then
      return
    end
    for index, player in pairs(game.players) do
      local gi = get_gui_info(index)
      if gi.selected.entity.unit_number == entity.unit_number then
        gi.selected = nil
        update_player_gui(index)
      end
    end
    global.sinks[entity.unit_number] = nil
  end)

script.on_event(evs.on_gui_click, function(e)
  local player = game.players[e.player_index]
  local gi = get_gui_info(e.player_index)
  if not gi.limit then return end
  if e.element == gi.limit.button then
    local new_limit_str = gi.limit.textfield.text
    local new_limit = tonumber(new_limit_str)
    if new_limit then
      gi.selected.consume_per_sec = new_limit
    else
      player.print("error: could not convert " .. new_limit_str .. " to a number")
    end
    update_player_gui(e.player_index, {update_limit=true})
  end
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
