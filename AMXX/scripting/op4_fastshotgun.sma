#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>


/* WEAPONS OP4 OFFSETS */

    const m_pPlayer               = 31
    const m_flPumptime            = 36;
    const m_fInSpecialReload      = 37;
    const m_flNextPrimaryAttack   = 38;
    const m_flNextSecondaryAttack = 39;
    const m_flTimeWeaponIdle      = 40;
    const m_iClip                 = 43;

/* PLAYER HL OFFSETS */

    const m_flNextAttack   = 151;

 /* CONSTANTS */

    new const gShotgunClassname[] = "weapon_shotgun";

    const MAX_CLIENTS          = 32;
    const LINUX_OFFSET_WEAPONS = 4;

/* VARIABLES */

    new gOldClip         [ MAX_CLIENTS + 1 char ];
    new gOldSpecialReload[ MAX_CLIENTS + 1 char ];


public plugin_init()
{
    register_plugin( "Shotgun Reload/Fire Rate", "1.0.0", "Arkshine" );

    RegisterHam( Ham_Weapon_PrimaryAttack  , gShotgunClassname, "Shotgun_PrimaryAttack_Pre" , 0 );
    RegisterHam( Ham_Weapon_PrimaryAttack  , gShotgunClassname, "Shotgun_PrimaryAttack_Post", 1 );
    RegisterHam( Ham_Weapon_SecondaryAttack, gShotgunClassname, "Shotgun_SecondaryAttack_Pre" , 0 );
    RegisterHam( Ham_Weapon_SecondaryAttack, gShotgunClassname, "Shotgun_SecondaryAttack_Post", 1 );
    RegisterHam( Ham_Weapon_Reload         , gShotgunClassname, "Shotgun_Reload_Pre" , 0 );
    RegisterHam( Ham_Weapon_Reload         , gShotgunClassname, "Shotgun_Reload_Post", 1 );
    
    RegisterHam(Ham_Weapon_PrimaryAttack	 , "weapon_crossbow", "Crossbow_PrimaryAttack_Post", 1) 
    RegisterHam(Ham_Weapon_Reload	         , "weapon_crossbow", "Crossbow_Reload_Post", 1)
    RegisterHam(Ham_Weapon_SecondaryAttack , "weapon_crossbow", "Crossbow_SecondaryAttack_Post", 1)
    
    RegisterHam(Ham_Weapon_PrimaryAttack	 , "weapon_sniperrifle", "Sniperrifle_PrimaryAttack_Post", 1) 
    RegisterHam(Ham_Weapon_Reload	         , "weapon_sniperrifle", "Sniperrifle_Reload_Post", 1)
    RegisterHam(Ham_Weapon_SecondaryAttack , "weapon_sniperrifle", "Sniperrifle_SecondaryAttack_Post", 1)
}

// ===================================================================== FAST SHOTGUN ========================

public Shotgun_PrimaryAttack_Pre ( const shotgun )
{
    new player = get_pdata_cbase( shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS );
    gOldClip{ player } = get_pdata_int( shotgun, m_iClip, LINUX_OFFSET_WEAPONS );
}

public Shotgun_PrimaryAttack_Post ( const shotgun )
{
    new player = get_pdata_cbase( shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS );

    if ( gOldClip{ player } <= 0 )
    {
        return;
    }

    set_pdata_float( shotgun, m_flNextPrimaryAttack  , 0.6, LINUX_OFFSET_WEAPONS );
    set_pdata_float( shotgun, m_flNextSecondaryAttack, 0.6, LINUX_OFFSET_WEAPONS );

    if ( get_pdata_int( shotgun, m_iClip, LINUX_OFFSET_WEAPONS ) != 0 )
    {
        set_pdata_float( shotgun, m_flTimeWeaponIdle, 2.0, LINUX_OFFSET_WEAPONS );
    }
    else
    {
        set_pdata_float( shotgun, m_flTimeWeaponIdle, 0.3, LINUX_OFFSET_WEAPONS );
    }
}

public Shotgun_SecondaryAttack_Pre ( const shotgun )
{
    new player = get_pdata_cbase( shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS );
    gOldClip{ player } = get_pdata_int( shotgun, m_iClip, LINUX_OFFSET_WEAPONS );
}

