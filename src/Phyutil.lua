local Common = require("Common")

local Phyutil = {}

-- Retrieves the velocity of the body w.r.t. it's facing vector (assuming it's (1, 0)).
--
-- @return x component of the vector
-- @return y component of the vector
-- @return direction: -1 if the body is going forward, 1 otherwise.
function Phyutil.get_forward_velocity(body)
  local local_forward_x, local_forward_y = body:getWorldVector( 1, 0 )
  local lin_vel_x, lin_vel_y = body:getLinearVelocity( )
  local dot = Common.dot_product(local_forward_x, local_forward_y, lin_vel_x, lin_vel_y)

  local direction = 1
  if dot < 0 then
    direction = -1
  end
  return dot * local_forward_x, dot * local_forward_y, direction
end

return Phyutil
