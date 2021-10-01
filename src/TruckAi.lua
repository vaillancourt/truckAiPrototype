local BehaviourTree = require("behaviourtree/lib/behaviour_tree")
local Common = require("Common")
local Constants = require("Constants")
local Phyutil = require("Phyutil")

-- Unused for now:
--local inspect = require("inspect")

local TruckAi = {}

-- https://github.com/vaillancourt/behaviourtree.lua/tree/decorator-repeater
local task_find_destination = BehaviourTree.Task:new({
    name = "task_find_destination",
    run = function(task, obj)
        obj.ai_data.current_index = obj.ai_data.current_index + 1
        local index = obj.ai_data.current_index

        if index > #obj.ai_data.waypoints then
            -- We've reached the final waypoint, remove the destination.
            task:fail()
            return
        end

        print("BehaviourTree.Task:new({")
        print(obj.ai_data)
        obj.ai_data.current_destination = {}
        obj.ai_data.current_destination.index = index
        print("obj.ai_data.current_destination.index " .. obj.ai_data.current_destination.index)
        obj.ai_data.current_destination.x = obj.ai_data.waypoints[index].x
        obj.ai_data.current_destination.y = obj.ai_data.waypoints[index].y
        print("task_find_destination success")
        task:success()
    end
})


local task_reach_destination_forward = BehaviourTree.Task:new({
    name = "task_reach_destination_forward",
    run = function(task, obj)

        local ai = obj.ai_data

        local truck_x, truck_y = Common.t_to_v(ai.position)
        local to_target_x, to_target_y = Common.vector_sub(
            ai.current_destination.x,
            ai.current_destination.y,
            truck_x,
            truck_y)
        local dist_to_target = Common.vector_length(to_target_x, to_target_y)

        if dist_to_target < ai.waypoints[ai.current_destination.index].radius then
            task:success()
            return
        end

        -- Calculating the angle of the wheels
        local local_forward_x, local_forward_y = obj.body:getWorldVector( 1, 0 )
        local to_target_x_normalized, to_target_y_normalized = Common.vector_normalize(to_target_x, to_target_y)
        local truck_angle = math.atan2(local_forward_y, local_forward_x)
        local desired_angle = math.atan2(to_target_y, to_target_x)
        local angle_diff = desired_angle - truck_angle
        local angle_clamped = Common.clamp_between(angle_diff, -obj.front_angle_limit, obj.front_angle_limit)
        local angle_ratio = angle_clamped / obj.front_angle_limit

        local drive_control = 1
        local brake_control = 0


        do
            -- Calculating the drive_control

            -- Limit the acceleration
            --print("(obj.last_frame.control.drive or nil) " .. (obj.last_frame.control.drive or "nil"))
            if ai.acceleration < obj.robo_config.max_accel_forward_empty then
              drive_control = (obj.last_frame.control.drive or 0) + 0.01
              print("accel " .. ai.acceleration .. " < " .. obj.robo_config.max_accel_forward_empty)
            elseif ai.acceleration > obj.robo_config.max_accel_forward_empty then
              drive_control = (obj.last_frame.control.drive or 0) - 0.1
              print("deaccel " .. ai.acceleration .. " > " .. obj.robo_config.max_accel_forward_empty)
            end

            -- https://www.physicsclassroom.com/class/1DKin/Lesson-6/Kinematic-Equations
            -- vf^2 = vi^2 + 2*a*d
            -- 2*a*d = vf^2 - vi^2
            -- d = (vf^2 - vi^2) / (2 * a)

            local vfSq = 0
            local viSq = ai.speed * ai.speed
            local a = -obj.robo_config.max_accel_forward_empty
            local distance_to_stop_at_allowed_rate = vfSq - viSq / (2 * a)
            -- print("dist_to_target " .. dist_to_target ..
            --     " distance_to_stop_at_allowed_rate " .. distance_to_stop_at_allowed_rate)
            if dist_to_target < 2*distance_to_stop_at_allowed_rate then
              drive_control = 0
              brake_control = 0.75
            end
            drive_control = Common.clamp_between(drive_control, 0, 1)
        end

        local turn_control = angle_ratio -- We've made this [-1..1]
        obj:update_manual(ai.dt, turn_control, brake_control, drive_control)

        ai.destination = { ai.current_destination.x, ai.current_destination.y }
        ai.local_forward = { local_forward_x, local_forward_y }
        ai.local_to_target = { to_target_x_normalized, to_target_y_normalized }

        task:running()
    end
})


