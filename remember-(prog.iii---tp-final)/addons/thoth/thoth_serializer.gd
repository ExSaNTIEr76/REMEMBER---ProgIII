extends Node
class_name ThothSerializer

######################################
## variable serialization
######################################

static func _serialize_variable(variable, object_convert_to_references = false):
	match typeof(variable):
		TYPE_NIL:
			return null
		TYPE_VECTOR2:
			return _serialize_vector2(variable)
		TYPE_VECTOR3:
			return _serialize_vector3(variable)
		TYPE_COLOR:
			return _serialize_color(variable)
		TYPE_BASIS:
			return _serialize_basis(variable)
		TYPE_TRANSFORM3D:
			return _serialize_transform(variable)
		TYPE_TRANSFORM2D:
			return _serialize_transform2d(variable)
		TYPE_ARRAY:
			return _serialize_array(variable)
		TYPE_DICTIONARY:
			return _serialize_dictionary(variable)
		TYPE_OBJECT:
			if object_convert_to_references:
				return _serialize_object_reference(variable)
			return _serialize_object(variable)
	return variable

######################################
## data types serialization
######################################

static func _serialize_vector2(input):
	return {
		"type": "vector2",
		"x" : input.x,
		"y" : input.y
	}

static func _serialize_vector3(input):
	return {
		"type": "vector3",
		"x" : input.x,
		"y" : input.y,
		"z" : input.z
	}

static func _serialize_color(input):
	return {
		"type": "color",
		"r" : input.r,
		"g" : input.g,
		"b" : input.b,
		"a" : input.a
	}

static func _serialize_basis(input):
	return {
		"type": "basis",
		"x": _serialize_variable(input.x),
		"y": _serialize_variable(input.y),
		"z": _serialize_variable(input.z)
	}

static func _serialize_transform(input):
	return {
		"type": "transform",
		"basis": _serialize_variable(input.basis),
		"origin": _serialize_variable(input.origin)
	}

static func _serialize_transform2d(input):
	return {
		"type": "transform2d",
		"x": _serialize_variable(input.x),
		"y": _serialize_variable(input.y),
		"origin": _serialize_variable(input.origin)
	}

static func _serialize_array(input):
	var array = []
	for entry in input:
		array.push_back(_serialize_variable(entry, true))
	return {
		"type": "array",
		"data": array
	}

static func _serialize_dictionary(input):
	var dict = {}
	for entry in input:
		dict[entry] = _serialize_variable(input[entry], true)
	return {
		"type": "dictionary",
		"data": dict
	}


static func _serialize_object_reference(object):
	if not is_instance_valid(object):
		return null

	return {
		"type": "object_reference",
		"name": _serialize_get_path(object)
	}




static func _serialize_children(object):
	var children = {}
	for child in object.get_children():
		if child is ThothSerializable or child is ThothGameState:
			continue
		if ThothSerializable._serialize_get_serializable(child):
			children[_serialize_get_name(child)] = _serialize_object(child)
		else:
			var recurse = _serialize_children(child)
			if recurse == {}:
				continue
			children[_serialize_get_name(child)] = recurse
	return children



static func _serialize_get_name(object):
	# Para Nodes usamos su name de escena
	if object is Node:
		return str(object.name).replace("@", "_")
	# Para Resources usamos resource_name o el nombre de la clase
	elif object is Resource:
		if object.resource_name != "":
			return str(object.resource_name).replace("@", "_")
		return object.get_class()
	# Fallback genérico
	return str(object).replace("@", "_")

static func _serialize_get_path(object):
	if not is_instance_valid(object):
		return null

	if object is Node:
		return str(object.get_path()).replace("@", "_")
	elif object is Resource:
		if object.resource_path != "":
			return str(object.resource_path).replace("@", "_")
		if object.resource_name != "":
			return str(object.resource_name).replace("@", "_")
		return object.get_class()

	return str(object).replace("@", "_")


static func _serialize_object(object):
	if not is_instance_valid(object):
		return null

	var serializable = ThothSerializable._serialize_get_serializable(object)
	if serializable == null:
		return null

	var serialized = {
		"type": "object",
		"name": _serialize_get_name(object),
	}

	# 🔹 Recursos: no tienen transform ni children
	if object is Resource:
		serialized["object_type"] = object.get_class()

	else:
		# 🔹 Escenas normales
		if object is TileMap:
			serialized["core_object"] = true
			serialized["object_type"] = "TileMap"
		elif object.scene_file_path == "":
			serialized["core_object"] = true
			serialized["object_type"] = object.get_class()
		else:
			serialized["scene_file_path"] = object.scene_file_path

	# Transform solo si aplica
	var has_transform := false
	if typeof(serializable) == TYPE_DICTIONARY:
		has_transform = serializable.has("transform") and serializable["transform"]
	elif serializable is ThothSerializable:
		has_transform = serializable.transform

	if has_transform and object.has_method("get_transform"):
		serialized["transform"] = _serialize_variable(object.transform)


	# Variables
	var vars_list := []
	if typeof(serializable) == TYPE_DICTIONARY and serializable.has("variables"):
		vars_list = serializable["variables"]
	elif serializable is ThothSerializable:
		vars_list = serializable.variables

	if len(vars_list) > 0:
		serialized["variables"] = {}

		# Cacheamos las propiedades existentes si es un Resource
		var valid_props := []
		if object is Resource:
			for prop in object.get_property_list():
				valid_props.append(prop.name)

		# Cacheamos propiedades de nodos
		var node_props := []
		if object is Node:
			for prop in object.get_property_list():
				node_props.append(prop.name)

		for variable in vars_list:
			# ⚙️ Validamos que se pueda obtener
			if not object.has_method("get"):
				continue
			if object is Resource and not (variable in valid_props):
				continue
			if object is Node and not (variable in node_props):
				continue

			# Serializamos valor
			var value = object.get(variable)

			# ❌ no serializar instancias muertas
			if typeof(value) == TYPE_OBJECT and not is_instance_valid(value):
				continue

			# ❌ no serializar Timers / Tweens / Callables
			if value is Timer or value is Tween or value is Callable:
				continue

			serialized["variables"][variable] = _serialize_variable(value, true)



	# Children solo si aplica
	var has_children := false
	if typeof(serializable) == TYPE_DICTIONARY:
		has_children = serializable.has("children") and serializable["children"]
	elif serializable is ThothSerializable:
		has_children = serializable.children

	if has_children and object is Node:
		serialized["children"] = _serialize_children(object)


	return serialized
