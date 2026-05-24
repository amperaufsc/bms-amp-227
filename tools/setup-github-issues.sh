#!/usr/bin/env bash
# =============================================================================
# setup-github-issues.sh
# -----------------------------------------------------------------------------
# Cria as 19 issues iniciais do bms-amp-227 no GitHub via gh CLI.
# Idempotente parcialmente: nao detecta issues ja criadas. Se rodar 2 vezes,
# duplica. Use apenas no setup inicial do repo.
#
# Pre-requisitos:
#   - gh CLI instalado e autenticado (gh auth status OK com scopes
#     'repo, project, read:org, workflow')
#   - Labels e milestones ja criados (ver fases anteriores do setup)
# =============================================================================
set -euo pipefail

REPO="amperaufsc/bms-amp-227"

create_issue() {
  local title="$1"
  local milestone="$2"
  local labels="$3"
  local body="$4"
  local url
  url=$(printf '%s' "$body" | gh issue create -R "$REPO" \
    --title "$title" \
    --body-file - \
    --milestone "$milestone" \
    --label "$labels" 2>&1 | tail -1)
  printf '  %s  %s\n' "$url" "$title"
}

# =============================================================================
echo "=== M1 Bring-up & toolchain ==="
# =============================================================================

create_issue \
  "Refactor CMakeLists.txt: organize sources by module, -Os in Release" \
  "M1 Bring-up & toolchain" \
  "area:tooling,type:refactor,prio:P0,effort:S" \
  "## Objetivo
Limpar o CMakeLists.txt antes de adicionar mais arquivos. Hoje esta como template do CubeIDE com flags fixas; precisa virar algo escalavel.

## To-do
- [ ] Separar add_subdirectory() pra cada bloco (App/, Bsp/, Drivers/, External/)
- [ ] Mover flags pra target_compile_options() em vez de CMAKE_C_FLAGS global
- [ ] Adicionar -Os -ffunction-sections -fdata-sections no build Release (otimiza pra tamanho em MCU)
- [ ] Adicionar -Wl,--print-memory-usage no linker pra ver flash/RAM ocupados ao final do build
- [ ] Adicionar -Wextra -Wshadow -Wdouble-promotion ao -Wall -Werror que ja tem

## Aceitacao
Build dos 4 presets continua passando. Diff de tamanho Release vs Debug mostra otimizacao."

create_issue \
  "Add OpenOCD config + VS Code launch.json for SWD debug" \
  "M1 Bring-up & toolchain" \
  "area:tooling,type:feat,prio:P1,effort:S" \
  "## Objetivo
Habilitar debug via ST-Link/SWD sem depender do CubeIDE. Permite VS Code + gdb-multiarch + OpenOCD.

## To-do
- [ ] tools/openocd/stm32g474.cfg apontando pro chip
- [ ] .vscode/launch.json com configuracao GDB pra OpenOCD localhost:3333
- [ ] .vscode/tasks.json com tarefas Build/Clean/Flash
- [ ] README: secao 'Debugging' com prerequisitos (Cortex-Debug extension)

## Aceitacao
Pressionar F5 no VS Code carrega o ELF, para em main(), permite step-over."

create_issue \
  "Vendor CMSIS device headers (stm32g4xx.h, core_cm4.h, system_stm32g4xx.c)" \
  "M1 Bring-up & toolchain" \
  "area:bsp,type:feat,prio:P0,effort:S" \
  "## Objetivo
Trazer os headers CMSIS necessarios pra acessar registradores do G474 via simbolos (RCC->CR, GPIOA->MODER, etc.) em vez de offsets crus.

## To-do
- [ ] Criar Drivers/CMSIS/Device/ST/STM32G4xx/Include/ com stm32g4xx.h, stm32g474xx.h, system_stm32g4xx.h
- [ ] Criar Drivers/CMSIS/Device/ST/STM32G4xx/Source/system_stm32g4xx.c
- [ ] Criar Drivers/CMSIS/Core/Include/ com core_cm4.h, cmsis_compiler.h, cmsis_gcc.h, mpu_armv7.h e outros
- [ ] Pegar do plugin STM32CubeMX_*/Repository/STM32Cube_FW_G4_V*/Drivers/CMSIS (ou do GitHub STMicroelectronics/cmsis_device_g4)
- [ ] Definir STM32G474xx como compile_definition no CMake
- [ ] Validar: main.c pode incluir stm32g4xx.h e ler SystemCoreClock sem erro

## Aceitacao
Build passa. Sem warnings. SystemCoreClock definido. Target -DSTM32G474xx setado."

