-- premake5.lua
--
-- spdlog has no premake script of its own, so Walnut builds the subset it needs
-- as a static library here (premake pulls in the vendored premake5.lua of every
-- other third-party dependency, but spdlog ships none).

project "spdlog"
   kind "StaticLib"
   language "C++"
   cppdialect "C++20"

   targetdir ("bin/" .. outputdir .. "/%{prj.name}")
   objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

   files
   {
      "vendor/spdlog/include/spdlog/*.h",
      "vendor/spdlog/src/spdlog.cpp",
      "vendor/spdlog/src/stdout_sinks.cpp",
      "vendor/spdlog/src/color_sinks.cpp",
      "vendor/spdlog/src/file_sinks.cpp",
      "vendor/spdlog/src/cfg.cpp",
      "vendor/spdlog/src/async.cpp",
      -- spdlog vendors fmt 10.x; without this translation unit the format
      -- symbols are unresolved at link time.
      "vendor/spdlog/src/bundled_fmtlib_format.cpp"
   }

   includedirs
   {
      "vendor/spdlog/include"
   }

   -- Links against the compiled (rather than header-only) spdlog API.
   defines { "SPDLOG_COMPILED_LIB" }

   -- See FmtConstevalWorkaround in Build-Walnut-External.lua.
   buildoptions (FmtConstevalWorkaround)

   filter "system:windows"
      staticruntime "off"
      systemversion "latest"
      cppdialect "C++17"

   filter "system:linux"
      staticruntime "off"
      pic "On"
      cppdialect "C++17"

   filter "configurations:Debug"
      runtime "Debug"
      symbols "on"

   filter "configurations:Release"
      runtime "Release"
      optimize "on"

   filter "configurations:Dist"
      runtime "Release"
      optimize "on"
      symbols "off"