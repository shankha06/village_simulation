<div align="center">

<br>

![The Hollow Village](docs/images/hero_banner.png)

<br>

![Stats](docs/images/stats_banner.png)

<br>

> *"The forest does not enjoy what we give it. It grieves every time.*
> *Let me show it that at least one of us can walk in with open hands."*
>
> — **Wren, the only willing sacrifice in 300 years**

<br>

---

</div>

## The Premise

Every thirty years, the lord of Ashvale feeds a human soul to the forest. In return, the crops grow. The wells run sweet. The plagues stay away.

**This year, the lord refused.**

Now the crops are dying. The water tastes of poison. A priest preaches divine punishment while a thieves' guild plots in the shadows. An army gathers on the horizon. And deep in the Thornwood, something ancient is losing patience.

*You arrive carrying a dead man's compass. It hasn't pointed north in thirty years.*

---

<div align="center">

## ─── The World ───

</div>

![World Map](docs/images/world_map.png)

<table>
<tr>
<td width="50%">

### Ashvale Village
A once-prosperous farming village. The bread tastes like chalk. The well water has a metallic aftertaste that Elara says smells like "bitter almonds and broken promises." The blacksmith's dog still waits at an empty forge.

</td>
<td width="50%">

### Thornwood Forest
Ten thousand years old. A vast consciousness dreaming in the root network. It remembers every soul given to it. They're not dead — they're *dreaming* inside the roots. And the forest is running out of patience.

</td>
</tr>
<tr>
<td>

### Ashworth Manor & Catacombs
The lord paces fourteen steps. Desk to window. Below: catacombs with 300 years of ghost letters, scratch marks from nine sacrifices, and a ritual chamber where the altar still pulses with a heartbeat that isn't yours.

</td>
<td>

### Eastern Road & Beyond
Ironmarch scouts. Broken merchant carts. Boot prints from twenty soldiers. And beyond — the continent of Valdris, where 16 more pacts wait to be broken, honored, or betrayed.

</td>
</tr>
</table>

---

<div align="center">

## ─── The People Who Carry This Weight ───

</div>

> *Every NPC has a schedule, a memory system, a multi-dimensional relationship (trust / affection / respect / fear / debt), and a past that connects to every other character through blood, grief, or silence.*

![Characters](docs/images/character_showcase.png)

<details>
<summary><b>The Maren Family Triangle — the emotional spine of the story</b></summary>
<br>

**Old Maren** (grandmother) → lost her son **Silas** to the forest sacrifice 30 years ago

**Silas** had two children: **Elara** (the herbalist) and **Brother Maren** (the priest)

They are **siblings** — neither knows. Old Maren recognized her grandson the day he arrived and **said nothing**. The priest has been poisoning the village where his sister lives.

*"I lost my son to the forest. I lost my grandson to the Church. And now the grandson is poisoning the village where the granddaughter lives. Tell me — what god designs a family like this?"*

</details>

---

<div align="center">

## ─── The Weight of Choice ───

</div>

> *There are no good choices in Ashvale. Only less terrible ones.*

![Consequences](docs/images/consequence_cascade.png)

A single decision cascades through **six interconnected systems** over weeks of in-game time. The player who burned the silo and the player who helped Elara investigate experience completely different worlds — different NPC dialogue, different economy, different faction power, different visual environment, different endings.

**51 consequence chains. 500+ flags. No two playthroughs are the same.**

---

<div align="center">

## ─── 10 Endings, Each One a Scar ───

</div>

![Endings](docs/images/endings_showcase.png)

Every ending plants a **sequel hook**. The Heartwood's distress call is propagating through the continental root network. After 3,000 years, the consciousnesses are reaching a verdict on humanity. **What they decide depends on what happened in Ashvale.**

---

<div align="center">

## ─── Artifacts & Items ───

</div>

![Items](docs/images/items_showcase.png)

- **The Compass** — Made from a dead wife's wedding ring, carpentry nails, and chapel glass. Inscription: *"For E — find the sunlight. For M — find the warmth."*
- **Ghost Letters** — Five goodbyes spanning 300 years, found in the manor catacombs
- **The Talisman** — Shows what the forest wants you to see. Not always what you want to see.

