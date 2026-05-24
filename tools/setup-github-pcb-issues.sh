#!/usr/bin/env bash
# =============================================================================
# setup-github-pcb-issues.sh
# -----------------------------------------------------------------------------
# Cria as 15 issues de PCB design (M0) do bms-amp-227, em Altium Designer.
# Pre-requisitos: label area:pcb e milestone "M0 PCB Design" ja criados.
# Idempotente parcialmente (nao detecta duplicatas).
# =============================================================================
set -euo pipefail

REPO="amperaufsc/bms-amp-227"
MILESTONE="M0 PCB Design"

# Garantir label type:docs (usado por algumas issues PCB)
gh label create "type:docs" -R "$REPO" -d "Documentacao tecnica" -c "0075CA" --force >/dev/null 2>&1 || true

create_issue() {
  local title="$1"
  local labels="$2"
  local body="$3"
  local url
  url=$(printf '%s' "$body" | gh issue create -R "$REPO" \
    --title "$title" \
    --body-file - \
    --milestone "$MILESTONE" \
    --label "$labels" \
    --assignee guilettmann 2>&1 | tail -1)
  printf '  %s  %s\n' "$url" "$title"
}

# =============================================================================
echo "=== Setup (3 issues) ==="
# =============================================================================

create_issue \
  "[pcb-setup] Setup Altium project (PrjPcb, libraries, templates)" \
  "area:pcb,type:chore,prio:P0,effort:S" \
  "## Objetivo
Criar a estrutura base do projeto Altium em hw/pcb/ com bibliotecas e templates compartilhados com outros projetos da Ampera.

## To-do
- [ ] Criar hw/pcb/AMP-227-BMS.PrjPcb
- [ ] Adicionar SchLib e PcbLib base (componentes recorrentes: STM32, resistor/capacitor padrao, conectores Molex/JST usados pela equipe)
- [ ] Setar parametros do projeto: title block com BOARD_REV, autor, data, hierarquia de folhas
- [ ] Setar Schematic Sheet template (A3 paisagem) com logo Ampera + titulo+versao em rodape
- [ ] Configurar Output Job (.OutJob) base apontando pros formatos: gerbers RS-274X, drill Excellon, PDF schematic, BOM CSV
- [ ] Salvar .DsnWrk (workspace) com todos os arquivos abertos pro proximo dev abrir 1-clique

## Aceitacao
Outro membro da equipe consegue abrir o projeto e ver schematic + PCB libraries carregadas sem erro de path."

create_issue \
  "[pcb-setup] Definir requisitos eletricos e conv. de design" \
  "area:pcb,type:docs,prio:P0,effort:S" \
  "## Objetivo
Documento curto que outras issues PCB referenciam quando precisam saber 'qual a tensao do shunt?', 'qual o pinout do conector?', etc.

## Conteudo de hw/docs/AMP-227-design-requirements.md
- [ ] **Pack eletrico**: numero de celulas em serie, paralelo, modelo (Molicel P28A), Q_nominal, V_min/V_max
- [ ] **Topologia BMS**: N L9963E em daisy chain, qual o pino TOP/BOTTOM, isolamento
- [ ] **Supplies**: HV bus (V_pack), supply LV externo (12 V auxiliar?), supply LV interno (3.3 V regulado da propria PCB ou externo?)
- [ ] **Correntes esperadas**: pack nominal (50 A?), pico (200 A?), shunt R_SHUNT valor + dissipacao
- [ ] **Comunicacao**: FDCAN ao VCU e demais nodes (baud rate, ID base, terminadores)
- [ ] **Contactors**: numero (AIR+, AIR-, precharge), drive level (12 V ou nivel logico), feedback (NO+NC ou so NO?)
- [ ] **Sensores**: numero de NTCs no pack, modelo (MF52/NTC5D-13/...), localizacao
- [ ] **Conectores externos**: pinout HV (Anderson SB50?), pinout LV (header DIN ou Molex Microfit?), debug (Tag-Connect TC2050?)
- [ ] **Refdes conv**: R1xx capacitores de bypass MCU, R2xx resistores divisores celula, etc.
- [ ] **Naming nets**: VDD33, VBAT, ISENSEp/ISENSEm, CELLn, NTCn, etc.

## Aceitacao
Documento checado por outro engenheiro da Ampera + revisado pela diretoria de PWT."

