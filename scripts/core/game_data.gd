class_name GameData
extends RefCounted
## Definições estáticas do jogo: edifícios, regiões, missões, conquistas e
## melhorias de prestígio. Nenhum estado mutável fica aqui.

# --- Layout do mundo -------------------------------------------------------
const LOT_W := 240.0
const LOTS_PER_REGION := 10
const WORLD_MARGIN := 200.0
const GROUND_Y := 520.0
const SIDEWALK_Y1 := 548.0
const ROAD_Y0 := 548.0
const ROAD_Y1 := 632.0
const LANE_FAR_Y := 578.0
const LANE_NEAR_Y := 614.0

# --- Regras de economia ----------------------------------------------------
const START_MONEY := 300.0
const BUILD_COST_GROWTH := 1.12
const UPGRADE_COST_FACTOR := 0.5
const UPGRADE_COST_GROWTH := 1.14
const MAX_LEVEL := 100
const LEVEL_MILESTONES := [10, 25, 50, 75, 100]
const DEMOLISH_REFUND := 0.25
const OFFLINE_MAX_SECONDS := 86400.0
const MIN_WORK_EFFICIENCY := 0.3

const CATEGORIES := ["res", "com", "biz", "pub", "fun", "esp"]
const CATEGORY_NAMES := {
	"res": "Residencial",
	"com": "Comercial",
	"biz": "Empresarial",
	"pub": "Serviços",
	"fun": "Lazer",
	"esp": "Especiais",
}
const CATEGORY_COLORS := {
	"res": Color("4fa3e0"),
	"com": Color("f39c12"),
	"biz": Color("8e6fd8"),
	"pub": Color("e05a5a"),
	"fun": Color("3fbf6f"),
	"esp": Color("d4a017"),
}
const SERVICE_NAMES := {
	"saude": "Saúde",
	"edu": "Educação",
	"seg": "Segurança",
	"lazer": "Lazer",
}

# --- Regiões -------------------------------------------------------------------
const REGIONS := [
	{"id": "vila", "name": "Vila inicial", "cost": 0.0, "pop": 0,
		"desc": "Uma pequena vila americana cercada por colinas verdes.",
		"grass": Color("7cc576"), "sky_tint": Color(1, 1, 1), "backdrop": "hills"},
	{"id": "bairro", "name": "Bairro residencial", "cost": 3000.0, "pop": 50,
		"desc": "Ruas arborizadas e casas modernas para novas famílias.",
		"grass": Color("6dbb6a"), "sky_tint": Color(1, 1, 1), "backdrop": "suburb"},
	{"id": "comercio", "name": "Centro comercial", "cost": 60000.0, "pop": 250,
		"desc": "Lojas, mercados e escritórios movimentam a economia.",
		"grass": Color("8fc46a"), "sky_tint": Color(1, 1, 1), "backdrop": "town"},
	{"id": "industria", "name": "Zona industrial", "cost": 1200000.0, "pop": 1000,
		"desc": "Fábricas e logística: muita renda, um pouco de poluição.",
		"grass": Color("a3b86c"), "sky_tint": Color(1, 0.97, 0.9), "backdrop": "industry"},
	{"id": "financeiro", "name": "Centro financeiro", "cost": 18000000.0, "pop": 3500,
		"desc": "Bancos, hotéis e empresas de tecnologia em torres de vidro.",
		"grass": Color("78b97a"), "sky_tint": Color(1, 1, 1), "backdrop": "city"},
	{"id": "metropole", "name": "Grande metrópole", "cost": 300000000.0, "pop": 10000,
		"desc": "Arranha-céus, estádios e universidades de ponta.",
		"grass": Color("6aab7c"), "sky_tint": Color(1, 1, 1), "backdrop": "metro"},
	{"id": "mega", "name": "Megacidade", "cost": 6000000000.0, "pop": 35000,
		"desc": "O futuro chegou: torres gigantes e tecnologia sem limites.",
		"grass": Color("5fa58f"), "sky_tint": Color(0.95, 0.97, 1.05), "backdrop": "future"},
	{"id": "orla", "name": "Orla Dourada", "cost": 120000000000.0, "pop": 90000,
		"desc": "Região especial à beira-mar: resorts de luxo, marina e turismo.",
		"grass": Color("e6cf8f"), "sky_tint": Color(1, 1, 1), "backdrop": "coast"},
]
## Recompensa ao desbloquear cada região: minutos de renda + pontos de pesquisa.
const REGION_REWARD_MINUTES := 10.0
const REGION_REWARD_RP := [0, 20, 40, 80, 150, 300, 600, 1200]

