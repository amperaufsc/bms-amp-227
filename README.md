# bms-amp-227

> Battery Management System firmware do prototipo **AMP-227** (temporada 2027) da **Ampera Racing UFSC**.

Firmware em C bare-metal para um STM32G474RE (Cortex-M4F, 170 MHz, LQFP64) que faz interface com um stack de **ST L9963E** (Multicell BMIC) atraves do transceiver **L9963T**, lendo tensoes/temperaturas de cada celula do pack e publicando telemetria via **FDCAN**.

## Stack

| Camada | Tecnologia |
|---|---|
| MCU | STM32G474RE @ 170 MHz |
| BMS IC | ST L9963E + L9963T (daisy-chain, iso-SPI 2.66 Mbps) |
| Driver L9963E | [`squadracorsepolito/L9963E_lib`](https://github.com/squadracorsepolito/L9963E_lib) (BEER-WARE) |
| Toolchain | `arm-none-eabi-gcc` 13.3.1 (GNU Tools for STM32, embarcada no STM32CubeIDE 1.18.1) |
| Build | CMake 3.25+ via `CMakePresets.json` |
| Build tool | `make` ou `ninja` (do CubeIDE) |

## Pre-requisitos

- **STM32CubeIDE 1.18.1** instalado em `C:\ST\STM32CubeIDE_1.18.1\` (traz a toolchain, make e ninja).
- **CMake 3.25+** (`cmake --version`).
- **VS Code** com extensao [CMake Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cmake-tools) **OU** STM32CubeIDE (importar como existing CMake project).

> Caso o numero de versao do plugin de toolchain do CubeIDE mude no seu PC, atualizar as variaveis `CUBEIDE_*_PLUGIN` em [`cubeide-gcc.cmake`](cubeide-gcc.cmake) e `CMAKE_MAKE_PROGRAM` em [`CMakePresets.json`](CMakePresets.json).

## Build

```powershell
# Configure (uma vez ou quando mexer no CMakeLists)
cmake --preset Debug

# Build (rotina)
cmake --build --preset Debug
```

Presets disponiveis: `Debug`, `Release`, `Debug-Ninja`, `Release-Ninja`. Cada um gera em sua propria pasta de build (`Debug/`, `Release/`, etc., gitignoradas).

O binario `bms-amp-227.elf` sai em `Debug/` (ou na pasta do preset correspondente).

## Estrutura

```
bms-amp-227/
+- CMakeLists.txt           # configuracao do build
+- CMakePresets.json        # presets Debug/Release × Make/Ninja
+- cubeide-gcc.cmake        # toolchain file (paths absolutos do CubeIDE)
+- STM32G474RETX_FLASH.ld   # linker script (gerado pelo CubeIDE)
+- Startup/
|  +- startup_stm32g474retx.s  # vector table e startup ASM
+- Sources/
|  +- main.c
|  +- syscalls.c
|  +- sysmem.c
+- (TBD) App/               # logica de aplicacao (bms.c, faults.c, can_bms.c)
+- (TBD) Bsp/               # board support: clock, gpio, spi, board.h
+- (TBD) Drivers/           # CMSIS + LL drivers necessarios
+- (TBD) External/          # bibliotecas vendored (L9963E_lib)
```

## Status

Em bring-up. Veja [Issues](https://github.com/amperaufsc/bms-amp-227/issues) e [Project board](https://github.com/orgs/amperaufsc/projects) pro estado atual.

## Licenca

A definir pela diretoria da Ampera Racing UFSC.
