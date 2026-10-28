class_name EnemyRegistry
extends Node
## Dusman spatial hash'i (Faz 05): en yakin hedef arama, yaricap sorgusu ve
## ayrilma (separation) icin O(komsu) erisim. Hucre boyutu 128 px.
## Kayit, birim agactan cikarken otomatik temizlenir.


const CELL: float = 128.0

var _buckets: Dictionary = {}
var _bucket_of: Dictionary = {}


func register(unit: Node2D) -> void:
        if _bucket_of.has(unit):
                return
        if not unit.tree_exiting.is_connected(_on_unit_exiting):
                unit.tree_exiting.connect(_on_unit_exiting.bind(unit))
        _place(unit)


func unregister(unit: Node2D) -> void:
        if not _bucket_of.has(unit):
                return
        var key: Vector2i = _bucket_of[unit]
        _bucket_of.erase(unit)
        if _buckets.has(key):
                _buckets[key].erase(unit)
                if (_buckets[key] as Array).is_empty():
                        _buckets.erase(key)


func update_position(unit: Node2D) -> void:
        if not _bucket_of.has(unit):
                register(unit)
                return
        var key := _key_for(unit.global_position)
        if key != _bucket_of[unit]:
                unregister(unit)
                register(unit)


func count() -> int:
        return _bucket_of.size()


func nearest(from: Vector2, max_dist: float, exclude: Node = null) -> Node2D:
        var best: Node2D = null
        var best_d := max_dist * max_dist
        var r := int(ceil(max_dist / CELL))
        var center := _key_for(from)
        for gx in range(center.x - r, center.x + r + 1):
                for gy in range(center.y - r, center.y + r + 1):
                        var key := Vector2i(gx, gy)
                        if not _buckets.has(key):
                                continue
                        for u in _buckets[key]:
                                if u == exclude or not is_instance_valid(u):
                                        continue
                                var d: float = from.distance_squared_to((u as Node2D).global_position)
                                if d <= best_d:
                                        best_d = d
                                        best = u
        return best


func in_radius(from: Vector2, radius: float, exclude: Node = null) -> Array:
        var out: Array = []
        var r := int(ceil(radius / CELL))
        var center := _key_for(from)
        var r2 := radius * radius
        for gx in range(center.x - r, center.x + r + 1):
                for gy in range(center.y - r, center.y + r + 1):
                        var key := Vector2i(gx, gy)
                        if not _buckets.has(key):
                                continue
                        for u in _buckets[key]:
                                if u == exclude or not is_instance_valid(u):
                                        continue
                                if from.distance_squared_to((u as Node2D).global_position) <= r2:
                                        out.append(u)
        return out


func all_units() -> Array:
        var out: Array = []
        for key in _buckets:
                for u in _buckets[key]:
                        out.append(u)
        return out


func _key_for(p: Vector2) -> Vector2i:
        return Vector2i(int(floor(p.x / CELL)), int(floor(p.y / CELL)))


func _place(unit: Node2D) -> void:
        var key := _key_for(unit.global_position)
        if not _buckets.has(key):
                _buckets[key] = []
        _buckets[key].append(unit)
        _bucket_of[unit] = key


func _on_unit_exiting(unit: Node2D) -> void:
        unregister(unit)
