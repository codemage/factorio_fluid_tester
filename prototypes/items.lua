local ptg_icon = data.raw.item["pipe-to-ground"].icon

local make_item = function(info)
  local item = table.deepcopy(info.base)
  item.name = info.name
  item.place_result = info.name
  item.icons = {{icon=info.base.icon, tint=info.tint}}
  item.order = "a[" .. info.name .. "]"
  return item
end

local fluid_infinite_sink = make_item{
  name="fluid-infinite-sink",
  base=data.raw.item.pipe,
  tint={r=0,g=0,b=1,a=0.3},
}
local fluid_defined_sink = make_item{
  name="fluid-defined-sink",
  base=data.raw.item.pump,
  tint={r=0,g=1,b=0,a=0.3},
}
local fluid_source = make_item{
  name="fluid-source",
  base=data.raw.item.pump,
  tint={r=1,g=0,b=0,a=0.3},
}

data:extend{fluid_infinite_sink, fluid_defined_sink, fluid_source}

