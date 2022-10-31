#include <amxmodx>
#include <amxmisc>
#include <xs>
#include <fakemeta>

#define PLUGIN "OP4 Rune Mod"
#define VERSION "1.0"
#define AUTHOR "GordonFreeman"

new const runenames[][]={
	"nothing",
	"item_ctfbackpack",
	"item_ctfaccelerator",
	"item_ctfportablehev",
	"item_ctfregeneration",
	"item_ctflongjump"
}

new fwd,crent,move,idedit

// Custome Entity Storage
new Array:g_runenames
new Array:g_origins
new Array:g_angles

// Modifed Entity Storage
new Array:g_move
new Array:g_mclass

// Deleted Entity Storage
new Array:g_del
new Array:g_dclass

new path[256],bool:b,bool:f,bool:m//,bool:s

public plugin_precache(){
	precache_model("models/w_backpack.mdl")
	precache_model("models/w_jumppack.mdl")
	precache_model("models/w_accelerator.mdl")
	precache_model("models/w_porthev.mdl")
	precache_model("models/w_health.mdl")
	precache_sound("ctf/itemthrow.wav")
	precache_sound("ctf/pow_armor_charge.wav")
	precache_sound("ctf/pow_backpack.wav")
	precache_sound("ctf/pow_big_jump.wav")
	precache_sound("ctf/pow_health_charge.wav")
	precache_sound("items/ammopickup1.wav")
	precache_sound("turret/tu_ping.wav")

}

public plugin_init() {
	register_plugin("OP4 Runes","1.0","GordonFreeman")
	
	register_clcmd("rune_spawn_132","start_edit",ADMIN_CFG," - start rune spawner")
}

new Float:strmv[3]

public plugin_cfg(){
	g_runenames = ArrayCreate(32)
	g_origins = ArrayCreate(3)
	g_angles = ArrayCreate(3)
	
	g_move = ArrayCreate(10)
	g_mclass = ArrayCreate(32)
	
	g_del = ArrayCreate(3)
	g_dclass = ArrayCreate(32)
	
	get_localinfo("amxx_configsdir",path,255)
	formatex(path,255,"%s/op4_runes/",path)
	
	if(!dir_exists(path))
		mkdir(path)
	
	
	new map[96]
	get_mapname(map,31)
	
	formatex(path,255,"%s%s.ini",path,map)
	
	new file = fopen(path,"rt")
	
	new classname[32],sorig[20],sanlge[20]
	new Float:origin[3],Float:angle[3]
	
	new i,z,su
	
	if(file){
		while(!feof(file)){
			fgets(file,map,95)
			trim(map)
			
			if (map[0]&&!equali(map,";",1)){
				if(equali(map,"[addent]")){
					su=1
					continue
				}else if(equali(map,"[movent]")){
					su=2
					continue
				}else if(equali(map,"[deleted]")){
					su=3
					continue
				}
				
				if(su==1){
					parse(map,classname,31,sorig,19,sanlge,19)
					
					ParseVec(sorig,19,origin)
					ParseVec(sanlge,19,angle)
					
					ArrayPushString(g_runenames,classname)
					ArrayPushArray(g_origins,origin)
					ArrayPushArray(g_angles,angle)
					
					new ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,classname))
					
					if(!ent){
						log_error(AMX_ERR_GENERAL,"failed to creating %s entity",classname)
						
						return
					}
					
					dllfunc(DLLFunc_Spawn,ent)
					
					set_pev(ent,pev_origin,origin)
					set_pev(ent,pev_angles,angle)
					set_pev(ent,pev_iuser3,1)
					set_pev(ent,pev_iuser4,i)
					
					i++
				}else if(su==2){
					new sorg[20],Float:endorg[3],Float:allorg[9]
					
					parse(map,classname,31,sorig,19,sorg,19,sanlge,19)
					
					ParseVec(sorig,19,origin)
					ParseVec(sorg,19,endorg)
					ParseVec(sanlge,19,angle)
					
					allorg[0] = origin[0]
					allorg[1] = origin[1]
					allorg[2] = origin[2]
					allorg[3] = endorg[0]
					allorg[4] = endorg[1]
					allorg[5] = endorg[2]
					allorg[6] = angle[0]
					allorg[7] = angle[1]
					allorg[8] = angle[2]
					
					ArrayPushArray(g_move,allorg)
					ArrayPushString(g_mclass,classname)
					
					new ent = find_ent_at_origin(classname,origin)
					
					if(!ent){
						log_error(AMX_ERR_NOTFOUND,"failed to find %s at %.0f %.0f %.0f",classname,origin[0],origin[1],origin[2])
						
						return
					}
					
					
					set_pev(ent,pev_origin,endorg)
					set_pev(ent,pev_angles,angle)
					set_pev(ent,pev_iuser3,2)
					set_pev(ent,pev_iuser4,z)
					
					z++
				}else if(su==3){
					parse(map,classname,31,sorig,19)
					
					ParseVec(sorig,19,origin)
					
					ArrayPushArray(g_del,origin)
					ArrayPushString(g_dclass,classname)
					
					new ent = find_ent_at_origin(classname,origin)
					
					if(!ent){
						log_error(AMX_ERR_NOTFOUND,"failed to find %s at %.0f %.0f %.0f",classname,origin[0],origin[1],origin[2])
						
						return
					}
					
					engfunc(EngFunc_RemoveEntity,ent)
				}
			}
		}
		
		fclose(file)
	}
}

