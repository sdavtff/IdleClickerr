# Idle City 3.0

Jogo mobile 2D (Android) de construção e gerenciamento de cidades no estilo **idle tycoon**. Comece com uma pequena vila americana e transforme-a numa megacidade à beira-mar, equilibrando economia, trânsito, poluição e qualidade de vida. Visão lateral com rolagem horizontal, arte cartoon vetorial, moeda em reais (R$) e interface em português brasileiro.

- **Motor:** Godot **4.3-stable** (GDScript), renderizador *GL Compatibility* (roda em celulares básicos com OpenGL ES 3.0)
- **Plataforma:** Android 5.0+ (API 21, alvo API 34), arm64-v8a e armeabi-v7a, orientação paisagem
- **Funciona offline**, sem nenhuma permissão especial
- Novidades e bugs corrigidos: veja [CHANGELOG.md](CHANGELOG.md)

## Como jogar

1. **Junte dinheiro**: comércios, empresas, lazer e especiais rendem sozinhos; os moradores pagam impostos.
2. **Construir**: escolha um edifício; a obra começa no próximo terreno livre e leva alguns segundos (dá para acelerar pagando). Tocar num terreno vazio também abre o menu.
3. **Melhorias**: suba o nível (x1, x10, x100 ou MÁX). Nos níveis 10, 25, 50, 75 e 100 a renda dobra e o visual muda.
4. **População e felicidade**: moradias trazem moradores; empregos, saúde, educação, lazer e segurança deixam a cidade feliz. Felicidade alta atrai gente mais rápido; desemprego, poluição e impostos altos atrapalham.
5. **Finanças**: ajuste os impostos, veja receitas por categoria, aplique em investimentos, pegue empréstimos e acompanhe o relatório.
6. **Pesquisa**: escolas, bibliotecas e universidades geram pontos para uma árvore de 20 tecnologias em 6 ramos.
7. **Eventos e desafios**: eventos aleatórios (Festival, Boom imobiliário, Crise, Turismo, Tempestade...), 3 desafios diários e 3 metas semanais.
8. **Expansão**: 8 regiões em sequência, da Vila inicial à Orla Dourada, cada uma com recompensa ao ser desbloqueada.
9. **Missões e conquistas**: 36 missões e 35 conquistas (cada conquista dá dinheiro e +2% de renda para sempre).
10. **Prestígio**: renasça a cidade em troca de estrelas (+5% de renda permanente cada) e compre melhorias de legado.
11. **Renda offline**: ao voltar, a tela "Bem-vindo de volta!" mostra o resumo do que a cidade produziu (até 24 horas).
12. **Qualidade de vida**: trânsito, poluição e produtividade afetam felicidade, crescimento e renda. Terminais de ônibus, metrô, reciclagem e escolas ajudam.
13. **Bônus**: incentivo grátis a cada 3 horas, moedas douradas e recompensa diária em sequência de 7 dias (botão de presente no topo).
14. **Navegação**: arraste a cidade ou toque/arraste no minimapa (canto superior direito).

## Conteúdo

| Sistema | Destaques |
|---|---|
| Edifícios | 53 tipos com arte própria em 6 categorias (residencial, comercial, empresarial/industrial, serviços, lazer, especiais), obras com duração e evolução visual por nível |
| Economia | impostos ajustáveis, receitas e manutenção por categoria, banco (4 investimentos, empréstimo), relatório, histórico em gráfico |
| População | moradia, empregos e desemprego, 6 necessidades com indicadores, crescimento ligado à felicidade e à infraestrutura |
| Qualidade de vida | trânsito (deslocamentos × capacidade de transporte), poluição, produtividade e nota A–E, com gráficos históricos |
| Bônus | renda x2, obras turbo, ciência acelerada, migração; incentivo grátis, moedas douradas e recompensa diária de 7 dias |
| Som | música de dia e de noite, ambiente da cidade (pássaros, trânsito, grilos) e efeitos, com 3 volumes separados |
| Cidade viva | carros, ônibus e caminhões que param nos semáforos, pedestres que entram nas lojas, sombras, dia e noite com luzes, chuva, raios, confete, fogos de artifício |
| Salvamento | automático a cada 15 s e ao sair/minimizar; manual; SHA-256, escrita atômica, backup automático, 3 cópias rotativas restauráveis e migração de saves da 1.0 e 2.0 |

