## DialogueNode — individual node in a dialogue tree.
## Note: Dialogues are primarily loaded from JSON. This resource is for
## editor-authored dialogues and type reference.
class_name DialogueNode
extends Resource

enum NodeType { TEXT, CHOICE, END }

@export var node_id: String = ""
@export var type: NodeType = NodeType.TEXT
@export var speaker: String = ""
@export var portrait: String = "neutral"
@export var text: String = ""
@export var slot_fills: Dictionary = {}
@export var conditions: Array = []
@export var triggers: Array[Dictionary] = []
@export var next_node: String = ""

# For CHOICE type
@export var options: Array[Dictionary] = []
