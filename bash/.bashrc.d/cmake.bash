# CMake defaults for every NEW build directory (CMake reads these environment
# variables at configure time). An existing build dir keeps what is already in
# its CMakeCache.txt, so old Makefile builds are not affected.
# Only applies to cmake run from a shell; IDEs started from the desktop
# (e.g. Qt Creator) do not read ~/.bashrc.

export CMAKE_GENERATOR=Ninja              # CMake >= 3.15
export CMAKE_EXPORT_COMPILE_COMMANDS=ON   # CMake >= 3.17; clangd finds build/compile_commands.json

# Compiler cache for C, C++ and nvcc (CMake >= 3.17). Check hits with: ccache -s
if command -v ccache >/dev/null; then
  export CMAKE_C_COMPILER_LAUNCHER=ccache
  export CMAKE_CXX_COMPILER_LAUNCHER=ccache
  export CMAKE_CUDA_COMPILER_LAUNCHER=ccache
fi