public plugin_end(){	
	new classname[32],Float:origin[3],Float:angle[3],Float:sorg[9]
	
	new map[32]
	get_mapname(map,31)
	
	new file = fopen(path,"w+")
	if(!file) return
	
	if(f){
		fclose(file)
		delete_file(path)
		
		return
	}
	
	if(!ArraySize(g_runenames)&&!ArraySize(g_move)&&!ArraySize(g_del)){
		fclose(file)
		delete_file(path)
		
		return
	}
	
	fprintf(file,"; Op4 Runes^n")
	fprintf(file,"; %s - map configuration file^n",map)
	fprintf(file,"^n")
	
	if(ArraySize(g_runenames)){
		fprintf(file,"^n;Item        origin (xyz)        angles (pyr)^n")
		fprintf(file,"[addent]^n^n")
		for(new i;i<ArraySize(g_runenames);++i){
			ArrayGetString(g_runenames,i,classname,31)
			
			if(equal(classname,"yandex"))
				continue
				
			fprintf(file,"%s ",classname)
			
			ArrayGetArray(g_origins,i,origin)
			ArrayGetArray(g_angles,i,angle)
			
			fprintf(file,"^"%.0f %.0f %.0f^" ^"%.0f %.0f %.0f^"^n",origin[0],origin[1],origin[2],angle[0],angle[1],angle[2])
		}
		
		fprintf(file,"^n")
		
		ArrayDestroy(g_runenames)
		ArrayDestroy(g_origins)
		ArrayDestroy(g_angles)
	}
	
	if(ArraySize(g_move)){
		fprintf(file,"^n;Item        moved from (xyz)        moved to (xyz)        Angles (pyr)^n")
		fprintf(file,"[movent]^n^n")
		
		for(new i;i<ArraySize(g_move);++i){
			ArrayGetString(g_mclass,i,classname,31)
			
			if(equal(classname,"yandex"))
				continue
				
			fprintf(file,"%s ",classname)
			
			ArrayGetArray(g_move,i,sorg)
			
			fprintf(file,"^"%.0f %.0f %.0f^" ^"%.0f %.0f %.0f^" ^"%.0f %.0f %.0f^"^n",sorg[0],sorg[1],sorg[2],sorg[3],sorg[4],sorg[5],sorg[6],sorg[7],sorg[8])
		}
		
		fprintf(file,"^n")
		
		ArrayDestroy(g_move)
		ArrayDestroy(g_mclass)
	}
	
	if(ArraySize(g_del)){
		if(!b){
			fprintf(file,"^n;Item        deleted from (xyz)^n")
			fprintf(file,"[deleted]^n^n")
		
			for(new i;i<ArraySize(g_del);++i){
				ArrayGetString(g_dclass,i,classname,31)
				
				if(equal(classname,"yandex"))
					continue
					
				fprintf(file,"%s ",classname)
			
				ArrayGetArray(g_del,i,origin)
			
				fprintf(file,"^"%.0f %.0f %.0f^"^n",origin[0],origin[1],origin[2])
			}
		
			fprintf(file,"^n")
		}
		
		ArrayDestroy(g_del)
		ArrayDestroy(g_dclass)
	}
	
	fprintf(file,"^n")
	fprintf(file,";^n")
	fprintf(file,"; Opposing Force Rune Mod")
	
	fclose(file)
	
	return
}

