local BehaviourTree = require("behaviourtree/lib/behaviour_tree")
local inspect = require("inspect")
TruckAi = {}

-- https://github.com/tanema/behaviourtree.lua
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

        obj.ai_data.current_destination = {}
        obj.ai_data.current_destination.index = index
        print("obj.ai_data.current_destination.index " .. obj.ai_data.current_destination.index)
        obj.ai_data.current_destination.x = obj.ai_data.waypoints[index].x
        obj.ai_data.current_destination.y = obj.ai_data.waypoints[index].y
        print("task_find_destination success")
        task:success()
    end
})


local task_reach_destination = BehaviourTree.Task:new({
    name = "task_reach_destination",
    run = function(task, obj)

        local ai = obj.ai_data
        local truck_x, truck_y = obj.body:getPosition()
        local to_target_x, to_target_y = Common.vector_sub(ai.current_destination.x, ai.current_destination.y, truck_x, truck_y)
        local dist_to_target = Common.vector_length(to_target_x, to_target_y)

        if dist_to_target < ai.waypoints[ai.current_destination.index].radius then
              print("task_reach_destination success")
              task:success()
              return
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
        obj:update_manual(obj.ai_data.dt, turn_control, brake_control, drive_control)

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

local task_idle = BehaviourTree.Task:new({
  name = "task_idle",
  run = function(task, obj)
    turn_control = 0
    brake_control = 0.005
    drive_control = 0

    obj:update_manual(obj.ai_data.dt, turn_control, brake_control, drive_control)
    task:running()
  end
})

BehaviourTree.register('task_find_destination', task_find_destination)
BehaviourTree.register('task_reach_destination', task_reach_destination)
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
            'task_reach_destination' 
          } 
        }) 
      }),
      'task_idle',
    }
  })
})

function TruckAi.init(self, truck, waypoints)
    if not truck.ai_data then
        truck.ai_data = {}
        truck.ai_data.waypoints = waypoints
        truck.ai_data.current_index = 0
        truck.ai_data.dt = 0
        truck.ai_data.behaviour_tree = truck_tree
    end
end

function TruckAi.update(self, truck, dt)
    truck.ai_data.dt = dt
    truck.ai_data.behaviour_tree:run(truck)
end


return TruckAi
