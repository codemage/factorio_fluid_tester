local adjust_paths = function(animations, adjustment)
  for category, settings in pairs(animations) do
    settings.filename = adjustment(settings.filename)
    if settings.hr_version then
      settings.hr_version.filename = adjustment(settings.hr_version.filename)
    end
  end
end

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
fluid_infinite_sink.icons = {{icon = data.raw.item.pipe.icon, tint={r=0,g=0,b=1,a=0.3}},}
fluid_infinite_sink.minable.result = "fluid-infinite-sink"
fluid_infinite_sink.operable = true
adjust_paths(fluid_infinite_sink.pictures, function(filename)
  return filename:gsub("__base__/graphics/entity/pipe", "__FluidTester__/graphics/infinite-sink", 1)
end)
setup_fluid_box(fluid_infinite_sink.fluid_box)

local fluid_defined_sink = table.deepcopy(data.raw.pump["pump"])
fluid_defined_sink.name = "fluid-defined-sink"
fluid_defined_sink.pumping_speed = 200
fluid_defined_sink.icons = {{icon = data.raw.item.pump.icon, tint={r=0,g=1,b=0,a=0.3}},}
fluid_defined_sink.minable.result = "fluid-defined-sink"
fluid_defined_sink.fluid_box.pipe_connections = {
  -- input only:
  data.raw.pump.pump.fluid_box.pipe_connections[2] }
adjust_paths(fluid_defined_sink.animations, function(filename)
  return filename:gsub("__base__/graphics/entity/pump", "__FluidTester__/graphics/defined-sink", 1)
end)
-- setup_fluid_box(fluid_defined_sink.fluid_box)

data:extend{fluid_infinite_sink, fluid_defined_sink}

