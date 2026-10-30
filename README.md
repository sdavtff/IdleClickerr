# Idle City

Jogo mobile 2D (Android) de construção de cidades no estilo **idle tycoon**. Comece com uma pequena vila americana e transforme-a numa megacidade. Visão lateral com rolagem horizontal, arte cartoon vetorial, moeda em reais (R$) e interface em português brasileiro.

- **Motor:** Godot 4.3 (GDScript), renderizador *GL Compatibility* (roda em celulares básicos com OpenGL ES 3.0)
- **Plataforma:** Android 5.0+ (API 21), arm64-v8a e armeabi-v7a, orientação paisagem
- **Funciona offline**, sem nenhuma permissão especial

## Como jogar

1. Junte dinheiro: comércios, empresas e áreas de lazer rendem automaticamente e os moradores pagam impostos.
2. **Construir**: escolha um edifício; ele aparece sozinho no próximo terreno livre. Tocar num terreno vazio também abre o menu.
3. **Melhorias**: suba o nível dos edifícios (x1, x10, x100 ou MÁX). Nos níveis 10, 25, 50, 75 e 100 a renda dobra e o visual muda.
4. **População e felicidade**: casas trazem moradores; hospitais, escolas, segurança e lazer deixam a cidade feliz. Felicidade alta atrai moradores mais rápido; baixa afasta.
5. **Expansão**: desbloqueie 7 regiões em sequência (Vila inicial → Bairro residencial → Centro comercial → Zona industrial → Centro financeiro → Grande metrópole → Megacidade).
6. **Missões e conquistas**: 36 missões com recompensas e bônus; 24 conquistas permanentes (+2% de renda cada).
7. **Prestígio**: renasça a cidade em troca de estrelas (+5% de renda permanente cada) e compre melhorias de legado.
8. **Renda offline**: ao voltar, a tela "Bem-vindo de volta!" mostra quanto a cidade rendeu (até 24 horas).

Toque nas moedas flutuantes para ganhar bônus e toque num edifício para ver seus detalhes.

## Conteúdo

| Sistema | Destaques |
|---|---|
| Edifícios | 37 tipos com arte própria em 5 categorias (residencial, comercial, empresarial/industrial, serviços públicos, lazer) |
| Economia | renda/s, despesas de manutenção, eficiência de trabalhadores (empregos x população), multiplicadores |
| Cidade viva | carros e ônibus, pedestres que entram e saem das lojas, ciclo de dia e noite com janelas e postes acesos, chuva, roda-gigante, turbina eólica, fumaça das fábricas |
| Salvamento | automático a cada 15 s e ao sair/minimizar; checksum SHA-256, escrita atômica e backup automático contra corrupção |

## Estrutura do projeto

```
project.godot            Configuração (autoloads, tela, renderizador)
export_presets.cfg       Predefinição de exportação Android
scenes/                  Boot (carregamento), MainMenu, Game
scripts/core/            GameData (definições/balanceamento), Fmt (formatação R$)
scripts/systems/         economy, building, population, happiness, expansion,
                         mission, prestige, idle (offline) e save — um sistema por arquivo
scripts/autoload/        GameManager (loop e ciclo de vida), Settings, Audio
scripts/city/            CityView (câmera/toques), arte dos edifícios, carros, pedestres,
                         céu, paralaxe, chuva, efeitos
scripts/ui/              HUD, painéis (construções, melhorias, missões, expansão,
                         prestígio, configurações, estatísticas), diálogos, menu inicial
assets/                  ícones, ícones do app, sons/música, fonte Fredoka (SIL OFL)
tools/generate_assets.py Gera ícones, ícone do app e áudio (Python + Pillow + NumPy)
tests/                   Testes automatizados, simulação de balanceamento e capturas de tela
```

## Abrir e editar

Abra a pasta no **Godot 4.3** (Importar → `project.godot`). A cena inicial é `scenes/Boot.tscn`. Para ajustar o balanceamento, edite `scripts/core/game_data.gd`.

## Testes

```bash
# 69 testes de mecânicas + simulação de 10 horas de jogo
godot --headless --path . res://tests/TestRunner.tscn -- --balance
# toques reais na interface e capturas de tela (requerem vídeo, ex.: xvfb-run)
godot --path . res://tests/InputTest.tscn
godot --path . res://tests/ScreenshotTour.tscn -- --out=/tmp/capturas
```

## Gerar o APK

1. No Godot: *Editor → Configurações do Editor → Export → Android*: informe o caminho do Android SDK e do JDK 17+.
2. Instale os *Export Templates* 4.3 (*Editor → Gerenciar modelos de exportação*).
3. *Projeto → Exportar → Android*: em *Keystore → Release*, informe sua keystore (ou use a de depuração) e clique em *Exportar Projeto*.

Pela linha de comando:

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/caminho/idlecity-release.keystore
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=idlecity
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=sua_senha
godot --headless --path . --export-release "Android" build/Idle-City-Android.apk
```

## Créditos

- Arte vetorial, ícones, efeitos sonoros e música: criados para este projeto (desenho procedural em GDScript e `tools/generate_assets.py`).
- Fonte [Fredoka](https://github.com/hafontia/Fredoka-One) — SIL Open Font License 1.1 (`assets/fonts/OFL-LICENSE.txt`).
- Feito com [Godot Engine](https://godotengine.org) (licença MIT).
