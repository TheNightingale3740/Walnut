-- WalnutExternal-Headless.lua

include "Build-Walnut-Shared.lua"

-- gmake does not propagate a static library's links, so executables have to name
-- the dependencies themselves. There is no GUI platform here, so spdlog (which
-- Walnut's Log.cpp needs) is the whole list.
HeadlessLibraries = { "spdlog" }

-- Subset of MacOSFrameworkLinkOptions that a headless binary actually needs:
-- GameNetworkingSockets' crypto and cert store. GLFW and MoltenVK account for the
-- rest of the list, and neither is built in this workspace.
MacOSHeadlessFrameworkLinkOptions =
{
   "-framework Security",
   "-framework CoreServices"
}

group "Dependencies"
   -- spdlog is not optional here: Walnut's Log.cpp is part of the headless
   -- platform too, and gmake does not propagate a static library's links.
   include "vendor/yaml-cpp"
   include "Build-Walnut-Spdlog.lua"
group ""

group "Core"
    include "Walnut/Build-Walnut-Headless.lua"

    -- Optional modules
    if os.isfile("Walnut-Modules/Walnut-Networking/Build-Walnut-Networking.lua") then
        include "Walnut-Modules/Walnut-Networking/Build-Walnut-Networking.lua"
    end
group ""
