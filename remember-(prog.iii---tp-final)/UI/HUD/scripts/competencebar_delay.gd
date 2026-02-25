class_name CompetencebarDelay    extends Competencebar

@export var delayCompetenceBar : Competencebar
@export var updateValueDelayTimer : Timer

func _ready() -> void:
	updateValueDelayTimer.timeout.connect(updateChildBar)

func updateChildBar() -> void:
	delayCompetenceBar.updateValue(value)

func setUp(maxValue : float) -> void:
	super.setUp(maxValue)
	delayCompetenceBar.setUp(maxValue)

func updateValue(_newValue : float) -> void:
	super.updateValue(_newValue)
	updateValueDelayTimer.start()
