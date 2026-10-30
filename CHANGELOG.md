# Histórico de versões

## 3.0.0

Evolução da 2.0 trabalhando sobre o projeto-fonte completo, sem remover sistemas existentes. Saves da 1.0 e da 2.0 são migrados automaticamente.

### Melhorias implementadas

**Índices urbanos (novo sistema)**
- **Trânsito**: deslocamentos dos moradores × capacidade de transporte (ruas por região, Terminal de ônibus, Estação de metrô, Aeroporto e a pesquisa Linhas de ônibus). Congestionamento reduz a felicidade e a produtividade, e coloca mais carros, mais lentos, nas ruas.
- **Poluição** de 0 a 100 (indústrias com filtros de pesquisa, mais parte do trânsito), substituindo o cálculo simples anterior.
- **Produtividade** (educação e trânsito) aplicada à renda de comércios e empresas.
- **Qualidade de vida** (nota A–E), que acelera ou freia o crescimento populacional.
- Nova aba "Qualidade de vida" no painel da cidade, com gráficos históricos de população, felicidade e trânsito.

**Bônus temporários e recompensas (novo sistema)**
- Renda em dobro, Obras turbo, Ciência acelerada e Onda de migração, com indicadores e contagem regressiva no HUD.
- Incentivo da prefeitura grátis a cada 3 horas, com proteção contra relógio alterado.
- Moedas douradas (7% das moedas flutuantes) dão bônus surpresa.
- Recompensa diária em sequência de 7 dias (dinheiro, pesquisa, bônus e uma estrela no 7º dia), que abre automaticamente uma vez por dia.
- Bônus não multiplicam a renda offline; o tempo fora os consome.

**Construções**
- 5 novas (53 no total): Posto de saúde (saúde já na vila), Terminal de ônibus, Usina de reciclagem (renda e redução de poluição), Centro de pesquisa e Torre comercial.

**Visual**
- Sombras que acompanham o sol (longas de manhã e à tarde, curtas ao meio-dia, ausentes à noite e mais fracas na chuva).
- Neblina ao amanhecer, moedas douradas com brilho giratório e densidade de carros ligada ao trânsito.
- Minimapa com regiões, edifícios e área visível: toque ou arraste para navegar pela cidade.

**Áudio**
- Som ambiente da cidade (pássaros e trânsito de dia, grilos à noite) e música noturna, com transição suave pelo ciclo de dia e noite.
- Novos sons de bônus e de recompensa diária; volume próprio para o ambiente.

**Salvamento e recuperação**
- 3 cópias de segurança rotativas (a cada 5 minutos), que podem ser restauradas em Configurações e sobrevivem a "Novo jogo".
- Formato de save 3, com migração e cópia automática do save anterior por versão.
- Modo de **autoteste** (`-- --selftest`) para validar builds exportados: inicialização, obra, renda, salvar/carregar, renda offline e cena do jogo, usando arquivos separados do save do jogador.

### Bugs e limitações corrigidos
- O painel de Melhorias mostrava o botão de melhorar em edifícios ainda em obra (o toque falhava com som de erro); agora mostra "Em obra" e o tempo restante.
- A pesquisa só dobrava com eventos; agora usa todos os modificadores (inclui bônus).
- A cópia do save antigo era sempre gravada como "v1"; agora uma cópia por versão, para não sobrescrever nem pular a cópia da 2.0.
- "Apagar todo o progresso" e "Novo jogo" não deixavam forma de recuperar a cidade anterior; agora as cópias rotativas permanecem.

### Testes realizados
- 162 testes automatizados de mecânica e mais 1 com a simulação de 10 horas (progressão: região 4 em ~2h, região 5 em ~6h).
- 8 testes de toques reais na interface.
- Desempenho com a cidade cheia (80 edifícios) nas 3 qualidades gráficas.
- Build exportado (Linux, mesmo pacote de jogo do APK) rodado sem o editor: autoteste completo com renderização real.
- APK assinado e verificado com `apksigner` e `aapt2`.

## 2.0.0

Atualização feita sobre o projeto 1.0, preservando todos os sistemas existentes e os saves dos jogadores.

### Melhorias implementadas

**Construções**
- 11 edifícios novos (48 no total): Mercado, Praça, Depósito, Estação de metrô, Resort, Marina e a nova categoria **Especiais** (Monumento, Porto, Complexo financeiro, Aeroporto, Torre Icônica).
- Toda construção agora tem **tempo de obra** (3 s a ~5 min, conforme o porte), com andaime, guindaste, rede de proteção, barra de progresso e animação de conclusão. A obra pode ser acelerada pagando, avança offline e aparece no resumo de retorno.
- Edifícios especiais únicos dão bônus de renda/felicidade; alguns exigem pesquisa (Metrô, Porto, Aeroporto).

