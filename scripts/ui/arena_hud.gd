class_name ArenaHud
extends CanvasLayer
## Kanit sahnesi hata ayiklama HUD'i: performans izleyicileri + konum + durum.
## Godot varsayilan fontu kullanir (Turkce glif guvencesi; production fontu
## ASSET_PIPELINE B.9.3 dogrulamasiyla eklenecek).

signal pause_button_pressed
signal wave_button_pressed
signal bench_button_pressed

@onready var perf_label: Label = $Root/PerfLabel
@onready var pos_label: Label = $Root/PosLabel
@onready var status_label: Label = $Root/StatusLabel
@onready var combat_label: Label = $Root/CombatLabel
@onready var pause_button: Button = $Root/PauseButton
@onready var wave_button: Button = $Root/WaveButton
@onready var bench_button: Button = $Root/BenchButton

var _accumulator: float = 0.0


func _ready() -> void:
        pause_button.pressed.connect(func() -> void: pause_button_pressed.emit())
        wave_button.pressed.connect(func() -> void: wave_button_pressed.emit())
        bench_button.pressed.connect(func() -> void: bench_button_pressed.emit())


func _process(delta: float) -> void:
        _accumulator += delta
        if _accumulator < 0.2:
                return
        _accumulator = 0.0
        var fps := int(Performance.get_monitor(Performance.TIME_FPS))
        var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
        var objects := int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
        var vram_mb := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / (1024.0 * 1024.0)
        perf_label.text = "FPS: %d  |  Draw call: %d  |  Objeler: %d  |  VRAM: %.1f MB" % [
                fps, draws, objects, vram_mb
        ]


func update_position(cell: Vector2i, world: Vector2, zoom: float) -> void:
        pos_label.text = "Hücre: (%d, %d)   |   Konum: (%.0f, %.0f)   |   Zoom: %.2f" % [
                cell.x, cell.y, world.x, world.y, zoom
        ]


func set_status(text: String) -> void:
        status_label.text = text


func set_combat_info(text: String) -> void:
        combat_label.text = text
