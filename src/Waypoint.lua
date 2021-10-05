local Common = require("Common")
local Constants = require("Constants")

-- Waypoint class
local Waypoint = {
    x = 50,
    y = 50,
    radius = 2.5,
    draw_radius = 2.5,
    index = 0 }
Waypoint.__index = Waypoint

function Waypoint.generate_bucket_waypoint(left_edge_end, right_edge_end, entry_direction)
    entry_direction = entry_direction or "from_right"
    local stop_waypoint = {
        x = (left_edge_end.x + right_edge_end.x) / 2,
        y = (left_edge_end.y + right_edge_end.y) / 2,
    }

    local entry_waypoint = nil
    if entry_direction == "from_right" then
        local direction, _ = Common.vector_normalize(Common.vector_sub(right_edge_end, left_edge_end))
        entry_waypoint = Common.vector_add(right_edge_end, Common.vector_mul(direction, 10))
    else
        local direction, _ = Common.vector_normalize(Common.vector_sub(left_edge_end, right_edge_end))
        entry_waypoint = Common.vector_add(left_edge_end, Common.vector_mul(direction, 10))
    end

    return 
        Waypoint.new(entry_waypoint.x, entry_waypoint.y, "bucket_entry"),
        Waypoint.new(stop_waypoint.x, stop_waypoint.y, "bucket_stop")

end

function Waypoint.new(x, y, type)
    local self = setmetatable({}, Waypoint)

    self.x = x or self.x
    self.y = y or self.y

    if type == "reverse" or type == "bucket_entry" or type == "bucket_stop" then
        self.type = type
    else
        self.type = "forward"
    end

    return self
end

function Waypoint.get_arrive_direction(self)
    if self.type == "forward" then
        return "forward"
    end

    return "reverse"
end

function Waypoint.draw(self)

    if self.type == "forward" then
        love.graphics.setColor(Constants.colours.waypoint_forward)
    elseif self.type == "reverse" then
        love.graphics.setColor(Constants.colours.waypoint_reverse)
    elseif self.type == "bucket_entry" then
        love.graphics.setColor(Constants.colours.waypoint_bucket_entry)
    elseif self.type == "bucket_stop" then
        love.graphics.setColor(Constants.colours.waypoint_bucket_stop)
    end
    love.graphics.circle("fill", self.x, self.y, self.draw_radius)

    love.graphics.setColor(Constants.colours.text_background)
    love.graphics.print(self.index, Common.round(self.x - 0.5), Common.round(self.y - 0.5), 0, 0.5 )

    love.graphics.setColor(Constants.colours.text_foreground)
    love.graphics.print(self.index, Common.round(self.x), Common.round(self.y), 0, 0.5 )
end


return Waypoint
