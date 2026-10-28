class_name GameHud
extends CanvasLayer
## Faz 06: mobil oyun HUD'u (ART_DIRECTION B.9/B.12, ARCHITECTURE B.14).
##
## Yerlesim (guvenli alan icinde — DisplayServer.get_display_safe_area):
##   sol ust  : can barı (amber; %30 alti kizil) + XP barı (turkuaz) + seviye
##   orta ust : hayatta kalma suresi (MM:SS) + dalga + bildirim (toast)
##   sag ust  : hurda sayacı + DEV toggle + duraklat dugmesi
##   sol alt  : sanal joystick (320x320 dokunma hedefi)
##   sag alt  : Enerji Patlamasi + Atılım yetenek dugmeleri (96x96, radyal
##              cooldown)
##   merkez   : seviye atlama yetenek secimi (acikken oyun ARENA tarafindan
##              duraklatilir; secim/atlama ile devam eder)
##
## En-boy orani: stretch canvas_items+expand + tum yerlesim anchor tabanli
## -> 16:9, 19.5:9, 4:3 vb. oranlarda govde kaymasi olmadan adapte olur.
## Ikonlar/dokular GECICI (TMP) placeholder'dir (ASSET_LICENSES.csv).

signal joystick_moved(vector: Vector2)
signal ability_burst_pressed
signal ability_dash_pressed
signal pause_pressed
signal dev_toggled(shown: bool)
signal upgrade_chosen(id: String)
signal upgrade_skipped

const TEX_JOY_BASE := preload("res://assets/art/ui/tex_ui_joystick_base_01.png")
const TEX_JOY_KNOB := preload("res://assets/art/ui/tex_ui_joystick_knob_01.png")
const TEX_IC_BURST := preload("res://assets/art/ui/tex_ui_icon_burst_01.png")
const TEX_IC_DASH := preload("res://assets/art/ui/tex_ui_icon_dash_01.png")
const TEX_SCRAP := preload("res://assets/art/vfx/tex_fx_scrap_01.png")

# palet kisaltmalari (ART_DIRECTION B.4)
const GR900 := Color(0.078, 0.086, 0.102)
const GR800 := Color(0.106, 0.118, 0.137)
const GR700 := Color(0.149, 0.157, 0.173)
const GR600 := Color(0.227, 0.239, 0.267)
const GR400 := Color(0.604, 0.639, 0.686)
const KU100 := Color(0.965, 0.89, 0.72)
const KU300 := Color(0.91, 0.79, 0.56)
const KU500 := Color(0.85, 0.63, 0.36)
const TE500 := Color(0.18, 0.77, 0.71)
const TK500 := Color(0.84, 0.27, 0.25)

var player: CombatUnit = null
var state: PlayerState = null
var budget: FXBudget = null

var _root: Control
var _safe: Control
var _notch: Control
var _hp_bar: ProgressBar
var _hp_fill: StyleBoxFlat
var _hp_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _time_label: Label
var _wave_label: Label
var _toast_label: Label
var _scrap_label: Label
var _pause_btn: Button
var _dev_btn: Button
var _joy: TouchJoystick
var _burst_btn: Button
var _dash_btn: Button
var _burst_cd: TextureProgressBar
var _dash_cd: TextureProgressBar
var _burst_cd_lbl: Label
var _dash_cd_lbl: Label
var _levelup_root: Control
var _levelup_title: Label
var _levelup_cards: HBoxContainer
var _toast_tween: Tween
var _burst_was_ready := true
var _dash_was_ready := true
var _refresh_acc := 0.0
var _debug_notch := false
var _debug_insets := Vector4.ZERO  # l,t,r,b — test modu


func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        _root = Control.new()
        _root.name = "Root"
        _root.set_anchors_preset(Control.PRESET_FULL_RECT)
        _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(_root)
        _safe = Control.new()
        _safe.name = "SafeMargin"
        _safe.set_anchors_preset(Control.PRESET_FULL_RECT)
        _safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _root.add_child(_safe)
        _notch = Control.new()
        _notch.set_anchors_preset(Control.PRESET_FULL_RECT)
        _notch.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _notch.draw.connect(_draw_notch)
        _safe.add_child(_notch)
        _build_top_left()
        _build_top_center()
        _build_top_right()
        _build_bottom_left()
        _build_bottom_right()
        _build_levelup_panel()
        _apply_safe_area()
        get_viewport().size_changed.connect(_apply_safe_area)


# ---------------------------------------------------------------- kurulum