create_issue \
  "Implement SystemClock_Config: HSI16 -> PLL -> 170 MHz (Range 1 Boost, 4 WS)" \
  "M1 Bring-up & toolchain" \
  "area:bsp,type:feat,prio:P0,effort:M" \
  "## Objetivo
Subir o SYSCLK pra 170 MHz (max do G474) usando HSI16 + PLL. Sem dependencia de cristal externo.

## Sequencia (RM0440 secoes 6.1.5 + 7.2.4 + 3.3.3)
1. Habilitar PWR clock no RCC_APB1ENR1.PWREN
2. PWR_CR1.VOS = 01 (Range 1)
3. PWR_CR5.R1MODE = 0 (Boost)
4. FLASH_ACR: LATENCY=4 + PRFTEN=1 + ICEN=1 + DCEN=1 (4 wait states pra 170 MHz)
5. Habilitar HSI16 (RCC_CR.HSION), aguardar HSIRDY
6. PLL OFF, configurar RCC_PLLCFGR: PLLSRC=HSI16 (10), PLLM=4 (HSI16/4=4MHz), PLLN=85 (x85=340MHz VCO), PLLR=00 (/2=170MHz), PLLREN=1
7. PLL ON, aguardar PLLRDY
8. AHB prescaler =2 (transiente), switch SW=PLL, aguardar SWS=PLL, AHB prescaler=1
9. APB1 e APB2 prescalers = 1 (max 170 MHz cada)

## To-do
- [ ] Bsp/clock.c: void clock_init_170mhz(void)
- [ ] Atualizar SystemCoreClock global pra 170000000
- [ ] Validar via MCO (output PLLCLK/16 em PA8 = 10.625 MHz) com osciloscopio
- [ ] Validar via SWO timestamp ou GPIO toggle

## Aceitacao
GPIO toggle no main loop bate 170 MHz / N ciclos esperados via osciloscopio ou simulacao."

create_issue \
  "Implement SysTick @ 1 kHz with HAL_GetTick equivalent" \
  "M1 Bring-up & toolchain" \
  "area:bsp,type:feat,prio:P0,effort:S" \
  "## Objetivo
Timebase de 1 ms pra delay/timeout. SysTick e o timer do Cortex-M4, nao precisa periferico ST.

## To-do
- [ ] Bsp/systick.c: systick_init(SystemCoreClock) configura LOAD = 170000-1, CTRL = CLKSOURCE|TICKINT|ENABLE
- [ ] Handler SysTick_Handler incrementa volatile uint32_t g_tick_ms
- [ ] API: uint32_t bsp_get_tick_ms(void), void bsp_delay_ms(uint32_t ms)
- [ ] Adapter pra L9963E_lib: GetTickMs() = bsp_get_tick_ms, DelayMs(d) = bsp_delay_ms(d)
- [ ] Atualizar entry do SysTick_Handler no vector table do startup.s

## Aceitacao
Loop com bsp_delay_ms(500) + GPIO toggle gera periodo de 1 Hz medido."

create_issue \
  "board.h: pinout central definitions" \
  "M1 Bring-up & toolchain" \
  "area:bsp,type:feat,prio:P1,effort:S" \
  "## Objetivo
Centralizar mapping de pinos num unico header. Qualquer mudanca de schematic = uma edicao.

## To-do
- [ ] Bsp/board.h com macros pra cada signal:
  - SPI1 do L9963T (CS, SCK, MOSI, MISO)
  - 5 GPIOs L9963T (TXEN, BNE, ISOFREQ, DIS)
  - FDCAN1 (TX, RX)
  - Heartbeat LED (se houver)
  - Outros (debug UART, etc.)
- [ ] Cada macro define: GPIO_PORT, GPIO_PIN, GPIO_AF (quando aplicavel), e descricao em comentario
- [ ] Adicionar versionamento da revisao da PCB no topo (BOARD_REV = AMP-227 v0.1)

## Aceitacao
include Bsp/board.h em qualquer arquivo da acesso aos pinos. Schematic integrado nesse header (com link/PDF na descricao da PR)."

# =============================================================================
echo ""
echo "=== M2 L9963E driver ==="
# =============================================================================

create_issue \
  "Vendor L9963E_lib in External/" \
  "M2 L9963E driver" \
  "area:driver,type:chore,prio:P0,effort:S" \
  "## Objetivo
Trazer a lib L9963E_lib (Squadra Corse, BEER-WARE) pra dentro do repo de forma versionada.

## Opcoes
- (A) Copia direta pra External/L9963E_lib/ (mais simples, vira parte do repo)
- (B) Git submodule (mais limpo mas atrito em CI/clones)
- (C) Git subtree (meio termo)

