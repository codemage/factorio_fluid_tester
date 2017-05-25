-- all the stuff in this mod is just for testing, so let's make it cheap
-- and not require any technologies to unlock it:
local simple_recipe = function (name)
  return {
    type = "recipe",
    name = name,
    enabled = true,
    ingredients = {{"iron-plate", 1}},
    result = name,
  }
end

local fluid_infinite_sink = simple_recipe("fluid-infinite-sink")
local fluid_defined_sink = simple_recipe("fluid-defined-sink")
local fluid_source = simple_recipe("fluid-source")

data:extend{fluid_infinite_sink, fluid_defined_sink, fluid_source}

