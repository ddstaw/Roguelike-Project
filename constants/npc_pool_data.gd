# npc_pool_data.gd
extends Node

const NPC_POOLS := {
	"grassland_explore_fields": {
		"snakes": {
			"types": ["CRE0002"],
			"spawn_chance": 0.8,
			"min_per_chunk": 1,
			"max_per_chunk": 3,
			"initial_spawn": true
		},
		"cats": {
			"types": ["CRE0001"],
			"spawn_chance": 0.5,
			"min_per_chunk": 1,
			"max_per_chunk": 2,
			"initial_spawn": true
		},
		"wizards": {
			"types": ["NPC0001"],
			"spawn_chance": 0.3,
			"min_per_chunk": 1,
			"max_per_chunk": 1,
			"initial_spawn": true
		}
	}
}
