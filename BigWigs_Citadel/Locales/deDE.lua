local L = BigWigs:NewBossLocale("Blood Prince Council", "deDE")
if L then
	L.switch_message = "Ziel wechseln: %s"
	L.switch_bar = "~Ziel wechseln"

	--L.empowered_flames = "Machtvolle Flammen"
	L.empowered_bar = "~Machtvolle Flammen"

	L.empowered_shock_message = "Schockvortex kommt!"
	L.regular_shock_message = "Schockzone"
	L.shock_say = "Schockzone auf MIR!"
	L.shock_bar = "~Nächster Schock"

	L.iconprince = "Symbol auf aktivem Prinz"
	L.iconprince_desc = "Plaziert das erste Schlachtzugs-Symbol auf dem aktiven Blutprinzen (benötigt Assistent oder höher)."

	L.prison_message = "%dx Schattengefängnis!"
end

L = BigWigs:NewBossLocale("Blood-Queen Lana'thel", "deDE")
if L then
	L.engage_trigger = "Ihr habt... unklug... gewählt."

	--L.shadow = "Schatten"
	L.shadow_message = "Schatten"
	L.shadow_bar = "Nächster Schatten"

	L.feed_message = "Blutdurst stillen!"

	L.pact_message = "Pakt"
	L.pact_bar = "Nächster Pakt"

	L.phase_message = "Flugphase kommt!"
	L.phase1_bar = "Zurück am Boden"
	L.phase2_bar = "Flugphase"
end

L = BigWigs:NewBossLocale("Deathbringer Saurfang", "deDE")
if L then
	L.adds = "Blutbestien"
	L.adds_desc = "Zeigt Timer und Nachrichten für das Auftauchen der Blutbestien."
	L.adds_warning = "Blutbestien in 5 sek!"
	L.adds_message = "Blutbestien!"
	L.adds_bar = "~Blutbestien"
	
	L.nova_warning = "Blutnova in 5 sek!"
	L.nova_message = "Blutnova!"
	L.nova_bar = "Nächste Blutnova"
	
	L.rune_bar = "~Nächste Rune"

	L.mark = "Mal %d"

	L.engage_trigger = "BEI DER MACHT DES LICHKÖNIGS!"
	L.warmup_alliance = "Dann beeilen wir uns! Brechen wir au..."
	L.warmup_horde = "Kor'kron, Aufbruch! Champions, gebt Acht. Die Geißel ist..."
end

L = BigWigs:NewBossLocale("Festergut", "deDE")
if L then
	L.engage_trigger = "Zeit für Spaß?"

	L.inhale_message = "Einatmen %d"
	L.inhale_bar = "Einatmen %d"

	L.blight_warning = "Stechende Seuche in ~5 sek!"
	L.blight_bar = "Nächste Seuche"

	L.bloat_message = "%2$dx Magenblähung: %1$s"
	L.bloat_bar = "~Magenblähung"

	L.spore_bar = "~Gassporen"

	L.ball_message = "Glibber!"
end

