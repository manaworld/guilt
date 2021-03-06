local path = (...)
local sub1 = path:match("(.-)%.[^%.]+$")
local sub2 = sub1:match("(.-)%.[^%.]+$")
local sub3 = sub2:match("(.-)%.[^%.]+$")
local sub4 = sub3:match("(.-)%.[^%.]+$")

local roboto                  = require (sub2..".material-design.roboto")

local smooth_line             = require (sub2..".utils.smooth_line")
local smooth_rectangle        = require (sub2..".utils.smooth_rectangle")
local font_writer             = require (sub3..".font_writer")

local pleasure                = require (sub3..".pleasure")
local rgb                     = require (sub4..".color.rgb")
local rgba                    = require (sub4..".color.rgba")
local clamp                   = require (sub4..".math.clamp")
local minmax                  = require (sub4..".math.minmax")
local unicode                 = require (sub4..".unicode")

local function is_ctrl_down () return love.keyboard.isDown("lctrl" , "rctrl" ) end
local function is_shift_down() return love.keyboard.isDown("lshift", "rshift") end

local is_callable = pleasure.is.callable

local EditableText = {}
EditableText.__index = EditableText

function EditableText.new(class, owner)
  local self = setmetatable({
    owner = owner;
    caret =  1;
    off_x =  0;
    x     =  0;
    y     =  0;
  }, class)
  return self
end

EditableText.x_pad              =  12
EditableText.text_color         = rgb(0, 0, 0)
EditableText.hint_color         = rgba(0, 0, 0, 0.3)
EditableText.double_click_delay = 0.5
EditableText.font               = roboto.body1

function EditableText:set_text(text)
  self:_set_text(tostring(text or ""))
  self.select = nil
  self.caret  = unicode.len(self.owner.text) + 1
end

function EditableText:_set_text(text)
  local owner = self.owner
  local old_text = owner.text
  owner.text = text
  if is_callable(self.on_change) then
    self:on_change(text, old_text)
  end
end

function EditableText:_set_caret(new_caret, select)
  self.select = (select or (select == nil and is_shift_down())) and (self.select or self.caret) or nil
  self.caret  = clamp(new_caret, 1, unicode.len(self.owner.text) + 1)
  self:_text_x()
end

function EditableText:bounds()
  local x, y, width, height = self.owner:bounds()
  return x, y, self.width or width, self.height or height
end

function EditableText:_text_x()
  local x, _, width, _ = self:bounds()

  local left_x  = x + self.x_pad + self.x
  local right_x = left_x + width - 2*self.x_pad
  local caret_x = left_x + self.font:getWidth(unicode.sub(self:text_as_shown(), 1, self.caret - 1))
  local off_x = self.off_x

  if caret_x + off_x < left_x then
    off_x = left_x - caret_x
  end
  if caret_x + off_x >= right_x then
    off_x = right_x - caret_x
  end

  self.off_x = off_x

  return left_x + off_x
end


function EditableText:_paste_text(input)
  local select, old_caret = self.select, self.caret
  local start, stop

  if select then
    start, stop = minmax(select, old_caret)
    self.select = nil
  else
    start, stop = old_caret, old_caret
  end
  input = input:gsub("\n", "")
  self:_set_text(unicode.splice(self.owner.text, start, input, stop - start))
  self:_set_caret(start + unicode.len(input), false)

end

function EditableText:textinput (input)
  self:_paste_text(input)
end

function EditableText:_copy_to_clipboard()
  if self.owner.texttype == "password" then return end
  local select, old_caret = self.select, self.caret
  if not select then return end
  local from, to = minmax(select, old_caret)
  local clip = unicode.sub(self.owner.text, from, to - 1)
  love.system.setClipboardText(clip)
end

function EditableText:_select_all ()
  self.select = 1
  self:_set_caret(unicode.len(self.owner.text) + 1, true)
end

function EditableText:_token_start()
  local pos = self.caret

  while pos > 1
  and unicode.is_alphanumeric(unicode.sub(self.owner.text, pos - 1, pos - 1)) do
    pos = pos - 1
  end

  return pos
end

function EditableText:_token_end()
  local text_len = unicode.len(self.owner.text)
  local pos = self.caret

  while pos <= text_len
  and unicode.is_alphanumeric(unicode.sub(self.owner.text, pos, pos)) do
    pos = pos + 1
  end

  return pos
end

function EditableText:_select_token ()
  if self.owner.texttype == "password" then
    self:_select_all()
  else
    self.select = self:_token_start()
    self:_set_caret(math.max(self:_token_end(), self.select + 1), true)
  end
