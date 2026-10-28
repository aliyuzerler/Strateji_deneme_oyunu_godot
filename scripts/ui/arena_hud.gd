class_name ArenaHud
extends CanvasLayer
## Gelistirici/teshis HUD'i (kanit sahnesinden kalanti; Faz 06'da DEV paneli
## olarak gorunur — varsayilan gizli, GameHud DEV dugmesiyle acilir).
## Godot varsayilan fontu kullanir (Turkce glif guvencesi; production fontu
## ASSET_PIPELINE B.9.3 dogrulamasiyla eklenecek).
##
## Performans satirlari: FPS/draw/VRAM + konum + durum + savas bilgisi +
## FX butce durumu (Faz 06). Davranis metotlari aynen korunur (smoke uyumu).

signal pause_button_pressed
signal wave_button_pressed
signal bench_button_pressed

@onready var dev_panel: Control = $Root/DevPanel
@onready var perf_label: Label = $Root/DevPanel/PerfLabel
@onready var pos_label: Label = $Root/DevPanel/PosLabel
@onready var status_label: Label = $Root/DevPanel/StatusLabel
@onready var combat_label: Label = $Root/DevPanel/CombatLabel
@onready var fx_label: Label = $Root/DevPanel/FxLabel
@onready var pause_button: Button = $Root/DevPanel/PauseButton
@onready var wave_button: Button = $Root/DevPanel/WaveButton
@onready var bench_button: Button = $Root/DevPanel/BenchButton
@onready var hint_label: Label = $Root/DevPanel/HintLabel

var _accumulator: float = 0.0


func _ready() -> void:
        pause_button.pressed.connect(func() -> void: pause_button_pressed.emit())
        wave_button.pressed.connect(func() -> void: wave_button_pressed.emit())
        bench_button.pressed.connect(func() -> void: bench_button_pressed.emit())
        dev_panel.visible = false


func set_dev_visible(shown: bool) -> void:
        dev_panel.visible = shown


func _process(delta: float) -> void:
        if not dev_panel.visible:
                return
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


func set_fx_info(text: String) -> void:
        fx_label.text = text
