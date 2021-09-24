local BT = require("bheaviourtree")

TruckAi = {}

-- https://github.com/tanema/behaviourtree.lua
local task_find_destination = BT.Task:new({
  start = function(task, obj)
    obj.isStarted = true
  end,

  finish = function(task, obj)
    obj.isStarted = false
  end,

  run = function(task, obj)
    task:success()
  end
})


local task_reach_destination = BT.Task:new({
  start = function(task, obj)
    obj.isStarted = true
  end,

  finish = function(task, obj)
    obj.isStarted = false
  end,

  run = function(task, obj)
    task:success()
  end
})

local task_idle = BT.Task:new({
  start = function(task, obj)
    obj.isStarted = true
  end,

  finish = function(task, obj)
    obj.isStarted = false
  end,

  run = function(task, obj)
    task:success()
  end
})


function TruckAi.init(truck)
    if not truck.ai_data then
        truck.ai_data = {}

    end
end

function TruckAi.update(truck)

end


return TruckAi