---

<div align="center">

## ─── Lore That Lives in the Details ───

</div>

> *88 codex entries. 144 progressive fragments. 40 village memories. 5 ghost letters. 30 micro-lore entries. This isn't a world described in exposition dumps — it's a world you discover in margins, scratches, and whispers.*

<table>
<tr>
<td width="50%" valign="top">

**Objects That Tell Stories**
- A half-finished chair in an abandoned workshop. It was for Elara. She was four.
- An inn beam carved: "H + S — FISHING FOREVER"
- A knife with no blade. The lord's men took the blade when they came for Fenrick's grandmother.
- The chapel bell hasn't rung since the priest arrived — it resonates at a frequency the forest can hear.

</td>
<td width="50%" valign="top">

**The World Whispers**
- Dead songbirds near the well with black beaks, still staring at the sky
- A river downstream spells words every night: COME. BACK. PLEASE.
- The Ash Wastes sand whispers — dead roots can't grow but can remember fire
- Harlan's unsent letter, rewritten every spring for 30 years: *"I should have been your friend when it mattered."*

</td>
</tr>
</table>

---

<div align="center">

## ─── The Tileset ───

</div>

![Tileset](docs/images/tileset_preview.png)

48 hand-crafted tiles with 3-tone shading, dithered textures, and distinct visual language. Cobblestone reads as cobblestone. Dead farmland reads as dead farmland. Every tile tells a story about what this place used to be.

---

<div align="center">

## ─── Architecture ───

</div>

Built on **10 interconnected autoload singletons** communicating through a signal-driven event bus.

```
 Player Action
      │
      ├──→ GameState.set_state("flag.X", true)
      │         │
      │         ├──→ QuestManager     ──→  FSM transitions  ──→  consequence chains
      │         ├──→ WorldSimulation  ──→  ecology/economy   ──→  visual tile changes
      │         ├──→ NarrativeEngine  ──→  atom evaluation   ──→  world events fire
      │         ├──→ FactionManager   ──→  reputation ripple ──→  NPC behavior shifts
      │         ├──→ RelationshipMgr  ──→  5-axis update     ──→  dialogue gating
      │         └──→ TimeManager      ──→  scheduled events  ──→  delayed consequences
      │
      └──→ 51 consequence chains with delayed/conditional effects over days
```

<details>
<summary><b>System Details</b></summary>

| System | Purpose | Scale |
|:-------|:--------|:------|
| **GameState** | Centralized blackboard — every system reads/writes here | 500+ flags |
| **NarrativeEngine** | JSON dialogue trees with conditions, triggers, slot-filling | 64 trees, 1000+ nodes |
| **QuestManager** | FSM-based quests with silent background updates | 15 quests, 113 variants |
| **WorldSimulation** | Ecology, economy, rumor propagation | Daily ticks |
| **ConsequenceChains** | Immediate + delayed + conditional cascading effects | 51 chains |
| **RelationshipManager** | Trust, affection, respect, fear, debt per NPC | 5 dimensions |
| **FactionManager** | 2D matrix with ripple effects | 6 factions |
| **TimeManager** | Clock + cron-job events + day/night | Minute-level |
| **SaveManager** | Full state serialization — multiple slots | Complete state |
| **AudioManager** | Mood-reactive music, ambient layering | 21 audio files |

</details>

---

<div align="center">

## ─── Narrative Design Influences ───

</div>

<table>
<tr>
<td align="center" width="25%">
<b>The Witcher 3</b><br><br>
<sub>Forked consequences across separate quests. One choice sets 4 flags that activate independently across 3 quest chains. No binary good/evil — only less terrible options.</sub>
</td>
<td align="center" width="25%">
<b>Baldur's Gate 3</b><br><br>
<sub>NPC interjections during dialogue. Silent approval tracking. Involuntary consequences from accumulated flag patterns — the Dark Urge pattern adapted for a village mystery.</sub>
</td>
<td align="center" width="25%">
<b>Red Dead Redemption 2</b><br><br>
<sub>Ambient overhear system. Honor-gated dialogue variants. Internal monologue journal. The weight of mundane moments — a chair never finished, a letter never sent.</sub>
</td>
<td align="center" width="25%">
<b>God of War Ragnarök</b><br><br>
<sub>Prophecy subversion through accumulated behavior. Family conflict woven into every mechanic. The grandmother, the grandson, and thirty years of silence between them.</sub>
</td>
</tr>
</table>

