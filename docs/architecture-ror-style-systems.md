# Architecture: stats, abilities, and items (RoR-style, Godot 4)

Top-down 2D games with **stacking items**, **procs**, and **synergies** (Risk of Rain–like) stay maintainable when you separate **data**, **runtime state**, and **rules**. This doc sketches that split and gives **Godot 4 / GDScript** examples you can adapt.

---

## Three layers

1. **Definitions (immutable data)** — `Resource` subclasses: item defs, ability defs, status defs. Export fields for editor authoring; no scene tree logic.
2. **Runtime instances** — “3× Item X”, “buff Y for 2s”, “skill Z on cooldown”.
3. **Rules engine** — listens to **game events**, recomputes stats, runs item/ability logic.

Keep “what it is” in Resources, “how many / what’s active” in nodes or plain objects, and “when things fire” in one event surface.

---

## Stats: explicit pipeline

Use **stat IDs** and a **fixed combine order** so stacking stays predictable:

1. Base (character + level)
2. Flat additive (+10 damage)
3. Additive “percent” bucket (sum bonuses, apply once)
4. Multiplicative (few explicit buckets)
5. Caps / floors (optional)

Recompute when stacks, buffs, or level change; **cache** `get_stat(id)` until something invalidates.

### Example: stat enum + modifier sources

```gdscript
# stat_ids.gd — autoload or class_name; enum keeps typos out of dictionaries
enum Id {
	DAMAGE,
	MAX_HP,
	MOVE_SPEED,
	CRIT_CHANCE,
}

const _INVALIDATE_ALL := -1
```

```gdscript
# stat_block.gd
class_name StatBlock
extends RefCounted

## Base values before any items/buffs.
var base: Dictionary = {} # StatIds.Id -> float

## Flat bonuses (stacked by addition).
var flat: Dictionary = {} # StatIds.Id -> float

## Additive multipliers: effective += sum * base (or sum as "0.2 per stack" style).
var add_mult: Dictionary = {} # StatIds.Id -> float (e.g. 0.2 means +20%)

## Final multipliers multiplied in sequence (use sparingly).
var more: Dictionary = {} # StatIds.Id -> float (e.g. 1.15)

var _cache: Dictionary = {}
var _dirty: Dictionary = {} # StatIds.Id -> bool

func set_base(id: int, value: float) -> void:
	base[id] = value
	_mark_dirty(id)


func add_flat(id: int, amount: float) -> void:
	flat[id] = flat.get(id, 0.0) + amount
	_mark_dirty(id)


func _mark_dirty(id: int) -> void:
	_dirty[id] = true


func get_stat(id: int) -> float:
	if not _dirty.get(id, true):
		return _cache[id]
	var b: float = base.get(id, 0.0)
	var f: float = flat.get(id, 0.0)
	var am: float = add_mult.get(id, 0.0)
	var v: float = (b + f) * (1.0 + am)
	var m: float = more.get(id, 1.0)
	if m != 0.0:
		v *= m
	_cache[id] = v
	_dirty[id] = false
	return v
```

### Example: damage resolution (single choke point)

```gdscript
# combat_context.gd — passed into hits so items can read proc coefficient, tags, etc.
class_name CombatContext
extends RefCounted

var attacker: Node2D
var target: Node2D
var base_damage: float
var proc_coefficient: float = 1.0
var tags: PackedStringArray = [] # e.g. ["primary", "bullet"]


# damage_resolver.gd
class_name DamageResolver
extends RefCounted

func resolve_damage(ctx: CombatContext, stats: StatBlock) -> float:
	var dmg: float = ctx.base_damage * stats.get_stat(StatIds.Id.DAMAGE)
	# Emit before/after hooks for items; crit, armor, etc. plug in here.
	return dmg
```

Route **all** outgoing damage through something like `DamageResolver` so items can subscribe to one place.

---

## Game events: one bus (or facade)

Items and abilities should **react** to the same events. Avoid every script calling every other script.

### Option A: autoload `GameEvents`

