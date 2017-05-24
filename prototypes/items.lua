local ptg_icon = data.raw.item["pipe-to-ground"].icon

local fluid_infinite_sink = table.deepcopy(data.raw["item"]["pipe"])
fluid_infinite_sink.name = "fluid-infinite-sink"
fluid_infinite_sink.icons = {{icon = ptg_icon, tint={r=0,g=0,b=1,a=0.3}},}
fluid_infinite_sink.order = "a[fluid-infinite-sink]"
-- order?
fluid_infinite_sink.place_result = "fluid-infinite-sink"

local fluid_defined_sink = table.deepcopy(data.raw["item"]["pipe"])
fluid_defined_sink.name = "fluid-defined-sink"
fluid_defined_sink.icons = {{icon = ptg_icon, tint={r=0,g=1,b=0,a=0.3}},}
fluid_defined_sink.order = "a[fluid-defined-sink]"
-- order?
fluid_defined_sink.place_result = "fluid-defined-sink"

data:extend{fluid_infinite_sink, fluid_defined_sink}