# --- Edifícios -----------------------------------------------------------------
# cost: custo base | income: R$/s (comerciais/empresariais/lazer)
# cap: moradores (residenciais) | tax: R$/s por morador | comfort: qualidade da moradia
# jobs: vagas de trabalho | upkeep: manutenção R$/s | service: tipo e cobertura
# happy: bônus fixo de felicidade | pollution: poluição | unique: apenas 1 por cidade
const BUILDINGS := [
	# ---------------- Vila inicial ----------------
	{"id": "casa_pequena", "name": "Casa pequena", "cat": "res", "region": 0, "w": 150,
		"cost": 100.0, "cap": 6, "tax": 0.25, "comfort": 0.3,
		"desc": "Um lar aconchegante para uma família."},
	{"id": "padaria", "name": "Padaria", "cat": "com", "region": 0, "w": 160,
		"cost": 250.0, "income": 3.0, "jobs": 4,
		"desc": "Pão quentinho toda manhã. O primeiro negócio da vila."},
	{"id": "loja_conveniencia", "name": "Loja de conveniência", "cat": "com", "region": 0, "w": 170,
		"cost": 1200.0, "income": 12.0, "jobs": 8,
		"desc": "Aberta 24 horas para tudo o que os moradores precisam."},
	{"id": "parque", "name": "Parque", "cat": "fun", "region": 0, "w": 220,
		"cost": 500.0, "upkeep": 0.4, "service": "lazer", "cov": 60, "happy": 2,
		"desc": "Árvores, fonte e bancos. Os moradores adoram."},
	{"id": "escola", "name": "Escola", "cat": "pub", "region": 0, "w": 200,
		"cost": 2000.0, "upkeep": 1.5, "service": "edu", "cov": 90,
		"desc": "Educação para as crianças da cidade."},
	# ---------------- Bairro residencial ----------------
	{"id": "casa_moderna", "name": "Casa moderna", "cat": "res", "region": 1, "w": 180,
		"cost": 3000.0, "cap": 20, "tax": 0.6, "comfort": 0.5,
		"desc": "Arquitetura moderna com grandes janelas."},
	{"id": "restaurante", "name": "Restaurante", "cat": "com", "region": 1, "w": 180,
		"cost": 6000.0, "income": 45.0, "jobs": 14,
		"desc": "Comida caseira e mesas na calçada."},
	{"id": "hospital", "name": "Hospital", "cat": "pub", "region": 1, "w": 200,
		"cost": 12000.0, "upkeep": 6.0, "service": "saude", "cov": 250,
		"desc": "Atendimento médico para a população."},
	{"id": "delegacia", "name": "Delegacia", "cat": "pub", "region": 1, "w": 180,
		"cost": 9000.0, "upkeep": 5.0, "service": "seg", "cov": 250,
		"desc": "Mantém as ruas seguras."},
	{"id": "academia", "name": "Academia", "cat": "fun", "region": 1, "w": 180,
		"cost": 7500.0, "income": 25.0, "jobs": 6, "service": "lazer", "cov": 200,
		"desc": "Saúde e bem-estar para os moradores."},
	{"id": "biblioteca", "name": "Biblioteca", "cat": "pub", "region": 1, "w": 180,
		"cost": 5000.0, "upkeep": 2.0, "service": "edu", "cov": 200,
		"desc": "Livros e cultura para todas as idades."},
	# ---------------- Centro comercial ----------------
	{"id": "apartamento", "name": "Apartamento", "cat": "res", "region": 2, "w": 170,
		"cost": 45000.0, "cap": 90, "tax": 1.4, "comfort": 0.5,
		"desc": "Prédio residencial de tijolos com vários andares."},
	{"id": "supermercado", "name": "Supermercado", "cat": "com", "region": 2, "w": 220,
		"cost": 70000.0, "income": 420.0, "jobs": 40,
		"desc": "Grande variedade e preços baixos."},
	{"id": "escritorio", "name": "Escritório", "cat": "biz", "region": 2, "w": 170,
		"cost": 110000.0, "income": 650.0, "jobs": 50,
		"desc": "Empresas de serviços e consultorias."},
	{"id": "bombeiros", "name": "Corpo de bombeiros", "cat": "pub", "region": 2, "w": 200,
		"cost": 90000.0, "upkeep": 30.0, "service": "seg", "cov": 1200,
		"desc": "Prontos para qualquer emergência."},
	{"id": "prefeitura", "name": "Prefeitura", "cat": "pub", "region": 2, "w": 220,
		"cost": 150000.0, "upkeep": 40.0, "happy": 6, "unique": true, "income_bonus": 0.1,
		"desc": "Sede do governo. +10% de renda e +6% de felicidade (única)."},
	{"id": "cinema", "name": "Cinema", "cat": "fun", "region": 2, "w": 190,
		"cost": 60000.0, "income": 220.0, "jobs": 15, "service": "lazer", "cov": 900,
		"desc": "Estreias toda semana na tela grande."},
	# ---------------- Zona industrial ----------------
	{"id": "casa_luxo", "name": "Casa de luxo", "cat": "res", "region": 3, "w": 210,
		"cost": 600000.0, "cap": 60, "tax": 22.0, "comfort": 1.0, "happy": 1,
		"desc": "Mansão com piscina. Moradores ricos pagam mais impostos."},
	{"id": "fabrica", "name": "Fábrica", "cat": "biz", "region": 3, "w": 220,
		"cost": 900000.0, "income": 6500.0, "jobs": 220, "pollution": 4,
		"desc": "Alta produção, mas gera poluição."},
	{"id": "centro_distribuicao", "name": "Centro de distribuição", "cat": "biz", "region": 3, "w": 220,
		"cost": 1500000.0, "income": 9000.0, "jobs": 160, "pollution": 2,
		"desc": "Logística que abastece toda a cidade."},
	{"id": "usina_solar", "name": "Usina solar", "cat": "biz", "region": 3, "w": 210,
		"cost": 1100000.0, "income": 3500.0, "jobs": 30, "pollution": -5, "happy": 2,
		"desc": "Energia limpa: reduz a poluição da cidade."},
	{"id": "shopping", "name": "Shopping", "cat": "com", "region": 3, "w": 220,
		"cost": 2200000.0, "income": 13000.0, "jobs": 260, "service": "lazer", "cov": 3000,
		"desc": "Centenas de lojas e praça de alimentação."},
	# ---------------- Centro financeiro ----------------
	{"id": "condominio", "name": "Condomínio", "cat": "res", "region": 4, "w": 200,
		"cost": 8000000.0, "cap": 900, "tax": 14.0, "comfort": 0.8,
		"desc": "Torres residenciais com lazer completo."},
	{"id": "hotel", "name": "Hotel", "cat": "com", "region": 4, "w": 190,
		"cost": 15000000.0, "income": 80000.0, "jobs": 600,
		"desc": "Turistas e executivos do mundo inteiro."},
	{"id": "empresa_tecnologia", "name": "Empresa de tecnologia", "cat": "biz", "region": 4, "w": 200,
		"cost": 25000000.0, "income": 140000.0, "jobs": 700,
		"desc": "Inovação, aplicativos e inteligência artificial."},
	{"id": "banco", "name": "Banco", "cat": "biz", "region": 4, "w": 190,
		"cost": 20000000.0, "income": 110000.0, "jobs": 400,
		"desc": "O coração financeiro da cidade."},
	{"id": "centro_medico", "name": "Centro médico", "cat": "pub", "region": 4, "w": 210,
		"cost": 12000000.0, "upkeep": 3000.0, "service": "saude", "cov": 12000,
		"desc": "Especialistas e tecnologia médica avançada."},
	{"id": "centro_entretenimento", "name": "Centro de entretenimento", "cat": "fun", "region": 4, "w": 210,
		"cost": 10000000.0, "income": 30000.0, "jobs": 200, "service": "lazer", "cov": 12000,
		"desc": "Fliperamas, boliche e shows."},
	# ---------------- Grande metrópole ----------------
	{"id": "arranha_ceu_res", "name": "Arranha-céu residencial", "cat": "res", "region": 5, "w": 190,
		"cost": 120000000.0, "cap": 5000, "tax": 40.0, "comfort": 0.8,
		"desc": "Milhares de moradores com vista para a cidade."},
	{"id": "centro_empresarial", "name": "Centro empresarial", "cat": "biz", "region": 5, "w": 210,
		"cost": 400000000.0, "income": 2000000.0, "jobs": 3500,
		"desc": "Torres gêmeas de grandes corporações."},
	{"id": "estadio", "name": "Estádio", "cat": "fun", "region": 5, "w": 230,
		"cost": 250000000.0, "income": 600000.0, "jobs": 1500, "service": "lazer", "cov": 60000,
		"desc": "Clássicos de futebol e grandes shows."},
	{"id": "universidade", "name": "Universidade", "cat": "pub", "region": 5, "w": 220,
		"cost": 180000000.0, "upkeep": 40000.0, "service": "edu", "cov": 60000,
		"desc": "Pesquisa e ensino superior de excelência."},
	{"id": "central_seguranca", "name": "Central de segurança", "cat": "pub", "region": 5, "w": 200,
		"cost": 150000000.0, "upkeep": 35000.0, "service": "seg", "cov": 60000,
		"desc": "Monitoramento inteligente de toda a metrópole."},
	# ---------------- Megacidade ----------------
	{"id": "torre_megacity", "name": "Torre Megacidade", "cat": "res", "region": 6, "w": 210,
		"cost": 2500000000.0, "cap": 30000, "tax": 200.0, "comfort": 1.0, "happy": 2,
		"desc": "Uma cidade vertical com jardins suspensos."},
	{"id": "bolsa_valores", "name": "Bolsa de valores", "cat": "biz", "region": 6, "w": 210,
		"cost": 8000000000.0, "income": 35000000.0, "jobs": 12000,
		"desc": "Onde fortunas são feitas a cada segundo."},
	{"id": "parque_diversoes", "name": "Parque de diversões", "cat": "fun", "region": 6, "w": 230,
		"cost": 5000000000.0, "income": 12000000.0, "jobs": 6000, "service": "lazer", "cov": 300000,
		"desc": "Roda-gigante, montanha-russa e muita diversão."},
	{"id": "complexo_hospitalar", "name": "Complexo hospitalar", "cat": "pub", "region": 6, "w": 220,
		"cost": 3000000000.0, "upkeep": 600000.0, "service": "saude", "cov": 300000,
		"desc": "Medicina do futuro para milhões de pessoas."},
	# ---------------- Novos na 2.0 ----------------
	{"id": "mercado", "name": "Mercado", "cat": "com", "region": 0, "w": 160,
		"cost": 600.0, "income": 6.5, "jobs": 5,
		"desc": "Frutas, verduras e o cafezinho do bairro."},
	{"id": "praca", "name": "Praça", "cat": "fun", "region": 1, "w": 200,
		"cost": 2500.0, "upkeep": 0.8, "service": "lazer", "cov": 150, "happy": 1,
		"desc": "Coreto, canteiros floridos e bancos à sombra."},
	{"id": "deposito", "name": "Depósito", "cat": "biz", "region": 2, "w": 200,
		"cost": 90000.0, "income": 560.0, "jobs": 25, "pollution": 1,
		"desc": "Armazenagem para o comércio que não para de crescer."},
	{"id": "monumento", "name": "Monumento", "cat": "esp", "region": 2, "w": 180,
		"cost": 250000.0, "happy": 5, "unique": true, "income_bonus": 0.05,
		"desc": "Cartão-postal da cidade: atrai turistas. +5% renda e +5% felicidade (único)."},
	{"id": "estacao_metro", "name": "Estação de metrô", "cat": "pub", "region": 3, "w": 200,
		"cost": 2500000.0, "upkeep": 900.0, "happy": 3, "transit": 20000, "income_bonus": 0.03, "research": "t2",
		"desc": "Transporte rápido: +3% renda da cidade e mais felicidade. Requer pesquisa."},
	{"id": "porto", "name": "Porto", "cat": "esp", "region": 3, "w": 236,
		"cost": 8000000.0, "income": 60000.0, "jobs": 900, "pollution": 2, "research": "t3",
		"desc": "Navios cargueiros movimentam milhões todos os dias. Requer pesquisa."},
	{"id": "complexo_financeiro", "name": "Complexo financeiro", "cat": "esp", "region": 4, "w": 220,
		"cost": 60000000.0, "income": 400000.0, "jobs": 1500, "unique": true, "income_bonus": 0.08,
		"desc": "Sede de bancos internacionais. +8% renda da cidade (único)."},
	{"id": "aeroporto", "name": "Aeroporto", "cat": "esp", "region": 5, "w": 238,
		"cost": 900000000.0, "income": 4500000.0, "jobs": 6000, "unique": true, "income_bonus": 0.1, "research": "t4", "transit": 60000,
		"desc": "Voos para o mundo todo. +10% renda da cidade (único). Requer pesquisa."},
	{"id": "torre_iconica", "name": "Torre Icônica", "cat": "esp", "region": 6, "w": 220,
		"cost": 20000000000.0, "income": 60000000.0, "jobs": 15000, "happy": 4, "unique": true,
		"desc": "O arranha-céu mais alto do país. Símbolo da megacidade (único)."},
	# ---------------- Novos na 3.0 ----------------
	{"id": "posto_saude", "name": "Posto de saúde", "cat": "pub", "region": 0, "w": 160,
		"cost": 1500.0, "upkeep": 1.0, "service": "saude", "cov": 60,
		"desc": "Atendimento básico de saúde para a vila."},
	{"id": "terminal_onibus", "name": "Terminal de ônibus", "cat": "pub", "region": 1, "w": 210,
		"cost": 8000.0, "upkeep": 4.0, "transit": 1500, "happy": 1,
		"desc": "Linhas de ônibus que reduzem o trânsito da cidade."},
	{"id": "reciclagem", "name": "Usina de reciclagem", "cat": "biz", "region": 2, "w": 210,
		"cost": 120000.0, "income": 300.0, "jobs": 40, "pollution": -6,
		"desc": "Transforma lixo em renda e limpa o ar da cidade."},
	{"id": "centro_pesquisa", "name": "Centro de pesquisa", "cat": "pub", "region": 4, "w": 200,
		"cost": 30000000.0, "upkeep": 6000.0, "happy": 1, "rp": 1.5,
		"desc": "Laboratórios de ponta: gera muitos pontos de pesquisa."},
	{"id": "torre_comercial", "name": "Torre comercial", "cat": "com", "region": 5, "w": 190,
		"cost": 300000000.0, "income": 1500000.0, "jobs": 4000,
		"desc": "Andares de lojas, restaurantes e um mirante no topo."},
	{"id": "resort", "name": "Resort", "cat": "com", "region": 7, "w": 220,
		"cost": 50000000000.0, "income": 160000000.0, "jobs": 30000,
		"desc": "Hotel cinco estrelas pé na areia."},
	{"id": "marina", "name": "Marina", "cat": "fun", "region": 7, "w": 230,
		"cost": 30000000000.0, "income": 70000000.0, "jobs": 8000, "service": "lazer", "cov": 1500000, "happy": 3,
		"desc": "Iates, passeios de barco e pôr do sol inesquecível."},
]