```gdscript
# game_events.gd (Autoload)
extends Node

signal enemy_hit(ctx: CombatContext)
signal enemy_killed(attacker: Node2D, victim: Node2D)
signal player_healed(amount: float, source: Node)
signal level_up(level: int)
signal skill_used(skill_id: StringName, ctx: CombatContext)
```

### Option B: `Main` or `RunCoordinator` node

Same signals on a node in the scene tree; pass its path into systems that need it. Autoload is convenient for prototypes.

### Example: enemy hit notifies the bus

```gdscript
# In enemy.gd or bullet.gd after you confirm a hit:
func _apply_hit_to_enemy(enemy: Node2D, base_dmg: float) -> void:
	var ctx := CombatContext.new()
	ctx.attacker = player
	ctx.target = enemy
	ctx.base_damage = base_dmg
	ctx.proc_coefficient = 0.5 # e.g. fast tick = lower proc
	ctx.tags = PackedStringArray(["bullet", "primary"])
	GameEvents.enemy_hit.emit(ctx)
	var final_dmg: float = damage_resolver.resolve_damage(ctx, player_stats)
	# apply final_dmg to enemy HP...
```

---

## Abilities: definition + runtime

**Definition** (`Resource`): id, cooldown, targeting hints, tags for proc rules.

**Runtime**: cooldowns, input, animation — often on `Player` or an `AbilityController` child node.

```gdscript
# ability_def.gd
class_name AbilityDef
extends Resource

@export var id: StringName
@export var cooldown: float = 1.0
@export var proc_coefficient: float = 1.0
@export var tags: PackedStringArray = []
```

```gdscript
# ability_controller.gd — child of CharacterBody2D
class_name AbilityController
extends Node

@export var primary: AbilityDef

var _primary_cd: float = 0.0

func _process(delta: float) -> void:
	_primary_cd = maxf(_primary_cd - delta, 0.0)


func try_use_primary(player: CharacterBody2D, stats: StatBlock) -> bool:
	if primary == null or _primary_cd > 0.0:
		return false
	var ctx := CombatContext.new()
	ctx.attacker = player
	ctx.base_damage = 10.0 # or from stat
	ctx.proc_coefficient = primary.proc_coefficient
	ctx.tags = primary.tags
	GameEvents.skill_used.emit(primary.id, ctx)
	_primary_cd = primary.cooldown # optionally divide by attack speed stat
	return true
```

Items listen to `skill_used` and filter by `skill_id` or `tags`.

---

## Items: stacks + Resource definitions

**Runtime stack**: `item_id` → count.

**Definition**: rarity, max stacks, display, and **registration** logic (or a strategy script).

```gdscript
# item_def.gd
class_name ItemDef
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var max_stacks: int = 0 # 0 = unlimited


# item_effect.gd — optional: one script per behavior type
class_name ItemEffect
extends Resource

func on_stack_changed(inventory: ItemInventory, stacks: int) -> void:
	pass


func on_enemy_hit(ctx: CombatContext, inventory: ItemInventory, stacks: int) -> void:
	pass
```

```gdscript
# item_inventory.gd
class_name ItemInventory
extends Node

var stacks: Dictionary = {} # StringName -> int
var defs: Dictionary = {} # StringName -> ItemDef — filled from a registry

signal stack_changed(id: StringName, count: int)


func add_item(id: StringName, amount: int = 1) -> void:
	var def: ItemDef = defs.get(id) as ItemDef
	if def == null:
		return
	var cur: int = stacks.get(id, 0)
	var next: int = cur + amount
	if def.max_stacks > 0:
		next = mini(next, def.max_stacks)
	stacks[id] = next
	stack_changed.emit(id, next)
	_run_stack_hooks(id, next)


func get_stacks(id: StringName) -> int:
	return stacks.get(id, 0)


func _run_stack_hooks(id: StringName, count: int) -> void:
	pass # lookup ItemEffect resources and call on_stack_changed
```

### Example: proc-on-hit item (chance × proc coefficient)

```gdscript
# effect_chain_lightning.gd (example ItemEffect subclass or standalone)
extends ItemEffect

@export var chance_per_stack: float = 0.07
@export var bonus_damage: float = 15.0


func on_enemy_hit(ctx: CombatContext, inventory: ItemInventory, stacks: int) -> void:
	if stacks <= 0:
		return
	var p: float = chance_per_stack * stacks * ctx.proc_coefficient
	if randf() >= p:
		return
	# spawn secondary hit, VFX, etc.
	var _dmg: float = bonus_damage * stacks
```

