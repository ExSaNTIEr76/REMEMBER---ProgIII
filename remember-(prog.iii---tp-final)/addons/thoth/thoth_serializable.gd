extends Node
class_name ThothSerializable

@export var transform: bool = true
@export var children: bool = true
@export var variables: Array[String] = []


static func _serialize_get_serializable(object):
	if object is Node:
		for child in object.get_children():
			if child is ThothSerializable:
				return child

	elif object is Resource:
		if object is ThothSerializable:
			return object

		var property_names: Array[String] = []
		for prop in object.get_property_list():
			if prop.name.begins_with("_"):
				continue
			if prop.usage & PROPERTY_USAGE_STORAGE != 0:
				property_names.append(prop.name)

		return {
			"transform": false,
			"children": false,
			"variables": property_names
		}

	return null
