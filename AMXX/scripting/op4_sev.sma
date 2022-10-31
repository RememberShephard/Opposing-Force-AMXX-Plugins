#include <amxmodx>
#include <amxmisc>
#include <xs>
#include <fakemeta>
#include <engine>
#include <hamsandwich>

#define PLUGIN "Opposing Force 2.0"
#define VERSION ""
#define AUTHOR "LetiLetiLepestok + Gearbox"

#define GAME_DESCRIPTION "Opposing Force Sev+"

const Float:g_DamagePerShot		  		= 25.0
const Float:g_DamageCrowbar				= 50.0
const Float:g_SnarkThrowInterval		= 0.1
const g_GibsDmg							= 180
const g_HornetTrailTime 		  		= 10

/* WEAPONS OP4 OFFSETS */
const m_pPlayer					    	= 31
const m_flPumptime              		= 36
const m_fInSpecialReload				= 37
const m_flNextPrimaryAttack				= 38
const m_flNextSecondaryAttack			= 39
const m_flTimeWeaponIdle				= 40
const m_iClip							= 40
const m_pBeam 							= 176
const LINUX_OFFSET_WEAPONS				= 4
const LINUX_OFFSET_AMMO					= 5
const OFFSET_AMMO_HEGRENADE				= 319
const m_flNextAttack					= 151

const MAX_CLIENTS          				= 32;
const LINUX_OFFSET_WEAPONS 				= 4;

new g_LastTripmineAttack[33]
new g_SpawnsId[64]
new g_BlockSound
new g_MaxPlayers
new g_GrenadeAllocString
new g_HudSyncObj

new g_pcvar_fraglimit
new g_pcvar_timelimit
new g_pcvar_snark_style
new g_pcvar_hornet_style
new g_pcvar_status_style
new g_pcvar_tripmine_style
new g_pcvar_spawnprotect_time
new g_pcvar_remove_map_equip
new g_pcvar_death_info
new g_pcvar_shotgun_gibs
new g_pcvar_shotgun_blod

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	RegisterHam(Ham_Weapon_PrimaryAttack    , "weapon_tripmine"   ,     "TripminePrimaryAttack_Pre",    0)
	RegisterHam(Ham_Weapon_PrimaryAttack    , "weapon_snark"      ,     "Snark_PrimaryAttack_Post",     1)
	RegisterHam(Ham_Weapon_PrimaryAttack    , "weapon_handgrenade",     "Grenade_PrimaryAttack_Post",   1)
	RegisterHam(Ham_Weapon_SecondaryAttack  , "weapon_snark"      ,     "Snark_SecondaryAttack_Post",   1)
	RegisterHam(Ham_Weapon_SecondaryAttack  , "weapon_handgrenade",     "Grenade_SecondaryAttack_Pre",  0)
	RegisterHam(Ham_Weapon_SecondaryAttack  , "weapon_handgrenade",     "Grenade_SecondaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack  , "weapon_tripmine"   ,     "Tripmine_SecondaryAttack_Pre", 0)
	
	RegisterHam(Ham_Touch					          , "grenade"				    ,     "Grenade_Touch",                0)
	RegisterHam(Ham_Spawn					          , "monster_tripmine"	,     "TripMine_Spawn_Post",          0)
	RegisterHam(Ham_Spawn					          , "player"				    ,     "Player_Spawn_Pre",             0)
	RegisterHam(Ham_Spawn				          	, "player"				    ,     "Player_Spawn_Post",            1)
	RegisterHam(Ham_Killed					        , "player"				    ,     "Player_Death_Post",            1)
	RegisterHam(Ham_Killed					        , "player"				    ,     "Player_Death_Post",            1)
	RegisterHam(Ham_Think					          , "monster_tripmine"	,     "TripMine_Think_Post",          1)
	
	RegisterHam(Ham_TraceAttack			      	, "player"				    ,     "fw_TraceAttack")       
	RegisterHam(Ham_TraceAttack			      	, "worldspawn"			  ,     "fw_TraceAttackWorld")
	RegisterHam(Ham_TakeDamage			      	, "player"				    ,     "fw_TakeDamage")


	register_forward(FM_EmitSound		      	, "fwd_EmitSound")
	register_forward(FM_SetModel			      , "fwd_SetModel")
	register_forward(FM_GetGameDescription	, "fwd_GetGameDescription")
	
	register_message(get_user_msgid("StatusValue")	, "msg_StatusValue")
	register_message(SVC_TEMPENTITY					        , "msg_TempEntity" )
	
	register_cvar("SevModAMXXversion", VERSION	, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)
	register_cvar("SevModAMXXauthor", AUTHOR	, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)
	
	g_pcvar_snark_style 					= register_cvar("sev_snark_style"		, "1")
	g_pcvar_status_style 					= register_cvar("sev_status_style"		, "1")
	g_pcvar_hornet_style 					= register_cvar("sev_hornet_style"		, "1")
	g_pcvar_tripmine_style 					= register_cvar("sev_tripmine_style"	, "1")
	g_pcvar_death_info						= register_cvar("sev_death_info"		, "1")
	g_pcvar_spawnprotect_time				= register_cvar("sev_sp_time"			, "1.0")
	g_pcvar_remove_map_equip				= register_cvar("sev_remove_map_equip"	, "1")
	g_pcvar_shotgun_gibs					= register_cvar("sev_shotgun_gibs"		, "1")
	g_pcvar_shotgun_blod					= register_cvar("sev_shotgun_bloodspray", "1")

	g_pcvar_fraglimit 						= get_cvar_pointer("mp_fraglimit")
	g_pcvar_timelimit 						= get_cvar_pointer("mp_timelimit")
	
	g_GrenadeAllocString = engfunc(EngFunc_AllocString, "grenade")
	g_HudSyncObj = CreateHudSyncObj()
	g_MaxPlayers = get_maxplayers()
	start_map()
}