public start_edit(id,level,cid){
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
		
	if(idedit){
		new name[32]
		get_user_name(idedit,name,31)
		
		set_hudmessage(255, 127, 0, -1.0, 0.60, 0, 6.0, 5.0)
		show_hudmessage(id, "Currently editor is %s^nMore is not allowed",name)
		
		return PLUGIN_HANDLED
	}
	
	idedit=id
	start_menu(id)
	
	return PLUGIN_HANDLED	
}

public start_menu(id){
	new menu = menu_create("OP4 Runes","fw_MenuHandler")
	
	menu_additem(menu,"Spawn a Runes","s1",0)
	menu_additem(menu,"Edit Entities^n","s3",0)
	//menu_additem(menu,"Spawn Editor^n","s6",0)
	menu_additem(menu,"Come back all deleted items","s4",0)
	menu_additem(menu,"Full RESET","s5")
	
	m=false
	
	new data[1]
	data[0] = id
	
	set_task(0.1,"reshow",31337,data,1,"b",1)
	
	menu_display(id,menu)
}


public rune_menu(id){
	new menu = menu_create("Spawn a Rune","fw_MenuHandler")
	
	menu_additem(menu,"Back Pack^n","w1",0)
	menu_additem(menu,"Death Accelerator^n","w2",0)
	menu_additem(menu,"Portable HEV^n","w3",0)
	menu_additem(menu,"Regeneration^n","w4",0)
	menu_additem(menu,"Long Jump","w5",0)
	
	m=true
	
	menu_display(id,menu)
}


public edit_menu(id){
	if(!fwd)
		fwd = register_forward(FM_PlayerPreThink,"fw_EditPreThink")
	else{
		unregister_forward(FM_PlayerPreThink,fwd)
		fwd = register_forward(FM_PlayerPreThink,"fw_EditPreThink")
	}
	
	new menu = menu_create("Editor Menu","fw_MenuHandler")
	menu_additem(menu,"Origins/Angles^n","x1")
	menu_additem(menu,"Delete Item","x2")
	
	m=true
	
	menu_display(id, menu, 0)
}

