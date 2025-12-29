import Lake
open Lake DSL
open System (FilePath)

package assimptor where
  version := v!"0.1.0"

-- Assimp link arguments (system assimp from Homebrew)
def assimpLinkArgs : Array String := #[
  "-L/opt/homebrew/lib",
  "-L/usr/local/lib",
  "-lassimp",
  "-lz",
  "-lc++"
]

@[default_target]
lean_lib Assimptor where
  roots := #[`Assimptor]
  moreLinkArgs := assimpLinkArgs

-- Assimp loader (C++ code for 3D model loading)
-- Uses system assimp from Homebrew: brew install assimp
target assimp_loader_o pkg : FilePath := do
  let oFile := pkg.buildDir / "native" / "assimp_loader.o"
  let srcFile := pkg.dir / "native" / "src" / "common" / "assimp_loader.cpp"
  let includeDir := pkg.dir / "native" / "include"
  buildO oFile (← inputTextFile srcFile) #[
    "-I", includeDir.toString,
    "-I/opt/homebrew/include",  -- Apple Silicon Homebrew
    "-I/usr/local/include",      -- Intel Homebrew fallback
    "-std=c++17",
    "-fPIC",
    "-O2"
  ] #[] "clang++"

-- Lean bridge for asset loading
target lean_bridge_o pkg : FilePath := do
  let oFile := pkg.buildDir / "native" / "lean_bridge.o"
  let srcFile := pkg.dir / "native" / "src" / "lean_bridge.c"
  let includeDir := pkg.dir / "native" / "include"
  let leanIncludeDir ← getLeanIncludeDir
  buildO oFile (← inputTextFile srcFile) #[
    "-I", leanIncludeDir.toString,
    "-I", includeDir.toString,
    "-fPIC",
    "-O2"
  ] #[] "cc"

extern_lib assimptor_native pkg := do
  let name := nameToStaticLib "assimptor_native"
  let loaderO ← assimp_loader_o.fetch
  let bridgeO ← lean_bridge_o.fetch
  buildStaticLib (pkg.staticLibDir / name) #[loaderO, bridgeO]