func _label(parent: Control, size: int, color: Color) -> Label:
        var l := Label.new()
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        l.add_theme_font_size_override("font_size", size)
        l.add_theme_color_override("font_color", color)
        l.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.07, 0.9))
        l.add_theme_constant_override("outline_size", 6)
        parent.add_child(l)
        return l


func _panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
        var sb := StyleBoxFlat.new()
        sb.bg_color = bg
        sb.border_color = border
        sb.set_border_width_all(2)
        sb.set_corner_radius_all(radius)
        return sb


func _build_top_left() -> void:
        var box := VBoxContainer.new()
        box.name = "TopLeft"
        box.position = Vector2(16, 12)
        box.add_theme_constant_override("separation", 5)
        box.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _safe.add_child(box)
        # can barı
        var hp_holder := Control.new()
        hp_holder.custom_minimum_size = Vector2(400, 28)
        hp_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
        box.add_child(hp_holder)
        _hp_bar = ProgressBar.new()
        _hp_bar.show_percentage = false
        _hp_bar.custom_minimum_size = Vector2(400, 28)
        _hp_bar.size = Vector2(400, 28)
        _hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var hp_bg := _panel_style(Color(GR900.r, GR900.g, GR900.b, 0.82), GR600, 8)
        _hp_fill = _panel_style(KU500, GR700, 8)
        _hp_bar.add_theme_stylebox_override("background", hp_bg)
        _hp_bar.add_theme_stylebox_override("fill", _hp_fill)
        hp_holder.add_child(_hp_bar)
        _hp_label = _label(hp_holder, 18, KU100)
        _hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
        _hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        # XP barı
        var xp_holder := Control.new()
        xp_holder.custom_minimum_size = Vector2(400, 18)
        xp_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
        box.add_child(xp_holder)
        _xp_bar = ProgressBar.new()
        _xp_bar.show_percentage = false
        _xp_bar.custom_minimum_size = Vector2(400, 18)
        _xp_bar.size = Vector2(400, 18)
        _xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _xp_bar.add_theme_stylebox_override("background",
                        _panel_style(Color(GR900.r, GR900.g, GR900.b, 0.82), GR700, 6))
        _xp_bar.add_theme_stylebox_override("fill", _panel_style(TE500, GR700, 6))
        xp_holder.add_child(_xp_bar)
        _xp_label = _label(xp_holder, 13, Color(0.79, 0.97, 0.94))
        _xp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
        _xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _xp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _build_top_center() -> void:
        var box := VBoxContainer.new()
        box.name = "TopCenter"
        box.set_anchors_preset(Control.PRESET_CENTER_TOP)
        box.alignment = BoxContainer.ALIGNMENT_BEGIN
        box.grow_horizontal = Control.GROW_DIRECTION_BOTH
        box.offset_top = 8
        box.add_theme_constant_override("separation", 0)
        box.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _safe.add_child(box)
        _time_label = _label(box, 32, KU100)
        _time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _wave_label = _label(box, 15, GR400)
        _wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _toast_label = _label(box, 18, KU300)
        _toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _toast_label.modulate.a = 0.0


func _build_top_right() -> void:
        var box := HBoxContainer.new()
        box.name = "TopRight"
        box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
        box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
        box.offset_left = -460.0
        box.offset_right = -16.0
        box.offset_top = 12
        box.alignment = BoxContainer.ALIGNMENT_END
        box.add_theme_constant_override("separation", 10)
        _safe.add_child(box)
        var scrap_icon := TextureRect.new()
        scrap_icon.texture = TEX_SCRAP
        scrap_icon.custom_minimum_size = Vector2(38, 38)
        scrap_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        scrap_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        box.add_child(scrap_icon)
        _scrap_label = _label(box, 25, KU300)
        _dev_btn = _hud_button(box, "DEV", 64)
        _dev_btn.pressed.connect(func() -> void: dev_toggled.emit(not _dev_btn.button_pressed))
        _dev_btn.toggle_mode = true
        _pause_btn = _hud_button(box, "II", 64)
        _pause_btn.pressed.connect(func() -> void: pause_pressed.emit())


func _hud_button(parent: Control, text: String, side: float) -> Button:
        var b := Button.new()
        b.text = text
        b.custom_minimum_size = Vector2(side, 44)
        b.focus_mode = Control.FOCUS_NONE
        b.add_theme_font_size_override("font_size", 17)
        b.add_theme_color_override("font_color", KU100)
        b.add_theme_stylebox_override("normal", _panel_style(Color(GR700.r, GR700.g, GR700.b, 0.92), GR600, 10))
        b.add_theme_stylebox_override("hover", _panel_style(GR600, KU500, 10))
        b.add_theme_stylebox_override("pressed", _panel_style(GR800, KU500, 10))
        parent.add_child(b)
        return b