public fw_MenuHandler(id,menu,item){
	if(item==MENU_EXIT){
		if(task_exists(31337))
			remove_task(31337)
	
		if(m)
			start_menu(id)
		else{
			menu_destroy(menu)
		
			idedit=0
		}
		
		if(fwd)
			unregister_forward(FM_PlayerPreThink,fwd)
			
		fwd = 0
		
		if(move){
			set_pev(move,pev_origin,strmv)
			res_ren(move)
			move = 0
		}
		
		if(crent>0){
			engfunc(EngFunc_RemoveEntity,crent)
			crent = 0
		}
		
		return PLUGIN_HANDLED
	}
	
	new data[6],name[64]
	new access,callback
	menu_item_getinfo(menu,item,access,data,5,name,63,callback)
	
	new key = str_to_num(data[1])
	
	switch(data[0]){
		case 's':{
			switch(key){
				case 1:	rune_menu(id)
				case 3: edit_menu(id)
				case 4:{
					ArrayClear(g_del)
					ArrayClear(g_dclass)
					b=true
					
					set_hudmessage(255, 85, 0, -1.0, -1.0, 0, 6.0, 12.0)
					show_hudmessage(id, "Undelete!")
					
					start_menu(id)
				}
				case 5:{
					ArrayClear(g_runenames)
					ArrayClear(g_origins)
					ArrayClear(g_angles)
					ArrayClear(g_move)
					ArrayClear(g_mclass)
					ArrayClear(g_del)
					ArrayClear(g_dclass)
					
					f=true
					
					set_hudmessage(255, 85, 0, -1.0, -1.0, 0, 6.0, 12.0)
					show_hudmessage(id, "RESET!^nRestart Your Server")
					
					start_menu(id)
				}
				/*case 6:{
					spawn_editor(id)
				}*/
			}
		}
		case 'w': addent(id,key,1)
			case 'a': addent(id,key,2)
			case 'z':{
			switch(key){
				case 1: spawnit(id)
				case 2:{
					angles(id)
					addentmenu(id)
				}
				case 3:{
					engfunc(EngFunc_RemoveEntity,crent)
					crent = 0
					
					if(fwd)
						unregister_forward(FM_PlayerPreThink,fwd)
					
					rune_menu(id)
				}
			}
		}
		case 'x':{
			switch(key){
				case 1:{
					if(!move){
						move = get_aiment(id)
						if(move){
							pev(move,pev_origin,strmv)
							
							set_task(0.2,"render",move)
							
							set_pev(move,pev_movetype,MOVETYPE_FLY)
							set_pev(move,pev_nextthink,0.0)
							set_pev(move,pev_solid,SOLID_NOT)
							
							move_menu(id)
						}else{
							set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 12.0)
							show_hudmessage(id, "No aiment founded")
							
							edit_menu(id)
						}
					}else{
						new classname[32],Float:temp[3],Float:endmv[3]
						pev(move,pev_angles,temp)
						
						pev(move,pev_origin,endmv)
						pev(move,pev_classname,classname,31)
							
						set_pev(move,pev_renderfx,kRenderFxDistort)
						set_pev(move,pev_rendermode,kRenderTransAdd)
						set_pev(move,pev_renderamt,128.0)
							
						switch(pev(move,pev_iuser3)){
							case 0:{
								new Float:org[9]
						
								org[0] = strmv[0]
								org[1] = strmv[1]
								org[2] = strmv[2]
								org[3] = endmv[0]
								org[4] = endmv[1]
								org[5] = endmv[2]
								org[6] = temp[0]
								org[7] = temp[1]
								org[8] = temp[2]
							
								ArrayPushString(g_mclass,classname)
								ArrayPushArray(g_move,org)
							}
							case 1:{
								ArraySetArray(g_origins,pev(move,pev_iuser4),endmv)
								ArraySetArray(g_angles,pev(move,pev_iuser4),temp)
							}case 2:{
								new Float:org[9]
								ArrayGetArray(g_move,pev(move,pev_iuser4),org)
								
								org[3] = endmv[0]
								org[4] = endmv[1]
								org[5] = endmv[2]
								org[6] = temp[0]
								org[7] = temp[1]
								org[8] = temp[2]
	
								
								ArraySetArray(g_move,pev(move,pev_iuser4),org)
							}
						}
							
						move = 0
						edit_menu(id)
					}
				}
				case 2:{
					new delent = get_aiment(id)
					
					if(delent){
						new Float:org[3],classname[32]
						
						pev(delent,pev_classname,classname,31)
						pev(delent,pev_origin,org)
						
						switch(pev(delent,pev_iuser3)){
							case 0:{
								ArrayPushString(g_dclass,classname)
								ArrayPushArray(g_del,org)
							}
							case 1:{
								ArraySetString(g_runenames,pev(delent,pev_iuser4),"yandex")
							}
							case 2:{
								new Float:lola[9]
								ArrayGetArray(g_move,pev(delent,pev_iuser4),lola)
								
								org[0]=lola[0]
								org[1]=lola[1]
								org[2]=lola[2]
								
								ArraySetString(g_mclass,pev(delent,pev_iuser4),"yandex")
								
								pev(delent,pev_classname,classname,31)
								
								ArrayPushString(g_dclass,classname)
								ArrayPushArray(g_del,org)
							}
						}
						
						engfunc(EngFunc_RemoveEntity,delent)
						
						set_hudmessage(255, 170, 0, -1.0, 0.60, 0, 6.0, 12.0)
						show_hudmessage(id, "%s is deleted from map",classname)
						
						edit_menu(id)
					}else{
						set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 12.0)
						show_hudmessage(id, "No aiment founded")
						
						edit_menu(id)
					}
				}
				case 3:{
					start_menu(id)
				}
			}
		}
		case 'm':{
			switch(key){
				case 1:{
					if(move){
						new Float:angle[3]
						pev(move,pev_angles,angle)
	
						angle[1]+=15.0
		
						if(angle[1]>=360.0)
							angle[1]=0.0
	
						set_pev(move,pev_angles,angle)
					
						move_menu(id)
					}else{
						set_hudmessage(255, 0, 0, -1.0, 0.60, 0, 6.0, 12.0)
						show_hudmessage(id, "No Moving Item Founded")
						edit_menu(id)
					}

				}
				case 2:{
					if(move){					
						set_pev(move,pev_origin,strmv)
						set_pev(move,pev_movetype,MOVETYPE_NONE)
						set_pev(move,pev_nextthink,1.0)
						set_pev(move,pev_solid,SOLID_TRIGGER)
						set_pev(move,pev_renderfx,kRenderFxNone)
						set_pev(move,pev_rendermode,kRenderNormal)
						set_pev(move,pev_renderamt,0.0)
						move = 0
						
						edit_menu(id)
					}else{
						set_hudmessage(255, 0, 0, -1.0, 0.60, 0, 6.0, 12.0)
						show_hudmessage(id, "No Moving Item Founded")
						edit_menu(id)
					}
				}
			}
		}
	}
	
	return PLUGIN_CONTINUE
}

