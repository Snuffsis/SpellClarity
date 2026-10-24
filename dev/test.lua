local count = 0
assert(loadfile("dev/spellclarity_test.lua"))(function(message)
 count = count + 1
 print("PASS " .. message)
end)
print(count .. " standalone scenarios passed")
