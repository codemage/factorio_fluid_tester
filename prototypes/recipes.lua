local fluid_infinite_sink_recipe = table.deepcopy(data.raw.recipe["pipe-to-ground"])
fluid_infinite_sink_recipe.name = "fluid-infinite-sink"
fluid_infinite_sink_recipe.enabled = true
fluid_infinite_sink_recipe.ingredients = {{"iron-plate", 1},}
fluid_infinite_sink_recipe.result = "fluid-infinite-sink"
fluid_infinite_sink_recipe.result_count = 1

local fluid_defined_sink_recipe = table.deepcopy(data.raw.recipe["pipe-to-ground"])
fluid_defined_sink_recipe.name = "fluid-defined-sink"
fluid_defined_sink_recipe.enabled = true
fluid_defined_sink_recipe.ingredients = {{"iron-plate", 1},}
fluid_defined_sink_recipe.result = "fluid-defined-sink"
fluid_defined_sink_recipe.result_count = 1

data:extend{fluid_infinite_sink_recipe, fluid_defined_sink_recipe}