---

<div align="center">

## ─── The Continent of Valdris ───

*Ashvale is Pact #14 of 17. Sixteen remain unresolved.*

</div>

```
        ┌─────────────────────────────────────────────────────────┐
        │                    VALDRIS CONTINENT                     │
        │                                                          │
        │   ◆ Silverpine (#15)           ◇ Breathing Marshes (#16) │
        │     Mountain — THRIVING          UNKNOWN                  │
        │     Church crusade incoming                               │
        │                                                          │
        │          ◆ Druid Conclave (hidden)                       │
        │                     ◆ Hollowreach (Guild HQ)             │
        │   ◇◇◇ Eastern                                            │
        │   Frontier         ★ ASHVALE (#14)                       │
        │   (#8-10)            ← YOU ARE HERE                      │
        │   Under Church                                            │
        │   attack           ◆ Rivendale (#11)                     │
        │                      River pact — DORMANT                │
        │   ▓▓▓▓▓▓▓▓▓▓        The river calls for Voss            │
        │   ASH WASTES                                              │
        │   (#1-7)           ◆ Ironhold (Legion Capital)           │
        │   7 DESTROYED        Built on dead roots                 │
        │   PACTS                                                   │
        │                    ◆ Cinderfall (Church HQ)              │
        └─────────────────────────────────────────────────────────┘
```

<details>
<summary><b>Sequel Hooks</b></summary>

- **Harmony ending** → Silverpine calls: *"The Church is coming. Send the bridge-walker."*
- **Exodus ending** → Voss: *"Rivendale. I have unfinished business."*
- **Martyr ending** → Thousands of dreaming sacrifices, singing the same song across the continent
- **All endings** → The deep root network reaches a verdict on humanity after 3,000 years of debate. What they decide depends on what happened in Ashvale.

</details>

---

<div align="center">

## ─── Quick Start ───

</div>

```bash
# Clone
git clone https://github.com/shankha06/village_simulation.git
cd village_simulation

# Play (requires Godot 4.6+)
godot --path .

# Or open in editor
godot --path . --editor    # Then press F5
```

| Key | Action | | Key | Action |
|:---:|:-------|---|:---:|:-------|
| `WASD` | Move | | `I` | Inventory |
| `E` | Interact | | `J` | Journal |
| `Space` | Dodge | | `Q` | Quest Log |
| `Click` | Attack | | `L` | Lore / Codex |
| `H` | Help | | `M` | Map |

<details>
<summary><b>Project Structure</b></summary>

```
village_simulation/
├── autoloads/           # 10 singleton systems
├── scenes/
│   ├── main/            # Root scene, game flow
│   ├── player/          # Movement, stats, combat
│   ├── npcs/            # NPC AI, memory, schedules
│   ├── ui/              # Dialogue, journal, inventory, codex
│   ├── world/           # 8 regions, interactables, transitions
│   ├── combat/          # Enemy AI, damage, surrender
│   ├── effects/         # Day/night, weather, visual changes
│   └── intro/           # Cinematic prologue
├── data/
│   ├── dialogues/       # 64+ branching dialogue trees
│   ├── quests/          # 15 FSM quest definitions
│   ├── narrative/       # 51 consequence chains, atoms, clues
│   ├── lore/            # 88 codex + 40 memories + ghost letters + world history
│   ├── world/           # Tilemaps, interactables, ecology, economy
│   └── items/           # 21 items + 5 recipes
├── assets/              # Pixel art, audio, UI
└── tools/               # Python generators
```

</details>

---

<div align="center">

<br>

> *"We are not the main characters. We are the first chapter.*
> *What happens after us — that is the story."*
>
> — **Old Maren, the last druid of the Thornwood Circle**

<br>

*Built with [Godot Engine 4.6](https://godotengine.org) · Narrative design by [Claude](https://claude.ai)*

**© 2026 — The Hollow Collective**

*The roots remember. The roots always remember.*

<br>

</div>