public plugin_precache()
{
	precache_sound("debris/beamstart4.wav")
	precache_sound("weapons/glauncher.wav")
	precache_sound("items/gunpickup2.wav")
	precache_sound("weapons/glauncher.wav")
	precache_sound("weapons/glauncher2.wav")

	precache_model("sprites/b-tele1.spr")
	precache_model("models/w_grenade.mdl")
	precache_model("models/w_chainammo.mdl")
}

public start_map()
{
	new cfg_dir[64]	
	new map_name[32]
	new equip_file[128]
	new no_eqip_file
	new ent
	new i
	
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "info_player_deathmatch")))
	{
		g_SpawnsId[i++] = ent
		if(i == sizeof g_SpawnsId)
			break
	}
	
	get_localinfo("amxx_configsdir", cfg_dir, charsmax(cfg_dir))
	get_mapname(map_name, charsmax(map_name)) 
	format(equip_file, charsmax(equip_file), "%s/maps/%s.ini", cfg_dir, map_name)
	
	if(!file_exists(equip_file))
	{
		format(equip_file, charsmax(equip_file), "%s/equipment.ini", cfg_dir)
		
		if(!file_exists(equip_file))
		{
			log_amx("No equipment file found.")
			return
		}		
	}
	else
		no_eqip_file = 1
	
	if(file_size(equip_file) < 8)
	{
		log_amx("Equipment file is too small.")
		return
	}

	new text[36]
	new equip_name[32]
	new equip_num[3]
	new line
	new textsize

	ent = 0
	
	if(no_eqip_file || get_pcvar_num(g_pcvar_remove_map_equip))
	{
		while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "game_player_equip")))
			engfunc(EngFunc_RemoveEntity, ent)	
	}
	
	ent = create_entity("game_player_equip")
	
	log_amx("Reading equipment file: ^"%s^"", equip_file)
	
	while(read_file(equip_file, line, text, charsmax(text), textsize))
	{
		line++
		trim(text)

		if(text[0] == ';')
			continue
	
		parse(text, equip_name, charsmax(equip_name), equip_num, charsmax(equip_num))
		
		if(!str_to_num(equip_num))
			continue
		
		DispatchKeyValue(ent, equip_name , equip_num)
		
		if(line > 48)
			break

		//server_print("* [%d] '%s'^t^t^t^t'%s'", line, equip_name , equip_num)
		equip_name = ""
		equip_num = ""
	}
	DispatchSpawn(ent)
}


// ===================================================================== SHOTGUN & CROWBAR POWER =========================