public move_menu(id){
	new menu  =menu_create("Origins/Angles Menu","fw_MenuHandler")
	
	menu_additem(menu,"Move Here","x1",0)
	menu_additem(menu,"Angles","m1",0)
	menu_additem(menu,"Cancel","m2",0)
	
	menu_display(id,menu)
}

public addent(id,entid,type){
	if(fwd||crent){
		engfunc(EngFunc_RemoveEntity,crent)
		crent = 0
		unregister_forward(FM_PlayerPreThink,fwd)
	}
	
	if(type==1)
		crent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,runenames[entid]))

	
	set_pev(crent,pev_renderfx,kRenderFxDistort)
	set_pev(crent,pev_rendermode,kRenderTransAdd)
	set_pev(crent,pev_renderamt,128.0)
	
	dllfunc(DLLFunc_Spawn,crent)
	
	set_pev(crent,pev_movetype,MOVETYPE_FLY)
	set_pev(crent,pev_nextthink,0.0)
	set_pev(crent,pev_solid,SOLID_NOT)
	set_pev(crent,pev_iuser1,entid)
	set_pev(crent,pev_iuser2,type)
	set_pev(crent,pev_iuser3,1)
	
	fwd = register_forward(FM_PlayerPreThink,"fw_PlayerPreThink")
	
	addentmenu(id)
}

public addentmenu(id){
	new title[32]
	pev(crent,pev_classname,title,31)
	
	replace_all(title,32,"weapon_","")
	replace_all(title,32,"ammo_","")
	replace_all(title,32,"item_","")
	ucfirst(title)
	
	format(title,31,"Spawn %s",title)
	new menu = menu_create(title,"fw_MenuHandler")
	
	menu_additem(menu,"Spawn It","z1")
	menu_additem(menu,"Change Angle^n","z2")
	menu_additem(menu,"Cancle Adding","z3")
	
	menu_display(id,menu)
}

public angles(id){
	if(!crent){
		set_hudmessage(255, 0, 0, -1.0, 0.60, 0, 6.0, 12.0)
		show_hudmessage(id, "Change Angles Failed, no enitity is selected")
		
		if(fwd)
			unregister_forward(FM_PlayerPreThink,fwd)
		
		return
	}
	
	new Float:angle[3]
	pev(crent,pev_angles,angle)
	
	angle[1]+=15.0
	
	if(angle[1]>=360.0)
		angle[1]=0.0
	
	set_pev(crent,pev_angles,angle)
}

public spawnit(id){
	if(!crent){
		set_hudmessage(255, 0, 0, -1.0, 0.60, 0, 6.0, 12.0)
		show_hudmessage(id, "Adding Failed, no enitity is selected")
		
		if(fwd)
			unregister_forward(FM_PlayerPreThink,fwd)
		
		return
	}
	
	
	new Float:origin[3],Float:angle[3],classname[32]
	pev(crent,pev_origin,origin)
	pev(crent,pev_classname,classname,31)
	pev(crent,pev_angles,angle)
	
	set_hudmessage(255, 170, 0, -1.0, 0.60, 0, 6.0, 12.0)
	show_hudmessage(id, "Spawn position added^n[%.2f %.2f %.2f]",origin[0],origin[1],origin[2])
	
	new type = pev(crent,pev_iuser2)
	
	new tp = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,classname))
	
	set_pev(tp,pev_renderfx,kRenderFxDistort)
	set_pev(tp,pev_rendermode,kRenderTransAdd)
	set_pev(tp,pev_renderamt,128.0)
	
	dllfunc(DLLFunc_Spawn,tp)
	
	set_pev(tp,pev_movetype,MOVETYPE_FLY)
	set_pev(tp,pev_nextthink,0.0)
	set_pev(tp,pev_solid,SOLID_NOT)
	
	origin[2]+=5.0
	
	set_pev(tp,pev_origin,origin)
	set_pev(tp,pev_angles,angle)
	
	set_pev(tp,pev_iuser3,1)
	
	engfunc(EngFunc_RemoveEntity,crent)
	crent = 0
	
	ArrayPushString(g_runenames,classname)
	ArrayPushArray(g_origins,origin)
	ArrayPushArray(g_angles,angle)
	
	if(fwd)
		unregister_forward(FM_PlayerPreThink,fwd)
	
	if(type==1)
		rune_menu(id)
}