# --- Missões (em ordem) --------------------------------------------------------
# type: build_total | own | earn | pop | happy | region | level | total_levels | income | bubbles
const MISSIONS := [
	{"id": "m01", "type": "build_total", "target": 1, "text": "Construa seu primeiro edifício", "reward": 200.0},
	{"id": "m02", "type": "own", "key": "casa_pequena", "target": 5, "text": "Tenha 5 casas pequenas", "reward": 500.0},
	{"id": "m03", "type": "own", "key": "parque", "target": 1, "text": "Construa um parque", "reward": 400.0},
	{"id": "m04", "type": "bubbles", "target": 5, "text": "Toque em 5 moedas flutuantes", "reward": 600.0},
	{"id": "m05", "type": "earn", "target": 10000.0, "text": "Ganhe R$ 10.000", "reward": 1500.0},
	{"id": "m06", "type": "own", "key": "escola", "target": 1, "text": "Construa uma escola", "reward": 1000.0},
	{"id": "m07", "type": "level", "target": 5, "text": "Melhore um edifício até o nível 5", "reward": 1500.0},
	{"id": "m08", "type": "pop", "target": 50, "text": "Alcance 50 moradores", "reward": 2000.0},
	{"id": "m09", "type": "region", "target": 2, "text": "Desbloqueie o Bairro residencial", "reward": 3000.0, "bonus": 0.05},
	{"id": "m10", "type": "own", "key": "hospital", "target": 1, "text": "Construa um hospital", "reward": 8000.0},
	{"id": "m11", "type": "happy", "target": 80, "text": "Alcance 80% de felicidade", "reward": 10000.0},
	{"id": "m12", "type": "pop", "target": 100, "text": "Conquiste 100 moradores", "reward": 12000.0},
	{"id": "m13", "type": "own", "key": "casa_moderna", "target": 4, "text": "Tenha 4 casas modernas", "reward": 15000.0},
	{"id": "m14", "type": "income", "target": 200.0, "text": "Atinja renda de R$ 200/s", "reward": 20000.0},
	{"id": "m15", "type": "region", "target": 3, "text": "Desbloqueie o Centro comercial", "reward": 40000.0, "bonus": 0.05},
	{"id": "m16", "type": "own", "key": "prefeitura", "target": 1, "text": "Construa a Prefeitura", "reward": 100000.0},
	{"id": "m17", "type": "total_levels", "target": 100, "text": "Some 100 níveis nos edifícios", "reward": 150000.0},
	{"id": "m18", "type": "earn", "target": 1000000.0, "text": "Ganhe R$ 1 milhão", "reward": 200000.0},
	{"id": "m19", "type": "pop", "target": 1000, "text": "Alcance 1.000 moradores", "reward": 300000.0},
	{"id": "m20", "type": "region", "target": 4, "text": "Desbloqueie a Zona industrial", "reward": 600000.0, "bonus": 0.1},
	{"id": "m21", "type": "own", "key": "fabrica", "target": 2, "text": "Tenha 2 fábricas", "reward": 1500000.0},
	{"id": "m22", "type": "own", "key": "usina_solar", "target": 1, "text": "Construa uma usina solar", "reward": 2000000.0},
	{"id": "m23", "type": "level", "target": 50, "text": "Leve um edifício ao nível 50", "reward": 3000000.0},
	{"id": "m24", "type": "income", "target": 50000.0, "text": "Atinja renda de R$ 50 mil/s", "reward": 5000000.0},
	{"id": "m25", "type": "region", "target": 5, "text": "Desbloqueie o Centro financeiro", "reward": 10000000.0, "bonus": 0.1},
	{"id": "m26", "type": "own", "key": "empresa_tecnologia", "target": 1, "text": "Construa uma empresa de tecnologia", "reward": 20000000.0},
	{"id": "m27", "type": "pop", "target": 5000, "text": "Alcance 5.000 moradores", "reward": 50000000.0},
	{"id": "m28", "type": "earn", "target": 1000000000.0, "text": "Ganhe R$ 1 bilhão", "reward": 100000000.0},
	{"id": "m29", "type": "region", "target": 6, "text": "Desbloqueie a Grande metrópole", "reward": 200000000.0, "bonus": 0.1},
	{"id": "m30", "type": "own", "key": "estadio", "target": 1, "text": "Construa um estádio", "reward": 500000000.0},
	{"id": "m31", "type": "pop", "target": 35000, "text": "Alcance 35.000 moradores", "reward": 1000000000.0},
	{"id": "m32", "type": "region", "target": 7, "text": "Desbloqueie a Megacidade", "reward": 3000000000.0, "bonus": 0.15},
	{"id": "m33", "type": "own", "key": "torre_megacity", "target": 3, "text": "Tenha 3 Torres Megacidade", "reward": 10000000000.0},
	{"id": "m34", "type": "income", "target": 100000000.0, "text": "Atinja renda de R$ 100 mi/s", "reward": 30000000000.0},
	{"id": "m35", "type": "pop", "target": 100000, "text": "Alcance 100.000 moradores", "reward": 100000000000.0},
	{"id": "m36", "type": "earn", "target": 1000000000000.0, "text": "Ganhe R$ 1 trilhão", "reward": 500000000000.0, "bonus": 0.25},
]

