# hw/ — Hardware do BMS-AMP-227

Projeto eletrico em **Altium Designer** + documentacao + (futuro) modelos mecanicos da placa BMS do prototipo AMP-227.

## Estrutura

```
hw/
+- pcb/      Projeto Altium (.PrjPcb, .SchDoc, .PcbDoc, libraries)
+- docs/     Documentos de design: requisitos, design rules, changelog
+- mech/     Modelos 3D (STEP) e desenhos mecanicos da carcaca/fixacao
```

## Pre-requisitos pra mexer na PCB

- **Altium Designer** 22 ou mais novo (licenca da equipe Ampera).
- **Git LFS** instalado (\`git lfs install\` uma vez por maquina) - arquivos binarios do Altium ficam em LFS pra nao inchar o repo.

## Workflow

1. Antes do **primeiro clone**: \`git lfs install\` no terminal (uma vez por maquina).
2. **Clone**: \`git clone https://github.com/amperaufsc/bms-amp-227.git\` - o LFS resolve automaticamente.
3. **Abre** \`hw/pcb/AMP-227-BMS.PrjPcb\` no Altium.
4. **Edita**, salva.
5. **Commit + push** normalmente - o LFS faz o resto.

> **Atencao**: arquivos LFS sao gerenciados separado do git normal. Nunca tente fazer merge manual de \`.SchDoc\`/\`.PcbDoc\` - prefira branchear e fazer 1 pessoa editar de cada vez, ou usar Altium's ECO compare.

## Status

Em design inicial. Veja [issues M0 PCB Design](https://github.com/amperaufsc/bms-amp-227/milestone/6) pro progresso.

## Documentos chave

- (TBD) \`hw/docs/AMP-227-design-requirements.md\` - requisitos eletricos
- (TBD) \`hw/docs/AMP-227-stackup.md\` - decisao de stackup + impedance control
- (TBD) \`hw/docs/AMP-227-design-rules.md\` - rationale, test points, jumpers
