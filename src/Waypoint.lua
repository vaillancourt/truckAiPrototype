local Common = require("Common")
local Constants = require("Constants")

-- Waypoint class
local Waypoint = {
    x = 50,
    y = 50,
    radius = 2.5,
    index = 0 }
Waypoint.__index = Waypoint

function Waypoint.new(x, y)
   local self = setmetatable({}, Waypoint)

   self.x = x or self.x
   self.y = y or self.y

   return self
end


function Waypoint.draw(self)
    local colour = {1, 1, 0.0, 1.0}
    love.graphics.setColor(colour)
    love.graphics.circle("fill", self.x, self.y, self.radius)

    love.graphics.setColor(Constants.colours.text_background)
    love.graphics.print(self.index, Common.round(self.x - 0.5), Common.round(self.y - 0.5), 0, 0.5 )

    love.graphics.setColor(Constants.colours.text_foreground)
    love.graphics.print(self.index, Common.round(self.x), Common.round(self.y), 0, 0.5 )
end


return Waypoint
