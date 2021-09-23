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

    local r = self.radius
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(self.index, self.x-0.5, self.y-0.5, 0, 0.5 )

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.index, self.x, self.y, 0, 0.5 )

end


return Waypoint
