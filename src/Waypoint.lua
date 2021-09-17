-- Waypoint class
local Waypoint = {
    x = 50,
    y = 50 }
Waypoint.__index = Waypoint

function Waypoint.new(x, y)
   local self = setmetatable({}, Waypoint)

   self.x = x or self.x
   self.y = y or self.y

   return self
end


function Waypoint.draw(self)
    local colour = {1.0, 1.0, 1.0, 1.0}
    local radius = 5
    love.graphics.setColor(colour)
    love.graphics.circle("fill", self.x, self.y, radius)
end


return Waypoint