/*public spawn_editor(id){
	server_print("[C] Spawn Editor Called for %d",id)
	
	new ent,Float:origin[3]
	
	while((ent = engfunc(EngFunc_FindEntityByString,ent,"classname","info_player_deathmatch"))){
		pev(ent,pev_origin,origin)
		
		server_print("[%d] -> Founded at %.0f %.0f %.0f",ent,origin[0],origin[1],origin[2])
		
		new temp = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
		
		set_pev(temp,pev_classname,"spawnpoint_avatar")
		set_pev(temp,pev_origin,origin)
	
		pev(ent,pev_angles,origin)
		set_pev(temp,pev_angles,origin)
		
		set_pev(temp,pev_solid,SOLID_BBOX)
		engfunc(EngFunc_SetSize, temp, Float:{-20.0, -20.0, -20.0} , Float:{20.0, 20.0, 20.0})
		
		engfunc(EngFunc_SetModel,temp,"models/player.mdl")
	}
}*/


public fw_PlayerPreThink(id){
	if(!crent){
		unregister_forward(FM_PlayerPreThink,fwd)
		return FMRES_HANDLED
	}
	
	if(idedit!=id)
		return FMRES_HANDLED
	
	new orig[3],Float:origin[3]
	get_user_origin(id,orig,3)
	
	origin[0] = float(orig[0])
	origin[1] = float(orig[1])
	origin[2] = float(orig[2])
	
	set_pev(crent,pev_origin,origin)
	
	return FMRES_IGNORED
}

public fw_EditPreThink(id){
	if(idedit!=id)
		return FMRES_IGNORED
	
	if(move){
		new orig[3],Float:origin[3]
		get_user_origin(id,orig,3)
		
		origin[0] = float(orig[0])
		origin[1] = float(orig[1])
		origin[2] = float(orig[2])
		
		set_pev(move,pev_origin,origin)
		
		set_hudmessage(255, 255, 0, 0.01, 0.14, 0, 6.0, 0.1,_,_,1)
		show_hudmessage(id,"Entity Moving in Progress^nCurrent Origins: [%.1f] [%.1f] [%.1f]",origin[0],origin[1],origin[2])
		
		return FMRES_IGNORED
	}
	
	new target = get_aiment(id)
	
	new classname[32],Float:origin[3],Float:angle[3]
	
	pev(target,pev_classname,classname,31)
	pev(target,pev_origin,origin)
	pev(target,pev_angles,angle)
	
	set_hudmessage(128, 255, 0, 0.01, 0.14, 0, 6.0, 0.1,_,_,1)
	show_hudmessage(id, "Entity Editor^nID: %d [%s]^nOrigin: [%.1f] [%.1f] [%.1f]^nAngles: [%.1f] [%.1f] [%.1f]",target,classname,origin[0],origin[1],origin[2],angle[0],angle[1],angle[2])
	
	if(pev(target,pev_iuser3)){
		new olo[20]
		switch(pev(target,pev_iuser3)){
			case 1:formatex(olo,19,"Custome Entity")
			case 2:formatex(olo,19,"Moved Entity")
		}
		set_hudmessage(128, 255, 0, 0.01, 0.22, 0, 6.0, 0.1, _, _, 2)
		show_hudmessage(id, "FrameWork Entity. ID: %d^n%s",pev(target,pev_iuser4),olo)
	}
	
	set_ren(target)
	
	return FMRES_IGNORED
}

public render(ent){
	set_pev(ent,pev_renderfx,kRenderFxGlowShell)
	set_pev(ent,pev_rendermode,kRenderNormal)
	set_pev(ent,pev_rendercolor,{255.0,255.0,0.0})
	set_pev(ent,pev_renderamt,64.0)
}

public set_ren(ent){
	if(!pev_valid(ent))
		return PLUGIN_HANDLED
	set_pev(ent,pev_renderfx,kRenderFxGlowShell)
	set_pev(ent,pev_rendermode,kRenderNormal)
	set_pev(ent,pev_rendercolor,{128.0,255.0,0.0})
	set_pev(ent,pev_renderamt,64.0)
	
	set_task(0.01,"res_ren",ent)
	
	return PLUGIN_CONTINUE
}

