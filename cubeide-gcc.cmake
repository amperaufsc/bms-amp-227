# CMake toolchain definition for STM32CubeIDE bundled GNU Tools for STM32
#
# Aponta para o toolchain ARM, make e ninja que já vêm dentro do STM32CubeIDE
# (plugins Eclipse). Não precisa instalar nada externo.
#
# Se o CubeIDE atualizar e mudar o número de versão do plugin, basta atualizar
# as três variáveis CUBEIDE_*_PLUGIN abaixo.

set(CMAKE_SYSTEM_PROCESSOR "arm" CACHE STRING "")
set(CMAKE_SYSTEM_NAME "Generic" CACHE STRING "")

# Skip link step during toolchain validation.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# ---------------------------------------------------------------------------
# Localização do STM32CubeIDE e seus plugins de toolchain
# ---------------------------------------------------------------------------
set(CUBEIDE_ROOT "C:/ST/STM32CubeIDE_1.18.1/STM32CubeIDE/plugins")

set(CUBEIDE_GCC_PLUGIN
    "com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.13.3.rel1.win32_1.0.100.202509120712")
set(CUBEIDE_MAKE_PLUGIN
    "com.st.stm32cube.ide.mcu.externaltools.make.win32_2.2.0.202409170845")
set(CUBEIDE_NINJA_PLUGIN
    "com.st.stm32cube.ide.mcu.externaltools.ninja.win32_1.1.0.202511131536")

set(TOOLCHAIN_BIN  "${CUBEIDE_ROOT}/${CUBEIDE_GCC_PLUGIN}/tools/bin")
set(MAKE_BIN       "${CUBEIDE_ROOT}/${CUBEIDE_MAKE_PLUGIN}/tools/bin")
set(NINJA_BIN      "${CUBEIDE_ROOT}/${CUBEIDE_NINJA_PLUGIN}/tools/bin")

# ---------------------------------------------------------------------------
# Ferramentas (paths absolutos — não dependem de PATH do usuário)
# ---------------------------------------------------------------------------
set(TOOLCHAIN_PREFIX   "arm-none-eabi-")

set(CMAKE_C_COMPILER   "${TOOLCHAIN_BIN}/${TOOLCHAIN_PREFIX}gcc.exe")
set(CMAKE_ASM_COMPILER "${TOOLCHAIN_BIN}/${TOOLCHAIN_PREFIX}gcc.exe")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_BIN}/${TOOLCHAIN_PREFIX}g++.exe")
set(CMAKE_AR           "${TOOLCHAIN_BIN}/${TOOLCHAIN_PREFIX}ar.exe")
set(CMAKE_LINKER       "${TOOLCHAIN_BIN}/${TOOLCHAIN_PREFIX}ld.exe")
set(CMAKE_OBJCOPY      "${TOOLCHAIN_BIN}/${TOOLCHAIN_PREFIX}objcopy.exe")
set(CMAKE_OBJDUMP      "${TOOLCHAIN_BIN}/${TOOLCHAIN_PREFIX}objdump.exe")
set(CMAKE_RANLIB       "${TOOLCHAIN_BIN}/${TOOLCHAIN_PREFIX}ranlib.exe")
set(CMAKE_SIZE         "${TOOLCHAIN_BIN}/${TOOLCHAIN_PREFIX}size.exe")
set(CMAKE_STRIP        "${TOOLCHAIN_BIN}/${TOOLCHAIN_PREFIX}strip.exe")
set(CMAKE_GDB          "${TOOLCHAIN_BIN}/${TOOLCHAIN_PREFIX}gdb.exe")

# Build tool: o CMake escolhe entre make e ninja conforme o generator
# (-G "Unix Makefiles" usa make; -G "Ninja" usa ninja). Para evitar depender
# do PATH, indicamos ambos via CMAKE_MAKE_PROGRAM no script de invocação.
set(CUBEIDE_MAKE_EXE  "${MAKE_BIN}/make.exe"  CACHE FILEPATH "")
set(CUBEIDE_NINJA_EXE "${NINJA_BIN}/ninja.exe" CACHE FILEPATH "")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
