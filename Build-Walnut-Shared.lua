-- Build-Walnut-Shared.lua
--
-- Definitions shared by the GUI and headless workspaces (and by application
-- workspaces that include either of them). Anything naming a path under
-- vendor/ is written relative to Walnut/Walnut/, which is where the projects
-- consuming them are declared.

VULKAN_SDK = os.getenv("VULKAN_SDK")

-- LunarG's macOS SDK installs headers and libvulkan.dylib directly into the prefix
-- (rather than into Include/ and Lib/ subdirectories like the Windows SDK), and
-- registers MoltenVK as a portability driver ICD.
VulkanPrefixMac = os.isdir("/usr/local/include/vulkan") and "/usr/local" or "/opt/homebrew"

IncludeDir = {}
IncludeDir["glm"] = "../vendor/glm"
IncludeDir["spdlog"] = "../vendor/spdlog/include"

LibraryDir = {}
Library = {}

if os.target() == "macosx" then
   IncludeDir["VulkanSDK"] = VulkanPrefixMac .. "/include"
   LibraryDir["VulkanSDK"] = VulkanPrefixMac .. "/lib"
   Library["Vulkan"] = "vulkan"
else
   IncludeDir["VulkanSDK"] = "%{VULKAN_SDK}/Include"
   LibraryDir["VulkanSDK"] = "%{VULKAN_SDK}/Lib"
   Library["Vulkan"] = "%{LibraryDir.VulkanSDK}/vulkan-1.lib"
end

-- Every project that links against Walnut needs the full set: premake's gmake
-- action does not propagate a static library's own `links` to the projects that
-- depend on it, so executables have to name them explicitly.
CoreLibraries =
{
   "ImGui",
   "GLFW",
   "spdlog"
}

if os.target() == "macosx" then
   -- Two Vulkan loaders can be installed at once (the LunarG SDK under /usr/local
   -- and Homebrew's under /opt/homebrew), and "-lvulkan" resolves to whichever
   -- lands first on the search path. Mixing them with Homebrew's MoltenVK makes
   -- the instance come up without VK_EXT_metal_surface, so pin the SDK copy by
   -- absolute path instead. premake rewrites `links` entries into "-l<name>", so
   -- this has to travel as a raw link option.
   CoreLinkOptions = { VulkanPrefixMac .. "/lib/libvulkan.dylib" }
else
   table.insert(CoreLibraries, "%{Library.Vulkan}")
   CoreLinkOptions = {}
end

-- Homebrew prefix for the third-party libraries GameNetworkingSockets needs.
HomebrewPrefix = os.isfile("/opt/homebrew/bin/brew") and "/opt/homebrew" or "/usr/local"
OpenSSLPrefix = HomebrewPrefix .. "/opt/openssl@3"

-- GameNetworkingSockets' static archive needs protobuf at link time. Homebrew's
-- protobuf links abseil, and the two-level namespace resolves those symbols
-- transitively, so only protobuf itself has to be named.
MacOSNetworkLibraries = { "protobuf", "crypto" }

-- premake5 beta8 has no `frameworks` API, and it rewrites `links` entries into
-- `-l<name>`, which the macOS linker rejects. System frameworks therefore have to
-- travel as raw link options. Security/CoreServices are needed by
-- GameNetworkingSockets; the rest by GLFW and MoltenVK.
MacOSFrameworkLinkOptions =
{
   "-framework Cocoa",
   "-framework IOKit",
   "-framework CoreVideo",
   "-framework CoreGraphics",
   "-framework CoreFoundation",
   "-framework OpenGL",
   "-framework UniformTypeIdentifiers",
   "-framework QuartzCore",
   "-framework Metal",
   "-framework MetalKit",
   "-framework Security",
   "-framework CoreServices"
}

-- spdlog 1.15 vendors fmt 10.x. On Apple clang 21 its base.h feature-detects
-- consteval support (FMT_USE_CONSTEVAL 1) and the library then fails to
-- constant-evaluate its own FMT_STRING()/compile_string expressions, producing
-- "call to consteval function ... is not a constant expression".
--
-- FMT_USE_CONSTEVAL cannot simply be pre-defined, because base.h redefines it
-- unconditionally. The only knob it honours is FMT_GLIBCXX_RELEASE, which forces
-- the value to 0 when it is non-zero and below 10. libc++ never reads
-- _GLIBCXX_RELEASE, so lying about it is inert outside fmt.
FmtConstevalWorkaround = { "-D_GLIBCXX_RELEASE=8" }

-- The GameNetworkingSockets macOS archive is built from source by
-- Walnut-Modules/Walnut-Networking/Build-GameNetworkingSockets.sh, which
-- compiles it for the host architecture. Passing "x64" on the workspace would
-- make the linker reject that archive on Apple Silicon, so nothing outside of
-- the Windows/Linux filters below pins an architecture on Apple platforms.
--
-- Resolved against this file's own directory rather than left relative: every
-- consumer sits at a different depth (Walnut/WalnutApp, Walnut-Modules/
-- Walnut-Networking, or an application workspace in a project that vendors
-- Walnut as a submodule), and premake resolves relative libdirs against the
-- directory of the script that declared the project, not the one that defined
-- the variable.
WalnutDir = path.getdirectory(_SCRIPT)
NetworkingBinDir = path.getabsolute("Walnut-Modules/Walnut-Networking/vendor/GameNetworkingSockets/bin", WalnutDir)

MacOSNetworkLibDirs =
{
   NetworkingBinDir .. "/MacOS",
   HomebrewPrefix .. "/lib",
   OpenSSLPrefix .. "/lib"
}

MacOSNetworkLinkOptions =
{
   "-Wl,-rpath," .. HomebrewPrefix .. "/lib",
   "-Wl,-rpath," .. OpenSSLPrefix .. "/lib"
}
