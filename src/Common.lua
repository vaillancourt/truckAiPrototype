local Common = {}

function Common.world_to_gfx(world_coord)
    -- for now, 1 meter is one pixel
    return world_coord
end


function Common.v_to_t(x, y)
  return { x, y }
end

function Common.t_to_v(t)
  return t[1], t[2]
end


function Common.dot_product(x1, y1, x2, y2)
    return (x1 * x2) + (y1 * y2)
end

function Common.vector_length_2(x, y)
    return x*x + y*y
end

function Common.vector_length(x, y)
    return math.sqrt(Common.vector_length_2(x, y))
end

function Common.vector_normalize(x, y)
    local length = Common.vector_length(x, y)
    return x / length, y / length, length
end

function Common.vector_sub(x1, y1, x2, y2)
    return x1 - x2, y1 - y2
end

function Common.vector_print(x, y, name)
    if name then
        print(name .. " (" .. x .. ", " .. y .. ")")
    else
        print("(" .. x .. ", " .. y .. ")")
    end
end

function Common.equivalent(v1, v2, epsilon)
    epsilon = epsilon or 0.000001

    if v2 > v1 then 
        return ((v2 - v1) <= epsilon) 
    end
    if v1 > v2 then 
        return ((v1 - v2) <= epsilon) 
    end
    -- if v1 == v2 then 
    return true
end

function Common.clamp_between(value, min, max)
    if value < min then return min end
    if value > max then return max end

    return value
end

function Common.zero_near_zero(value, epsilon)
    if Common.equivalent(0, value, epsilon) then
        return 0
    end

    return value
end

function Common.sign(v)
    -- http://lua-users.org/wiki/SimpleRound
    return (v >= 0 and 1) or -1
end
function Common.round(v, bracket)
    -- http://lua-users.org/wiki/SimpleRound
    bracket = bracket or 1
    return math.floor(v/bracket + Common.sign(v) * 0.5) * bracket
end

function Common.kmh_to_mps(kmh)
    return kmh * 1000 / 3600
end

function Common.mps_to_kmh(mps)
    return mps * 3600 / 1000
end

function Common.d2r(degrees)
    return degrees  / 360 * 2 * math.pi
end

function Common.g_to_mss(g)
    return g * 9.8
end

return Common