public fw_TraceAttack(victim, inflictor, Float:damage, Float:direction[3], traceresult, damagebits)
{
	if(!(1 <= inflictor <= g_MaxPlayers))
		return HAM_IGNORED

	static weapon
	static Float:hitpoint[3]
	static Float:vector[3]
	static Float:bloodstart[3]

	weapon = get_user_weapon(inflictor)

	if(weapon == HLW_SHOTGUN)
	{
		SetHamParamFloat(3, g_DamagePerShot)
		
		if(!get_pcvar_num(g_pcvar_shotgun_blod))
			return HAM_IGNORED
		
		get_tr2(traceresult, TR_vecEndPos, hitpoint)

		xs_vec_mul_scalar(direction, random_float(100.0, 400.0), vector)
		xs_vec_mul_scalar(direction, 50.0, bloodstart)
		xs_vec_add(hitpoint, bloodstart, bloodstart)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BLOODSTREAM)
		write_coord(floatround(bloodstart[0]))
		write_coord(floatround(bloodstart[1]))
		write_coord(floatround(bloodstart[2]))
		write_coord(floatround(vector[0])) // x
		write_coord(floatround(vector[1])) // y
		write_coord(floatround(vector[2])) // z
		write_byte(70) // color
		write_byte(150) // speed
		message_end()
		return HAM_IGNORED
	}
	
	if(weapon == HLW_CROWBAR)		
		SetHamParamFloat(3, g_DamageCrowbar)
			
	return HAM_IGNORED
}

public fw_TraceAttackWorld(victim, inflictor, Float:damage, Float:direction[3], traceresult, damagebits)
{
	if(damagebits != DMG_BULLET)
		return HAM_IGNORED
	
	static Float:hitpoint[3]
	get_tr2(traceresult, TR_vecEndPos, hitpoint)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	write_coord(floatround(hitpoint[0]))
	write_coord(floatround(hitpoint[1]))
	write_coord(floatround(hitpoint[2]))
	message_end()
	return HAM_HANDLED
}

// ===================================================================== GIBS ==================================

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(damage < g_GibsDmg || !(1 <= inflictor <= g_MaxPlayers) || !get_pcvar_num(g_pcvar_shotgun_gibs))
		return HAM_IGNORED

	if(get_user_weapon(inflictor) == HLW_SHOTGUN)
		SetHamParamInteger(5, DMG_ALWAYSGIB)
		
	return HAM_IGNORED
}

// ===================================================================== SNARK MODEL & SOUND ===================

public  fwd_EmitSound(ent, channel, sample[], Float:volume, Float:attn, flags, pitch) 
{
	if(g_BlockSound)
		return FMRES_SUPERCEDE
	
	new classname[32]
	pev(ent, pev_classname, classname, 31)

	if(equal(classname, "monster_tripmine")  &&  equal(sample, "weapons/mine_activate.wav"))
	{
		TripMine_Beam(ent)
		return FMRES_HANDLED
	}
	
	if(!get_pcvar_num(g_pcvar_snark_style) || !equal(classname, "monster_snark"))
		return FMRES_IGNORED

	
	emit_sound(ent, channel, sample, volume, attn, 0, pitch)
	return FMRES_SUPERCEDE
}

// ===================================================================== SNARK INTERVAL ========================

public Snark_PrimaryAttack_Post(weapon)
	set_pdata_float(weapon, m_flNextPrimaryAttack, g_SnarkThrowInterval, LINUX_OFFSET_WEAPONS)

// ===================================================================== SNARK TELEPORT ========================

