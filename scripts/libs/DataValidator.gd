# DataValidator.gd
# Uma biblioteca de validação de dados com schema para Godot Script
# Inspirada no Zod (JavaScript)

class_name DataValidator

# Tipos básicos de dados
enum Type {
	STRING,
	INT,
	FLOAT,
	BOOL,
	ARRAY,
	DICT,
	OBJECT,
	ANY
}

var _type: int = Type.ANY
var _optional: bool = false
var _nullable: bool = false
var _default = null
var _has_default: bool = false
var _min = null
var _max = null
var _regex = null
var _allowed_values = null
var _custom_validator = null
var _array_schema = null
var _dict_schema = {}
var _error_message: String = ""

# Construtores para cada tipo
static func string() -> DataValidator:
	var validator = DataValidator.new()
	validator._type = Type.STRING
	return validator

static func int() -> DataValidator:
	var validator = DataValidator.new()
	validator._type = Type.INT
	return validator
	
static func float() -> DataValidator:
	var validator = DataValidator.new()
	validator._type = Type.FLOAT
	return validator
	
static func bool() -> DataValidator:
	var validator = DataValidator.new()
	validator._type = Type.BOOL
	return validator
	
static func array(item_schema = null) -> DataValidator:
	var validator = DataValidator.new()
	validator._type = Type.ARRAY
	validator._array_schema = item_schema
	return validator
	
static func dict(schema = {}) -> DataValidator:
	var validator = DataValidator.new()
	validator._type = Type.DICT
	validator._dict_schema = schema
	return validator
	
static func object(obj_type) -> DataValidator:
	var validator = DataValidator.new()
	validator._type = Type.OBJECT
	validator._custom_validator = func(value): return value is obj_type
	return validator
	
static func any() -> DataValidator:
	return DataValidator.new()

# Modificadores
func optional() -> DataValidator:
	self._optional = true
	return self

func nullable() -> DataValidator:
	self._nullable = true
	return self
	
func default(value) -> DataValidator:
	self._default = value
	self._has_default = true
	return self
	
func min(value) -> DataValidator:
	self._min = value
	return self
	
func max(value) -> DataValidator:
	self._max = value
	return self
	
func regex(pattern: String) -> DataValidator:
	self._regex = RegEx.new()
	self._regex.compile(pattern)
	return self
	
func values(allowed_values: Array) -> DataValidator:
	self._allowed_values = allowed_values
	return self
	
func custom(validator_func: Callable) -> DataValidator:
	self._custom_validator = validator_func
	return self

# Método principal de validação
func validate(data):
	self._error_message = ""
	
	# Verificação de valor null
	if data == null:
		if self._nullable:
			return {"valid": true, "value": null}
		elif self._optional:
			if self._has_default:
				return {"valid": true, "value": self._default}
			return {"valid": true, "value": null}
		else:
			self._error_message = "Valor não pode ser null"
			return {"valid": false, "error": self._error_message}
	
	# Verificação de tipo básico
	if !_validate_type(data):
		return {"valid": false, "error": self._error_message}
	
	# Verificar valores permitidos
	if self._allowed_values != null and not data in self._allowed_values:
		self._error_message = "Valor deve ser um dos valores permitidos"
		return {"valid": false, "error": self._error_message}
	
	# Verificações específicas para cada tipo
	match self._type:
		Type.STRING:
			if !_validate_string(data):
				return {"valid": false, "error": self._error_message}
		Type.INT, Type.FLOAT:
			if !_validate_number(data):
				return {"valid": false, "error": self._error_message}
		Type.ARRAY:
			if !_validate_array(data):
				return {"valid": false, "error": self._error_message}
		Type.DICT:
			if !_validate_dict(data):
				return {"valid": false, "error": self._error_message}
	
	# Validador personalizado
	if self._custom_validator != null:
		if !self._custom_validator.call(data):
			self._error_message = "Falhou na validação personalizada"
			return {"valid": false, "error": self._error_message}
	
	return {"valid": true, "value": data}

# Validação de tipo
func _validate_type(data) -> bool:
	match self._type:
		Type.STRING:
			if not data is String:
				self._error_message = "Valor deve ser uma string"
				return false
		Type.INT:
			if not data is int:
				self._error_message = "Valor deve ser um inteiro"
				return false
		Type.FLOAT:
			if not (data is float or data is int):
				self._error_message = "Valor deve ser um número"
				return false
		Type.BOOL:
			if not data is bool:
				self._error_message = "Valor deve ser um booleano"
				return false
		Type.ARRAY:
			if not data is Array:
				self._error_message = "Valor deve ser um array"
				return false
		Type.DICT:
			if not data is Dictionary:
				self._error_message = "Valor deve ser um dicionário"
				return false
	return true

# Validação de string
func _validate_string(data: String) -> bool:
	if self._min != null and data.length() < self._min:
		self._error_message = "String deve ter no mínimo %d caracteres" % self._min
		return false
		
	if self._max != null and data.length() > self._max:
		self._error_message = "String deve ter no máximo %d caracteres" % self._max
		return false
		
	if self._regex != null and !self._regex.search(data):
		self._error_message = "String não corresponde ao padrão regex"
		return false
		
	return true

# Validação de número
func _validate_number(data) -> bool:
	if self._min != null and data < self._min:
		self._error_message = "Valor deve ser maior ou igual a %s" % str(self._min)
		return false
		
	if self._max != null and data > self._max:
		self._error_message = "Valor deve ser menor ou igual a %s" % str(self._max)
		return false
		
	return true

# Validação de array
func _validate_array(data: Array) -> bool:
	if self._min != null and data.size() < self._min:
		self._error_message = "Array deve ter no mínimo %d itens" % self._min
		return false
		
	if self._max != null and data.size() > self._max:
		self._error_message = "Array deve ter no máximo %d itens" % self._max
		return false
	
	if self._array_schema != null:
		for i in range(data.size()):
			var result = self._array_schema.validate(data[i])
			if !result.valid:
				self._error_message = "Item %d do array é inválido: %s" % [i, result.error]
				return false
	
	return true

# Validação de dicionário
func _validate_dict(data: Dictionary) -> bool:
	if self._dict_schema.is_empty():
		return true
		
	# Verificar se todas as chaves necessárias estão presentes
	for key in self._dict_schema.keys():
		var schema = self._dict_schema[key]
		
		if not data.has(key):
			if schema._optional or schema._has_default:
				continue
			self._error_message = "Chave obrigatória '%s' está ausente" % key
			return false
	
	# Validar cada valor
	for key in data.keys():
		if not self._dict_schema.has(key):
			continue  # Permite chaves extras por padrão
			
		var schema = self._dict_schema[key]
		var result = schema.validate(data[key])
		
		if !result.valid:
			self._error_message = "Valor para a chave '%s' é inválido: %s" % [key, result.error]
			return false
	
	return true

# Método para criar um esquema de objeto completo
static func schema(structure: Dictionary) -> DataValidator:
	return dict(structure)

# Método parse que lança erro em caso de falha
func parse(data):
	var result = validate(data)
	if result.valid:
		return result.value
	else:
		push_error(result.error)
		return null

# Método parse_safe que retorna o resultado completo
func parse_safe(data):
	return validate(data)
