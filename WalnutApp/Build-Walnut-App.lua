project "WalnutApp"
   kind "ConsoleApp"
   language "C++"
   cppdialect "C++20"
   targetdir "bin/%{cfg.buildcfg}"

   files { "src/**.h", "src/**.cpp" }

   includedirs
   {
      "../vendor/imgui",
      "../vendor/glfw/include",

      "../Walnut/Source",
      "../Walnut/Platform/GUI",

      "%{IncludeDir.VulkanSDK}",
      "%{IncludeDir.glm}",
   }

    links
    {
        "Walnut"
    }

    buildoptions (FmtConstevalWorkaround)

   targetdir ("../bin/" .. outputdir .. "/%{prj.name}")
   objdir ("../bin-int/" .. outputdir .. "/%{prj.name}")

   filter "system:windows"
      staticruntime "off"
      systemversion "latest"
      defines { "WL_PLATFORM_WINDOWS" }
      buildoptions { "/utf-8" }

filter "system:macosx"
      pic "On"
      defines { "WL_PLATFORM_MACOS" }
      -- gmake does not propagate a static library's links, so repeat them here.
      links (CoreLibraries)

      -- ...same for the optional Walnut-Networking module, which is pulled in when
      -- the submodule is present. See Walnut-Modules/Walnut-Networking/Build-Walnut-Networking.lua.
      libdirs
      {
         "../Walnut-Modules/Walnut-Networking/vendor/GameNetworkingSockets/bin/MacOS"
      }
      links { "GameNetworkingSockets_s" }
      links (MacOSNetworkLibraries)

      libdirs
      {
         HomebrewPrefix .. "/lib",
         OpenSSLPrefix .. "/lib"
      }
      linkoptions (CoreLinkOptions)

      linkoptions (MacOSFrameworkLinkOptions)
      linkoptions
      {
         "-Wl,-rpath," .. VulkanPrefixMac .. "/lib",
         "-Wl,-rpath," .. HomebrewPrefix .. "/lib",
         "-Wl,-rpath," .. OpenSSLPrefix .. "/lib"
      }

   filter "configurations:Debug"
      defines { "WL_DEBUG" }
      runtime "Debug"
      symbols "On"

   filter "configurations:Release"
      defines { "WL_RELEASE" }
      runtime "Release"
      optimize "On"
      symbols "On"

   filter "configurations:Dist"
      kind "WindowedApp"
      defines { "WL_DIST" }
      runtime "Release"
      optimize "On"
      symbols "Off"