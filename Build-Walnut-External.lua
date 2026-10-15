-- WalnutExternal.lua

include "Build-Walnut-Shared.lua"

group "Dependencies"
   include "vendor/imgui"
   include "vendor/glfw"
   include "vendor/yaml-cpp"
   include "Build-Walnut-Spdlog.lua"
group ""

group "Core"
    include "Walnut/Build-Walnut.lua"

    -- Optional modules
    if os.isfile("Walnut-Modules/Walnut-Networking/Build-Walnut-Networking.lua") then
        include "Walnut-Modules/Walnut-Networking/Build-Walnut-Networking.lua"
    end
group ""