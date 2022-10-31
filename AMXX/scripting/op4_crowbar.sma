/* Flying Crowbar for Half-Life DeathMatch */
/* by GordonFreeman and Gauss */

#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <fakemeta_util>
#include <xs>

#define CROW "fly_crowbar"	

new g_maxplayers

new blood_drop
new blood_spray
new trail

new const m_pPlayer = 31
new const m_flNextSecondaryAttack = 39

new const XTRA_OFS_WEAPON = 4

new crowbar_render,damage_crowbar,crowbar_speed,crowbar_trail,crowbar_lifetime

#define IsPlayer(%1) (1 <= %1 <= g_maxplayers)

public plugin_init() {
	register_plugin("Flying Crowbar","0.3","GordonFreeman//Gauss")
	
	g_maxplayers = get_maxplayers()
	
	register_message(get_user_msgid("DeathMsg"),"DeathMsg")
	
	RegisterHam(Ham_Weapon_SecondaryAttack,"weapon_crowbar","fw_CrowbarSecondaryAttack")
	RegisterHam(Ham_Item_AddToPlayer,"weapon_crowbar","fw_CrowbarItemAdd")
	RegisterHam(Ham_Item_AddDuplicate,"weapon_crowbar","fw_CrowbarItemAdd")
	
	register_think(CROW,"FlyCrowbar_Think")
	register_touch(CROW,"*","FlyCrowbar_Touch")
	
	crowbar_lifetime = register_cvar("fly_crowbar_time","15.0")
	crowbar_speed = register_cvar("fly_crowbar_speed","1300")
	crowbar_render = register_cvar("fly_crowbar_render","1")
	crowbar_trail = register_cvar("fly_crowbar_trail","1")
	damage_crowbar = register_cvar("fly_crowbar_damage","240.0")
}

public plugin_precache(){
	blood_drop = precache_model("sprites/blood.spr")
	blood_spray = precache_model("sprites/bloodspray.spr")
	trail = precache_model("sprites/zbeam3.spr")
}

//Замена сообщения об убийстве, что оно произошло именно монтировкой
public DeathMsg()					
{	
	static sWeapon[20]
	get_msg_arg_string(3,sWeapon,19)
	if(equal(sWeapon,CROW)) 
		set_msg_arg_string(3,"crowbar")
}

//Вторичная атака для лома
public fw_CrowbarSecondaryAttack(ent){
	new id = get_pdata_cbase(ent,m_pPlayer,XTRA_OFS_WEAPON)
	
	if(!FlyCrowbar_Spawn(id))
		return HAM_IGNORED
	
	set_pdata_float(ent,m_flNextSecondaryAttack,0.5,XTRA_OFS_WEAPON)
	ExecuteHam(Ham_RemovePlayerItem,id,ent)
	user_has_weapon(id,HLW_CROWBAR,0)
	ExecuteHamB(Ham_Item_Kill,ent)
	
	return HAM_IGNORED
}

//Отлов столкновений летящего лома с другими объектами
public FlyCrowbar_Touch(toucher,touched){
	new Float:origin[3],Float:angles[3]
	pev(toucher,pev_origin,origin)
	pev(toucher,pev_angles,angles)
	
	if(!IsPlayer(touched)){
		emit_sound(toucher,CHAN_WEAPON,"weapons/cbar_hit1.wav",0.9,ATTN_NORM,0,PITCH_NORM)
		
		engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0)
		write_byte(TE_SPARKS)
		engfunc(EngFunc_WriteCoord,origin[0])
		engfunc(EngFunc_WriteCoord,origin[1])
		engfunc(EngFunc_WriteCoord,origin[2])
		message_end()
	}else{
		ExecuteHamB(Ham_TakeDamage,touched,toucher,pev(toucher,pev_owner),get_pcvar_float(damage_crowbar),DMG_CLUB)	
		emit_sound(toucher,CHAN_WEAPON,"weapons/cbar_hitbod1.wav",0.9,ATTN_NORM,0,PITCH_NORM)
		
		engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0)
		write_byte(TE_BLOODSPRITE)
		engfunc(EngFunc_WriteCoord,origin[0]+random_num(-20,20))
		engfunc(EngFunc_WriteCoord,origin[1]+random_num(-20,20))
		engfunc(EngFunc_WriteCoord,origin[2]+random_num(-20,20))
		write_short(blood_spray)
		write_short(blood_drop)
		write_byte(248) // color index
		write_byte(15) // size
		message_end()
	}
	
	engfunc(EngFunc_RemoveEntity,toucher)// Уничтожить
	
	new crow = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"weapon_crowbar"))
		
	DispatchSpawn(crow)
	set_pev(crow,pev_spawnflags,SF_NORESPAWN)	
	
	angles[0] = 0.0
	angles[2] = 0.0
	
	set_pev(crow,pev_origin,origin)
	set_pev(crow,pev_angles,angles)
	
	if(get_pcvar_num(crowbar_render))
		fm_set_rendering(crow, kRenderFxGlowShell,55+random(200),55+random(200),55+random(200),kRenderNormal)
	
	set_task(get_pcvar_float(crowbar_lifetime),"Crowbar_Think",crow)
}