L = BigWigs:NewBossLocale("Highking Beemz", "deDE")
if L then
	L.warmup_trigger = "Was denkt ihr werden sie mit euch machen"
	L.engage_trigger = "Hütet euch vor den Schatten!"
	L.enrage_trigger = "Eure Zeit ist abgelaufen!"
	L.enrage_message = "Berserker!"
	
	L.pactDarkfallen_message = "Pakt der Sinistren"
	L.swarmingShadows_message = "Schwärmende Schatten"
	L.fatalAttraction_message = "Verh\195\164ngnisvolle Aff\195\164re"
	
	L.add_warning_key = "Warnungen f\195\188r Adds"
	L.add_warning_key_desc = "Warnt wenn neue Adds Spawnen und stellt Leisten dar"
	L.ability_warning_key = "Generelle Leiste f\195\188r die n\195\164chsten f\195\164higkeiten"
	L.ability_warning_key_desc = "Stellt anhand einer Leiste dar wann die n\195\164chsten F\195\164higkeiten aktiv werden. (Das ist nur eine allgemeine Anzeige und betrifft keine spezifischen F\195\164higkeiten / bleibt nur so lange bestehen bis ein Add erkannt wurde)"
	
	--L.swarmingShadows_trigger = "Hütet euch vor den Schatten!"
	
	L.add_trigger = "Ihr wisst nicht, was euch erwartet!!!"
	L.add_message = "Neue Adds"
	L.nextAdds_bar = "N\195\164chsten Adds"
	L.nextAbilitys_bar = "N\195\164chsten F\195\164higkeiten"
	
	L.valk_identify_massage = "Val'kyr erkannt!"
	L.valk_walk_bar = "Val'kyr (Sengendes Licht)"
	L.valk_ability_message = "Sengendes Licht wird kommen!"
	L.lightbomb_other = "Sengendes Licht"
	
	L.fireEle_identify_massage = "Feuer Ele erkannt!"
	L.fireEle_walk_bar = "Feuer Ele (Legionsflamme)"
	L.fireEle_ability_message = "Legionsflamme wird kommen!"
	L.legionflame_message = "Legionsflamme"
	
	L.arcaneEle_identify_massage = "Arcane Ele erkannt!"
	L.arcaneEle_walk_bar = "Arcane Ele (Seelensturm)"
	L.arcaneEle_ability_message = "Seelensturm wird kommen!"
	
	L.frostOrb_identify_massage = "Frost Kugel erkannt!"
	L.frostOrb_walk_bar = "Frost Kugel (Durchdringende Kälte)"
	L.frostOrb_ability_message = "Durchdringende Kälte wird kommen!"
	L.chilled_message = "Durchgefroren x%d!"
	
	L.waterEle_identify_massage = "Wasser Ele erkannt!"
	L.waterEle_walk_bar = "Wasser Ele (Manabarriere)"
	L.waterEle_ability_message = "Manabarriere wird kommen!"
	
	L.flower_identify_massage = "Blume erkannt!"
	L.flower_walk_bar = "Blume (Egelschwarm)"
	L.flower_ability_message = "Egelschwarm wird kommen!"
	
	L.essence_identify_massage = "Essenz erkannt!"
	L.essence_walk_bar = "Essenz (Aura der Begierde)"
	L.essence_ability_message = "Aura der Begierde wird kommen!"
	
	L.bloodBeast_identify_massage = "Blutbestie erkannt!"
	L.bloodBeast_walk_bar = "Blutbestie (Wutanfall)"
	L.bloodBeast_ability_message = "Wutanfall wird kommen!"
	
	L.goo_identify_massage = "Schleim erkannt!"
	L.goo_walk_bar = "Schleim (Gasnova)"
	L.goo_ability_message = "Gasnova wird kommen!"
	L.gas_message = "Zaubert Gasnova!"
	L.gas_bar = "~Gasnova Cooldown"
	
	L.spore_identify_massage = "Spore erkannt!"
	L.spore_walk_bar = "Spore (Aasschwarm)"
	L.spore_ability_message = "Aasschwarm wird kommen!"
	L.swarm_message = "Schwarm!"
	L.swarm_bar = "~Schwarm Cooldown"
end

L = BigWigs:NewBossLocale("Icecrown Gunship Battle", "deDE")
if L then
	L.adds = "Portal"
	L.adds_desc = "Warnt vor den Portalen."
	--L.adds_trigger_alliance = "Häscher, Unteroffiziere, Angriff!"
	--L.adds_trigger_horde = "Soldaten! Zum Angriff!"
	L.adds_message = "Portal!"
	L.adds_bar = "Nächstes Portal"

	L.mage = "Magier"
	L.mage_desc = "Warnt, wenn ein Magier erscheint, um die Kanonen einzufrieren."
	L.mage_message = "Magier gespawnt!"
	L.mage_bar = "Nächster Magier"

	--L.warmup_trigger_alliance = "Alle Maschinen auf Volldampf"
	--L.warmup_trigger_horde = "Erhebt Euch, Söhne und Töchter"

	--L.disable_trigger_alliance = "Vorwärts, Brüder und Schwestern"
	--L.disable_trigger_horde = "Vorwärts zum Lichkönig"