## Estrutura do projeto

```
project.godot            Configuração (autoloads, tela, renderizador)
export_presets.cfg       Exportação Android (versão 3.0.0, código 3) e Linux (para testes do build exportado)
scenes/                  Boot (carregamento), MainMenu, Game
scripts/core/            GameData (definições/balanceamento), Fmt (R$), Modifiers (bônus)
scripts/systems/         economy, building, population, happiness, expansion, mission,
                         prestige, idle (offline), save, research, event, challenge,
                         city_index (trânsito/poluição/qualidade de vida), boost (bônus e recompensa diária)
scripts/autoload/        GameManager (loop, ciclo de vida, migração), Settings, Audio, SelfTest
scripts/city/            CityView, arte dos edifícios, carros, pedestres, semáforos,
                         céu, paralaxe, chuva, efeitos
scripts/ui/              HUD, painéis (construções, melhorias, finanças, pesquisa,
                         eventos, missões, expansão, prestígio, configurações, cidade)
assets/                  ícones, ícones do app, sons/música, fonte Fredoka (SIL OFL)
tools/generate_assets.py Gera ícones, ícone do app e áudio (Python + Pillow + NumPy)
tests/                   Testes automatizados, balanceamento, toques, desempenho e capturas
dist/backup/             Cópias dos projetos das versões 1.0 e 2.0
```

## Abrir e editar

1. Instale o **Godot 4.3-stable** (versão padrão, não a .NET).
2. No gerenciador de projetos: *Importar* → selecione `project.godot`.
3. A cena inicial é `scenes/Boot.tscn`. Balanceamento (preços, rendas, regiões, pesquisas, eventos) fica em `scripts/core/game_data.gd`.

## Testes

```bash
# 162 testes de mecânica (+1 com a simulação de 10 horas de jogo)
godot --headless --path . res://tests/TestRunner.tscn -- --balance
# desempenho com a cidade cheia, nas 3 qualidades gráficas
godot --headless --path . res://tests/PerfTest.tscn
# toques reais na interface e capturas de tela (requerem vídeo, ex.: xvfb-run)
godot --path . res://tests/InputTest.tscn
# autoteste embutido (também funciona no jogo exportado, sem o editor;
# usa saves separados e não toca no progresso do jogador)
godot --path . -- --selftest
./IdleCity.x86_64 -- --selftest
godot --path . res://tests/ScreenshotTour.tscn -- --out=/tmp/capturas
```

## Gerar o APK

1. No Godot: *Editor → Configurações do Editor → Export → Android*: caminho do Android SDK (build-tools 34) e do JDK 17+.
2. Instale os *Export Templates* 4.3 (*Editor → Gerenciar modelos de exportação*).
3. *Projeto → Exportar → Android*: em *Keystore → Release* informe a keystore de release e clique em *Exportar Projeto*.

Pela linha de comando:

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/caminho/idlecity-release.keystore
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=idlecity
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=sua_senha
godot --headless --path . --export-release "Android" build/Idle-City-3.0.apk
```

Use a mesma keystore das versões anteriores para que a 3.0 instale por cima, mantendo o progresso dos jogadores.

## Créditos

- Arte vetorial, ícones, efeitos sonoros e música: criados para este projeto (desenho procedural em GDScript e `tools/generate_assets.py`).
- Fonte [Fredoka](https://github.com/hafontia/Fredoka-One) — SIL Open Font License 1.1 (`assets/fonts/OFL-LICENSE.txt`).
- Feito com [Godot Engine](https://godotengine.org) 4.3 (licença MIT).
