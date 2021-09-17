local Wheel = require "Wheel"
local Waypoint = require "Waypoint"
local Truck = require "Truck"

local window_width, window_height = 768, 768

-- Main app. 

local waypoints = {}
local truck = {}
local world = nil
local wheels = {}

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

    truck = Truck.new(150, 150)

    -- No gravity since we're using a "top down view"
    world = love.physics.newWorld( 0, 0, false )
    table.insert(wheels, Wheel.new(world, 10, 10))
end


local iteration = 0

function love.update(dt)

    iteration = iteration + 1

    local turn_control = (iteration % 360) / 360 * 2 - 1
    local drive_control = (iteration % 480) / 480 * 2 - 1

    wheels[1]:update_friction()
    wheels[1]:update_drive(dt, 1)
    --wheels[1]:update_turn(dt, turn_control)
    world:update(dt)
end


function love.draw()

    love.graphics.push()
    love.graphics.scale(10, 10)   -- reduce everything by 50% in both X and Y coordinates

    -- draw_waypoints()
    draw_physics()
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