func _build_bottom_left() -> void:
        _joy = TouchJoystick.new()
        _joy.name = "Joystick"
        _joy.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
        _joy.grow_vertical = Control.GROW_DIRECTION_BEGIN
        _joy.offset_left = 0
        _joy.offset_top = -330
        _joy.offset_right = 320
        _joy.offset_bottom = -10
        _safe.add_child(_joy)
        _joy.stick_vector_changed.connect(func(v: Vector2) -> void: joystick_moved.emit(v))


func _build_bottom_right() -> void:
        var box := HBoxContainer.new()
        box.name = "AbilityBar"
        box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
        box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
        box.grow_vertical = Control.GROW_DIRECTION_BEGIN
        box.offset_left = -240.0
        box.offset_top = -128.0
        box.offset_right = -18.0
        box.offset_bottom = -16.0
        box.alignment = BoxContainer.ALIGNMENT_END
        box.add_theme_constant_override("separation", 18)
        _safe.add_child(box)
        _burst_btn = _ability_button(box, TEX_IC_BURST, "Q")
        _burst_cd = _ability_cooldown(_burst_btn)
        _burst_cd_lbl = _ability_cd_label(_burst_btn)
        _burst_btn.pressed.connect(func() -> void: ability_burst_pressed.emit())
        _dash_btn = _ability_button(box, TEX_IC_DASH, "E")
        _dash_cd = _ability_cooldown(_dash_btn)
        _dash_cd_lbl = _ability_cd_label(_dash_btn)
        _dash_btn.pressed.connect(func() -> void: ability_dash_pressed.emit())


func _ability_button(parent: Control, icon: Texture2D, key_hint: String) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(96, 96)
        b.focus_mode = Control.FOCUS_NONE
        b.add_theme_stylebox_override("normal", _panel_style(Color(GR700.r, GR700.g, GR700.b, 0.94), GR600, 20))
        b.add_theme_stylebox_override("hover", _panel_style(GR600, TE500, 20))
        b.add_theme_stylebox_override("pressed", _panel_style(GR800, TE500, 20))
        b.add_theme_stylebox_override("disabled", _panel_style(Color(GR800.r, GR800.g, GR800.b, 0.7), GR700, 20))
        parent.add_child(b)
        var ic := TextureRect.new()
        ic.texture = icon
        ic.set_anchors_preset(Control.PRESET_FULL_RECT)
        ic.offset_left = 10
        ic.offset_top = 10
        ic.offset_right = -10
        ic.offset_bottom = -10
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(ic)
        var hint := _label(b, 13, GR400)
        hint.text = key_hint
        hint.position = Vector2(6, 2)
        return b


func _ability_cooldown(btn: Button) -> TextureProgressBar:
        var tp := TextureProgressBar.new()
        tp.fill_mode = TextureProgressBar.FILL_CLOCKWISE
        tp.min_value = 0.0
        tp.max_value = 1.0
        tp.value = 0.0
        tp.texture_under = null
        tp.set_anchors_preset(Control.PRESET_FULL_RECT)
        tp.mouse_filter = Control.MOUSE_FILTER_IGNORE
        # radyal karanlik kapak: dolu disk (knob dokusu) — deger = kalan cooldown;
        # 1.0 (yeni kullanildi) tam kapali, 0.0 (hazir) tamamen acilir
        tp.texture_progress = TEX_JOY_KNOB
        tp.tint_progress = Color(0.03, 0.03, 0.045, 0.66)
        btn.add_child(tp)
        return tp


func _ability_cd_label(btn: Button) -> Label:
        var l := _label(btn, 24, KU100)
        l.set_anchors_preset(Control.PRESET_FULL_RECT)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        l.text = ""
        return l