## To-do
- [ ] Decidir A/B/C (recomendo A pelo escopo)
- [ ] Adicionar lib em External/L9963E_lib/ (preservando LICENSE e README originais)
- [ ] Atualizar CMakeLists.txt raiz pra add_subdirectory(External/L9963E_lib)
- [ ] Criar External/L9963E_lib/CMakeLists.txt (a lib nao tem CMake nativo) que exporta target INTERFACE com include path inc/ e sources src/L9963E.c src/L9963E_drv.c
- [ ] Aplicar fixes apontados no doc de conhecimento .agents/knowledge/L9963E_lib.md secao 8 (enable_vref, trimming_retrigger, addressing timeout 10ms para 100ms)

## Aceitacao
include L9963E.h compila no main.c. Target L9963E_lib linkavel."

create_issue \
  "Implement stm32_if_g474.c - LL adapter for L9963E_IF callbacks" \
  "M2 L9963E driver" \
  "area:driver,type:feat,prio:P0,effort:M" \
  "## Objetivo
Implementar as 6 callbacks que a L9963E_lib precisa, usando STM32 LL (nao HAL) - mais leve e direto.

## Callbacks a implementar (de L9963E_interface.h)
- L9963E_IF_PinState GPIO_ReadPin(L9963E_IF_PINS pin)
- L9963E_StatusTypeDef GPIO_WritePin(L9963E_IF_PINS pin, L9963E_IF_PinState state)
- L9963E_StatusTypeDef SPI_Receive(uint8_t *data, uint8_t size, uint8_t timeout_ms)
- L9963E_StatusTypeDef SPI_Transmit(uint8_t *data, uint8_t size, uint8_t timeout_ms)
- uint32_t GetTickMs(void)
- void DelayMs(uint32_t delay)

## To-do
- [ ] Bsp/stm32_if_g474.c (substitui o exemplo interface_example/stm32_if.c da lib)
- [ ] Mapeia os 5 pinos lib (CS, TXEN, BNE, ISOFREQ, DIS) pros pinos definidos em Bsp/board.h
- [ ] SPI_Transmit/Receive usam LL_SPI_TransmitData8 + polling de LL_SPI_IsActiveFlag_TXE/RXNE com timeout via SysTick
- [ ] Nao usar HAL_GetTick - usar bsp_get_tick_ms do SysTick implementado

## Aceitacao
Compila. Wrapper L9963E_IfTypeDef iface populavel."

create_issue \
  "LL_SPI init: SPI1 master CPOL=0 CPHA=0 5MHz manual NSS" \
  "M2 L9963E driver" \
  "area:bsp,type:feat,prio:P0,effort:S" \
  "## Objetivo
Configurar SPI1 pra falar com o L9963T (4-wire, CPOL=0/CPHA=0, 5 MHz max).

## Parametros (datasheet L9963E Tab. 14)
- SPI_CR1.MSTR = 1 (master)
- SPI_CR1.CPOL = 0, CPHA = 0
- SPI_CR1.BR = 100 (PCLK2/32 = 170/32 = 5.3 MHz)
- SPI_CR1.LSBFIRST = 0 (MSB-first)
- SPI_CR1.SSM = 1, SSI = 1 (software NSS - CS e manipulado manualmente via GPIO)
- SPI_CR2.DS = 0111 (8-bit data size)
- SPI_CR2.FRXTH = 1 (RXNE threshold 8-bit)

## To-do
- [ ] Bsp/spi_l9963.c: spi_l9963_init(void)
- [ ] Configurar pinos PA5/PA6/PA7 como AF5 (SPI1) - ver board.h
- [ ] Pino CS (PA4 sugerido) como GPIO output push-pull, default HIGH
- [ ] Validar com loopback (MOSI conectado a MISO via fio) antes de plugar L9963T

## Aceitacao
Loopback test: enviar 0x55 e receber 0x55."

create_issue \
  "LL_GPIO init for L9963T (CS, TXEN, BNE, ISOFREQ, DIS)" \
  "M2 L9963E driver" \
  "area:bsp,type:feat,prio:P0,effort:S" \
  "## To-do
- [ ] CS: output push-pull, no-pull, MEDIUM speed, default HIGH
- [ ] TXEN: output push-pull, no-pull, HIGH speed (comuta rapido durante SPI), default HIGH
- [ ] ISOFREQ: output push-pull, no-pull, LOW speed (e DC), default LOW (slow iso-SPI inicial)
- [ ] DIS: output push-pull, no-pull, LOW speed, default LOW (transceiver sleep ate o init)
- [ ] BNE: input com EXTI rising (para usar interrupt depois) ou so input polling (versao inicial)
- [ ] Adicionar definitions pros macros L9963E_DRV_CS_HIGH/LOW etc. do drv.h baterem com nossos pinos via stm32_if.c

