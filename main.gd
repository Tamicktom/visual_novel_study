extends Node2D

func _ready():
	validar_usuario();
	pass;

func validar_usuario():
	print("\n=== Validação de Usuário ===")

	# Definir o schema
	var user_schema = DataValidator.schema({
		"nome": DataValidator.string().min(3).max(50),
		"idade": DataValidator.int().min(18),
		"email": DataValidator.string().regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"),
		"avatar": DataValidator.string().optional(),
		# "configuracoes": DataValidator.dict({
		# 	"tema": DataValidator.string().values(["claro", "escuro", "sistema"]).default("sistema"),
		# 	"notificacoes": DataValidator.bool().default(true)
		# })
	})

	# Dados válidos
	var dados_validos = {
		"nome": "João Silva",
		"idade": 25,
		"email": "joao@exemplo.com",
		"configuracoes": {
			"tema": "escuro"
		}
	}

	# Validar dados
	var resultado = user_schema.parse_safe(dados_validos)
	if resultado.valid:
		print("Usuário válido:", resultado.value)
	else:
		print("Erro de validação:", resultado.error)

	# Dados inválidos
	var dados_invalidos = {
		"nome": "Jo", # Nome muito curto
		"idade": 16, # Idade abaixo do mínimo
		"email": "invalido" # Email inválido
	}

	# Validar dados inválidos
	resultado = user_schema.parse_safe(dados_invalidos)
	if !resultado.valid:
		print("Erro esperado:", resultado.error)
