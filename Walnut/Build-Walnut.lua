project "Walnut"
   kind "StaticLib"
   language "C++"
   cppdialect "C++20"
   targetdir "bin/%{cfg.buildcfg}"

   files
   {
        "Source/**.h",
        "Source/**.cpp",

        "Platform/GUI/**.h",
        "Platform/GUI/**.cpp",
    }

   includedirs
   {
      "Source",
      "Platform/GUI",

      "../vendor/imgui",
      "../vendor/glfw/include",
      "../vendor/stb_image",

      "%{IncludeDir.VulkanSDK}",
      "%{IncludeDir.glm}",
      "%{IncludeDir.spdlog}",
   }

   links
   {
        "ImGui",
        "GLFW",
        "spdlog",

        "%{Library.Vulkan}",
   }

   -- ApplicationGUI.cpp defines GLFW_INCLUDE_NONE before including glfw3.h; keep the
   -- backends from pulling in Cocoa headers, which are not valid C++.
   defines { "GLFW_INCLUDE_NONE", "GLFW_INCLUDE_VULKAN" }

   buildoptions (FmtConstevalWorkaround)

   targetdir ("../../bin/" .. outputdir .. "/%{prj.name}")
   objdir ("../../bin-int/" .. outputdir .. "/%{prj.name}")

   filter "system:windows"
      staticruntime "off"
      systemversion "latest"
      defines { "WL_PLATFORM_WINDOWS" }
      buildoptions { "/utf-8" }

   filter "system:macosx"
      pic "On"
      defines { "WL_PLATFORM_MACOS" }
      libdirs { VulkanPrefixMac .. "/lib" }
      linkoptions (CoreLinkOptions)

      linkoptions (MacOSFrameworkLinkOptions)
      linkoptions { "-Wl,-rpath," .. VulkanPrefixMac .. "/lib" }

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
      defines { "WL_DIST" }
      runtime "Release"
      optimize "On"
      symbols "Off"