local task_reach_destination_reverse = BehaviourTree.Task:new({
    name = "task_reach_destination_reverse",
    run = function(task, obj)

        local ai = obj.ai_data

        local truck_x, truck_y = Common.t_to_v(ai.position)
        local to_target_x, to_target_y = Common.vector_sub(
            ai.current_destination.x,
            ai.current_destination.y,
            truck_x,
            truck_y)
        local dist_to_target = Common.vector_length(to_target_x, to_target_y)

        if dist_to_target < ai.waypoints[ai.current_destination.index].radius then
            task:success()
            return
        end

        -- Calculating the angle of the wheels
        local local_reverse_x, local_reverse_y = obj.body:getWorldVector( -1, 0 )
        local to_target_x_normalized, to_target_y_normalized = Common.vector_normalize(to_target_x, to_target_y)
        local truck_angle = Common.over_2pi(math.atan2(local_reverse_y, local_reverse_x))
        local desired_angle = Common.over_2pi(math.atan2(to_target_y, to_target_x))
        local angle_diff = Common.over_2pi(desired_angle - truck_angle)
        local angle_diff_neg = Common.from_over_2pi_to_minus_pi_to_pi(angle_diff)
        local angle_clamped = Common.clamp_between(angle_diff_neg, -obj.front_angle_limit, obj.front_angle_limit)
        local angle_ratio = -angle_clamped / obj.front_angle_limit

        local drive_control = -1
        local brake_control = 0
        -- print(
        --     " truck_angle " .. truck_angle ..
        --     " desired_angle " .. desired_angle ..
        --     " angle_diff " .. angle_diff ..
        --     " angle_diff_neg " .. angle_diff_neg ..
        --     " angle_clamped " .. angle_clamped ..
        --     " angle_ratio " .. angle_ratio ..
        --     "")

        do
            -- Calculating the drive_control

            -- Limit the acceleration
            --print("(obj.last_frame.control.drive or nil) " .. (obj.last_frame.control.drive or "nil"))
            if -obj.robo_config.max_accel_reverse < ai.acceleration  then
              drive_control = (obj.last_frame.control.drive or 0) - 0.01
              print("accel " .. ai.acceleration .. " < " .. obj.robo_config.max_accel_reverse)
            elseif ai.acceleration < -obj.robo_config.max_accel_reverse then
              drive_control = (obj.last_frame.control.drive or 0) + 0.1
              print("deaccel " .. ai.acceleration .. " > " .. obj.robo_config.max_accel_reverse)
            end

            -- https://www.physicsclassroom.com/class/1DKin/Lesson-6/Kinematic-Equations
            -- vf^2 = vi^2 + 2*a*d
            -- 2*a*d = vf^2 - vi^2
            -- d = (vf^2 - vi^2) / (2 * a)

            local vfSq = 0
            local viSq = ai.speed * ai.speed
            local a = -obj.robo_config.max_accel_forward_empty
            local distance_to_stop_at_allowed_rate = vfSq - viSq / (2 * a)
            print(
                "dist_to_target " .. dist_to_target ..
                " distance_to_stop_at_allowed_rate " .. distance_to_stop_at_allowed_rate)
            if dist_to_target < 2*distance_to_stop_at_allowed_rate then
              drive_control = 0
              brake_control = 0.75
            end
            drive_control = Common.clamp_between(drive_control, -1, 0)
        end

        local turn_control = angle_ratio -- We've made this [-1..1]
        obj:update_manual(ai.dt, turn_control, brake_control, drive_control)

        local local_forward_x, local_forward_y = obj.body:getWorldVector( 1, 0 )
        ai.destination = { ai.current_destination.x, ai.current_destination.y }
        ai.local_forward = { local_forward_x, local_forward_y }
        ai.local_to_target = { to_target_x_normalized, to_target_y_normalized }

        task:running()
    end
})


local task_idle = BehaviourTree.Task:new({
  name = "task_idle",
  run = function(task, obj)
    local turn_control = 0
    local brake_control = 0.5
    local drive_control = 0

    obj:update_manual(obj.ai_data.dt, turn_control, brake_control, drive_control)
    task:running()
  end
})


BehaviourTree.register('task_find_destination', task_find_destination)
BehaviourTree.register('task_reach_destination_reverse', task_reach_destination_reverse)
BehaviourTree.register('task_idle', task_idle)


