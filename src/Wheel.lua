local Common = require("Common")

-- This is based on 
-- * http://www.iforce2d.net/b2dtut/top-down-car
-- * http://www.iforce2d.net/src/iforce2d_TopdownCar.h

local Wheel = {
    x = 50,
    y = 50,
    max_forward_speed = Common.kmh_to_mps(35),
    max_backward_speed = Common.kmh_to_mps(30),
    max_drive_force = 1,
    max_brake_force = 300,
    max_lateral_impulse = 0.1,
    max_torque = 15,
    body = nil,
    fixture = nil,
    shape = nil,

    -- Assuming the truck is facing "right"/x+
    -- the width is the width of the truck (in y)
    -- length is the length of the truck (in x)
    width = 0.25, 
    length = 0.75,
    -- this `debug` flag turns the "print" commands "on". It is designed to be used on a single 
    -- wheel to have only data about that wheel print out
    debug = false, } 
Wheel.__index = Wheel

function Wheel.new(world, x, y)
    local self = setmetatable({}, Wheel)

    self.x = x or self.x
    self.y = y or self.y

    self.body = love.physics.newBody( world, x, y, "dynamic" )

    self.shape = love.physics.newRectangleShape( self.length, self.width )
    local density = 100
    self.fixture = love.physics.newFixture( self.body, self.shape, density )
    self.fixture:setMask()

    self.body:setUserData( self )

    return self
end


function Wheel.get_lateral_velocity(self)
    local local_side_x, local_side_y = self.body:getWorldVector( 0, 1 )
    local lin_vel_x, lin_vel_y = self.body:getLinearVelocity( )
    local dot = Common.dot_product(local_side_x, local_side_y, lin_vel_x, lin_vel_y)
    return dot * local_side_x, dot * local_side_y
end


function Wheel.get_forward_velocity(self)
    local local_forward_x, local_forward_y = self.body:getWorldVector( 1, 0 )
    local lin_vel_x, lin_vel_y = self.body:getLinearVelocity( )
    local dot = Common.dot_product(local_forward_x, local_forward_y, lin_vel_x, lin_vel_y)
    --if self.debug then
        --Common.vector_print(local_forward_x, local_forward_y, "local_forward")
        --Common.vector_print(lin_vel_x, lin_vel_y, "lin_vel")
        --print("dot " .. dot)
    --end
    local direction = 1
    if dot < 0 then
        direction = -1
    end
    return dot * local_forward_x, dot * local_forward_y, direction
end


function Wheel.update_friction(self, dt, brake_control)

    do
        -- lateral linear velocity
        local impulse_x, impulse_y = self:get_lateral_velocity()
        impulse_x = impulse_x * -self.body:getMass()
        impulse_y = impulse_y * -self.body:getMass()
        local impulse_length = Common.vector_length(impulse_x, impulse_y)

        self.body:applyLinearImpulse( impulse_x, impulse_y )
    end

    do
        -- angular velocity
        local inertia = self.body:getInertia()
        local ang_vel = self.body:getAngularVelocity()

        self.body:applyAngularImpulse(  inertia * -ang_vel)
    end

    do
        -- forward linear velocity
        local forward_vel_x, forward_vel_y, direction = self:get_forward_velocity()
        local forward_dir_x, forward_dir_y, speed = Common.vector_normalize(self:get_forward_velocity())
        if not Common.equivalent(speed, 0) then
            --Common.vector_print(forward_dir_x, forward_dir_y, "forward_dir")
            local drag_force_magnitude = -0.9 * speed * self.body:getMass()
            drag_force_magnitude = drag_force_magnitude - (speed / self.max_forward_speed) * (brake_control * self.max_brake_force)
            --if self.debug then
            --    print("speed " .. direction * speed .. " speed|kmh " .. direction * Common.mps_to_kmh(speed))
            --end
            self.body:applyForce(drag_force_magnitude * forward_dir_x, drag_force_magnitude * forward_dir_y)
        end
    end
end

--- Updates the driving of the wheel
-- 
-- @param control value in the range [-1..1]
function Wheel.update_drive(self, dt, control)

    local desired_speed = 0
    if control > 0 then
        desired_speed = control * self.max_forward_speed
    elseif control < 0 then
        desired_speed = control * self.max_backward_speed
    end 

    local local_forward_x, local_forward_y = self.body:getWorldVector( 1, 0 )
    local forward_vel_x, forward_vel_y, direction = self:get_forward_velocity()
    local current_speed = direction * Common.vector_length(forward_vel_x, forward_vel_y)
    local max_f = 2 * control

    -- if self.debug then
    --     print("desired_speed " .. desired_speed .. " current_speed " .. current_speed)
    -- end
    if desired_speed > 0 and desired_speed > current_speed then
        self.body:applyForce( local_forward_x * max_f, local_forward_y * max_f)
    elseif desired_speed < 0 and desired_speed < current_speed then
        self.body:applyForce( local_forward_x * max_f, local_forward_y * max_f)
    end
end


function Wheel.draw(self)
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))
end

return Wheel