## Aceitacao
Toggle de cada pino com osciloscopio na bancada."

create_issue \
  "Bring-up sanity: L9963E_addressing_procedure for N slaves + readback chip_ID" \
  "M2 L9963E driver" \
  "area:driver,type:feat,prio:P0,effort:M,needs-hw" \
  "## Objetivo
Smoke test que prova que o L9963T comunica com pelo menos 1 L9963E e o addressing funciona.

## To-do
- [ ] main.c: init clock + systick + gpio + spi + iface
- [ ] L9963E_init(handle, iface, slave_n=1) (ou N conforme placa)
- [ ] L9963E_DRV_trans_wakeup + DelayMs(2)
- [ ] L9963E_addressing_procedure(handle, iso_freq_sel=0b00, is_dual_ring=0, out_res_tx_iso=0b00, lock_isofreq=1)
- [ ] Loop lendo DEV_GEN_CFG de cada device, validando chip_ID==N e Farthest_Unit==1 no topo
- [ ] Output via SWO ITM ou GPIO toggle padrao Morse pra debug

## Aceitacao
Console (SWO) imprime 'addressing OK, N=X' OU GPIO LED1 acende. Precisa placa com L9963T+L9963E montados.

## Dependencias
Issues anteriores M2 (vendor + adapter + SPI + GPIO init)"

# =============================================================================
echo ""
echo "=== M3 BMS task ==="
# =============================================================================

create_issue \
  "BMS task scheduler: 100 Hz from SysTick, calls bms_acquire()" \
  "M3 BMS task" \
  "area:app,type:feat,prio:P1,effort:M" \
  "## To-do
- [ ] App/bms.c: estado da maquina BMS (idle/sampling/diagnosing/balancing)
- [ ] bms_task_tick() chamado a cada 10 ms via SysTick handler ou main loop com flag
- [ ] Subdivisao: a cada 1 ciclo dispara conversion; a cada 10 ciclos le faults; a cada 100 ciclos dispara BIST
- [ ] Stats: tempo de processamento por ciclo, max jitter

## Aceitacao
Telemetria via SWO mostra 100+-1 Hz consistente."

create_issue \
  "SOC algorithm: Coulomb counting via burst 0x7B" \
  "M3 BMS task" \
  "area:app,type:feat,prio:P2,effort:L,needs-hw" \
  "## Objetivo
Estimar SOC integrando corrente medida. Mais simples que OCV-based ou EKF. Para FSAE basta esta versao.

## To-do
- [ ] Burst 0x7B a cada 10 ciclos pra ler CoulombCounter MSB/LSB + CUR_INST_calib
- [ ] Conversao: V_ISENSE = code * V_ISENSE_RES (datasheet eq. 4); I_CELL = V_ISENSE / R_SHUNT (0.1 mOhm tipico)
- [ ] SOC% = SOC_inicial - integral(I) / Q_nominal * 100
- [ ] Tare quando corrente < 0.5 A por 10 s consecutivos
- [ ] Limites: SOC clampa em [0%, 100%]"

create_issue \
  "Cell balancing logic: manual mode, target Vmin, hysteresis" \
  "M3 BMS task" \
  "area:app,type:feat,prio:P2,effort:M,needs-hw" \
  "## To-do
- [ ] Achar Vmin entre todas as celulas
- [ ] Marcar para balancear: celulas com (V > Vmin + 50 mV)
- [ ] Histerese: descomissiona da lista quando V cai a Vmin + 10 mV
- [ ] Limite: max N celulas balanceando simultaneamente (termica do CI = 200 mA por canal)
- [ ] Pausa balanceamento se corrente de descarga > 5 A (Bal_auto_pause)
- [ ] Escrever registradores BalCell14_7act / BalCell6_1act + Bal_1.bal_start"

create_issue \
  "Fault diagnosis from burst 0x7A: parse each frame and set fault flags" \
  "M3 BMS task" \
  "area:app,type:feat,prio:P1,effort:M" \
  "## To-do
- [ ] Burst 0x7A a cada 10 ciclos (100 ms)
- [ ] Decodificar 13 frames em struct bms_faults_t:
  - VCELLx_UV/OV
  - GPIOx_UT/OT/OPEN
  - BALx_OPEN/SHORT
  - VCOM/VREG/VTREF UV/OV
  - HeartBeat_fault, FaultHline_fault
  - OSCFail, loss_gnd*, CSA overcurrent
