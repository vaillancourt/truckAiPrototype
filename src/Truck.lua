local Common = require("Common")
local Constants = require("Constants")
local TruckAi = require("TruckAi")
local Wheel = require("Wheel")

-- Truck class
local Truck = {

    FRONT_LEFT = 1,
    FRONT_RIGHT = 2,
    REAR_LEFT = 3,
    REAR_RIGHT = 4,

    -- Assuming the truck is facing "right"/x+
    -- the width is the width of the truck (in y)
    -- length is the length of the truck (in x)
    width = 2.0,
    length = 4.0,

    wheel_offset_x =
        (4.0  / 2) -- truck length / 2
        - (0.75 / 2), -- wheel length / 2
    wheel_offset_y =
        (2.0 / 2) -- truck width / 2
        - (0.25 / 2) + 0.25, -- wheel width / 2

    -- How much can the wheels turn, on either side (i.e. [-front_angle_limit, front_angle_limit])
    -- 32.6 gives a turning radius of 9.1m
    front_angle_limit = Common.d2r(32.6),
    robo_config = {
        max_accel_forward_full = Common.g_to_mss(0.25),
        max_accel_forward_empty = Common.g_to_mss(0.5),
        max_accel_reverse = Common.g_to_mss(0.15),
    },
    body = nil,
    fixture = nil,
    shape = nil,
    wheels = nil,
    joints = nil,
    -- last_frame = 
    -- {
    --     control = { turn = 0, brake = 0, drive = 0 },
    --     speed = 0,
    -- }
    last_frame = nil,

    }
Truck.__index = Truck

function Truck.new(world, x, y, angle, name)
    local self = setmetatable({}, Truck)

    self.name = name

    -- We create the object at 0, 0, then we'll move it.
    self.body = love.physics.newBody( world, 0, 0, "dynamic" )

    self.shape = love.physics.newRectangleShape( self.length, self.width )
    local density = 100
    self.fixture = love.physics.newFixture( self.body, self.shape, density )
    self.fixture:setMask(1)

    self.body:setUserData( self )

    local offset = {
        { x = self.wheel_offset_x, y = -self.wheel_offset_y },
        { x = self.wheel_offset_x, y = self.wheel_offset_y },
        { x = -self.wheel_offset_x, y = -self.wheel_offset_y },
        { x = -self.wheel_offset_x, y = self.wheel_offset_y },
    }
    local create_and_attach_wheel = function(index) 
        self.wheels[index] = Wheel.new(world, offset[index].x, offset[index].y)
        self.joints[index] = love.physics.newRevoluteJoint(
            self.body,
            self.wheels[index].body,
            offset[index].x,
            offset[index].y,
            false)
        self.joints[index]:setLimits(0, 0)
        self.joints[index]:setLimitsEnabled(true)
    end

    self.wheels = {}
    self.joints = {}
    create_and_attach_wheel(self.FRONT_LEFT)
    create_and_attach_wheel(self.FRONT_RIGHT)
    create_and_attach_wheel(self.REAR_LEFT)
    create_and_attach_wheel(self.REAR_RIGHT)

    -- Those two joints are free to move to some degree. 
    self.joints[self.FRONT_LEFT]:setLimits(-self.front_angle_limit, self.front_angle_limit)
    self.joints[self.FRONT_RIGHT]:setLimits(-self.front_angle_limit, self.front_angle_limit)


    -- The object has been created, now we can rotate it. 
    local rotated_offsets = {
        Common.vector_rotate(offset[self.FRONT_LEFT], angle),
        Common.vector_rotate(offset[self.FRONT_RIGHT], angle),
        Common.vector_rotate(offset[self.REAR_LEFT], angle),
        Common.vector_rotate(offset[self.REAR_RIGHT], angle),
    }

    self.body:setAngle(angle)
    self.body:setPosition(x, y)
    local replace_wheels = function(index)
        self.wheels[index].body:setAngle(angle)
        self.wheels[index].body:setPosition(x + rotated_offsets[index].x, y + rotated_offsets[index].y)
    end

    replace_wheels(self.FRONT_LEFT)
    replace_wheels(self.FRONT_RIGHT)
    replace_wheels(self.REAR_LEFT)
    replace_wheels(self.REAR_RIGHT)

    local p = function(index)
        local xx, yy = self.wheels[index].body:getPosition()
        print(xx .. " " .. yy)
    end

    -- p(self.FRONT_LEFT)
    -- p(self.FRONT_RIGHT)
    -- p(self.REAR_LEFT)
    -- p(self.REAR_RIGHT)
    -- print()

    -- self.wheels[self.FRONT_LEFT].debug = true

    self.last_frame = 
    {
        control = { turn = 0, brake = 0, drive = 0 },
        speed = 0,
    }

    return self
