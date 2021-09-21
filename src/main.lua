local Wheel = require "Wheel"
local Waypoint = require "Waypoint"
local Truck = require "Truck"

local window_width, window_height = 768, 768

-- Main app. 

local waypoints = {}
local truck = {}
local world = nil
local wheels = {}
local joystick = nil

function love.load(args)
    success = love.window.setMode(window_width, window_height, {resizable=false})

    waypoints = 
    {
        Waypoint.new(50, 50),
        Waypoint.new(100, 50),
        Waypoint.new(150, 50),
        Waypoint.new(200, 100),
        Waypoint.new(200, 150),
    }

    -- truck = Truck.new(150, 150)

    -- No gravity since we're using a "top down view"
    world = love.physics.newWorld( 0, 0, false )
    truck = Truck.new(world, 50, 50)
    -- table.insert(wheels, Wheel.new(world, 10, 10))

    local joysticks = love.joystick.getJoysticks()
    joystick = joysticks[1] or nil
end


local iteration = 0

function love.update(dt)

    iteration = iteration + 1

    local turn_control = ((iteration % 3600) / 3600 ) 
    local drive_control = (iteration % 480) / 480

    if joystick then
        local values = {
            leftx = joystick:getGamepadAxis("leftx"),
            lefty = joystick:getGamepadAxis("lefty"),
            rightx = joystick:getGamepadAxis("rightx"),
            righty = joystick:getGamepadAxis("righty"),
            triggerleft = joystick:getGamepadAxis("triggerleft"),
            triggerright = joystick:getGamepadAxis("triggerright")
        }
        turn_control = values.rightx
        drive_control = -values.lefty
        --for key,value in pairs(values) do print(key,value) end
    end


    --turn_control = 0
    --drive_control = 0

    for _, wheel in pairs(truck.wheels) do
        wheel:update_friction()
        wheel:update_drive(dt, drive_control)
    end
    --print("turn_control " .. turn_control)

    truck:update(dt, turn_control)
    --if turn_control <= 0.05 then
    --    truck.wheels[1]:update_turn(dt, turn_control)
    --else
    --    truck.wheels[1]:update_turn(dt, 0)
    --end
    if true or love.keyboard.isDown('space') then
        world:update(dt)
    end


end


function love.draw()

    love.graphics.push()
    local scale = 1
    love.graphics.scale(scale, scale)   -- reduce everything by 50% in both X and Y coordinates

    -- draw_waypoints()
    --draw_physics()
    truck:draw()

    love.graphics.pop()
end

function draw_waypoints()
    for i,v in ipairs(waypoints) do
        --print(v.x .. " " .. v.y)
        v:draw()
    end
end

function draw_physics()
    -- https://love2d.org/wiki/Tutorial:PhysicsDrawing

    love.graphics.setColor(0, 1, 0, 1)
    for _, body in pairs(world:getBodies()) do
        for _, fixture in pairs(body:getFixtures()) do
            local shape = fixture:getShape()

            if shape:typeOf("CircleShape") then
                local cx, cy = body:getWorldPoints(shape:getPoint())
                love.graphics.circle("fill", cx, cy, shape:getRadius())
            elseif shape:typeOf("PolygonShape") then
                love.graphics.polygon("fill", body:getWorldPoints(shape:getPoints()))
            else
                love.graphics.line(body:getWorldPoints(shape:getPoints()))
            end
        end
    end
end



function love.keyreleased(key)
   if key == "escape" then
      love.event.quit()
   end
end
