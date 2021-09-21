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


function Truck.update(self, dt, control_turn)
    local joint_left = self.joints[self.FRONT_LEFT]
    local joint_right = self.joints[self.FRONT_RIGHT]

    joint_left:setMotorEnabled(true)
    joint_right:setMotorEnabled(true)


    joint_current_left = joint_left:getJointAngle()
    joint_current_right = joint_right:getJointAngle()

    desired_angle = control_turn * self.front_angle_limit

    angle_missing_left = desired_angle - joint_current_left
    angle_missing_right = desired_angle - joint_current_right


    joint_left:setMotorSpeed(angle_missing_left / dt)
    joint_right:setMotorSpeed(angle_missing_right / dt)

    joint_right:setMaxMotorTorque(1000)
    joint_left:setMaxMotorTorque(1000)
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
