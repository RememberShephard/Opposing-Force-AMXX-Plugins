# Opposing Force AMXX Plugins

# Opposing Force Severians Mod+ (Requires 2 plugins)
// op4_sev.amxx
// op4_fastshotgun.amxx

As Opposing Force is different to Half-Life and uses different offsets, converting Severians Mod straight to Op4 had some minor issues. In order to fix this I split the files into two. 

// About Severians Mod
- The shotgun reloads much faster than usual.
- Shotgun rate of fire increased.
- The destructive power of the shotgun has been increased.
- Increased crossbow reload speed.
- Increased crossbow rate of fire.
- Increased sniperrifle reload speed.
- Increased sniperrifle rate of fire.
- Snarks' alternate attack teleports the player to a randomly chosen rep. The next teleport can be done in 3 minutes or after death (which comes first? :))
- The alternative attack of hand grenades allows you to shoot a grenade like an underbarrel. Explodes on impact. This can be done once every 5 seconds.
- Laser mines with a colored beam, with an alternative attack, a mine is placed with a lightning beam and 150% damage compared to a regular mine.
- Customizable spawnprotect.
- The flashlight is much brighter than usual.
- Information about the map, remaining time and frag limit after each death of the player.
- Information about the player when aiming a sight at him (Nickname, model).
- Flexible settings for the initial armament of the player.

// Requires the equipment.ini to be added to the configs folder. You can add the Opposing Force weapons as you wish
 - weapon_pipewrench
 - weapon_knife
 - weapon_grapple
 - weapon_eagle
 - weapon_sniperrifle
 - weapon_m249
 - weapon_sporelauncher
 - weapon_shockrifle
 - weapon_displacer
 - ammo_556 (for m249)
 - amm_762  (for sniperrifle)


# Opposing Force Crowbar
// op4_crowbar.amxx

- Allows you to throw your crowbar by using attack 2 (right click mouse)


# Opposing Force Weapon Framework
// op4_weapon_framework.amxx

Bind "wp_spawn" to start the plugin, or type it in console. This will save map.ini files in a folder called "weapon_factory" that can be found in your amxx configs folder.

# Opposing Force Rune Mod (Requires 2 plugins)
// op4_rune_list.amxx
// op4_runes.amxx

Requires both of these plugins to work. Bind "rune_spawn_132" to start the plugin, or type it in console. This will save rune.ini files in a folder called "op4_runes" that can be found in your amxx configs folder. This plugin does not work on all maps for some unknown reason. 

# Opposing Force CTF Jump Fix
// op4ctf_jumpfix.amxx

A plugin created by SPiNX. This fixes the bug with the CTF Longjump pack not working.

# Friction
// friction.amxx

A simple plugin created by SPiNX to stop the map changing the friction, as this there is a bug in Opposing Force that when you walk on ice, you cannot stop sliding across the map.
