local Common = require("Common")
local Phyutil = require("Phyutil")

-- This is based on
-- * http://www.iforce2d.net/b2dtut/top-down-car
-- * http://www.iforce2d.net/src/iforce2d_TopdownCar.h

local Wheel = {
    max_forward_speed = Common.kmh_to_mps(35),
    max_backward_speed = Common.kmh_to_mps(30),
    max_drive_force = 2,
    max_brake_force = 2,
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


function Wheel.update_friction(self, dt, brake_control)

    do
        -- lateral linear velocity
        local impulse_x, impulse_y = self:get_lateral_velocity()
        impulse_x = impulse_x * -self.body:getMass()
        impulse_y = impulse_y * -self.body:getMass()
        --local impulse_length = Common.vector_length(impulse_x, impulse_y)

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
        local forward_vel_x, forward_vel_y, _ = Phyutil.get_forward_velocity(self.body)
        local forward_dir_x, forward_dir_y, speed = Common.vector_normalize(forward_vel_x, forward_vel_y)
        if not Common.equivalent(speed, 0) then
            local drag_force_magnitude = -0.9 * self.body:getMass()
            drag_force_magnitude = drag_force_magnitude - (brake_control * self.max_brake_force)
            -- drag_force_magnitude =
            --     drag_force_magnitude
            --     - (speed / self.max_forward_speed) * (brake_control * self.max_brake_force)
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
    local forward_vel_x, forward_vel_y, direction = Phyutil.get_forward_velocity(self.body)
    local current_speed = direction * Common.vector_length(forward_vel_x, forward_vel_y)
    local max_f = self.max_drive_force * control

    if desired_speed > 0 and desired_speed > current_speed then
        if control > 0 then
            max_f = max_f * (desired_speed - current_speed) / self.max_forward_speed
        end
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
