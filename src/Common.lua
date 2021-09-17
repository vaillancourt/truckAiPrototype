local Common = {}

function Common.world_to_gfx(world_coord)
    -- for now, 1 meter is one pixel
    return world_coord
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

function Common.vector_print(x, y, name)
    if name then
        print(name .. " (" .. x .. ", " .. y .. ")")
    else
        print("(" .. x .. ", " .. y .. ")")
    end
end

function Common.kmh_to_mps(kmh)
    return kmh * 1000 / 3600
end


return Common
