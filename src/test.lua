local Common = require("Common")

local function test(value, expected, function_to_test)
    function_to_test = function_to_test or Common.clean_angle_minus_pi_to_pi
    result = function_to_test(value)
    pass = Common.equivalent(expected, result)
    print("Input: " .. value .. " Result: " .. result .. " Expected: " .. expected .. " Pass: " .. ((pass and "yes") or "no"))
end

print("Testing Common.clean_angle_minus_pi_to_pi")
test(0, 0)
test(math.pi, math.pi)
test(-math.pi, math.pi)
test(math.pi/2, math.pi/2)
test(math.pi + math.pi/2, -math.pi/2)
test(3*math.pi + math.pi/2, -math.pi/2)

print("")
print("Testing Common.over_2pi")
local function_to_test = Common.over_2pi
test(0, 0, function_to_test)
test(2 * math.pi, 0, function_to_test)
test(-2 * math.pi, 0, function_to_test)
test(-math.pi / 2, math.pi * 1.5, function_to_test)


print("")
print("Testing Common.from_over_2pi_to_minus_pi_to_pi")
local function_to_test = Common.from_over_2pi_to_minus_pi_to_pi
test(math.pi, math.pi)
test(0, 0)
test(math.pi/2, math.pi/2)
test(math.pi*1.5, -math.pi/2)
test(math.pi * 5 / 4, -math.pi * 3 / 4)
