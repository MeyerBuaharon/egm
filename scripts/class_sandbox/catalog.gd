extends RefCounted
const JOBS := ["Warden", "Strider", "Hexbinder", "Wildborn"]
const GENDERS := ["Female", "Male", "Male", "Female"]
const ITEMS := [
	[
		{"id":"sword","name":"Oathblade","type":"Sword","combo":"Forehand cut → rising backhand → cleave","dig":"Stunning emergence thrust","role":"Balanced melee"},
		{"id":"axe","name":"Sunderaxe","type":"Axe","combo":"Broad chop → reverse sweep → overhead cleave","dig":"Rising axe launcher","role":"Heavy sweeping blows"},
		{"id":"hammer","name":"Gravehammer","type":"Hammer","combo":"Cross-body blow → shoulder smash → overhead crush","dig":"Leap out, then ground slam","role":"Slow impact and burial"},
		{"id":"spear","name":"Dawnspear","type":"Spear","combo":"Thrust → diagonal sweep → butt-end strike","dig":"Rising spear launcher","role":"Reach and precision"}
	],
	[
		{"id":"daggers","name":"Bloodletter","type":"Dual daggers","combo":"Left cut → right cut → crossing bleed finisher","dig":"Bleeding rising ambush","role":"Close-range bleed pressure"},
		{"id":"blowgun","name":"Venom","type":"Blowgun + needle","combo":"Poison dart → twin darts → piercing venom shot; nearby needle jab","dig":"Poison dart fan","role":"Ranged damage over time"},
		{"id":"shuriken","name":"Shadow","type":"Shuriken","combo":"Single star → double fan → triple fan","dig":"Rising star fan","role":"Ranged throwing combos"},
		{"id":"whip","name":"Stone Lash","type":"Stone-tipped whip","combo":"Lash → wide sweep → weighted-tip slam","dig":"Rising whip catch","role":"Mid-range stagger and reach"}
	],
	[
		{"id":"fire","name":"Cinder Grimoire","type":"Fire book","combo":"Firebolt → paired embers → burning blast","dig":"Fire explosion and burning enemies","role":"Ranged burn damage"},
		{"id":"ice","name":"Rime Grimoire","type":"Ice book","combo":"Ice shard → frost fan → freezing burst","dig":"Freezing eruption","role":"Freeze on third hit"},
		{"id":"wind","name":"Gale Grimoire","type":"Wind book","combo":"Air blade → paired gust → rising cyclone","dig":"Airborne launch","role":"Launch and aerial control"},
		{"id":"earth","name":"Fault Grimoire","type":"Earth book","combo":"Stone fist → ground spikes → burial fissure","dig":"Earth pull and burial","role":"Grounded area control"}
	],
	[
		{"id":"claws","name":"Rending Claws","type":"Short ivory claws","combo":"Left rake → right rake → crossing maul","dig":"Claw launcher","role":"Direct melee damage"},
		{"id":"thorns","name":"Briar Claws","type":"Long forked thorn claws","combo":"Thorn shot → twin barbs → spreading volley","dig":"Radial thorn volley","role":"Distinct barbed silhouette, ranged attacks"},
		{"id":"roots","name":"Rootbind Tendrils","type":"Living root tendrils","combo":"Tendril lash → grapple pull → pinning root slam","dig":"Underground snare and pull","role":"Grapples and enemy placement"},
		{"id":"feral","name":"Prowler Set","type":"Paired hand + foot gear","combo":"Pounce → rising kick → diving heel strike","dig":"Leaping ambush into air combo","role":"Acrobatic melee and aerial chains"}
	]
]
static func item(job: int, slot: int) -> Dictionary:
	return ITEMS[clampi(job,0,3)][clampi(slot,0,3)]
