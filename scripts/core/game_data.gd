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

const CATEGORIES := ["res", "com", "biz", "pub", "fun"]
const CATEGORY_NAMES := {
	"res": "Residencial",
	"com": "Comercial",
	"biz": "Empresarial",
	"pub": "Serviços",
	"fun": "Lazer",
}
const CATEGORY_COLORS := {
	"res": Color("4fa3e0"),
	"com": Color("f39c12"),
	"biz": Color("8e6fd8"),
	"pub": Color("e05a5a"),
	"fun": Color("3fbf6f"),
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
]

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
]
const ACHIEVEMENT_BONUS := 0.02

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