end

L = BigWigs:NewBossLocale("Lady Deathwhisper", "deDE")
if L then
	L.engage_trigger = "Was soll die Störung? Ihr wagt es, heiligen Boden zu betreten? Dies wird der Ort Eurer letzten Ruhe sein!"
	L.phase2_message = "Manabarriere weg - Phase 2!"

	L.dnd_message = "Tod und Verfall auf DIR!"

	L.adds = "Adds"
	L.adds_desc = "Zeigt Timer und Nachrichten für das Auftauchen der Adds."
	L.adds_bar = "Nächsten Adds"
	L.adds_warning = "Adds in 5 sek!"

	L.touch_message = "%2$dx Berührung: %1$s"
	L.touch_bar = "~Nächste Berührung"

	L.deformed_fanatic = "Deformierter Fanatiker!"

	L.spirit_message = "Geister!"
	L.spirit_bar = "Nächsten Geister"

	L.dominate_bar = "~Gedankenkontrolle"
end

L = BigWigs:NewBossLocale("Lord Marrowgar", "deDE")
if L then
	L.impale_cd = "~Aufspießen"

	L.bonestorm_cd = "~Knochensturm"
	L.bonestorm_warning = "Knochensturm in 5 sek!"

	L.coldflame_message = "Eisflamme auf DIR!"

	L.engage_trigger = "Die Geißel wird über diese Welt kommen wie ein Schwarm aus Tod und Zerstörung!"
end

L = BigWigs:NewBossLocale("Professor Putricide", "deDE")
if L then
	L.phase = "Phasen"
	L.phase_desc = "Warnt vor Phasenwechsel."
	L.phase_warning = "Phase %d bald!"
	L.phase_bar = "Nächste Phase"
	L.slime_bar = "Nächste Schleimpfütze"
	L.slime_message = "Sleimpfützen!"

	L.engage_trigger = "Gute Nachricht, Freunde!"

	L.ball_bar = "Nächster Glibber"
	L.ball_say = "Glibber auf MIR!"

	L.experiment_message = "Schlamm kommt!"
	L.experiment_heroic_message = "Schlammer kommen!"
	L.experiment_bar = "Nächster Schlamm"
	L.blight_message = "Roter Schlamm"
	L.violation_message = "Grüner Schlamm"

	L.plague_message = "%2$dx Seuche: %1$s"
	L.plague_bar = "Nächste Seuche"

	L.gasbomb_bar = "Weitere Gasbomben"
	L.gasbomb_message = "Gasbomben!"

	L.unbound_bar = "Entfesselte Seuche: %s"
end

L = BigWigs:NewBossLocale("Putricide Dogs", "deDE")
if L then
	L.wound_message = "%2$dx Tödliche Wunde: %1$s"
end

L = BigWigs:NewBossLocale("Rotface", "deDE")
if L then
	L.engage_trigger = "WIIIIII!"

	L.infection_bar = "Infektion: %s"
	L.infection_message = "Infektion"

	L.ooze = "Brühschlammer verschmelzen"
	L.ooze_desc = "Warnt, wenn Brühschlammer miteinander verschmelzen."
	L.ooze_message = "%dx Brühschlammer!"

	L.spray_bar = "~Schleimsprühen"
end

