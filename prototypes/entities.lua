local ptg_icon = data.raw.item["pipe-to-ground"].icon

local setup_fluid_box = function (fb)
  fb.base_area = 20
  fb.base_level = -1
  fb.pipe_connections = {
    { type = "input", position = {0, -1},},
    { type = "input", position = {0, 1},},
    { type = "input", position = {-1, 0},},
    { type = "input", position = {1, 0},},
  }
end

local fluid_infinite_sink = table.deepcopy(data.raw.pipe["pipe"])
fluid_infinite_sink.name = "fluid-infinite-sink"
fluid_infinite_sink.icons = {{icon = ptg_icon, tint={r=0,g=0,b=1,a=0.3}},}
fluid_infinite_sink.minable.result = "fluid-infinite-sink"
fluid_infinite_sink.operable = true
setup_fluid_box(fluid_infinite_sink.fluid_box)

local fluid_infinite_sink_recipe = table.deepcopy(data.raw.recipe["pipe-to-ground"])
fluid_infinite_sink_recipe.name = "fluid-infinite-sink"
fluid_infinite_sink_recipe.enabled = true
fluid_infinite_sink_recipe.ingredients = {{"iron-plate", 1},}
fluid_infinite_sink_recipe.result = "fluid-infinite-sink"
fluid_infinite_sink_recipe.result_count = 1

local fluid_defined_sink = table.deepcopy(data.raw.pump["pump"])
fluid_defined_sink.name = "fluid-defined-sink"
fluid_defined_sink.pumping_speed = 200
fluid_defined_sink.icons = {{icon = ptg_icon, tint={r=0,g=1,b=0,a=0.3}},}
fluid_defined_sink.minable.result = "fluid-defined-sink"
fluid_defined_sink.fluid_box.pipe_connections = {
  -- input only:
  data.raw.pump.pump.fluid_box.pipe_connections[2] }
-- setup_fluid_box(fluid_defined_sink.fluid_box)

local fluid_defined_sink_recipe = table.deepcopy(data.raw.recipe["pipe-to-ground"])
fluid_defined_sink_recipe.name = "fluid-defined-sink"
fluid_defined_sink_recipe.enabled = true
fluid_defined_sink_recipe.ingredients = {{"iron-plate", 1},}
fluid_defined_sink_recipe.result = "fluid-defined-sink"
fluid_defined_sink_recipe.result_count = 1

data:extend{fluid_infinite_sink, fluid_infinite_sink_recipe,
            fluid_defined_sink, fluid_defined_sink_recipe}

