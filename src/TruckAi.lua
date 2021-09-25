local BT = require("bheaviourtree")

TruckAi = {}

-- https://github.com/tanema/behaviourtree.lua
local task_find_destination = BT.Task:new({
    -- start = function(task, obj)
    --   obj.isStarted = true
    -- end,

    -- finish = function(task, obj)
    --   obj.isStarted = false
    -- end,

    run = function(task, obj)
        obj.ai_data.current_index = obj.ai_data.current_index + 1
        local index = obj.ai_data.current_index

        if index > #obj.ai_data.waypoints then
            -- We've reached the final waypoint, remove the destination.
            task:failure()
        end

        obj.ai_data.current_destination = {}
        obj.ai_data.current_destination.index = index
        obj.ai_data.current_destination.x = self.ai.waypoints[index].x
        obj.ai_data.current_destination.y = self.ai.waypoints[index].y
        task:success()
    end
})


local task_reach_destination = BT.Task:new({
    -- start = function(task, obj)
    --   obj.isStarted = true
    -- end,

    -- finish = function(task, obj)
    --   obj.isStarted = false
    -- end,

    run = function(task, obj)

        local ai = obj.ai_data
        local truck_x, truck_y = obj.body:getPosition()
        local to_target_x, to_target_y = Common.vector_sub(ai.current_destination.x, ai.current_destination.y, truck_x, truck_y)
        local dist_to_target = Common.vector_length(to_target_x, to_target_y)

        if dist_to_target < ai.waypoints[ai.current_destination.index].radius then
              task:success()
              -- obj:ai_set_destination(ai.current_destination.index + 1)

              -- if not obj.ai.current_destination then
              --     turn_control = 0
              --     brake_control = 0
              --     drive_control = 0

              --     self:update_manual(dt, turn_control, brake_control, drive_control)
              --     self.ai_debug = nil
              --     return
              -- end
              -- to_target_x, to_target_y = Common.vector_sub(self.ai.current_destination.x, self.ai.current_destination.y, truck_x, truck_y)
              -- dist_to_target = Common.vector_length(to_target_x, to_target_y)
        end

        local local_forward_x, local_forward_y = obj.body:getWorldVector( 1, 0 )
        local to_target_x_normalized, to_target_y_normalized = Common.vector_normalize(to_target_x, to_target_y)
        local body_angle = obj.body:getAngle()
        local truck_angle = math.atan2(local_forward_y, local_forward_x)
        local desired_angle = math.atan2(to_target_y, to_target_x)
        local angle_diff = desired_angle - truck_angle

        local angle = Common.clamp_between(angle_diff, -obj.front_angle_limit, obj.front_angle_limit) / obj.front_angle_limit

        drive_control = 1
        brake_control = 0
        turn_control = angle -- We've made this [-1..1]
        obj:update_manual(dt, turn_control, brake_control, drive_control)

        obj.ai_debug = {}
        obj.ai_debug.position = { truck_x, truck_y }
        obj.ai_debug.destination = { ai.current_destination.x, ai.current_destination.y }
        obj.ai_debug.local_forward = { local_forward_x, local_forward_y }
        obj.ai_debug.local_to_target = { to_target_x_normalized, to_target_y_normalized }
        do 
            x, y = obj.body:getLinearVelocity( )
            obj.ai_debug.speed = Common.vector_length(x, y)
        end

        task:running()
    end
})

local task_idle = BT.Task:new({
  -- start = function(task, obj)
  --   obj.isStarted = true
  -- end,

  -- finish = function(task, obj)
  --   obj.isStarted = false
  -- end,

  run = function(task, obj)
    turn_control = 0
    brake_control = 0
    drive_control = 0

    obj:update_manual(dt, turn_control, brake_control, drive_control)
    task:running()
  end
})


function TruckAi.init(truck, waypoints)
    if not truck.ai_data then
        truck.ai_data = {}
        truck.ai_data.waypoints = waypoints
        truck.ai_data.current_index = 0
        truck.ai.dt = 0

        local mysequence = BehaviourTree.Sequence:new({
          nodes = {
            task_find_destination,
            task_reach_destination,
            -- here comes in a list of nodes (Tasks, Sequences or Priorities)
            -- as objects or as registered strings
          }
        })
    end
end

function TruckAi.update(truck)

end


return TruckAi