func _build_levelup_panel() -> void:
        _levelup_root = Control.new()
        _levelup_root.name = "LevelUpPanel"
        _levelup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
        _levelup_root.visible = false
        _levelup_root.mouse_filter = Control.MOUSE_FILTER_STOP
        _safe.add_child(_levelup_root)
        var dim := ColorRect.new()
        dim.color = Color(GR900.r, GR900.g, GR900.b, 0.62)
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        dim.mouse_filter = Control.MOUSE_FILTER_STOP
        _levelup_root.add_child(dim)
        var center := CenterContainer.new()
        center.set_anchors_preset(Control.PRESET_FULL_RECT)
        center.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _levelup_root.add_child(center)
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel", _panel_style(GR800, KU500, 18))
        panel.custom_minimum_size = Vector2(660, 330)
        center.add_child(panel)
        var vbox := VBoxContainer.new()
        vbox.add_theme_constant_override("separation", 10)
        vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
        panel.add_child(vbox)
        _levelup_title = _label(vbox, 27, KU100)
        _levelup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _levelup_title.text = "SEVİYE ATLADIN"
        var sub := _label(vbox, 15, GR400)
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sub.text = "Bir yetenek seç — oyun duraklatıldı"
        _levelup_cards = HBoxContainer.new()
        _levelup_cards.alignment = BoxContainer.ALIGNMENT_CENTER
        _levelup_cards.add_theme_constant_override("separation", 16)
        vbox.add_child(_levelup_cards)
        var skip := Button.new()
        skip.text = "ATLA"
        skip.custom_minimum_size = Vector2(120, 40)
        skip.focus_mode = Control.FOCUS_NONE
        skip.add_theme_font_size_override("font_size", 16)
        skip.add_theme_color_override("font_color", GR400)
        skip.add_theme_stylebox_override("normal", _panel_style(GR700, GR600, 10))
        skip.add_theme_stylebox_override("hover", _panel_style(GR600, KU500, 10))
        skip.pressed.connect(func() -> void: upgrade_skipped.emit())
        var sc := CenterContainer.new()
        sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vbox.add_child(sc)
        sc.add_child(skip)


# ---------------------------------------------------------------- safe area

## Guvenli ekran alani (ARCHITECTURE B.14): cihazda cihet/kulak boalrini
## HUD'a yansitir. Test modu: debug_notch + debug_insets ile simule edilir.
func _apply_safe_area() -> void:
        var l := 12.0
        var t := 12.0
        var r := 12.0
        var b := 12.0
        if _debug_insets != Vector4.ZERO:
                l = maxf(_debug_insets.x, 8.0)
                t = maxf(_debug_insets.y, 8.0)
                r = maxf(_debug_insets.z, 8.0)
                b = maxf(_debug_insets.w, 8.0)
        else:
                var vis := _root.get_viewport().get_visible_rect().size
                var win := Vector2(DisplayServer.window_get_size())
                var factor := win.x / maxf(vis.x, 1.0)
                if factor <= 0.0 or is_nan(factor):
                        factor = 1.0
                var sa := DisplayServer.get_display_safe_area()
                l = maxf(sa.position.x / factor, 8.0)
                t = maxf(sa.position.y / factor, 8.0)
                r = maxf((win.x - sa.end.x) / factor, 8.0)
                b = maxf((win.y - sa.end.y) / factor, 8.0)
        _safe.offset_left = l
        _safe.offset_top = t
        _safe.offset_right = -r
        _safe.offset_bottom = -b
        _notch.queue_redraw()


## Gercek cihaz olcumu/kanit icin: cihet boalgorini elle dayat.
func debug_force_safe_area(l: float, t: float, r: float, b: float, notch_visual: bool = true) -> void:
        _debug_insets = Vector4(l, t, r, b)
        _debug_notch = notch_visual
        _apply_safe_area()


func _draw_notch() -> void:
        if not _debug_notch:
                return
        var w := _notch.size.x
        var h := _notch.size.y
        var dark := Color(0.04, 0.045, 0.055, 0.88)
        var edge := Color(KU500.r, KU500.g, KU500.b, 0.9)
        # sol kulak / sag kulak (yatay telefon ciheti ciheti simülasyonu)
        _notch.draw_rect(Rect2(0, 0, 96, h), dark)
        _notch.draw_rect(Rect2(96, 0, 3, h), edge)
        _notch.draw_rect(Rect2(w - 64, 0, 64, h), dark)
        _notch.draw_rect(Rect2(w - 67, 0, 3, h), edge)
        # ust cihet hapise
        _notch.draw_rect(Rect2(w * 0.5 - 150, 0, 300, 26), dark)
        _notch.draw_rect(Rect2(w * 0.5 - 150, 26, 300, 3), edge)


# ---------------------------------------------------------------- akis

func setup(p_player: CombatUnit, p_state: PlayerState, p_budget: FXBudget = null) -> void:
        player = p_player
        state = p_state
        budget = p_budget
        _refresh(true)


func set_paused(p: bool) -> void:
        _pause_btn.text = ">" if p else "II"


