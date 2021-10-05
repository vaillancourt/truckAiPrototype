local Waypoint = require "Waypoint"
local Truck = require "Truck"
local Common = require "Common"

io.stdout:setvbuf('no') -- This makes is so that print() statements print right away.

local window_width, window_height = 768, 768

-- Main app.

local waypoints = {}
local trucks = {}
local world = nil
local joystick = nil
local use_ai = true
local simulation_started = false
local gfx_scale = 6
local time_scale = 4
local FRAME_TIME = 1/60

function love.load(args)
    love.window.setMode(window_width, window_height, {resizable=false})

    waypoints =
    {

       Waypoint.new(101, 68),
       Waypoint.new(92, 69),
       Waypoint.new(81, 79),
       Waypoint.new(67, 80),
       -- Waypoint.new(60, 32),
       -- Waypoint.new(193, 205),

       -- Waypoint.new(92, 40),
       -- Waypoint.new(31, 66),
       -- Waypoint.new(92, 66),
       -- -- Waypoint.new(42, 187),
       -- -- Waypoint.new(74, 233),
       -- -- Waypoint.new(180, 239),
       -- -- Waypoint.new(103, 199),
       -- -- Waypoint.new(172, 138),
       -- -- Waypoint.new(219, 29),
       -- -- Waypoint.new(228, 218),
       -- -- Waypoint.new(214, 80),
       -- -- Waypoint.new(111, 53),
       -- -- Waypoint.new(88, 184),
       -- --Waypoint.new(39, 224),
       -- Waypoint.new(37, 13),
    }

    for k, v in ipairs(waypoints) do
        v.index = k
    end

    -- No gravity since we're using a "top down view"
    world = love.physics.newWorld( 0, 0, false )
    trucks = 
    {
        Truck.new(world, 114, 68, 0, "first"),
        Truck.new(world, 4, 38, math.pi, "second")
    }


    local joysticks = love.joystick.getJoysticks()
    joystick = joysticks[1] or nil

    if use_ai then
        joystick = nil
        for _, truck in pairs(trucks) do
            truck:ai_init(waypoints)
        end
    end
end


local iteration = 0
local time_acc = 0
local frame_phy_count = 0
local frame_gfx_count = 0
local debug_time_accumulaltor = 0

function love.update(dt)

    time_acc = time_acc + dt * time_scale
    debug_time_accumulaltor = debug_time_accumulaltor + dt

    while time_acc >= FRAME_TIME do
        if love.keyboard.isDown('space') then
            simulation_started = true
        end

        if simulation_started then
            frame_phy_count = frame_phy_count + 1
            time_acc = time_acc - FRAME_TIME
            dt = FRAME_TIME
        else
            time_acc = time_acc - FRAME_TIME
            dt = FRAME_TIME
        end

        iteration = iteration + 1

        local turn_control = ((iteration % 3600) / 3600 )
        local drive_control = (iteration % 480) / 480
        local brake_control = 0

        if joystick then
            local values = {
                leftx = joystick:getGamepadAxis("leftx"),
                lefty = joystick:getGamepadAxis("lefty"),
                rightx = joystick:getGamepadAxis("rightx"),
                righty = joystick:getGamepadAxis("righty"),
                triggerleft = joystick:getGamepadAxis("triggerleft"),
                triggerright = joystick:getGamepadAxis("triggerright")
            }
            turn_control = Common.zero_near_zero(values.rightx)
            drive_control = -Common.zero_near_zero(values.lefty)
            brake_control = Common.zero_near_zero(values.triggerleft)
        end


        if simulation_started then
            if use_ai then
                for _, truck in pairs(trucks) do
                    truck:ai_update(dt)
                end
            else
                trucks[1]:update_manual(dt, turn_control, brake_control, drive_control)
            end

            world:update(dt)
        end

    end

    if debug_time_accumulaltor >= 1 then
        debug_time_accumulaltor = debug_time_accumulaltor - 1
        -- print("Phy: " .. frame_phy_count .. "Hz " .. "Gfx: " .. frame_gfx_count .. "Hz ")
        frame_phy_count = 0
        frame_gfx_count = 0
    end

end


local function draw_waypoints()
    for _,v in ipairs(waypoints) do
        --print(v.x .. " " .. v.y)
        v:draw()
    end
end

local function draw_physics()
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


function love.draw()
    frame_gfx_count = frame_gfx_count + 1

    if not simulation_started then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Press 'space' to start the simulation.", 0, 0, 0, 1.5 )
    end

    love.graphics.push()

    love.graphics.scale(gfx_scale, gfx_scale)

    draw_waypoints()
    -- draw_physics()
    for _, truck in pairs(trucks) do
        truck:draw()
    end

    love.graphics.pop()

    for _, truck in pairs(trucks) do
        truck:draw_text(gfx_scale)
    end
end

function love.keyreleased(key)
   if key == "escape" then
      love.event.quit()
   end
end

-- function love.mousepressed(x, y, button, istouch, presses)
function love.mousepressed(x, y, _, _, _)
    print("       Waypoint.new(" .. math.floor(x / gfx_scale) .. ", " .. math.floor(y / gfx_scale) .. "),")
end