create_issue \
  "[pcb-setup] Configurar Git LFS para binarios do Altium" \
  "area:pcb,area:tooling,type:chore,prio:P0,effort:S" \
  "## Objetivo
Altium files (.SchDoc, .PcbDoc, .SchLib, .PcbLib) sao binarios. Sem Git LFS o repo incha rapido e clones ficam lentos.

## To-do
- [ ] Instalar Git LFS local (\`git lfs install\`) - documentar no README
- [ ] Atualizar .gitattributes ja existente com regras LFS pra extensoes Altium
- [ ] Atualizar .gitignore: ignorar History/, Project Outputs for *, *.bak, *~, *.PrjPcbStructure (Altium gera lixo)
- [ ] Validar: commitar 1 .SchDoc fake, ver no GitHub que aparece como 'Stored with Git LFS'
- [ ] Cada novo dev precisa rodar 'git lfs install' antes de clonar

## Aceitacao
git lfs ls-files mostra todos os arquivos Altium como LFS-tracked."

# =============================================================================
echo ""
echo "=== Schematic (5 issues) ==="
# =============================================================================

create_issue \
  "[pcb-sch] Esquematico: power supply (HV -> 12V -> 3.3V) + protecoes" \
  "area:pcb,type:feat,prio:P0,effort:L" \
  "## Objetivo
Alimentar o MCU + comm + sensores a partir do pack HV (ou supply LV auxiliar do carro).

## Topologia sugerida (a confirmar nos design requirements)
- HV pack (cells * N) -> regulador isolado 12 V (ex: TEN 3-2412 ou similar - PMP fabrica?)
- 12 V -> buck 5 V (TPS54336 ou similar) -> LDO 3.3 V (LD39100 ou LP5907) com low-noise pro VDDA
- Alternativa: alimentar 12 V externo (do carro) e nao depender do pack

## To-do
- [ ] Folha hw/pcb/AMP-227-BMS-power.SchDoc
- [ ] TVS no input HV (clamp 60 V?), fusivel reset-able ou substituivel
- [ ] Reverse polarity protection (P-MOSFET ideal diode)
- [ ] Inrush limiter (NTC pra startup)
- [ ] Bypass capacitor caps perto de cada regulador (10 uF tantalum + 100 nF ceramico)
- [ ] Power-good signaling pro MCU (input do PWR_OK)
- [ ] Output VDDA filtrado (ferrite bead + 1 uF) pra ADC
- [ ] Test points em VDD33, VDD12, VDDA, GND

## Aceitacao
SPICE simulation passa pra step load 0 -> 500 mA com undershoot < 100 mV. Schematic review por mentor PWT."

create_issue \
  "[pcb-sch] Esquematico: STM32G474RE breakout + SWD + boot/reset" \
  "area:pcb,type:feat,prio:P0,effort:M" \
  "## Objetivo
Conectar o STM32G474RE LQFP64 com tudo que ele precisa pra ligar: power, decoupling, oscilador, programacao.

## To-do
- [ ] Folha hw/pcb/AMP-227-BMS-mcu.SchDoc
- [ ] Decoupling: 100 nF por pino VDD + 1 uF total no power tree do MCU
- [ ] VDDA separado (ferrite + caps) com VREF+ tied to VDDA via 100 ohm (datasheet recomenda)
- [ ] HSE: cristal 8 ou 16 MHz com load caps (opcional; HSI16 default no firmware - mas footprint pra crystal e bom ter)
- [ ] LSE: cristal 32.768 kHz se for usar RTC (opcional)
- [ ] BOOT0 pulldown 10k + jumper opcional pra forcar bootloader USART
- [ ] NRST com pull-up 10k + button momentaneo + cap 100 nF antibounce
- [ ] SWD header: 4 pinos (SWDIO, SWCLK, GND, VDD) - Tag-Connect TC2050 footprint
- [ ] Pinout reservado pra: SPI1 (L9963T), FDCAN1, UART debug, GPIO heartbeat LED, GPIO contactor drives

## Aceitacao
Schematic review. DFM check: footprint TQFP64 conferido (pitch 0.5 mm, body 10x10 mm)."

create_issue \
  "[pcb-sch] Esquematico: BMS frontend (L9963T + L9963E daisy chain + isolation)" \
  "area:pcb,type:feat,prio:P0,effort:L" \
  "## Objetivo
Coracao do BMS. Daisy chain L9963E com isolation transformers ate o L9963T do lado do MCU.

## Referencia
Figura 1 do datasheet L9963E (Typical application) - copiar a topologia.

## To-do
- [ ] Folha hw/pcb/AMP-227-BMS-frontend.SchDoc
- [ ] L9963T (lado MCU): pinout completo, decoupling 100 nF em cada Vxx
- [ ] L9963E (cada slave, N copias dependendo do pack): C0..C14, S0..S14, B0..B14, ISENSE+/-, VBAT, VCOM, VREG, VTREF
- [ ] Isolation transformers (1 entre L9963T-L9963E #1, 1 entre cada L9963E adjacente). Datasheet sugere TRANSF Coilcraft LPD8035V ou similar
- [ ] Cap-based isolation alternative documentada (so se XFMR nao disponivel)
- [ ] RC LPF em cada Sn/Cn (RLPF=4 kOhm + CLPF=100 nF tipico - datasheet Tab. 39)
- [ ] ESD diodes em cada celula sense input
- [ ] FAULTH/FAULTL optocoupler com pullup/pulldown corretos
- [ ] Resistor of bottom of stack (~10 ohm RTERM apos isolation)

## Aceitacao
Schematic review por mentor + simulacao isolation barrier OK (sem dc path entre celulas e GND_LV)."

create_issue \
  "[pcb-sch] Esquematico: celula sensing + NTC + ISENSE shunt" \
  "area:pcb,type:feat,prio:P0,effort:M" \
  "## Objetivo
Sense de cada celula (entrada dos pinos Cn/Sn/Bn do L9963E) e dos NTCs e do shunt de corrente.

## To-do
- [ ] Continuacao da folha frontend ou nova folha hw/pcb/AMP-227-BMS-sensing.SchDoc
- [ ] Conector para cabo de sensing das celulas (Molex Mini-Fit Jr ou similar, com codificacao)
- [ ] Cada linha Cn: fuse pico (PTC ou eletronico) + RLPF + CLPF + Zener clamp (opcional, pra protecao reverse)
- [ ] NTCs: tipicamente 7 por L9963E (GPIO3..9). Divisor com RNTC (pulldown) + RVTREF (pullup, valor depende do NTC modelo)
- [ ] NTC modelo: documentar no design requirements (MF52, NTC5D-13, etc.) + curva resistencia/temperatura
- [ ] ISENSE shunt: R_SHUNT 0.1 mOhm 5W (Welwyn LR2725 ou Vishay WSR3) com kelvin sensing
- [ ] ISENSE+/- de volta ao L9963E: RC filter (R = 10 ohm, C = 1 uF) + ESD

## Aceitacao
Schematic review. Calculo de dissipacao no shunt @ 200 A pico (200**2 * 0.0001 = 4 W -> shunt 5 W OK)."

create_issue \
  "[pcb-sch] Esquematico: FDCAN PHY + contactor drivers + indicadores" \
  "area:pcb,type:feat,prio:P0,effort:M" \
  "## Objetivo
Tudo que nao e core BMS mas a placa precisa: CAN ao VCU, drive dos contactors, LEDs.

## To-do
- [ ] Folha hw/pcb/AMP-227-BMS-io.SchDoc
- [ ] FDCAN PHY: TJA1051TK ou TCAN334 (sleep mode util pra wake-up do bus). Common-mode choke 100 ohm. Terminadores 120 ohm com jumper (so 2 dos N nodes terminam). ESD pro DB9/M12 conector
- [ ] Contactor drivers (AIR+, AIR-, precharge): N-MOSFET low-side com flyback diode + RC snubber. Drive de 12 V vindo do regulador. Feedback NO+NC pro MCU pra confirmar estado
- [ ] LEDs: 1 heartbeat (verde piscando), 1 fault (vermelho), 1 CAN activity (amarelo). Resistor 1k ou ajustar pra ~5 mA
- [ ] Test points: GND, VDD33, VDDA, VBUS, ISENSE_OUT, principais GPIOs do MCU
- [ ] Debug UART header (4 pinos: VDD, GND, TX, RX) pra serial monitor opcional
- [ ] Header de service: jumper pra desabilitar contactor drive durante bench test (safety)

## Aceitacao
Schematic review. Calculo dissipacao do FET de contactor (Rds_on * I_coil^2)."

# =============================================================================
echo ""
echo "=== Layout (3 issues) ==="
# =============================================================================

create_issue \
  "[pcb-layout] Stackup + impedance control + classes (HV/LV/digital/analog)" \
  "area:pcb,type:feat,prio:P0,effort:M" \
  "## Objetivo
Definir stackup antes de routar. Sem isso, fica refazendo o roteamento.

## To-do
- [ ] Decidir 4-layer (SIG/GND/PWR/SIG) ou 6-layer (SIG/GND/SIG/SIG/PWR/SIG)
- [ ] FR-4 standard 1.6 mm total? Ou stackup custom (consultar PCB fab Ampera usa)
- [ ] Impedance: iso-SPI 2.66 Mbps - calcular Zdiff target (100 ohm tipico)
- [ ] Definir classes/rules em Design Rules do Altium:
  - Net class HV: clearance 8 mm (cell to cell, depende da IEC 60664-1)
  - Net class LV: clearance default
  - Net class iso-SPI: routing diferencial pareado, length-match <1 mm
  - Net class CAN: routing diferencial pareado, length-match <1 mm
- [ ] Setar PCB shape: dimensoes mecanicas baseadas no envelope da pack ou da carcaca BMS
- [ ] Adicionar pad de fixacao: 4 furos M3 nos cantos com keepout 5 mm

## Aceitacao
Stackup documentado em hw/docs/AMP-227-stackup.md + impedance calculo anexado."

create_issue \
  "[pcb-layout] Floorplan + footprint placement (G474, L9963E, conectores)" \
  "area:pcb,type:feat,prio:P0,effort:M" \
  "## Objetivo
Primeira passada de placement antes de routar. Defines as zonas.

## Princpios
- Zona HV (entrada do pack, contactors, shunt) na borda - facilita isolation
- Zona Comm (L9963E + transformers + L9963T) ao centro
- Zona MCU/LV (G474 + FDCAN + LEDs) longe da HV
- Conector de CAN longe do shunt (correntes geram CAN noise)
- Decoupling caps colados nos pinos VDD do MCU/L9963E
- Cristal/oscillator <5 mm do MCU se for usar HSE

## To-do
- [ ] Importar netlist do schematic finalizado
- [ ] Place footprints respeitando zonas (cores diferentes no Room/Component class)
- [ ] Validar com 3D view: nada batendo no mecanico esperado
- [ ] Validar com DRC preliminar: sem overlap, sem violacao de clearance basica

## Aceitacao
3D view OK. Preliminary placement review por mentor PCB da equipe."

create_issue \
  "[pcb-layout] Routing: CAN diferencial, iso-SPI, HV clearances, GND star" \
  "area:pcb,type:feat,prio:P0,effort:L" \
  "## Objetivo
Routing real com atencao especial aos pontos sensiveis.

## To-do
- [ ] iso-SPI: rotar como par diferencial controlado em impedancia (~100 ohm). Length-match <1 mm. Manter par junto entre L9963T e cada xfmr; depois de cada xfmr, novo par ate o proximo L9963E
- [ ] CAN: par diferencial CANH/CANL, length-match <1 mm, terminadores 120 ohm bem posicionados
- [ ] HV: trilhas largas (calc IPC-2152 pra correntes, ex 100 A na trilha de shunt -> >5 mm largura em 2 oz cobre), clearance HV a HV >8 mm (cells)
- [ ] GND: plano solido em layer dedicada, sem split. Star point se houver GND analogico vs digital (decidir baseado em VDDA approach)
- [ ] Decoupling caps com vias proximas (low inductance)
- [ ] Crystal/oscillator com guarda de GND ao redor (se HSE usado)
- [ ] Test points acessiveis com sonda de osciloscopio (loops de fio ou pads grandes)
- [ ] Silkscreen com refdes + valor (se BOM permite) + identificacao de pinos importantes (TX/RX/GND/VDD)

## Aceitacao
DRC clean. Length report dos pares diferenciais bate criterio (length-match e impedance)."

# =============================================================================
echo ""
echo "=== Manufacturing & QA (3 issues) ==="
# =============================================================================

create_issue \
  "[pcb-bom] ActiveBOM consolidado + supply check (Mouser/Digikey/JLC)" \
  "area:pcb,type:feat,prio:P0,effort:M" \
  "## To-do
- [ ] Configurar ActiveBOM no Altium puxando dos parametros dos componentes
- [ ] Cada componente com: Manufacturer + MPN + Description + Package + Mouser/Digikey/LCSC PN
- [ ] Validar disponibilidade dos componentes principais (STM32G474RE, L9963E, L9963T, MOSFETs de contactor, transformer isolation)
- [ ] Alternates documentados pros componentes 'em falta' (segunda opcao)
- [ ] Estimar custo BOM total (target sob orcamento da diretoria) por placa em quantidade 5
- [ ] Exportar BOM CSV/Excel + PDF pra revisao da diretoria

## Aceitacao
BOM aprovada pela diretoria + componentes principais com estoque > 100 unidades em pelo menos um fornecedor."

create_issue \
  "[pcb-manuf] OutJob: gerbers + drill + assembly + pick&place + 3D STEP" \
  "area:pcb,type:feat,prio:P0,effort:S" \
  "## To-do
- [ ] Configurar OutJob com todos os outputs necessarios:
  - Gerbers RS-274X (top, bottom, top mask, bottom mask, top silk, bottom silk, top paste, bottom paste, edge cuts)
  - Drill files Excellon (PTH + NPTH)
  - Pick and Place file (CSV ou TXT, formato compativel com o fab)
  - Assembly drawings PDF (top + bottom)
  - 3D STEP do board (pra mecanico fazer fit check)
  - PDF schematic (com header e footer)
  - BOM CSV
- [ ] Output folder: hw/pcb/manufacturing/AMP-227-BMS-vX.Y/
- [ ] Zip dos manufacturing files com naming AMP-227-BMS-vX.Y-manuf.zip

## Aceitacao
Manuf zip enviado ao fab (JLCPCB, PCBWay, Eurocircuits ou parceiro da Ampera) passa pre-check sem warnings."

create_issue \
  "[pcb-qa] DRC clean + ERC clean + 3D mechanical fit check + checklist final" \
  "area:pcb,type:chore,prio:P0,effort:M" \
  "## Objetivo
Ultimo gate antes de enviar manufacturing. Pega tudo que escapou.

## To-do
- [ ] ERC (Electrical Rules Check) no schematic: zero warnings
- [ ] DRC (Design Rules Check) no PCB: zero warnings (ou justificar exceptions)
- [ ] Checklist DFM:
  - Minimal trace width >= capacidade do fab
  - Annular ring >= capacidade do fab
  - Drill diameters padrao
  - Silkscreen nao sobreposto a pads
  - Fiducials presentes (3 por lado pra assembly)
  - Mounting holes presentes
  - Test points marcados
- [ ] Checklist eletrico:
  - Decoupling em todos VDD
  - Termo de reset/boot OK
  - Test points acessiveis
  - Conectores corretos (genero, pitch, locking)
- [ ] Checklist mecanico:
  - 3D view sem colisao no carcaca
  - Conectores acessiveis na carcaca (cutouts)
- [ ] Cross-review por 2 engenheiros da equipe

## Aceitacao
Checklist preenchido + 2 assinaturas + DRC/ERC limpos. Gate pra envio."

# =============================================================================
echo ""
echo "=== Docs (1 issue) ==="
# =============================================================================

create_issue \
  "[pcb-docs] hw/docs/AMP-227-design-rules.md: rationale, test points, jumpers" \
  "area:pcb,area:docs,type:docs,prio:P1,effort:S" \
  "## Objetivo
Documento de design rationale pro proximo engenheiro entender 'por que esta decisao foi feita' sem ter que reconstruir o raciocinio.

## Conteudo (markdown em hw/docs/AMP-227-design-rules.md)
- [ ] Resumo do BMS e decisoes top-level (porque L9963E, porque G474, porque Altium etc.)
- [ ] Decisoes de power supply (porque essa topologia)
- [ ] Decisoes de isolation (xfmr vs cap, modelo)
- [ ] Lista de test points + o que cada um mede
- [ ] Lista de jumpers + o que cada um habilita/desabilita
- [ ] Procedimento de bring-up bench (ordem de aplicar tensoes, primeiros sinais a observar)
- [ ] Lista de erratas conhecidas e workarounds
- [ ] Changelog da PCB (vX.Y: o que mudou em relacao a versao anterior)

## Aceitacao
Documento revisado + commitado junto com a tag da PCB vX.Y release."

echo ""
echo "=============================================================="
echo "DONE. Listing PCB issues (M0):"
echo "=============================================================="
gh issue list -R "$REPO" --milestone "M0 PCB Design" --limit 30