public Snark_SecondaryAttack_Post(id)
{
	new spawnId
	new Float:origin[3]
	new Float:angles[3]
	new player = pev(id, pev_owner)
	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "cycler_sprite"))

	set_pev(ent, pev_rendermode, kRenderTransAdd)
	engfunc(EngFunc_SetModel, ent, "sprites/b-tele1.spr")

	set_pev(ent, pev_renderamt, 255.0)
	set_pev(ent, pev_animtime, 1.0)
	set_pev(ent, pev_framerate, 50.0)
	set_pev(ent, pev_frame, 10)
	
	pev(player, pev_origin, origin)
	
	set_pev(ent,  pev_origin, origin)
	dllfunc(DLLFunc_Spawn, ent)
	set_pev(ent, pev_solid, SOLID_NOT)
	
	emit_sound(ent, CHAN_AUTO, "debris/beamstart4.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_byte(35)
	write_byte(80)
	write_byte(255)
	write_byte(100)
	write_byte(80)
	write_byte(60)
	message_end()
	
	spawnId = g_SpawnsId[random_num(0, strlen(g_SpawnsId) - 1)]
	
	pev(spawnId, pev_origin, origin)
	pev(spawnId, pev_angles, angles)
	
	set_pev(player, pev_origin, origin)
	set_pev(player, pev_angles, angles)
	set_pev(player, pev_fixangle, 1)
	set_pev(player, pev_velocity, {0.0, 0.0, 0.0})
	
	emit_sound(player, CHAN_AUTO, "debris/beamstart4.wav", 0.5, ATTN_NORM, 0, PITCH_NORM)
	
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, player)
	write_short(1<<10) 
	write_short(1<<3)
	write_short(0)
	write_byte(100)
	write_byte(255)
	write_byte(100)
	write_byte(150)
	message_end()	
	
	set_pdata_float(id, m_flNextSecondaryAttack, 60.0, LINUX_OFFSET_WEAPONS)
	set_task(0.5, "remove_telesprite_task", ent + 33453)
}

public remove_telesprite_task(ent)
{
	ent -= 33453
	if(pev_valid(ent))
		engfunc(EngFunc_RemoveEntity, ent)
}

// ===================================================================== GRENADE SECONDARY =====================