public res_ren(ent){
	if(!pev_valid(ent))
		return PLUGIN_HANDLED
		
	set_pev(ent,pev_renderfx,kRenderFxNone)
	set_pev(ent,pev_rendermode,kRenderNormal)
	set_pev(ent,pev_rendercolor,{0.0,0.0,0.0})
	set_pev(ent,pev_renderamt,0.0)
	
	return PLUGIN_CONTINUE
}

public reshow(data[1]){
	new id = data[0]
	new jaja,jaja2,page
	
	player_menu_info(id,jaja,jaja2,page)
	
	if(jaja2<0){
		if(task_exists(31337))
			remove_task(31337)
		
		if(fwd)
			unregister_forward(FM_PlayerPreThink,fwd)
			
		idedit = 0
		
		if(crent){
			engfunc(EngFunc_RemoveEntity,crent)
			crent = 0
		}
		
		if(move){
			set_pev(move,pev_origin,strmv)
			res_ren(move)
			move = 0
		}
	}
}

// Parse Vector Function by KORD_12.7
ParseVec(szString[], iStringLen, Float: Vector[3]){
	new i;
	new szTemp[32];
	
	arrayset(_:Vector, 0, 3);
	
	while (szString[0] != 0 && strtok(szString, szTemp, charsmax(szTemp), szString, iStringLen, ' ', 1))
	{
		Vector[i++] = str_to_float(szTemp);
	}
}

stock traceline( const Float:vStart[3], const Float:vEnd[3], const pIgnore, Float:vHitPos[3] ){
	engfunc( EngFunc_TraceLine, vStart, vEnd, 0, pIgnore, 0 )
	get_tr2( 0, TR_vecEndPos, vHitPos )
	return get_tr2( 0, TR_pHit )
}

stock get_view_pos( const id, Float:vViewPos[3] ){
	new Float:vOfs[3]
	pev( id, pev_origin, vViewPos )
	pev( id, pev_view_ofs, vOfs )		
	
	vViewPos[0] += vOfs[0]
	vViewPos[1] += vOfs[1]
	vViewPos[2] += vOfs[2]
}

stock Float:vel_by_aim( id, speed = 1 ){
	new Float:v1[3], Float:vBlah[3]
	pev( id, pev_v_angle, v1 )
	engfunc( EngFunc_AngleVectors, v1, v1, vBlah, vBlah )
	
	v1[0] *= speed
	v1[1] *= speed
	v1[2] *= speed
	
	return v1
}

stock get_aiment(id){
	new target
	new Float:orig[3], Float:ret[3]
	get_view_pos( id, orig )
	ret = vel_by_aim( id, 9999 )
	
	ret[0] += orig[0]
	ret[1] += orig[1]
	ret[2] += orig[2]
	
	target = traceline( orig, ret, id, ret )
	
	new movetype
	if( target && pev_valid( target ) )
	{
		movetype = pev( target, pev_movetype )
		if( !( movetype == MOVETYPE_WALK || movetype == MOVETYPE_STEP || movetype == MOVETYPE_TOSS ) )
			return 0
	}
	else
	{
		target = 0
		new ent = engfunc( EngFunc_FindEntityInSphere, -1, ret, 10.0 )
		while( !target && ent > 0 )
		{
			movetype = pev( ent, pev_movetype )
			if( ( movetype == MOVETYPE_WALK || movetype == MOVETYPE_STEP || movetype == MOVETYPE_TOSS )
			&& ent != id  )
			target = ent
			ent = engfunc( EngFunc_FindEntityInSphere, ent, ret, 10.0 )
		}
	}

	if(0<target<=get_maxplayers())
		return 0
	
	new classname[32]
	pev(target,pev_classname,classname,31)
	
	if(equal(classname,"weaponbox"))
		return 0
	
	return target
}

stock find_ent_at_origin(classname[],Float:origin[3]){
	new ent = engfunc(EngFunc_FindEntityByString,ent,"classname",classname)
	
	new Float:corg[3]
	pev(ent,pev_origin,corg)
	
	while(origin[0]!=corg[0]||origin[1]!=corg[1]&&ent){
		ent = engfunc(EngFunc_FindEntityByString,ent,"classname",classname)
		pev(ent,pev_origin,corg)
	}
	
	return ent
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