- [ ] Categorizar em CRITICAL (abre AIR), WARNING (telemetria), INFO (log)
- [ ] Latch dos faults criticos ate reset explicito"

# =============================================================================
echo ""
echo "=== M4 CAN telemetry ==="
# =============================================================================

create_issue \
  "FDCAN1 init @ 500 kbps classical CAN" \
  "M4 CAN telemetry" \
  "area:can,type:feat,prio:P1,effort:M" \
  "## Objetivo
Subir o FDCAN1 em modo CAN classico (nao FD) a 500 kbps pra integrar com os outros nodes da AMP-227.

## Parametros (RM0440 secao 44 + datasheet J1939)
- Clock source: PLL Q (RCC_CCIPR.FDCANSEL = 01)
- 500 kbps com PCLK = 170 MHz (calc bit timing: SJW, TSEG1, TSEG2)
- Modo: Classical CAN (FDOE=0, BRSE=0)
- Pins: TBD do board.h (sugerido PA12/PA11 = AF9)

## To-do
- [ ] Bsp/fdcan.c: fdcan_init(void)
- [ ] Configurar bit timing
- [ ] Configurar Tx FIFO e Rx FIFO 0
- [ ] Sair de Init mode, verificar TXFQS

## Aceitacao
Loopback interno OK (TEST mode), depois conectar bus fisico."

create_issue \
  "Publish Vmin/Vmax/Tmin/Tmax/Ipack/SOC @ 100 Hz com J1939 IDs" \
  "M4 CAN telemetry" \
  "area:can,type:feat,prio:P1,effort:M,needs-hw" \
  "## To-do
- [ ] Reusar os IDs ja mapeados no projeto da Ampera (ver memoria project_can_bus_architecture)
- [ ] Frame periodico 100 Hz: Vmin (uint16), Vmax (uint16), Tmin (int8), Tmax (int8), Ipack (int16 / 0.1A), SOC (uint8 %)
- [ ] Frame de faults: bitmap das categorias criticas/warning
- [ ] Frame de identificacao: software version, build timestamp, slave_n count

## Aceitacao
Outro node CAN recebe as mensagens e exibe corretamente (validar via CAN analyzer)."

# =============================================================================
echo ""
echo "=== M5 Safety & production ==="
# =============================================================================

create_issue \
  "IWDG @ 100 ms timeout, kicked by BMS task" \
  "M5 Safety & production" \
  "area:safety,type:feat,prio:P1,effort:S" \
  "## To-do
- [ ] Bsp/iwdg.c: configurar IWDG com prescaler /32 (LSI=32 kHz -> 1 ms tick), RLR=100 -> timeout 100 ms
- [ ] Chamar iwdg_kick() ao fim de cada iteracao da BMS task (que roda a 100 Hz)
- [ ] Se watchdog reset: Faults1.HeartBeat_fault deve ser 0 (chip nao foi resetado), mas RCC_CSR.IWDGRSTF=1 - capturar e logar
- [ ] Validar: forcar travamento (while(1)) em codigo e ver MCU resetar em ~100 ms"

create_issue \
  "Contactor state machine: precharge -> closed -> open on fault" \
  "M5 Safety & production" \
  "area:safety,type:feat,prio:P0,effort:L,needs-hw" \
  "## Estados
1. SAFE (default ao boot): AIR+ open, AIR- open, precharge open
2. PRECHARGE: AIR- closed, precharge closed (controla rampa de inrush)
3. RUN: AIR+ closed, precharge open
4. FAULT: tudo open + latch

## Transicoes
- SAFE -> PRECHARGE: comando externo do VCU via CAN, e nenhum fault critico
- PRECHARGE -> RUN: V_bus > 95% V_pack (medido pelo BMS via L9963E VBATT_MONITOR)
- ANY -> FAULT: qualquer fault critico (OV/UV celula, OT celula, OC, comm_timeout)

## To-do
- [ ] App/contactor.c com contactor_sm_step() chamado pela BMS task
- [ ] GPIOs para drive dos contactors (board.h)
- [ ] Timer pra precharge timeout (sugerido 2 s - se nao chegar a 95% nesse tempo, FAULT)
- [ ] Estado publicado via CAN (campo no frame de status)

## Aceitacao
Bench test: comandar precharge, observar transicao RUN, forcar UV e ver FAULT + AIRs abertas."

echo ""
echo "=============================================================="
echo "DONE. Listing all issues:"
echo "=============================================================="
gh issue list -R "$REPO" --limit 30