**Economia e finanças** (novo menu *Finanças*)
- Impostos residenciais ajustáveis em 4 níveis (mais arrecadação × menos felicidade).
- Receitas e manutenção separadas por categoria.
- Banco da cidade: 4 investimentos (Poupança, CDB, Fundo imobiliário, Ações com risco), até 3 aplicações simultâneas.
- Empréstimo opcional com juros fixos e pagamento automático com parte do lucro.
- Relatório de ganhos e gastos por tipo e histórico de receitas/despesas em gráfico.
- Recompensas proporcionais à renda são limitadas pelo custo da próxima região, para manter a progressão gradual.

**População e felicidade**
- Desemprego (moradores sem vaga) passa a contar e reduz a felicidade em cidades maiores.
- Painel de **necessidades**: moradia, empregos, saúde, educação, lazer e segurança.
- Felicidade agora também considera impostos, eventos e pesquisas.

**Pesquisas e tecnologias** (novo menu *Pesquisa*)
- Árvore com 20 pesquisas em 6 ramos (Construção avançada, Transporte público, Tecnologia industrial, Energia eficiente, Administração pública, Desenvolvimento comercial).
- Pontos de pesquisa gerados por escolas, bibliotecas, universidades e polos de tecnologia; uma pesquisa por vez, com duração.

**Eventos e desafios** (novo menu *Eventos*)
- 7 eventos aleatórios com duração, efeitos, objetivo e recompensa: Festival, Boom imobiliário, Crise econômica, Semana do turismo, Tempestade, Mutirão de obras e Feira de tecnologia.
- 3 desafios diários e 3 metas semanais (as semanais valem uma estrela de prestígio).
- Faixa animada do evento ativo no topo da tela.

**Expansão**
- Nova região especial **Orla Dourada** (8 regiões no total), com praia, palmeiras e mar ao fundo.
- Cada expansão dá recompensa em dinheiro e pontos de pesquisa, com fogos de artifício.

**Conquistas e prestígio**
- 11 conquistas novas (35 no total), incluindo 50 construções, Primeira expansão e Primeira metrópole. Toda conquista agora também dá dinheiro.
- Prestígio: 3 melhorias de legado novas (Obras aceleradas, Laboratório, Juros melhores) e prévia do multiplicador antes/depois de renascer.

**Visual e vida na cidade**
- Faixas de pedestres e semáforos em ciclo; carros param no vermelho.
- Sombras de edifícios, carros e pedestres.
- Confete nos festivais, chuva forte com raios nas tempestades, chuva de moedas ao coletar recompensas.

**Interface, áudio e configurações**
- Barra inferior com 8 menus, contador de pesquisa e indicadores (badges) de itens prontos.
- Menu principal com painel "Novidades 2.0".
- Novos sons: evento, pesquisa, caixa registradora, fogos, trovão e obra concluída.
- Volumes separados para música e efeitos, qualidade gráfica em 3 níveis, economia de bateria (30 FPS) e notificações desligáveis.

**Renda offline e salvamento**
- O resumo de retorno mostra o ganho por categoria, as obras e pesquisas concluídas e os investimentos prontos.
- Relógio do aparelho voltando no tempo não gera renda; reabrir o jogo não duplica a recompensa.
- Formato de save versão 2 com **migração automática** dos saves da 1.0 e cópia de segurança do arquivo antigo.

### Bugs e limitações corrigidos
- Conquistas não davam nenhuma recompensa além do bônus de renda.
- `CityView` recriava listas e funções anônimas a cada quadro para ordenar os carros; agora ordena no lugar.
- A atualização de luzes noturnas percorria todos os nós do grupo a cada quadro durante o entardecer; agora no máximo 10 vezes por segundo.
- O HUD verificava 10 vezes por segundo se algo podia ser construído; agora 2 vezes por segundo.
- A fumaça das fábricas e a quantidade de chuva não respeitavam a qualidade gráfica.
- A opção "Mais carros e pedestres" era só ligado/desligado; virou qualidade gráfica em 3 níveis, que também ajusta sombras e FPS.
- Saves da 1.0 não tinham número de versão; agora há campo `format` e migração segura.

### Testes realizados
- 131 testes automatizados de mecânica (construções, economia, finanças, população, felicidade, pesquisa, eventos, desafios, expansão, missões, prestígio, offline, salvamento, corrupção e migração) e mais 1 com a simulação de 10 horas de jogo.
- 6 testes de toques reais na interface.
- Teste de desempenho com a cidade cheia (80 edifícios, festival ativo) nas 3 qualidades.
- Capturas de tela de todas as telas em 16:9, 20:9 e 4:3.
- APK assinado e verificado com `apksigner` e `aapt2`.

## 1.0.0
- Versão inicial: 37 edifícios, 7 regiões, economia, população, felicidade, missões, conquistas, prestígio, renda offline de 24 horas e salvamento automático.