public Grenade_SecondaryAttack_Pre(weapon)
{
	
	new player = pev(weapon, pev_owner)
	new ammo = get_pdata_int(player, OFFSET_AMMO_HEGRENADE, LINUX_OFFSET_AMMO)	
	
	if(!ammo)
		return HAM_SUPERCEDE
	
	new g_GrenadeSounds[2][48] = {"weapons/glauncher.wav", "weapons/glauncher2.wav"}

	new Float:origin[3]
	new Float:velocity[3]
	new Float:avelocity[3]
	new Float:v_ofs[3]
	new Float:angles[3]		

	ammo--
	
	set_pdata_int(player, OFFSET_AMMO_HEGRENADE, ammo, LINUX_OFFSET_AMMO)
	
	new ent = engfunc(EngFunc_CreateNamedEntity, g_GrenadeAllocString)
	
	pev(player, pev_origin, origin)
	pev(player, pev_view_ofs, v_ofs)
	pev(player, pev_angles, angles)
	
	origin[0] += v_ofs[0] 
	origin[1] += v_ofs[1]
	origin[2] += v_ofs[2] 
	
	velocity_by_aim (player, 800, velocity)	
	
	avelocity[0] = random_float(-500.0, 100.0)
	avelocity[2] = random_float(-100.0, 100.0)
	
	set_pev(ent, pev_avelocity, avelocity)	
	
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_angles, angles)
	set_pev(ent, pev_owner, player)
	set_pev(ent, pev_gravity, 0.5)
	set_pev(ent, pev_velocity, velocity)
	
	dllfunc(DLLFunc_Spawn, ent)
	
	set_pev(ent, pev_takedamage, DAMAGE_YES)
	set_pev(ent, pev_health, 100.0)
	
	engfunc(EngFunc_SetModel, ent, "models/w_grenade.mdl")	
	
	UTIL_PlayWeaponAnimation (player, 5)
	
	if(ammo)
		set_task(1.0, "grenade_draw_anim", player + 4454)
	
	emit_sound(ent, CHAN_WEAPON, g_GrenadeSounds[random_num(0, 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	return HAM_HANDLED
}
	
public Grenade_SecondaryAttack_Post(weapon)
	set_pdata_float (weapon, m_flNextSecondaryAttack, 5.0, LINUX_OFFSET_WEAPONS)

public grenade_draw_anim(player)
{
	player -= 4454
	if(get_user_weapon(player) == HLW_HANDGRENADE)
		UTIL_PlayWeaponAnimation(player, 7)
}

public Grenade_Touch(ent)
	ExecuteHam(Ham_TakeDamage, ent, 0, 0, 1000.0, 0)

public Grenade_PrimaryAttack_Post(weapon)
	set_pdata_float (weapon, m_flNextSecondaryAttack, 1.0, LINUX_OFFSET_WEAPONS)

// ===================================================================== HORNET COLOR ==========================	

public msg_TempEntity()
{
	static r
	static g
	static b
	static _max
	static Float:multiplier
	static classname[32]
	
	if(!get_pcvar_num(g_pcvar_hornet_style) || get_msg_arg_int(1) != TE_BEAMFOLLOW)
		return PLUGIN_CONTINUE

	pev(get_msg_arg_int(2), pev_classname, classname, 31)

	if(!equal(classname, "hornet"))
		return PLUGIN_CONTINUE

	r = random_num(0, 255)
	g = random_num(0, 255)
	b = random_num(0, 255)
	
	_max = max(r, max(g, b))
	
	if(_max < 255)
	{
		multiplier = 255.0 / _max
		r =  floatround(r * multiplier)
		g =  floatround(g * multiplier)
		b =  floatround(b * multiplier)
	}
		
	set_msg_arg_int(4, ARG_BYTE, g_HornetTrailTime)
	set_msg_arg_int(6, ARG_BYTE, r)
	set_msg_arg_int(7, ARG_BYTE, g)
	set_msg_arg_int(8, ARG_BYTE, b)
	set_msg_arg_int(9, ARG_BYTE, 200)
	return PLUGIN_CONTINUE
}


// ===================================================================== TRIPMINE SECONDARY ====================	
		
public TripminePrimaryAttack_Pre(weapon)
{
	new player = pev(weapon, pev_owner)
	g_LastTripmineAttack[player] = 1
	return HAM_HANDLED
}	

public Tripmine_SecondaryAttack_Pre(weapon)
{
	if(!get_pcvar_num(g_pcvar_tripmine_style))
		return HAM_SUPERCEDE
	
	new player = pev(weapon, pev_owner)
	g_LastTripmineAttack[player] = 2
	ExecuteHam(Ham_Weapon_PrimaryAttack, weapon)
	set_pdata_float (weapon, m_flNextSecondaryAttack, 0.3, LINUX_OFFSET_WEAPONS)
	return HAM_SUPERCEDE
}

public TripMine_Spawn_Post(tripmine)
{
	new player = pev(tripmine, pev_owner)
	if(g_LastTripmineAttack[player] == 2)
	{
		set_pev(tripmine, pev_iuser4, player)
		UTIL_PlayWeaponAnimation (player, 6)
	}	
}

public TripMine_Beam(tripmine)
{
	if(!get_pcvar_num(g_pcvar_tripmine_style))
		return HAM_IGNORED
	
	new player = pev(tripmine, pev_iuser4)
	new beam = get_pdata_cbase(tripmine, m_pBeam, 5)
	
	if(player)
	{
		set_pev(beam, pev_body, 30)
		set_pev(tripmine, pev_dmg, 225.0) // 150% damage
	}
	else
		set_pev(beam, pev_body, 2)

	set_pev(beam, pev_renderamt, 100.0)
	set_pev(beam, pev_scale, 10.0)

	TripMine_Think_Post(tripmine)
	return false
}

public TripMine_Think_Post(tripmine)
{
	if(!get_pcvar_num(g_pcvar_tripmine_style) || !pev_valid(tripmine))
		return HAM_IGNORED
	
	static Float:color_time
	
	pev(tripmine, pev_fuser1, color_time)

	if(color_time < get_gametime())
	{
		new Float:rgb[3]
		new beam = get_pdata_cbase(tripmine, m_pBeam, 5)
		
		if(!pev_valid(beam))
			return HAM_IGNORED
			
		rgb[0] = random_float(0.0, 255.0)
		rgb[1] = random_float(0.0, 255.0)
		rgb[2] = random_float(0.0, 255.0)
		
		set_pev(beam, pev_animtime, random_float(100.0, 255.0))
		set_pev(beam, pev_rendercolor, rgb)
		set_pev(tripmine, pev_fuser1, get_gametime() + random_float(3.0, 20.0))
	}
	return HAM_IGNORED
}

// ===================================================================== SPAWN PROTECT & SPAWN SOUND ===========		

public Player_Spawn_Pre(player)
	g_BlockSound = 1

public Player_Spawn_Post(player)
{
	const 	Float:opacity = 128.0
	new 	Float:sp_time = get_pcvar_float(g_pcvar_spawnprotect_time)
	
	g_BlockSound = 0	

	emit_sound(player, CHAN_AUTO, "items/gunpickup2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
	
	if(sp_time > 0)
	{
		set_pev(player, pev_takedamage, DAMAGE_NO)
		set_pev(player, pev_rendermode, kRenderTransAlpha)
		set_pev(player, pev_renderamt, opacity)
		set_task(sp_time, "unset_spawn_protection", player + 8712)
	}
}

public unset_spawn_protection(player)
{
	player -= 8712
	if(pev_valid(player))
	{
		set_pev(player, pev_takedamage, DAMAGE_AIM)
		set_pev(player, pev_rendermode, kRenderNormal)
		set_pev(player, pev_renderamt, 16.0)
	}
}

// ===================================================================== PLAYER INFO ===========================

public msg_StatusValue(iMsgID, iDest, iClient)
{
	if(!get_pcvar_num(g_pcvar_status_style))
		return PLUGIN_CONTINUE
	
	if(get_pcvar_num(g_pcvar_status_style) == 2 && !is_user_admin(iClient))
		return PLUGIN_HANDLED
	
	static value, status[2]
		
	value = get_msg_arg_int(2)
 
	if(value && get_msg_arg_int(1) == 1)
	{
		status[0] = iClient
		status[1] = value
		show_status(status)
	}
	return PLUGIN_HANDLED
}

public show_status(status[])
{
	const 	Float:x = -1.0
	const 	Float:y = 0.55
	
	const 	r = 180
	const 	g = 180
	const 	b = 255
	
	new 	id
	new 	body
	new 	name[32]
	new		model[32]
	
	get_user_name(status[1], name, 31)
	get_user_info(status[1], "model", model, 31)

	get_user_aiming(status[0], id, body)
	
	if(id != status[1])
		return
	
	set_hudmessage(r, g, b, x, y, 0, 0.0, 0.8, 0.1, 0.5, -1)
	ShowSyncHudMsg(status[0], g_HudSyncObj, "%s^n(%s)", name, model)
	set_task(1.5 , "show_status" , status[0] + 4090 , status , 3)
}

// ===================================================================== DEATH INFO ============================

public Player_Death_Post(player)
{
	if(!get_pcvar_num(g_pcvar_death_info))
		return
	
	new mapname[32]
	new message[128]
	new time_left[32]

	new fraglimit = get_pcvar_num(g_pcvar_fraglimit)
	new timelimit = get_pcvar_num(g_pcvar_timelimit)
	
	get_mapname(mapname, 31)
	format_time(time_left, 31, "%M min %S sec", get_timeleft())
	
	if(!fraglimit && !timelimit)
		formatex(message, 127, "Map '%s' no time limit", mapname)
	else if(!fraglimit && timelimit)
		formatex(message, 127, "Map '%s' for %d minutes (%s left)", mapname , timelimit, time_left)
	else if(fraglimit && !timelimit)
		formatex(message, 127, "Map '%s' no time limit (%d frags left)", get_fragsleft())
	else
		formatex(message, 127, "Map '%s' for %d minutes (%s or %d frags left)", mapname , timelimit, time_left, get_fragsleft())
	
	set_hudmessage(random(256), random(256), random(256), -1.0, 0.6, 0, 2.0, 8.0, 0.1, 1.5, 4) 
	show_hudmessage(player, "Half-Life Opposing Force Severian's Mod+ ^n^n^n%s www.half-life-opposing-force.info^n^n^n%s", VERSION, message) 
}

public get_fragsleft()
{
    new i
    new frags
    new frags_max = -32767
    
    for(i = 1; i <= g_MaxPlayers; i++)
    {
        if(is_user_connected(i))
        {
            frags = get_user_frags(i)
            if(frags > frags_max)
                frags_max = frags
        }
    }
    return clamp(get_pcvar_num(g_pcvar_fraglimit) - frags_max, 0)
}

// ===================================================================== GAME DESCRIPTION ======================

public fwd_GetGameDescription()
{ 
	forward_return(FMV_STRING, GAME_DESCRIPTION)
	return FMRES_SUPERCEDE
}
	
// ===================================================================== STOCKS ================================	




stock UTIL_PlayWeaponAnimation (const Player, const Sequence)
{
    set_pev (Player, pev_weaponanim, Sequence)

    message_begin (MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
    write_byte(Sequence)
    write_byte(0)
    message_end()
}