local truck_tree = BehaviourTree:new({
  name = "BehaviourTree",
  tree = BehaviourTree.Sequence:new({
    name = "globalSequence",
    nodes = {
      BehaviourTree.RepeatDecorator:new({
        name = "repeatDecorator",
        node = BehaviourTree.Sequence:new({
          name = "movingSequence",
          nodes = {
            'task_find_destination',
            'task_reach_destination_reverse'
          }
        })
      }),
      'task_idle',
    }
  })
})


local tree_truck_turn_left = BehaviourTree:new({
  name = "BehaviourTree_turn_left",
  tree = BehaviourTree.Task:new({
    name = "task_turn_left",
    run = function(task, obj)
      local turn_control = -1
      local brake_control = 0
      local drive_control = 1

      if not obj.ai_data.spots then
        obj.ai_data.spots = {}
        obj.ai_data.spots_last_index = 0

        obj.ai_data.draw_function = function(truck)
          love.graphics.points(truck.ai_data.spots)
        end

        obj.ai_data.draw_text_function = function(truck, gfx_scale)
          local min_x, max_x = 100000, -100000
          for _, v in ipairs(truck.ai_data.spots) do
            local x = v[1]
            min_x = math.min(x, min_x)
            max_x = math.max(x, max_x)
          end

          do
            local x1, y1 = Common.t_to_v(obj.ai_data.position)
            local x, y = Common.round(x1 * gfx_scale), Common.round(y1 * gfx_scale)
            local bg_off = 2 -- background offset

            local text = string.format("%.1f", (max_x - min_x) / 2)

            love.graphics.setColor(Constants.colours.text_background)
            love.graphics.print(text, x - bg_off, y - bg_off)

            love.graphics.setColor(Constants.colours.text_foreground)
            love.graphics.print(text, x, y)
          end

        end


      end

      local left_wheel_body = obj.wheels[obj.FRONT_RIGHT]
      local x, y = left_wheel_body.body:getPosition()

      obj.ai_data.spots_last_index = obj.ai_data.spots_last_index + 1
      obj.ai_data.spots[obj.ai_data.spots_last_index] = {x, y}

      if obj.ai_data.spots_last_index == 500 then
        obj.ai_data.spots_last_index = 0
      end

      obj:update_manual(obj.ai_data.dt, turn_control, brake_control, drive_control)
      task:running()
    end
  })
})


function TruckAi.init(self, truck, waypoints)
    if not truck.ai_data then
        truck.ai_data = {}
        truck.ai_data.waypoints = waypoints
        truck.ai_data.current_index = 0
        truck.ai_data.dt = 0
        truck.ai_data.speed = 0


        truck.ai_data.previous_speeds = {0}
        truck.ai_data.previous_speed_index = 1

        truck.ai_data.behaviour_tree = truck_tree
        --truck.ai_data.behaviour_tree = tree_truck_turn_left
    end
end

function TruckAi.update(self, truck, dt)

    truck.ai_data.previous_speed_index = truck.ai_data.previous_speed_index + 1
    if truck.ai_data.previous_speed_index == 6 then
        truck.ai_data.previous_speed_index = 1
    end


    truck.ai_data.dt = dt
    truck.ai_data.position = Common.v_to_t(truck.body:getPosition())
    local local_forward_x, local_forward_y, direction = Phyutil.get_forward_velocity(truck.body)
    truck.ai_data.previous_speeds[truck.ai_data.previous_speed_index] =
        direction * Common.vector_length(local_forward_x, local_forward_y)

    local count = 0
    local sum = 0
    --print()
    for _, v in ipairs(truck.ai_data.previous_speeds) do
      count = count + 1
      --print(v)
      sum = sum + v
    end
    truck.last_frame.speed = truck.ai_data.speed
    truck.ai_data.speed = sum / count


    --truck.ai_data.speed = direction * Common.vector_length(local_forward_x, local_forward_y)
    truck.ai_data.acceleration = (truck.ai_data.speed - truck.last_frame.speed) / dt
    truck.ai_data.forward_vel = {
        x = local_forward_x,
        y = local_forward_y }
    truck.ai_data.direction = direction

    -- print("acceleration " .. truck.ai_data.acceleration
    --     .. " speed " .. truck.ai_data.speed
    --     )

    truck.ai_data.behaviour_tree:run(truck)
end


return TruckAi