# --- Conquistas permanentes (+2% de renda cada) --------------------------------
# stat: chave em MissionSystem.lifetime
const ACHIEVEMENTS := [
	{"id": "a_build_1", "name": "Primeira pedra", "desc": "Construa 1 edifício", "stat": "built", "target": 1},
	{"id": "a_build_25", "name": "Construtor", "desc": "Construa 25 edifícios", "stat": "built", "target": 25},
	{"id": "a_build_100", "name": "Mestre de obras", "desc": "Construa 100 edifícios", "stat": "built", "target": 100},
	{"id": "a_build_500", "name": "Império imobiliário", "desc": "Construa 500 edifícios", "stat": "built", "target": 500},
	{"id": "a_upg_100", "name": "Reformador", "desc": "Faça 100 melhorias", "stat": "upgrades", "target": 100},
	{"id": "a_upg_1000", "name": "Engenheiro-chefe", "desc": "Faça 1.000 melhorias", "stat": "upgrades", "target": 1000},
	{"id": "a_pop_100", "name": "Vilarejo", "desc": "Alcance 100 moradores", "stat": "max_pop", "target": 100},
	{"id": "a_pop_1k", "name": "Cidade de verdade", "desc": "Alcance 1.000 moradores", "stat": "max_pop", "target": 1000},
	{"id": "a_pop_10k", "name": "Metrópole", "desc": "Alcance 10.000 moradores", "stat": "max_pop", "target": 10000},
	{"id": "a_pop_100k", "name": "Megalópole", "desc": "Alcance 100.000 moradores", "stat": "max_pop", "target": 100000},
	{"id": "a_earn_1m", "name": "Milionário", "desc": "Ganhe R$ 1 milhão no total", "stat": "earned", "target": 1000000.0},
	{"id": "a_earn_1b", "name": "Bilionário", "desc": "Ganhe R$ 1 bilhão no total", "stat": "earned", "target": 1000000000.0},
	{"id": "a_earn_1t", "name": "Trilionário", "desc": "Ganhe R$ 1 trilhão no total", "stat": "earned", "target": 1000000000000.0},
	{"id": "a_happy_90", "name": "Cidade feliz", "desc": "Alcance 90% de felicidade", "stat": "max_happy", "target": 90},
	{"id": "a_happy_99", "name": "Paraíso urbano", "desc": "Alcance 99% de felicidade", "stat": "max_happy", "target": 99},
	{"id": "a_region_3", "name": "Expansionista", "desc": "Desbloqueie 3 regiões", "stat": "max_regions", "target": 3},
	{"id": "a_region_5", "name": "Urbanista", "desc": "Desbloqueie 5 regiões", "stat": "max_regions", "target": 5},
	{"id": "a_region_7", "name": "Senhor da Megacidade", "desc": "Desbloqueie todas as regiões", "stat": "max_regions", "target": 7},
	{"id": "a_level_25", "name": "Edifício premiado", "desc": "Leve um edifício ao nível 25", "stat": "max_level", "target": 25},
	{"id": "a_level_100", "name": "Obra-prima", "desc": "Leve um edifício ao nível 100", "stat": "max_level", "target": 100},
	{"id": "a_bubbles_50", "name": "Caçador de moedas", "desc": "Toque em 50 moedas flutuantes", "stat": "bubbles", "target": 50},
	{"id": "a_offline_8h", "name": "Descanso merecido", "desc": "Colete 8 horas de renda offline", "stat": "max_offline", "target": 28800},
	{"id": "a_prestige_1", "name": "Renascimento", "desc": "Faça o primeiro prestígio", "stat": "prestiges", "target": 1},
	{"id": "a_prestige_5", "name": "Lenda urbana", "desc": "Faça 5 prestígios", "stat": "prestiges", "target": 5},
	{"id": "a_build_50", "name": "50 construções", "desc": "Construa 50 edifícios", "stat": "built", "target": 50},
	{"id": "a_region_2", "name": "Primeira expansão", "desc": "Desbloqueie a primeira nova região", "stat": "max_regions", "target": 2},
	{"id": "a_region_6", "name": "Primeira metrópole", "desc": "Chegue à Grande metrópole", "stat": "max_regions", "target": 6},
	{"id": "a_region_8", "name": "Pé na areia", "desc": "Desbloqueie a Orla Dourada", "stat": "max_regions", "target": 8},
	{"id": "a_research_5", "name": "Cientista", "desc": "Conclua 5 pesquisas", "stat": "researched", "target": 5},
	{"id": "a_research_20", "name": "Gênio", "desc": "Conclua 20 pesquisas", "stat": "researched", "target": 20},
	{"id": "a_events_5", "name": "Agitador cultural", "desc": "Cumpra 5 objetivos de eventos", "stat": "events_done", "target": 5},
	{"id": "a_daily_10", "name": "Disciplinado", "desc": "Complete 10 desafios diários", "stat": "dailies", "target": 10},
	{"id": "a_special_1", "name": "Cartão-postal", "desc": "Construa um edifício especial", "stat": "specials", "target": 1},
	{"id": "a_invest_5", "name": "Investidor", "desc": "Resgate 5 investimentos", "stat": "investments", "target": 5},
]
## Recompensa em dinheiro de cada conquista (minutos da renda atual, mínimo R$ 500).
const ACHIEVEMENT_REWARD_MIN := 3.0
const ACHIEVEMENT_BONUS := 0.02

