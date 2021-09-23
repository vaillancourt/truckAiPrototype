local Common = require("Common")
local Wheel = require("Wheel")

-- Truck class
local Truck = {
    x = 0,
    y = 0,
    body = nil,
    fixture = nil,
    shape = nil,

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

    wheels = {},
    joints = {},

    front_angle_limit = 25 / 360 * 2 * math.pi
    }
Truck.__index = Truck

function Truck.new(world, x, y, angle_rad)
    local self = setmetatable({}, Truck)

    self.x = x or self.x
    self.y = y or self.y

    self.body = love.physics.newBody( world, x, y, "dynamic" )

    self.shape = love.physics.newRectangleShape( self.length, self.width )
    local density = 100
    self.fixture = love.physics.newFixture( self.body, self.shape, density )
    self.fixture:setMask(1)

    self.body:setUserData( self )
    
    self.wheels[self.FRONT_LEFT] = Wheel.new(world, x + self.wheel_offset_x, y - self.wheel_offset_y)
    self.wheels[self.FRONT_RIGHT] = Wheel.new(world, x + self.wheel_offset_x, y + self.wheel_offset_y)
    self.wheels[self.REAR_LEFT] = Wheel.new(world, x - self.wheel_offset_x, y - self.wheel_offset_y)
    self.wheels[self.REAR_RIGHT] = Wheel.new(world, x - self.wheel_offset_x, y + self.wheel_offset_y)

    self.joints[self.FRONT_LEFT] = love.physics.newRevoluteJoint( 
        self.body, 
        self.wheels[self.FRONT_LEFT].body, 
        x + self.wheel_offset_x,
        y - self.wheel_offset_y,
        false)
    self.joints[self.FRONT_RIGHT] = love.physics.newRevoluteJoint( 
        self.body, 
        self.wheels[self.FRONT_RIGHT].body, 
        x + self.wheel_offset_x,
        y + self.wheel_offset_y,
        false)

    self.joints[self.REAR_LEFT] = love.physics.newRevoluteJoint( 
        self.body, 
        self.wheels[self.REAR_LEFT].body, 
        x - self.wheel_offset_x,
        y - self.wheel_offset_y,
        false)
    self.joints[self.REAR_RIGHT] = love.physics.newRevoluteJoint( 
        self.body, 
        self.wheels[self.REAR_RIGHT].body, 
        x - self.wheel_offset_x,
        y + self.wheel_offset_y,
        false)

    for _, joint in ipairs(self.joints) do
        joint:setLimits(0, 0)
        joint:setLimitsEnabled(true)
    end

    self.joints[self.FRONT_LEFT]:setLimits(-self.front_angle_limit, self.front_angle_limit)
    self.joints[self.FRONT_RIGHT]:setLimits(-self.front_angle_limit, self.front_angle_limit)

    self.wheels[self.FRONT_LEFT].debug = true

    return self
end


function Truck.update_manual(self, dt, turn_control, brake_control, drive_control)
    for _, wheel in pairs(self.wheels) do
        wheel:update_friction(dt, brake_control)
        wheel:update_drive(dt, drive_control)
    end

    local joint_left = self.joints[self.FRONT_LEFT]
    local joint_right = self.joints[self.FRONT_RIGHT]

    joint_left:setMotorEnabled(true)
    joint_right:setMotorEnabled(true)

    joint_current_left = joint_left:getJointAngle()
    joint_current_right = joint_right:getJointAngle()

    desired_angle = turn_control * self.front_angle_limit

    angle_missing_left = desired_angle - joint_current_left
    angle_missing_right = desired_angle - joint_current_right


    joint_left:setMotorSpeed(angle_missing_left / dt)
    joint_right:setMotorSpeed(angle_missing_right / dt)

    joint_right:setMaxMotorTorque(1000)
    joint_left:setMaxMotorTorque(1000)
end


function Truck.ai_init(self, waypoints)
    self.ai = {}
    self.ai.waypoints = waypoints
    self:ai_set_destination(1)
end

function Truck.ai_set_destination(self, index)
    if index > #self.ai.waypoints then
        -- We've reached the final waypoint, remove the destination. 
        self.ai.current_destination = nil
        return
    end

    self.ai.current_destination = {}
    self.ai.current_destination.index = index
    self.ai.current_destination.x = self.ai.waypoints[index].x
    self.ai.current_destination.y = self.ai.waypoints[index].y
end

function Truck.ai_update(self, dt)
    if not self.ai.current_destination then
        turn_control = 0
        brake_control = 0
        drive_control = 0

        self:update_manual(dt, turn_control, brake_control, drive_control)
        return
    end

    local truck_x, truck_y = self.body:getPosition()
    local to_target_x, to_target_y = Common.vector_sub(self.ai.current_destination.x, self.ai.current_destination.y, truck_x, truck_y)
    local dist_to_target = Common.vector_length(to_target_x, to_target_y)

    if dist_to_target < self.ai.waypoints[self.ai.current_destination.index].radius then
        self:ai_set_destination(self.ai.current_destination.index + 1)

        if not self.ai.current_destination then
            turn_control = 0
            brake_control = 0
            drive_control = 0

            self:update_manual(dt, turn_control, brake_control, drive_control)
            return
        end
        to_target_x, to_target_y = Common.vector_sub(self.ai.current_destination.x, self.ai.current_destination.y, truck_x, truck_y)
        dist_to_target = Common.vector_length(to_target_x, to_target_y)
    end

    local local_forward_x, local_forward_y = self.body:getWorldVector( 1, 0 )
    local to_target_x_normalized, to_target_y_normalized = Common.vector_normalize(to_target_x, to_target_y)
    local body_angle = self.body:getAngle()
    local truck_angle = math.atan2(local_forward_y, local_forward_x)
    local desired_angle = math.atan2(to_target_y, to_target_x)
    local angle_diff = desired_angle - truck_angle

    local angle = Common.clamp_between(angle_diff, -self.front_angle_limit, self.front_angle_limit) / self.front_angle_limit

    drive_control = 1
    brake_control = 0
    turn_control = angle -- We've made this [-1..1]
    self:update_manual(dt, turn_control, brake_control, drive_control)

    -- for _, wheel in pairs(self.wheels) do
    --     wheel:update_friction(dt, brake_control)
    --     wheel:update_drive(dt, drive_control)
    -- end

    -- local joint_left = self.joints[self.FRONT_LEFT]
    -- local joint_right = self.joints[self.FRONT_RIGHT]

    -- joint_left:setMotorEnabled(true)
    -- joint_right:setMotorEnabled(true)

    -- joint_current_left = joint_left:getJointAngle()
    -- joint_current_right = joint_right:getJointAngle()

    -- desired_angle = turn_control * self.front_angle_limit

    -- angle_missing_left = desired_angle - joint_current_left
    -- angle_missing_right = desired_angle - joint_current_right


    -- joint_left:setMotorSpeed(angle_missing_left / dt)
    -- joint_right:setMotorSpeed(angle_missing_right / dt)

    -- joint_right:setMaxMotorTorque(1000)
    -- joint_left:setMaxMotorTorque(1000)
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
end


return Truck