L = BigWigs:NewBossLocale("Sindragosa", "deDE")
if L then
	L.engage_trigger = "Ihr seid Narren, euch hierher zu wagen. Der eisige Wind Nordends wird eure Seelen verschlingen!"

	L.phase2 = "Phase 2"
	L.phase2_desc = "Warnt, wenn Phase 2 bei 35% beginnt."
	L.phase2_trigger = "Fühlt die grenzenlose Macht meines Meisters, und verzweifelt!"
	L.phase2_message = "Phase 2!"

	L.airphase = "Flugphase"
	L.airphase_desc = "Warnt, wenn Sindragosa abhebt."
	L.airphase_trigger = "Euer Vormarsch endet hier! Keiner wird überleben!"
	L.airphase_message = "Flugphase kommt!"
	L.airphase_bar = "Nächste Flugphase"

	L.boom_message = "Explosion!"
	L.boom_bar = "Explosion"

	L.grip_bar = "Nächster Griff"

	L.unchained_message = "Entfesselte Magie auf DIR!"
	L.unchained_bar = "Entfesselte Magie"
	L.instability_message = "%dx Instabilität!"
	L.chilled_message = "%dx Durchgefroren!"
	L.buffet_message = "%dx Puffer!"
	L.buffet_cd = "Nächster Puffer"
end

L = BigWigs:NewBossLocale("The Lich King", "deDE")
if L then
	L.warmup_trigger = "Der vielgerühmte Streiter des Lichts ist endlich hier?"
	L.engage_trigger = "Ihr bleibt bis zum Ende am Leben, Fordring."
	L.horror_bar = "~Torkelnder Schrecken"
	L.horror_message = "Torkelnder Schrecken!"

	L.necroticplague_bar = "Nekrotische Seuche"

	L.ragingspirit_bar = "Tobender Geist"

	L.valkyr_bar = "Nächsten Val'kyr"
	L.valkyr_message = "Val'kyr!"

	L.vilespirits_bar = "~Widerwärtige Geister"

	L.harvestsoul_bar = "Seele ernten"

	L.remorselesswinter_message = "Unbarmherziger Winter kommt!"
	L.quake_message = "Beben kommt!"
	L.quake_bar = "Beben"

	L.defile_say = "Entweihen auf MIR!"
	L.defile_message = "Entweihen auf DIR!"
	L.defile_bar = "Nächstes Entweihen"

	L.infest_bar = "~Befallen"

	L.reaper_bar = "~Seelenernter"

	L.last_phase_bar = "Letzte Phase"

	L.trap_say = "Falle auf MIR!"
	L.trap_near_say = "Falle in meiner Nähe!"
	L.trap_message = "Falle"
	L.trap_bar = "Nächste Falle"

	L.valkyrhug_message = "Val'kyren"
	L.cave_phase = "Höhlenphase"

	L.frenzy_bar = "%s in Raserei"
	L.frenzy_survive_message = "%s wird Seuchentick überleben!"
	L.enrage_bar = "~Wutanfall"
	L.frenzy_message = "Add Raserei!"
	L.frenzy_soon_message = "5 sek bis Raserei!"
end

L = BigWigs:NewBossLocale("Valithria Dreamwalker", "deDE")
if L then
	--L.engage_trigger = "Eindringlinge im Inneren Sanktum! Beschleunigt die Vernichtung des grünen Drachen!"

	L.portal = "Alptraumportale"
	L.portal_desc = "Warnt, wenn Valithria Alptraumportale öffnet."
	L.portal_message = "Portale offen!"
	L.portal_bar = "Portale kommen"
	L.portalcd_message = "Portale %d in 14 sek offen!"
	L.portalcd_bar = "Portale %d"
	L.portal_trigger = "Ich habe ein Portal in den Traum geöffnet. Darin liegt Eure Erlösung, Helden..."

	L.manavoid_message = "Manaleere auf DIR!"

	L.suppresser = "Unterdrücker erscheinen"
	L.suppresser_desc = "Warnt, wenn eine Gruppe Unterdrücker erscheint."
	L.suppresser_message = "~Unterdrücker"

	L.blazing = "Loderndes Skelett"
	L.blazing_desc = "|cffff0000Geschätzter|r Timer für die Lodernden Skelette. Dieser Timer ist wahrscheinlich ungenau, nur als Schätzung verwenden."
	L.blazing_warning = "Loderndes Skelett bald!"
end