func toast(text: String) -> void:
        _toast_label.text = text
        if _toast_tween != null and _toast_tween.is_valid():
                _toast_tween.kill()
        _toast_label.modulate.a = 0.0
        _toast_tween = _toast_label.create_tween()
        _toast_tween.tween_property(_toast_label, "modulate:a", 1.0, 0.18)
        _toast_tween.tween_interval(1.7)
        _toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.45)


## Seviye atlama secimi (arena oyunu duraklatir; secim/ATLA ile kapanir).
func show_level_up(level: int, options: Array) -> void:
        _levelup_title.text = "SEVİYE %d — YETENEK SEÇ" % level
        for c in _levelup_cards.get_children():
                c.queue_free()
        for def: Dictionary in options:
                var card := Button.new()
                card.custom_minimum_size = Vector2(196, 208)
                card.focus_mode = Control.FOCUS_NONE
                card.add_theme_stylebox_override("normal", _panel_style(GR700, GR600, 14))
                card.add_theme_stylebox_override("hover", _panel_style(GR600, TE500, 14))
                card.add_theme_stylebox_override("pressed", _panel_style(GR800, TE500, 14))
                card.set_meta("upgrade_id", str(def["id"]))
                card.pressed.connect(func() -> void: upgrade_chosen.emit(str(card.get_meta("upgrade_id"))))
                var vb := VBoxContainer.new()
                vb.set_anchors_preset(Control.PRESET_FULL_RECT)
                vb.offset_top = 14
                vb.offset_bottom = -10
                vb.alignment = BoxContainer.ALIGNMENT_BEGIN
                vb.add_theme_constant_override("separation", 6)
                vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
                card.add_child(vb)
                var ic := TextureRect.new()
                ic.texture = TEX_IC_BURST if def["icon"] == "burst" \
                                else (TEX_IC_DASH if def["icon"] == "dash" else TEX_IC_BURST)
                ic.custom_minimum_size = Vector2(72, 72)
                ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
                ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
                vb.add_child(ic)
                var nm := _label(vb, 18, KU300)
                nm.text = str(def["name"])
                nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                var ds := _label(vb, 13, GR400)
                ds.text = str(def["desc"])
                ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                _levelup_cards.add_child(card)
        _levelup_root.visible = true


func hide_level_up() -> void:
        _levelup_root.visible = false


func is_level_up_open() -> bool:
        return _levelup_root.visible


func _process(delta: float) -> void:
        _refresh_acc += delta
        if _refresh_acc >= 0.1:
                _refresh_acc = 0.0
                _refresh(false)


func _refresh(force: bool) -> void:
        if state == null:
                return
        # sure + dalga
        _time_label.text = state.format_time()
        _wave_label.text = "DALGA %d" % state.wave
        _scrap_label.text = str(state.scrap)
        # can
        if player != null and is_instance_valid(player):
                _hp_bar.max_value = maxi(player.max_hp, 1)
                _hp_bar.value = player.hp
                _hp_label.text = "%d / %d" % [player.hp, player.max_hp]
                var frac := float(player.hp) / float(maxi(player.max_hp, 1))
                _hp_fill.bg_color = TK500 if frac < 0.3 else KU500
                _xp_bar.max_value = maxi(state.xp_to_next(), 1)
                _xp_bar.value = state.xp
                _xp_label.text = "SVY %d · %d/%d XP" % [state.level, state.xp, state.xp_to_next()]
                _refresh_cooldown(_burst_cd, _burst_cd_lbl, player.burst_frac(),
                                player.burst_cd, _burst_was_ready)
                _refresh_cooldown(_dash_cd, _dash_cd_lbl, player.dash_frac(),
                                player.dash_cd, _dash_was_ready)
                _burst_was_ready = player.burst_frac() >= 1.0
                _dash_was_ready = player.dash_frac() >= 1.0


func _refresh_cooldown(tp: TextureProgressBar, lbl: Label, frac: float, cd: float, was_ready: bool) -> void:
        tp.value = 1.0 - clampf(frac, 0.0, 1.0)  # karanlik kisim = kalan bekleme
        if frac >= 1.0:
                lbl.text = ""
                if not was_ready:
                        # hazir olma nabzi (3 Hz alti — fotosensif guvenlik)
                        var t := lbl.create_tween()
                        lbl.modulate.a = 0.2
                        t.tween_property(lbl, "modulate:a", 1.0, 0.3)
        else:
                lbl.text = str(int(ceil(cd * (1.0 - frac))))