Wire it in a central **effect registry** that connects `GameEvents.enemy_hit` to all registered effects and passes `inventory.get_stacks(effect_item_id)`.

---

## Effect registry (subscribes once, dispatches to many)

```gdscript
# effect_registry.gd
extends Node

@export var inventory: NodePath
@export var player_stats: NodePath

var _item_effects: Dictionary = {} # StringName item_id -> Array[ItemEffect]

func _ready() -> void:
	GameEvents.enemy_hit.connect(_on_enemy_hit)


func _on_enemy_hit(ctx: CombatContext) -> void:
	var inv: ItemInventory = get_node(inventory) as ItemInventory
	for item_id in _item_effects:
		var effects: Array = _item_effects[item_id]
		var s: int = inv.get_stacks(item_id)
		for e in effects:
			(e as ItemEffect).on_enemy_hit(ctx, inv, s)
```

---

## Buffs / status effects

Use the same **stat pipeline**: applying a buff adds flat/add_mult on `StatBlock` and removes them when the buff ends. For DoT, use a small `BuffManager` that ticks in `_process` or on a timer.

```gdscript
# buff_instance.gd
class_name BuffInstance
extends RefCounted

var id: StringName
var time_left: float
var stacks: int = 1
```

```gdscript
# buff_manager.gd
class_name BuffManager
extends Node

var buffs: Array[BuffInstance] = []

func add_buff(id: StringName, duration: float, stats: StatBlock) -> void:
	# Apply modifiers to stats, or merge stacks if same id
	var b := BuffInstance.new()
	b.id = id
	b.time_left = duration
	buffs.append(b)


func _process(delta: float) -> void:
	for i in range(buffs.size() - 1, -1, -1):
		buffs[i].time_left -= delta
		if buffs[i].time_left <= 0.0:
			# remove stat modifiers for this buff
			buffs.remove_at(i)
```

---

## Suggested project layout

```text
scripts/
  systems/
    stat_block.gd
    stat_ids.gd
    damage_resolver.gd
    combat_context.gd
    item_inventory.gd
    effect_registry.gd
    buff_manager.gd
  abilities/
    ability_def.gd
    ability_controller.gd
  items/
    item_def.gd
    item_effect.gd
    effects/
      chain_lightning.gd
resources/
  items/
    rubber_band.tres
  abilities/
    primary_shot.tres
```

Use `.tres` **ItemDef** / **AbilityDef** assets for tuning without touching code.

---

## Integration with your current `player.gd`

Your player already tracks **HP, stamina, XP, level** (`player.gd`). A gradual path:

1. Introduce `StatBlock` and map `max_speed` / damage into stat IDs when you add items.
2. Add `GameEvents` and emit `enemy_hit` from `bullet.gd` / `enemy.gd` once damage is centralized.
3. Add `ItemInventory` + `EffectRegistry` when the first stacking item appears.

You do not need the full system on day one; **the event bus + single damage resolver** are the highest-leverage first steps.

---

## Pitfalls to avoid

- **Deep inheritance per item** — prefer Resources + small `ItemEffect` scripts or callables.
- **Duplicated damage math** in bullet, enemy, and player — one resolver, one formula order.
- **Tight coupling** — items should talk to `StatBlock`, `ItemInventory`, and signals, not `$Player/Sprite2D`.
- **Unbounded multiplicative stacking** — expose explicit “more” buckets and cap where needed.

---

## Summary

| Concern | Approach |
|--------|----------|
| Stats | `StatBlock` + combine order + invalidation cache |
| Combat | `CombatContext` + `DamageResolver` + signals |
| Abilities | `AbilityDef` + cooldown runtime + emit `skill_used` |
| Items | `ItemDef` + stack counts + `ItemEffect` hooks + registry |
| Buffs | timed instances mutating `StatBlock` or parallel modifiers |

This structure scales to dozens of items and proc combinations while keeping each item’s behavior localized and testable.