# --- Pesquisas -------------------------------------------------------------------
const RESEARCH_BRANCHES := [
	["construcao", "Construção avançada"], ["transporte", "Transporte público"],
	["industria", "Tecnologia industrial"], ["energia", "Energia eficiente"],
	["administracao", "Administração pública"], ["comercio", "Desenvolvimento comercial"],
]
## effects: build_time, build_cost, upgrade_cost, res_cap, growth, happy, biz, com, fun,
## all_income, upkeep, pollution, tax, coverage, event_duration
const RESEARCH := [
	{"id": "c1", "branch": "construcao", "name": "Canteiro organizado", "cost": 20, "req": [], "fx": {"build_time": -0.2}, "desc": "Obras 20% mais rápidas"},
	{"id": "c2", "branch": "construcao", "name": "Pré-moldados", "cost": 80, "req": ["c1"], "fx": {"build_cost": -0.1}, "desc": "Construções 10% mais baratas"},
	{"id": "c3", "branch": "construcao", "name": "Guindastes modernos", "cost": 350, "req": ["c2"], "fx": {"build_time": -0.3, "upgrade_cost": -0.05}, "desc": "Obras 30% mais rápidas e melhorias 5% mais baratas"},
	{"id": "c4", "branch": "construcao", "name": "Arquitetura vertical", "cost": 1400, "req": ["c3"], "fx": {"res_cap": 0.15}, "desc": "+15% de moradores em todas as residências"},
	{"id": "t1", "branch": "transporte", "name": "Linhas de ônibus", "cost": 30, "req": [], "fx": {"growth": 0.15, "happy": 2.0, "transit": 0.25}, "desc": "+15% crescimento, +2% felicidade e +25% capacidade de trânsito"},
	{"id": "t2", "branch": "transporte", "name": "Metrô", "cost": 160, "req": ["t1"], "fx": {}, "desc": "Libera a Estação de metrô"},
	{"id": "t3", "branch": "transporte", "name": "Logística marítima", "cost": 650, "req": ["t2"], "fx": {"biz": 0.1}, "desc": "Libera o Porto e +10% renda empresarial"},
	{"id": "t4", "branch": "transporte", "name": "Aviação civil", "cost": 2600, "req": ["t3"], "fx": {}, "desc": "Libera o Aeroporto"},
	{"id": "i1", "branch": "industria", "name": "Automação", "cost": 40, "req": [], "fx": {"biz": 0.15}, "desc": "+15% renda empresarial e industrial"},
	{"id": "i2", "branch": "industria", "name": "Filtros industriais", "cost": 170, "req": ["i1"], "fx": {"pollution": -0.4}, "desc": "-40% de poluição"},
	{"id": "i3", "branch": "industria", "name": "Indústria 4.0", "cost": 950, "req": ["i2"], "fx": {"biz": 0.25}, "desc": "+25% renda empresarial e industrial"},
	{"id": "e1", "branch": "energia", "name": "Lâmpadas LED", "cost": 25, "req": [], "fx": {"upkeep": -0.15}, "desc": "-15% nos custos de manutenção"},
	{"id": "e2", "branch": "energia", "name": "Redes inteligentes", "cost": 210, "req": ["e1"], "fx": {"upkeep": -0.25}, "desc": "-25% nos custos de manutenção"},
	{"id": "e3", "branch": "energia", "name": "Energia limpa", "cost": 1100, "req": ["e2"], "fx": {"happy": 4.0, "pollution": -0.3}, "desc": "+4% felicidade e -30% de poluição"},
	{"id": "a1", "branch": "administracao", "name": "Governo digital", "cost": 35, "req": [], "fx": {"tax": 0.1}, "desc": "+10% na arrecadação de impostos"},
	{"id": "a2", "branch": "administracao", "name": "Gestão de serviços", "cost": 190, "req": ["a1"], "fx": {"coverage": 0.25}, "desc": "Serviços públicos atendem 25% mais pessoas"},
	{"id": "a3", "branch": "administracao", "name": "Cidade inteligente", "cost": 1600, "req": ["a2"], "fx": {"all_income": 0.1}, "desc": "+10% em toda a renda da cidade"},
	{"id": "m1", "branch": "comercio", "name": "Marketing local", "cost": 30, "req": [], "fx": {"com": 0.15}, "desc": "+15% renda comercial"},
	{"id": "m2", "branch": "comercio", "name": "Turismo", "cost": 230, "req": ["m1"], "fx": {"fun": 0.2, "event_duration": 0.5}, "desc": "+20% renda de lazer e eventos positivos 50% mais longos"},
	{"id": "m3", "branch": "comercio", "name": "Grandes redes", "cost": 1200, "req": ["m2"], "fx": {"com": 0.25}, "desc": "+25% renda comercial"},
]