end

function EditableText:keypressed (key)
  local select, old_caret = self.select, self.caret

  local ctrl_is_down = is_ctrl_down()

  if ctrl_is_down then
    if key == "a" then
      self:_select_all()
      return
    elseif key == "c" then
      self:_copy_to_clipboard()
      return
    elseif key == "v" then
      self:_paste_text(love.system.getClipboardText() or "")
      return
    elseif key == "x" then
      self:_copy_to_clipboard()
      self:_paste_text("")
      return
    end
  end

  if key == "backspace" then
    if select then
      local start  = math.min(select, old_caret)
      local length = math.abs(select - old_caret)
      self:_set_text(unicode.splice(self.owner.text, start, "", length))
      self:_set_caret(start)
      self.select = nil
    elseif self.caret > 1 then
      self:_set_text(unicode.splice(self.owner.text, self.caret - 1, "", 1))
      self:_set_caret(self.caret - 1)
    end
    return
  end

  if key == "left" then
    self:_set_caret(math.min(ctrl_is_down and self:_token_start() or math.huge, self.caret - 1))
  elseif key == "right" then
    self:_set_caret(math.max(ctrl_is_down and self:_token_end() or 0, self.caret + 1))
  elseif key == "home" then
    self:_set_caret(1)
  elseif key == "end" then
    self:_set_caret(math.huge)
  end
end

function EditableText:_mouse_index (mx, _)
  local text, text_x = self:text_as_shown(), self:_text_x()
  local text_len = unicode.len(text)
  for i = 0, text_len do
    local char_x = text_x + self.font:getWidth(unicode.sub(text, 1, i))
    if char_x >= mx then
      return i
    end
  end
  return text_len + 1
end

function EditableText:mousepressed (mx, my)
  local new_caret  = self:_mouse_index(mx, my)
  local last_press = self._last_press
  local timestamp  = love.timer.getTime()

  if self.caret == new_caret
  and last_press
  and last_press + self.double_click_delay > timestamp then
    self._last_press = nil
    self:_select_token()
  else
    self._last_press = timestamp
    self:_set_caret(new_caret)
  end
end

function EditableText:mousedragged (mx, my, _, _, button1, _)
  if not button1 or not self._last_press then return end
  self:_set_caret(self:_mouse_index(mx, my), true)
end

function EditableText:text_as_shown()
  local text = self.owner.text
  if self.owner.texttype == "password" then
    text = ("*"):rep(unicode.len(text))
  end
  return text
end

function EditableText:draw_default ()
  self:_set_caret(1, false) -- HACK resets caret & selection when not active

  local x, y, width, height = self:bounds()

  local text = self:text_as_shown()
  pleasure.push_region(x + self.x_pad, y, width - 2*self.x_pad, height)
  do
    local dy = self.y + height/2

    if #text == 0 then
      love.graphics.setColor(self.hint_color)
      font_writer.print_aligned(self.font, self.owner.hint, self.x, dy, "left", "center")
    else
      -- TODO if text is to long, add elipsis near right border
      love.graphics.setColor(self.text_color)
      font_writer.print_aligned(self.font, text, self.x, dy, "left", "center")
    end
  end
  pleasure.pop_region()
end

function EditableText:draw_active ()
  local x, y, width, height = self:bounds()
  pleasure.push_region(x + self.x_pad, y, width - 2*self.x_pad + 2, height)
  pleasure.translate(self.off_x, 0)
  do
    local text, caret = self:text_as_shown(), self.caret

    local dy = self.y + height/2

    local blink = (love.timer.getTime() % 1 < 0.5)
    if not blink then -- show caret
      local left  = unicode.sub(text, 1, caret - 1)
      local caret_x = self.font:getWidth(left) + 1
      smooth_line(caret_x, dy - 6, caret_x, dy + 6, 1, self.text_color)
    end

    local select = self.select
    if select then
      local start, stop = minmax(select, caret)
      local from_x = self.font:getWidth(unicode.sub(text, 1, start - 1)) + 1
      local size = self.font:getWidth(unicode.sub(text, start, stop - 1))
      local fh = self.font:getHeight()

      smooth_rectangle(from_x, dy - fh/2, size, fh, 0, rgb(30, 147, 213))
    end

    love.graphics.setColor(self.text_color)
    font_writer.print_aligned(self.font, text, self.x, dy - 1, "left", "center")
  end

  pleasure.pop_region()
end

return EditableText
