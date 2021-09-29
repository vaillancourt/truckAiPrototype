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

        obj.ai_data.destination = { ai.current_destination.x, ai.current_destination.y }
        obj.ai_data.local_forward = { local_forward_x, local_forward_y }
        obj.ai_data.local_to_target = { to_target_x_normalized, to_target_y_normalized }
        do 
            x, y = obj.body:getLinearVelocity( )
            obj.ai_data.speed = Common.vector_length(x, y)
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


local truck_turn_left = BehaviourTree:new({
  name = "BehaviourTree_turn_left",
  tree = BehaviourTree.Task:new({
    name = "task_turn_left",
    run = function(task, obj)
      turn_control = -1
      brake_control = 0
      drive_control = 1

      if not obj.ai_data.spots then
        obj.ai_data.spots = {}
        obj.ai_data.spots_last_index = 0

        obj.ai_data.draw_function = function(truck)
          love.graphics.points(truck.ai_data.spots)
        end

        obj.ai_data.draw_text_function = function(truck, gfx_scale)
          local min_x, max_x = 100000, -100000
          for _, v in ipairs(truck.ai_data.spots) do
            x = v[1]
            min_x = math.min(x, min_x)
            max_x = math.max(x, max_x)
          end

          do
            function x(t) return t[1], t[2] end

            local x1, y1 = x(obj.ai_data.position)
            local x, y = Common.round(x1 * gfx_scale), Common.round(y1 * gfx_scale)
            local bg_off = 2 -- background offset
            local sc = 1

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
        truck.ai_data.behaviour_tree = truck_tree
        --truck.ai_data.behaviour_tree = truck_turn_left
    end
end

function TruckAi.update(self, truck, dt)
    truck.ai_data.dt = dt
    truck.ai_data.behaviour_tree:run(truck)
end


return TruckAi
