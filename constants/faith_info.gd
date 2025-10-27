extends Node

# ✅ Faith info lookup — matches each divine skill key to its BBCode description
const FAITH_INFO := {
	"catechisms": """
The oldest organized sect are known as the [color=CC3333]Orthodox[/color].
They gather in Great old Catherdals under a [color=CC3333]Pontiff[/color].
A religion based in [color=CC3333]catechism and ritual[/color],
penitents carry [color=CC3333]rosaries[/color] while doing prayer,
study the [color=CC3333]lives of the saints[/color], give charity,
and be kind and forgiving for the blessings of God.
A popular religion in cities and towns and
among the feared [color=CC3333]Witchhunters[/color] of the Inquisition.
""",

	"devotionals": """
The most common sect in villages is the [color=99ccff]Reformationist[/color] Church.
They gather in halls known as Churches under a [color=99ccff]Archminister[/color].
Puritanical and stern, it is based mostly on acts of [color=99ccff]prayer[/color]
and giving charity, as well as doing kind and noble acts in God's name.
They must regularly attend church on sunday, study their [color=99ccff]Bibles[/color]
to continue to receive God's [color=99ccff]Divine Blessings[/color].
""",

	"holy_ghost_power": """
The zealots of the city slums and villages are known as [color=ff9966]Fundamentalists[/color].
They gather in large halls called [color=ff9966]Tabernacles[/color].
The God of this sect, although in theory the same as the [color=CC3333]Orthodox[/color]
and [color=99ccff]Reformationist[/color], [color=ff9966]speaks[/color] to his followers,
asking them sometimes to do [color=ff9966]strange acts[/color] but otherwise similar,
asking only for prayer, charity, good works and mercy.
""",

	"infernal_powers": """
The foul cult of [color=ED2939]devil worship[/color] and [color=ED2939]demon summoning[/color].
They gather in cabals hidden in wealthy homes in cities and villages.
Their leader is known as a [color=ED2939]High Cultist[/color],
they ask their followers to do [color=ED2939]blood sacrifice[/color]
of humans, animals and monsters alike with [color=ED2939]cursed daggers[/color].
Their Satanic god loves [color=ED2939]horrible acts, lies, crime and evil[/color],
rewarding his cultists with [color=ED2939]Infernal Servants[/color].
""",

	"eldritch_invocations": """
Followers of the void are known as [color=34e8eb]Esoteric Orders[/color].
They gather in abandoned places under a [color=34e8eb]Great One[/color].
The void speaks directly to you and asks you sometimes horrible,
sometimes [color=34e8eb]strange[/color] acts. Serve the void by obeying its requests,
studying [color=34e8eb]Esoteric Tomes[/color], and meditating on its mysteries.
But be ready — [color=34e8eb]the void is capricious[/color];
it gives its blessings and curses with no reason.
""",

	"druidic_rituals": """
The [color=25D366]nature religion[/color] of the old world, followed by the Elves.
Their temples still exist in the Elf Havens, maintained by [color=25D366]Druids[/color].
The way of the great mages and warriors of history.
They pray, perform [color=25D366]acts of power[/color] to venerate the Old Gods.
The pagan gods are [color=25D366]capricious[/color] — they bless and curse wildly,
but they always [color=25D366]hate technology[/color] and love the old magicks.
""",

	"the_rites_of_rex": """
The Dwarven God [color=3333ff]Rex Mundi[/color], known as the King of The World.
Worshipped in Dwarven Temples headed by [color=3333ff]Clerics[/color].
He is the god of crafting, metallurgy, technology and trade.
His disciples use [color=3333ff]lucky coins[/color] to call [color=3333ff]Rex's Favor[/color].
Worship is done through prayer, building, crafting and trading —
the patron God of merchants, craftsmen, and the [color=3333ff]pragmatic[/color].
""",

	"negation": """
You follow [color=ffa500]no god[/color], you have no creed of divine devotion.
This is a choice itself and has its own [color=ffa500]unique power[/color].
The Godless are less affected by magicks and divine powers —
their [color=ffa500]lack of faith[/color] seems to negate the supernatural.
They cannot be [color=ffa500]healed or helped by divine prayer[/color],
but they also have [color=ffa500]little to fear[/color] from divine attack.
"""
}
