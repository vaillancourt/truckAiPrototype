-- Truck class
local Truck = {
    x = 0,
    y = 0,
    angle_rad = 0
     }
Truck.__index = Truck

function Truck.new(x, y, angle_rad)
   local self = setmetatable({}, Truck)

   self.x = x or self.x
   self.y = y or self.y
   self.angle_rad = angle_rad or self.angle_rad

   return self
end


function Truck.draw(self)
    -- Assuming the truck is facing x+
    -- Assuming the coordinates x and y are in the center of the front axle

    -- draw the wheels

    -- draw the cabin

    local cabin_colour = {0.5, 1.0, 0.5, 1.0}
    local cabin_size = {x = 2.5, y = 2}
    local cabin_offset = {x = -0.75, y = 0} -- w.r.t. the center

    local cabin_x = self.x - cabin_size.x + cabin_offset.x
    local cabin_y = self.y - cabin_size.y + cabin_offset.y
    love.graphics.setColor(cabin_colour)
    love.graphics.rectangle("fill", cabin_x, cabin_y, cabin_size.x, cabin_size.y)

    -- draw the body
    local body_colour = {0.4, 0.7, 0.4, 1.0}
    local body_size = {x = 4, y = 2}
    local body_offset = {x = -1.5, y = 0} -- w.r.t. the center

    local body_x = self.x - body_size.x + body_offset.x
    local body_y = self.y - body_size.y + body_offset.y
    love.graphics.setColor(body_colour)
    love.graphics.rectangle("fill", body_x, body_y, body_size.x, body_size.y)
end


return Truck