# --- Eventos aleatórios ----------------------------------------------------------
## goal: bubbles | build | upgrade | happy_end   fx: mesmas chaves das pesquisas + rp
const EVENTS := [
	{"id": "festival", "name": "Festival da cidade", "dur": 180, "good": true, "fx": {"happy": 8.0, "fun": 0.5, "com": 0.2},
		"desc": "Música, comida e muita festa nas ruas!", "goal": "bubbles", "target": 3, "goal_text": "Toque em 3 moedas flutuantes", "reward_min": 4.0, "reward_rp": 10},
	{"id": "boom", "name": "Boom imobiliário", "dur": 180, "good": true, "fx": {"build_cost": -0.25, "tax": 0.3},
		"desc": "Construções 25% mais baratas e impostos residenciais +30%.", "goal": "build", "target": 2, "goal_text": "Construa 2 edifícios", "reward_min": 5.0, "reward_rp": 10},
	{"id": "crise", "name": "Crise econômica", "dur": 150, "good": false, "fx": {"all_income": -0.15},
		"desc": "A economia esfriou: -15% de renda. Mantenha os moradores felizes!", "goal": "happy_end", "target": 50, "goal_text": "Termine com felicidade acima de 50%", "reward_min": 6.0, "reward_rp": 20},
	{"id": "turismo", "name": "Semana do turismo", "dur": 200, "good": true, "fx": {"com": 0.4, "fun": 0.4},
		"desc": "Turistas lotam a cidade: comércio e lazer +40%.", "goal": "upgrade", "target": 10, "goal_text": "Melhore 10 níveis", "reward_min": 5.0, "reward_rp": 10},
	{"id": "tempestade", "name": "Tempestade", "dur": 120, "good": false, "fx": {"all_income": -0.1, "upkeep": 0.25},
		"desc": "Chuva forte: -10% de renda e +25% de manutenção.", "goal": "upgrade", "target": 5, "goal_text": "Reforce a cidade: melhore 5 níveis", "reward_min": 6.0, "reward_rp": 15},
	{"id": "mutirao", "name": "Mutirão de obras", "dur": 150, "good": true, "fx": {"build_time": -0.5},
		"desc": "Obras 50% mais rápidas!", "goal": "build", "target": 1, "goal_text": "Construa 1 edifício", "reward_min": 3.0, "reward_rp": 10},
	{"id": "feira_tech", "name": "Feira de tecnologia", "dur": 150, "good": true, "fx": {"rp": 1.0},
		"desc": "Pesquisa em dobro durante a feira.", "goal": "bubbles", "target": 2, "goal_text": "Toque em 2 moedas flutuantes", "reward_min": 3.0, "reward_rp": 25},
]
const EVENT_INTERVAL := [240.0, 420.0]

