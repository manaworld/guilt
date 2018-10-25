love.graphics.setDefaultFilter("nearest", "nearest")

local guilt                   = require "lib.mljware.guilt"
local pleasure                = require "lib.mljware.guilt.pleasure"
local rgb                     = require "lib.mljware.color.rgb"

local try_invoke  = pleasure.try.invoke

require "lib.mljware.guilt.sample-elements.material-design"
require "lib.mljware.guilt.sample-elements.layout"
require "lib.mljware.guilt.sample-elements.standard"
require "samples"

local gui

function love.load(arg)
  local w, h = love.graphics.getDimensions()

  love.keyboard.setKeyRepeat(true)

  gui = guilt.gui{
    render_scale = 1;
    x      = 0;
    y      = 0;
    preferred_width  = w;
    preferred_height = h;
    resize = function (self, display_width, display_height)
      self.preferred_width  = display_width/self.render_scale;
      self.preferred_height = display_height/self.render_scale;
    end;
  }

  local card = gui:new("Card", {
    anchor_x = 0.5;
    align_x = 0.5;
    anchor_y = 0.4;
    align_y = 0.5;
    preferred_width  = 300;
    preferred_height = 400;
    fill_color = rgb(99, 227, 246);
  })

  local properties = gui:new("PropertyTable", {
    anchor_x = 0.5;
    align_x = 0.5;
    anchor_y = 0.5;
    align_y = 0.5;
    preferred_width  = card.preferred_width  - 64;
    preferred_height = card.preferred_height - 64;
  })

  properties:add_group("Map")
  : insert_row("x", 100)
  : insert_row("y", 200)
  : insert_row("width", 45)
  : insert_row("height", 62)

  properties:add_group("Tile")
  : insert_row("id", 52)
  : insert_row("type", "grass")
  .collapsed = true

  properties:add_group("Entity")
  : insert_row("id", "player-1")
  : insert_row("type", "player")
  : insert_row("x", 87)
  : insert_row("y", 32)
  : insert_row("health", 100)

  card:add_child(properties)

  gui:add_child(card)
end

for i, callback in ipairs{
  "keypressed";
  "keyreleased";
  "mousemoved";
  "mousepressed";
  "mousereleased";
  "resize";
  "textinput";
} do
  love[callback] = function (...)
    local width, height = love.graphics.getDimensions()
    try_invoke(gui, callback, ...)
  end
end

function love.draw()
  love.graphics.clear(rgb(226, 225, 223))
  try_invoke(gui, "draw")
end