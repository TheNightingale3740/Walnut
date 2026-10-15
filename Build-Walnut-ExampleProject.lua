-- premake5.lua
workspace "WalnutApp"
   configurations { "Debug", "Release", "Dist" }
   startproject "WalnutApp"

   -- Workspace-wide build options for MSVC
   filter "system:windows"
      architecture "x64"
      buildoptions { "/EHsc", "/Zc:preprocessor", "/Zc:__cplusplus" }

   filter "system:linux"
      architecture "x64"

   -- Build for whatever Mac this is running on, so the app is a native arm64
   -- binary rather than one that needs Rosetta (and a MoltenVK that isn't).
   filter "system:macosx"
      architecture (os.hostarch():lower())

outputdir = "%{cfg.buildcfg}-%{cfg.system}-%{cfg.architecture}"

include "Build-Walnut-External.lua"
include "WalnutApp/Build-Walnut-App.lua"