public Shotgun_SecondaryAttack_Post ( const shotgun )
{
    new player = get_pdata_cbase( shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS );

    if ( gOldClip{ player } <= 1 )
    {
        return;
    }

    set_pdata_float( shotgun, m_flNextPrimaryAttack  , 0.4, LINUX_OFFSET_WEAPONS );
    set_pdata_float( shotgun, m_flNextSecondaryAttack, 0.8, LINUX_OFFSET_WEAPONS );

    if ( get_pdata_int( shotgun, m_iClip, LINUX_OFFSET_WEAPONS ) != 0 )
    {
        set_pdata_float( shotgun, m_flTimeWeaponIdle, 3.0, LINUX_OFFSET_WEAPONS );
    }
    else
    {
        set_pdata_float( shotgun, m_flTimeWeaponIdle, 0.85, LINUX_OFFSET_WEAPONS );
    }
}

public Shotgun_Reload_Pre ( const shotgun )
{
    new player = get_pdata_cbase( shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS );
    gOldSpecialReload{ player } = get_pdata_int( shotgun, m_fInSpecialReload, LINUX_OFFSET_WEAPONS );
}

public Shotgun_Reload_Post ( const shotgun )
{
    new player = get_pdata_cbase( shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS );

    switch ( gOldSpecialReload{ player } )
    {
        case 0 :
        {
            if ( get_pdata_int( shotgun, m_fInSpecialReload, LINUX_OFFSET_WEAPONS ) == 1 )
            {
                set_pdata_float( player , m_flNextAttack, 0.3 );

                set_pdata_float( shotgun, m_flTimeWeaponIdle     , 0.1, LINUX_OFFSET_WEAPONS );
                set_pdata_float( shotgun, m_flNextPrimaryAttack  , 0.4, LINUX_OFFSET_WEAPONS );
                set_pdata_float( shotgun, m_flNextSecondaryAttack, 0.5, LINUX_OFFSET_WEAPONS );
            }
        }
        case 1 :
        {
            if ( get_pdata_int( shotgun, m_fInSpecialReload, LINUX_OFFSET_WEAPONS ) == 2 )
            {
                set_pdata_float( shotgun, m_flTimeWeaponIdle, 0.1, LINUX_OFFSET_WEAPONS );
            }
        }
    }
}


// ===================================================================== CROSSBOW SPEED ========================

public Crossbow_PrimaryAttack_Post (const crossbow)
	set_pdata_float(crossbow, m_flNextPrimaryAttack  , 0.4, LINUX_OFFSET_WEAPONS)





public Crossbow_SecondaryAttack_Post(const crossbow)
	set_pdata_float(crossbow, m_flNextSecondaryAttack, 0.5, LINUX_OFFSET_WEAPONS)


	
	
	
public Crossbow_Reload_Post (const crossbow)
{
	new player = get_pdata_cbase(crossbow, m_pPlayer, LINUX_OFFSET_WEAPONS)
	
	set_pdata_float(player , m_flNextAttack, 2.0)
	set_pdata_float(crossbow, m_flTimeWeaponIdle	 , 2.9, LINUX_OFFSET_WEAPONS)
	set_pdata_float(crossbow, m_flNextPrimaryAttack  , 2.1, LINUX_OFFSET_WEAPONS)
	set_pdata_float(crossbow, m_flNextSecondaryAttack, 2.1, LINUX_OFFSET_WEAPONS)
}

// ===================================================================== SNIPERRIFLE SPEED ========================

public Sniperrifle_PrimaryAttack_Post (const sniperrifle)
	set_pdata_float(sniperrifle, m_flNextPrimaryAttack  , 0.4, LINUX_OFFSET_WEAPONS)





public Sniperrifle_SecondaryAttack_Post(const sniperrifle)
	set_pdata_float(sniperrifle, m_flNextSecondaryAttack, 0.5, LINUX_OFFSET_WEAPONS)


	
	
	
public Sniperrifle_Reload_Post (const sniperrifle)
{
	new player = get_pdata_cbase(sniperrifle, m_pPlayer, LINUX_OFFSET_WEAPONS)
	
	set_pdata_float(player , m_flNextAttack, 2.0)
	set_pdata_float(sniperrifle, m_flTimeWeaponIdle	 , 2.9, LINUX_OFFSET_WEAPONS)
	set_pdata_float(sniperrifle, m_flNextPrimaryAttack  , 2.1, LINUX_OFFSET_WEAPONS)
	set_pdata_float(sniperrifle, m_flNextSecondaryAttack, 2.1, LINUX_OFFSET_WEAPONS)
}