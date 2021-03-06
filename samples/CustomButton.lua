local roboto                  = require "lib.mljware.guilt.sample-elements.material-design.roboto"

local smooth_rectangle        = require "lib.mljware.guilt.sample-elements.utils.smooth_rectangle"

local guilt                   = require "lib.mljware.guilt"
local font_writer             = require "lib.mljware.guilt.font_writer"
local pleasure                = require "lib.mljware.guilt.pleasure"
local rgba                    = require "lib.mljware.color.rgba"

-- Example showing how to extend/override existing UI elements using the
-- `Template:from` method.

local namespace = guilt.namespace("samples")
local material  = guilt.namespace("material-design")

local StyleButton = namespace:template("StyleButton"):from(material.Button):needs{
  color_normal  = pleasure.need.table;
  color_hover   = pleasure.need.table;
  color_pressed = pleasure.need.table;
}

function StyleButton:draw_normal()
  local x, y, width, height = self:bounds()
  local cx, cy = x + width/2, y + height/2

  -- drop shadow
  smooth_rectangle(x, y, width, height, 2, rgba(0,0,0,0.62))
  -- button
  smooth_rectangle(x, y-1, width, height, 2, self.color_normal)
  love.graphics.setColor(1, 1, 1)
  font_writer.print_aligned(roboto.button, self.text:upper(), cx, cy, "middle", "center")
end

function StyleButton:draw_hover()
  local x, y, width, height = self:bounds()
  local cx, cy = x + width/2, y + height/2

  -- drop shadow
  smooth_rectangle(x, y, width, height, 2, rgba(0,0,0,0.62))
  -- button
  smooth_rectangle(x, y-1, width, height, 2, self.color_hover)
  love.graphics.setColor(1, 1, 1)
  font_writer.print_aligned(roboto.button, self.text:upper(), cx, cy, "middle", "center")
end

function StyleButton:draw_pressed ()
  local x, y, width, height = self:bounds()
  local cx, cy = x + width/2, y + height/2

  smooth_rectangle(x, y, width, height, 2, self.color_pressed)
  love.graphics.setColor(1,1,1)
  font_writer.print_aligned(roboto.button, self.text:upper(), cx, cy, "middle", "center")
end

namespace:finalize_template(StyleButton)