# --- Desafios diários e metas semanais -------------------------------------------
## kind: build | upgrade | bubbles | earn_minutes | research | invest
const DAILY_TEMPLATES := [
	{"kind": "build", "min": 2, "max": 5, "text": "Construa %d edifícios"},
	{"kind": "upgrade", "min": 10, "max": 40, "text": "Melhore %d níveis"},
	{"kind": "bubbles", "min": 4, "max": 10, "text": "Toque em %d moedas flutuantes"},
	{"kind": "earn_minutes", "min": 20, "max": 40, "text": "Ganhe %s"},
	{"kind": "research", "min": 1, "max": 1, "text": "Conclua %d pesquisa"},
	{"kind": "invest", "min": 1, "max": 2, "text": "Resgate %d investimento(s)"},
]
const WEEKLY_TEMPLATES := [
	{"kind": "build", "min": 15, "max": 25, "text": "Construa %d edifícios"},
	{"kind": "upgrade", "min": 120, "max": 200, "text": "Melhore %d níveis"},
	{"kind": "bubbles", "min": 30, "max": 50, "text": "Toque em %d moedas flutuantes"},
	{"kind": "earn_minutes", "min": 240, "max": 360, "text": "Ganhe %s"},
	{"kind": "research", "min": 4, "max": 6, "text": "Conclua %d pesquisas"},
]
const DAILY_REWARD_MIN := 15.0
const DAILY_REWARD_RP := 15
const WEEKLY_REWARD_MIN := 60.0
const WEEKLY_REWARD_RP := 80

# --- Bônus temporários -----------------------------------------------------------
## fx aplicado enquanto ativo (mesmas chaves dos modificadores).
const BOOSTS := {
	"renda": {"name": "Renda em dobro", "fx": {"all_income": 1.0}, "icon": "coin", "desc": "Toda a renda da cidade x2"},
	"obras": {"name": "Obras turbo", "fx": {"build_time": -0.5}, "icon": "build", "desc": "Obras 2x mais rápidas"},
	"pesquisa": {"name": "Ciência acelerada", "fx": {"rp": 1.0}, "icon": "research", "desc": "Pontos de pesquisa x2"},
	"populacao": {"name": "Onda de migração", "fx": {"growth": 1.0}, "icon": "people", "desc": "Crescimento populacional x2"},
}
const FREE_BOOST_SECONDS := 600.0
const FREE_BOOST_COOLDOWN := 10800.0
const BOOST_MAX_SECONDS := 7200.0
const GOLDEN_COIN_CHANCE := 0.07
## Recompensa diária (sequência de 7 dias). kind: money (minutos de renda) | rp | boost | star
const LOGIN_REWARDS := [
	[{"kind": "money", "v": 5}],
	[{"kind": "rp", "v": 20}],
	[{"kind": "boost", "id": "renda", "v": 600}],
	[{"kind": "money", "v": 15}],
	[{"kind": "boost", "id": "obras", "v": 900}],
	[{"kind": "rp", "v": 60}, {"kind": "boost", "id": "pesquisa", "v": 900}],
	[{"kind": "star", "v": 1}, {"kind": "boost", "id": "renda", "v": 1800}],
]

