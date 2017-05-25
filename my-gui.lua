require("mod-gui")

require("my-defines")

local evs = defines.events

my_gui = {}

-- gui_info is a table indexed by player index that stores GUI entities and related
--   state
-- each player has a table we'll call GuiInfo henceforth:
--   * button (GuiEntity) - button for toggling the GUI on and off
--   * frame (GuiEntity or nil) - the mod's frame, holding all our displayed
--      information, if it's open
--   * label (GuiEntity or nil) - the label that displays info on the
--      currently selected sink, if it's open
--   * selected (SourceInfo or SinkInfo or nil) - table describing currently
--      selected mod entity
--   * limit (table or nil) - defined sink limit GUI items, if visible
--     * flow (GuiEntity): flow for the line with the limit/s textfield
--     * textfield (GuiEntity): textfield where the limit is displayed/edited
--     * button (GuiEntity): 'set' button next to above textfield
--   * TODO: document limit-related stuff
if not global.gui_info then global.gui_info = {} end

-- set up the GUI for a player
my_gui.create_for_player = function (player)
  local button = mod_gui.get_button_flow(player).add{
    type = "sprite-button",
    name = "fluid-tester-button",
    sprite = "item/pipe-to-ground",
    style = mod_gui.button_style
  }
  global.gui_info[player.index] = {button = button}
  return global.gui_info[player.index]
end

-- setup the GUI for all existing players
my_gui.create_for_all_players = function()
  for index, player in pairs(game.players) do
    my_gui.create_for_player(player)
  end
end

-- get the info
my_gui.get_info = function(player_index)
  if global.gui_info[player_index] then
    return global.gui_info[player_index]
  else
    return my_gui.create_for_player(game.players[player_index])
  end
end

my_gui.open_for_player = function(player_index)
  local gi = my_gui.get_info(player_index)
  if gi.frame then return end -- already open

  local player = game.players[player_index]
  gi.frame = mod_gui.get_frame_flow(player).add{
    type = "frame",
    name = "fluid-tester-frame",
    caption = "Fluid Tester",
    direction = "vertical",
    style = mod_gui.frame_style
  }
  gi.label = gi.frame.add{
    type = "label",
    name = "fluid-tester-label",
    caption = {"messages.no-sink-selected"},
  }
  my_gui.update_for_player(player_index, {update_limit = true})
  return
end

my_gui.close_for_player = function(player_index)
  local gi = my_gui.get_info(player_index)
  if not gi.frame then return end

  gi.frame.destroy()
  gi.frame = nil
  gi.label = nil
  gi.limit = nil
end

-- update the "Limit/s" text box for a player, displaying and hiding it as needed
-- gi(table): player's GuiInfo
-- limit(number or nil): currently set limit for the selected defined sink, if any
--   (nil if no sink is selected or an infinite sink is selected)
-- options(table):
--   * update_limit(boolean): if true and a textfield is already present,
--      replace the current displayed text with the set limit. Otherwise
--      leave it in place since the player may be in the midst of changing it
--      manually.
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
      caption = {"labels.limit-per-second"},
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
      caption = {"labels.set"},
    }
  else
    gi.limit.flow.destroy()
    gi.limit = nil
  end
end

-- update the Fluid Tester gui for a player
-- player_index(number): index of the player whose GUI is to be updated
-- options(table):
--   * update_limit(boolean): see update_player_gui_limit above.
my_gui.update_for_player = function(player_index, options)
  local gi = my_gui.get_info(player_index)
  if not gi.frame then return end -- GUI not open, nothing to show
  local sink_info = gi.selected
  if sink_info then
    -- this isn't ideal for localisation, but it's the best I can figure out
    -- without a way to manually expand localised message inside Lua
    local consumed_str = string.format("%.2f", sink_info.consumed)
    local rates = ""
    for index, interval in pairs(my_defines.sum_intervals) do
      local per_second = sink_info.sums[index] / interval
      rates = rates .. string.format(", %ds = %.2f/s", interval, per_second)
    end
    gi.label.caption = {"messages.consumed-msg", consumed_str, rates}
    update_player_gui_limit(gi, sink_info.consume_per_sec, options)
  else
    gi.label.caption = {"messages.no-sink-selected"}
    update_player_gui_limit(gi, nil, options)
  end
end

-- update the Fluid Tester gui for each current player
my_gui.update_for_all_players = function()
  for player_index in pairs(game.players) do
    my_gui.update_for_player(player_index, {})
  end
end

-- select a new sink entity for display in the given player's FT GUI
-- player_index(number): index of the player whose selection is being set
-- sink_info(table): SinkInfo of selected sink, see control.lua for details
my_gui.select_sink = function(player_index, sink_info)
  my_gui.get_info(player_index).selected = sink_info
  my_gui.update_for_player(player_index, {update_limit=true})
end

-- deselect a sink entity from all players, e.g. before it is deconstructed
-- entity(LuaEntity): sink to be deselected
my_gui.deselect_sink = function(entity)
  for player_index in pairs(game.players) do
    local gi = my_gui.get_info(player_index)
    if gi.selected and gi.selected.entity == entity then
      gi.selected = nil
      my_gui.update_for_player(player_index)
    end
  end
end

-- click handler for toggle an "set limit" buttons
script.on_event(evs.on_gui_click, function(e)
  local gi = my_gui.get_info(e.player_index)
  if e.element == gi.button then
    if gi.frame then
      my_gui.close_for_player(e.player_index)
    else
      my_gui.open_for_player(e.player_index)
    end
    return
  end
  if gi.limit and e.element == gi.limit.button then
    local new_limit_str = gi.limit.textfield.text
    local new_limit = tonumber(new_limit_str)
    if new_limit then
      gi.selected.consume_per_sec = new_limit
    else
      -- TODO: localize
      local player = game.players[e.player_index]
      player.print({"could-not-convert", new_limit_str})
    end
    my_gui.update_for_player(e.player_index, {update_limit=true})
  end
end)

