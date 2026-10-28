class_name IsoEntity
extends Node2D
## Y-sort uyumlu varlik temeli (ARCHITECTURE B.7.2/B.10).
## Pivot: ayak-zemin temas noktasi (ASSET_PIPELINE B.4) - dusum origin'dedir,
## y-sort dogal olarak dogru calisir. 2x doku 0.5 scale ile cizilir (B.3).

const SHADOW_TEXTURE := preload("res://assets/art/vfx/tex_fx_blob_shadow_01.png")

@onready var body: Sprite2D = $Body
@onready var shadow: Sprite2D = $Shadow


func setup_texture(tex: Texture2D) -> void:
        var size := tex.get_size()
        body.texture = tex
        body.scale = Vector2(0.5, 0.5)
        body.offset = Vector2(-size.x * 0.5, -(size.y - 8.0))
        if shadow.texture == null:
                shadow.texture = SHADOW_TEXTURE