# --- Índices urbanos --------------------------------------------------------------
## Capacidade viária base por região desbloqueada (moradores que se deslocam sem trânsito).
const ROAD_CAPACITY_BASE := 300.0
const ROAD_CAPACITY_PER_REGION := 1000.0

# --- Finanças --------------------------------------------------------------------
const TAX_LEVELS := [
	{"name": "Baixo", "mult": 0.75, "happy": 5.0},
	{"name": "Normal", "mult": 1.0, "happy": 0.0},
	{"name": "Alto", "mult": 1.3, "happy": -6.0},
	{"name": "Muito alto", "mult": 1.6, "happy": -14.0},
]
const INVESTMENTS := [
	{"id": "poupanca", "name": "Poupança", "dur": 600.0, "min": 0.01, "max": 0.01, "desc": "10 minutos, rende 1%"},
	{"id": "cdb", "name": "CDB", "dur": 3600.0, "min": 0.08, "max": 0.08, "desc": "1 hora, rende 8%"},
	{"id": "fundo", "name": "Fundo imobiliário", "dur": 14400.0, "min": 0.4, "max": 0.4, "desc": "4 horas, rende 40%"},
	{"id": "acoes", "name": "Ações", "dur": 28800.0, "min": -0.1, "max": 1.5, "desc": "8 horas, de -10% a +150% (risco!)"},
]
const MAX_INVESTMENTS := 3
const LOAN_INTEREST := 0.15
const LOAN_REPAY_SHARE := 0.15

# --- Prestígio -----------------------------------------------------------------
const PRESTIGE_MIN_REGIONS := 3
const PRESTIGE_DIVISOR := 1000000.0
const STAR_INCOME_BONUS := 0.05
const PRESTIGE_UPGRADES := [
	{"id": "marketing", "name": "Marketing municipal", "desc": "+10% de renda por nível", "max": 15, "base": 1.0, "growth": 1.5},
	{"id": "eficiencia", "name": "Construtora eficiente", "desc": "-5% no custo de construções e melhorias por nível", "max": 8, "base": 2.0, "growth": 1.6},
	{"id": "imigracao", "name": "Imigração", "desc": "+25% de crescimento e +5% de capacidade por nível", "max": 6, "base": 2.0, "growth": 1.6},
	{"id": "carisma", "name": "Prefeito carismático", "desc": "+4% de felicidade por nível", "max": 5, "base": 2.0, "growth": 1.7},
	{"id": "capital", "name": "Capital inicial", "desc": "Comece cada cidade com mais dinheiro", "max": 4, "base": 3.0, "growth": 2.6},
	{"id": "heranca", "name": "Bairros herdados", "desc": "Comece com regiões já desbloqueadas", "max": 3, "base": 5.0, "growth": 2.8},
	{"id": "obras", "name": "Obras aceleradas", "desc": "-15% no tempo de construção por nível", "max": 4, "base": 2.0, "growth": 1.8},
	{"id": "laboratorio", "name": "Laboratório", "desc": "+25% de pontos de pesquisa por nível", "max": 6, "base": 2.0, "growth": 1.7},
	{"id": "juros", "name": "Juros melhores", "desc": "+10% de rendimento dos investimentos por nível", "max": 5, "base": 3.0, "growth": 1.9},
]
const CAPITAL_LEVELS := [0.0, 10000.0, 250000.0, 5000000.0, 100000000.0]

static var _index: Dictionary = {}


static func get_def(id: String) -> Dictionary:
	if _index.is_empty():
		for d in BUILDINGS:
			_index[d["id"]] = d
	return _index.get(id, {})


static func has_def(id: String) -> bool:
	return not get_def(id).is_empty()


static func buildings_in_category(cat: String) -> Array:
	var out := []
	for d in BUILDINGS:
		if d["cat"] == cat:
			out.append(d)
	return out


static func region_count() -> int:
	return REGIONS.size()


static func total_lots() -> int:
	return REGIONS.size() * LOTS_PER_REGION


static func lot_center_x(lot: int) -> float:
	return WORLD_MARGIN + lot * LOT_W + LOT_W * 0.5


static func region_start_x(region: int) -> float:
	return WORLD_MARGIN + region * LOTS_PER_REGION * LOT_W


static func region_end_x(region: int) -> float:
	return region_start_x(region + 1)


static func world_width() -> float:
	return WORLD_MARGIN * 2.0 + total_lots() * LOT_W


static func region_of_x(x: float) -> int:
	var r := int(floor((x - WORLD_MARGIN) / (LOTS_PER_REGION * LOT_W)))
	return clampi(r, 0, REGIONS.size() - 1)


static func mission_index(id: String) -> int:
	for i in MISSIONS.size():
		if MISSIONS[i]["id"] == id:
			return i
	return -1


static func prestige_upgrade(id: String) -> Dictionary:
	for u in PRESTIGE_UPGRADES:
		if u["id"] == id:
			return u
	return {}


static func research_def(id: String) -> Dictionary:
	for r in RESEARCH:
		if r["id"] == id:
			return r
	return {}


static func event_def(id: String) -> Dictionary:
	for e in EVENTS:
		if e["id"] == id:
			return e
	return {}


static func investment_def(id: String) -> Dictionary:
	for i in INVESTMENTS:
		if i["id"] == id:
			return i
	return {}


## Tempo de construção (segundos) antes de bônus.
static func base_build_time(def: Dictionary) -> float:
	var t := clampf(3.0 + 7.0 * log(maxf(float(def["cost"]), 100.0) / 100.0) / log(10.0), 3.0, 120.0)
	if def["cat"] == "esp":
		t *= 2.5
	return t


static func boost_def(id: String) -> Dictionary:
	return BOOSTS.get(id, {})