public Crowbar_Think(ent)
	if(pev_valid(ent))
		engfunc(EngFunc_RemoveEntity,ent)	// ЗДОХНИ!!!!

public fw_CrowbarItemAdd(ent,id)
	remove_task(ent)

//Кидаем лом
public FlyCrowbar_Spawn(id){
	new crowbar = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	
	if(!pev_valid(crowbar))
		return 0
	
	set_pev(crowbar,pev_classname,CROW)
	engfunc(EngFunc_SetModel,crowbar,"models/w_crowbar.mdl")
	engfunc(EngFunc_SetSize,crowbar,Float:{-4.0, -4.0, -4.0} , Float:{4.0, 4.0, 4.0})
	
	new Float:vec[3]
	get_projective_pos(id,vec)
	engfunc(EngFunc_SetOrigin,crowbar,vec)
	
	
	pev(id,pev_v_angle,vec)
	vec[0] = 90.0
	vec[2] = floatadd(vec[2],-90.0)
	
	set_pev(crowbar,pev_owner,id)
	set_pev(crowbar,pev_angles,vec)
	
	velocity_by_aim(id,get_pcvar_num(crowbar_speed)+get_speed(id),vec)
	set_pev(crowbar,pev_velocity,vec)
	
	set_pev(crowbar,pev_nextthink,get_gametime()+0.1)
	
	DispatchSpawn(crowbar)
	
	if(get_pcvar_num(crowbar_trail)){
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW)  
		write_short(crowbar)
		write_short(trail)
		write_byte(15)
		write_byte(2)
		write_byte(55+random(200))
		write_byte(55+random(200))
		write_byte(55+random(200))
		write_byte(255)
		message_end()
	}
	
	set_pev(crowbar,pev_movetype,MOVETYPE_TOSS)
	set_pev(crowbar,pev_solid,SOLID_BBOX)
	
	emit_sound(id,CHAN_WEAPON,"weapons/cbar_miss1.wav",0.9,ATTN_NORM,0,PITCH_NORM)
	set_task(0.1,"FlyCrowbar_Whizz",crowbar)
	
	return crowbar
}

//Лом вертится в полёте
public FlyCrowbar_Think(ent){
	new Float:vec[3]
	pev(ent,pev_angles,vec)
	vec[0] = floatadd(vec[0],-15.0)
	set_pev(ent,pev_angles,vec)
	
	set_pev(ent,pev_nextthink,get_gametime()+0.01)
}

//Звуки от летящего лома
public FlyCrowbar_Whizz(crowbar){
	if(pev_valid(crowbar)){
		emit_sound(crowbar,CHAN_WEAPON,"weapons/cbar_miss1.wav",0.9,ATTN_NORM,0,PITCH_NORM)
		
		set_task(0.2,"FlyCrowbar_Whizz",crowbar)
	}
}

//Вычисление позиции появления лома
get_projective_pos(player,Float:oridjin[3]){
	new Float:v_forward[3]
	new Float:v_right[3]
	new Float:v_up[3]
	
	GetGunPosition(player,oridjin)
	
	global_get(glb_v_forward,v_forward)
	global_get(glb_v_right,v_right)
	global_get(glb_v_up,v_up)
	
	xs_vec_mul_scalar(v_forward,6.0,v_forward)
	xs_vec_mul_scalar(v_right,2.0,v_right)
	xs_vec_mul_scalar(v_up,-2.0,v_up)
	
	xs_vec_add(oridjin,v_forward,oridjin)
	xs_vec_add(oridjin,v_right,oridjin)
	xs_vec_add(oridjin,v_up,oridjin)
}

//Получить положение оружия
stock GetGunPosition(const player,Float:origin[3]){
	new Float:viewOfs[3]
	
	pev(player,pev_origin,origin)
	pev(player,pev_view_ofs,viewOfs)
	
	xs_vec_add(origin,viewOfs,origin)
}

/* all comments made by Gauss */