end


function Truck.update_manual(self, dt, turn_control, brake_control, drive_control)

    self.last_frame.control = {
        turn = turn_control,
        brake = brake_control,
        drive = drive_control }

    --print("drive_control " .. drive_control)

    for _, wheel in pairs(self.wheels) do
        wheel:update_friction(dt, brake_control)
        wheel:update_drive(dt, drive_control)
    end

    local joint_left = self.joints[self.FRONT_LEFT]
    local joint_right = self.joints[self.FRONT_RIGHT]

    joint_left:setMotorEnabled(true)
    joint_right:setMotorEnabled(true)

    local joint_current_left = joint_left:getJointAngle()
    local joint_current_right = joint_right:getJointAngle()

    local desired_angle = turn_control * self.front_angle_limit

    local angle_missing_left = desired_angle - joint_current_left
    local angle_missing_right = desired_angle - joint_current_right


    joint_left:setMotorSpeed(angle_missing_left / dt)
    joint_right:setMotorSpeed(angle_missing_right / dt)

    joint_right:setMaxMotorTorque(1000)
    joint_left:setMaxMotorTorque(1000)
end


function Truck.ai_init(self, waypoints)
    TruckAi:init(self, waypoints)
end

function Truck.ai_update(self, dt)
    -- print()
    -- print("Truck.ai_update")
    TruckAi:update(self, dt)
end


function Truck.draw(self)
    -- Assuming the truck is facing x+
    -- Assuming the coordinates x and y are in the center of the front axle

    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))


    self.wheels[self.FRONT_LEFT]:draw()
    self.wheels[self.FRONT_RIGHT]:draw()
    self.wheels[self.REAR_LEFT]:draw()
    self.wheels[self.REAR_RIGHT]:draw()

    -- if self.ai_data then
        -- local scale_forward = 10
        -- local scale_to_target = scale_forward

        -- local x1, y1 = x(self.ai_data.position)
        -- local x2, y2 = x(self.ai_data.local_forward)
        -- x2 =  x1 + x2 * scale_forward
        -- y2 =  y1 + y2 * scale_forward
        -- love.graphics.setColor(Constants.colours.heading_vec)
        -- love.graphics.line(x1, y1, x2, y2)

        -- x2, y2 = x(self.ai_data.local_to_target)
        -- x2 = x1 + x2 * scale_to_target
        -- y2 = y1 + y2 * scale_to_target
        -- love.graphics.setColor(Constants.colours.destination_vec)
        -- love.graphics.line(x1, y1, x2, y2)
    -- end
    -- local p = function(index)
    --     local xx, yy = self.wheels[index].body:getPosition()
    --     print(xx .. " " .. yy)
    -- end
    -- p(self.FRONT_LEFT)
    -- p(self.FRONT_RIGHT)
    -- p(self.REAR_LEFT)
    -- p(self.REAR_RIGHT)
    -- print(self.wheels)
    -- print(self.name)
    if self.ai_data.draw_function then
        self.ai_data.draw_function(self)
    end
end


function Truck.draw_text(self, gfx_scale)
    if self.ai_data and self.ai_data.position then
        if not self.font then
            self.font = love.graphics.newFont(24, "mono")
        end

        local old_font = love.graphics.getFont()
        love.graphics.setFont(self.font)

        local x1, y1 = Common.t_to_v(self.ai_data.position)
        local x, y = Common.round(x1 * gfx_scale), Common.round(y1 * gfx_scale)
        local bg_off = 2 -- background offset

        local spd = Common.mps_to_kmh(self.ai_data.speed)
        local acc = Common.mss_to_g(self.ai_data.acceleration)
        local text = string.format("spd %.1f\nacc %.2f", spd, acc)

        love.graphics.setColor(Constants.colours.text_background)
        love.graphics.print(text, x - bg_off, y - bg_off)

        love.graphics.setColor(Constants.colours.text_foreground)
        love.graphics.print(text, x, y)

        if self.ai_data.draw_text_function then
            self.ai_data.draw_text_function(self, gfx_scale)
        end

        love.graphics.setFont(old_font)
    end
end


return Truck
