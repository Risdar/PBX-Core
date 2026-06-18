// This id the data for PB Weapons

extend class PBXCore_HUDHandler
{
//////////////////////////// PB WEAPONS ////////////////////////////////////////////////////////////////////////////////////
    protected
    ui void DrawPBWeapon(PB_Hud_ZS phud, PB_WeaponBase pbWeap)
    {
        
        // Set Defaults & Variables
        TextureID iconID = pbWeap.AltHudIcon.IsValid() ? pbWeap.AltHudIcon : pbWeap.Icon;
        string icon = TexMan.GetName(iconID);
        vector2 adjustPos,adjustPos2, adjustPos3 = (0,0);
        double adjustScale  = 1.0;
        double adjustScale2 = 1.0;
        double adjustScale3 = 1.0;
        isAkimbo            = pbWeap.akimboMode;

        // ADD ADJUSTMENTS HERE
        switch(pbWeap.GetClassName())
        {
//////////////// SLOT 1 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            case 'PB_Fists':
                adjustPos = (-15, 20); 
                adjustScale = 0.6;
                break;

            case 'PB_Chainsaw':
                adjustPos = (-20, 32); 
                break;

            case 'PB_Axe':
                adjustPos = (-30, 40); 
                break;

//////////////// SLOT 2 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            case 'PB_MP40':
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos = isAkimbo ? (-5, -10) : (-8,10); 
                adjustScale = 0.7;
                break;

            case 'PB_SMG':
                let smg = PB_SMG(pbWeap);
                if(!smg) return;
                bool smgSilenced = smg.hasSilencer;

                pbx_image = (smgSilenced ? "ATFLA0" : "ATFLB0");
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos = smgSilenced ?  (-13,14) : (10,14); // Single ? Silenced : Not Silenced
                adjustScale = 0.9;
                break;

            case 'PB_Pistol':
                let pistol = PB_Pistol(pbWeap);
                if(!pistol) return;
                bool pistolSilenced = pistol.hasSilencer;

                pbx_image = (pistolSilenced ? "graphics/pywheel/PISTOL_1.png" : "graphics/pywheel/PISTOL_0.png");
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos = pistolSilenced ?  (-2,18) : (18,18); // Single ? Silenced : Not Silenced
                adjustScale = 1.1;
                break;

            case 'PB_Revolver':
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos = (-20, 12); 
                break;

            case 'PB_Deagle':
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos = (-30, 13); 
                adjustScale = 1.1;
                break;

//////////////// SLOT 3 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            case 'PB_Shotgun':
                let shotgun = PB_Shotgun(pbWeap);
                bool shotgunUpgraded = PBX_PlayerHasInventory("PumpshotgunMagazine");
                if(!shotgun) return;

                switch(shotgun.shellsmode)
                {
                    case PB_Shotgun.Shell_Buck:
                        pbx_image2 = "buckhud";
                        break;
                    case PB_Shotgun.Shell_Slug:
                        pbx_image2 = "slughud";
                        break;
                    case PB_Shotgun.Shell_Drag:
                        pbx_image2 = "drgnhud";
                        break;
                }
                pbx_image = shotgunUpgraded ? "9SMUA0" : icon;
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos = (-5, 10); 
                // adjustScale = 1.0;
                break;

            case 'PB_Autoshotgun':
                bool asgUpgraded = PBX_PlayerHasInventory("AutoshotgunDrumMag");
                pbx_image = asgUpgraded ? "A9SCA0" : icon;
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos = (-9,15); 

                if(asgUpgraded) adjustPos.y -= -5; // Move up a bit if its upgraded
                break;

            case 'PB_SSG':
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos = (-20,13); 
                break;

            case 'PB_QuadSG':
                bool quadFullBlast = PBX_PlayerHasInventory("FullBlastMode");
                bool demonBreath = PBX_PlayerHasInventory("BreathMode");

                pbx_image = (demonBreath ? "graphics/pywheel/Quad_Demonic.png" : "QSPGA0");     
                pbx_image2 = quadFullBlast ? "graphics/WeaponIcons/QUAD_FULL.png" : "graphics/WeaponIcons/QUAD_HALF.png";
                pbx_image3 = ""; //its empty for now

                adjustPos = demonBreath ? (1,12) : (0,10);
                // MODE
                adjustPos2 = (0,-20);
                adjustScale2 = 0.2;
                break;

//////////////// SLOT 4 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            case 'PB_DMR':
                bool dmrUpgraded    = PBX_PlayerHasInventory("DMRUpgraded");
                bool hdmrSniperMode = PBX_PlayerHasInventory("HDMRSniperMode");
                bool hdmrGrenMode   = PBX_PlayerHasInventory("HDMRGrenadeMode");
                
                // Behold my masterpiece
                pbx_image = !dmrUpgraded ? icon : (hdmrSniperMode  ? "graphics/WeaponPickups/HDMR_SNIPER_SINGLE.png" : "HIFLA0");
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos   = !dmrUpgraded ? (-5,12) : hdmrSniperMode  ? (-6,10) : (-4,10); 
                adjustScale = dmrUpgraded ? 0.8 : 0.9;
                break;

            case 'PB_Carbine':
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now
                adjustPos = (-10,15);
                adjustScale = 1.2;
                break;

            case 'PB_LMG':
                pbx_image = "LMPIA0";
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now
                adjustPos = (3, 23);
                adjustScale = 0.8;
                break;

            case 'PB_ChexRifle':
                pbx_image = "CRRSA0";
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now
                adjustPos = (-10, 13);
                adjustScale = 0.9;
                break;

//////////////// SLOT 5 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            case 'PB_MG42':
                adjustPos = (-10, 32);
                adjustScale = 0.5;
                break;

            case 'PB_Minigun':
                bool tripleMode   = PBX_PlayerHasInventory("TripleBarrelMode");
                bool chaingunMode = PBX_PlayerHasInventory("ChainGunMode");
                bool tripleBarrel = PBX_PlayerHasInventory("TripleBarrelMode");

                // If the current mode is the triplebarrel
                int mode = !chaingunMode && tripleMode  ? 2       // triple
                            :  chaingunMode && !tripleMode ? 1    // chaingun (default)
                            : 0;                                  // normal

                pbx_image = tripleBarrel ? "8GUNA0" : icon;
                pbx_image2   =  mode == 2 ? "graphics/WeaponIcons/EXTREMELYHIHGSPID.png" : 
                                mode == 1 ? "graphics/WeaponIcons/NORMALSPEED.png" : 
                                "graphics/WeaponIcons/HIGHSPEED.png";
                pbx_image3 = ""; //its empty for now

                adjustPos = tripleMode ? (-15,30) : (-15,32);
                adjustPos2   = mode == 2 ? (-3, 0) : mode == 1 ? (0, 0) : (0, 0);
                adjustScale2 = mode == 2 ? 0.5      : mode == 1 ? 0.9     : 0.9;
                break;

            case 'PB_Nailgun':
                adjustPos = (-9,12);
                break;

//////////////// SLOT 6 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            case 'PB_RocketLauncher':
                // WHY IS THE ROCKETLAUNCHER MODE SWITCH SO JANK
                // WHAT DO YOU MEAN ITS A STRING
                if(pbweap)
                {
                    if(pbweap.rocketLauncherMode == "Standard")
                    {
                        pbx_image2 = "graphics/pywheel/rocket_standard.png";
                    }
                    else if (pbweap.rocketLauncherMode == "Homing")
                    {
                        pbx_image2 = "graphics/pywheel/rocket_homing.png";
                    }
                    else if (pbweap.rocketLauncherMode == "Laser")
                    {
                        pbx_image2 = "graphics/pywheel/rocket_laser.png";
                    }
                }
                pbx_image3 = ""; //its empty for now

                adjustPos = (-8 , 15);
                adjustScale = 0.9;

                adjustPos2 = (0,-20);
                adjustScale2 = 0.3;
                break;

            case 'PB_SuperGL':
                let sgl = PB_SuperGL(pbWeap);
                if(!sgl) return;

                static const string sglIcons[] = {
                    "graphics/pywheel/grenade_impact.png", "graphics/pywheel/grenade_sticky.png", 
                    "graphics/pywheel/grenade_acid.png", "graphics/pywheel/grenade_incendiary.png", 
                    "graphics/pywheel/grenade_cryo.png"
                };

                int sglgren = clamp(sgl.GrenadeMode, 0, sglIcons.Size() - 1);

                pbx_image2 = sglIcons[sglgren];
                pbx_image3 = ""; //its empty for now

                adjustPos = (-5, 13);
                adjustScale = 0.9;

                adjustPos2 = (3,-18);
                adjustScale2 = 0.3;
                break;

//////////////// SLOT 7 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            case 'PB_M1Plasma':
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos = (-10,12);
                break;

            case 'PB_M2Plasma':
                bool m2Upgraded = PBX_PlayerHasInventory("HasLightningGunUpgrade");

                pbx_image = (m2Upgraded ? "M2PRB0" : icon);
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos = (-10,15);
                adjustScale = 0.9;
                break;

            case 'PB_DTechRifle':
                adjustPos = (-5, 15);
                adjustScale = 0.9;
                break;

//////////////// SLOT 8 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            case 'PB_Flamethrower':
                bool flamerUpgraded = PBX_PlayerHasInventory("FlamerUpgraded");
                pbx_image = flamerUpgraded ? "FSPWB0" : "FSPWA0";
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos = flamerUpgraded ? (-15, 40) : (-10,15); 
                break;

            case 'PB_CryoRifle':
                let cryorifle = PB_CryoRifle(pbWeap);
                if(!cryorifle) return;

                bool cryoMissile = cryorifle.cryoPrimary   == cryorifle.PRIM_MISSILE;
                bool cryoSpear   = cryorifle.cryoSecondary == cryorifle.SEC_SPEAR;

                pbx_image = "FRPKA0";
                pbx_image2 = cryoSpear ? "graphics/pywheel/CryoRifle_Spear.png" : "graphics/pywheel/CryoRifle_Flak.png";
                pbx_image3 = cryoMissile ? "graphics/pywheel/CryoRifle_Missile.png" : "graphics/pywheel/CryoRifle_Beam.png";

                adjustPos = (-5, 15);

                adjustPos2   = (0,-60);
                adjustScale2 = 0.3;

                adjustPos3   = (0,-10);
                adjustScale3 = 0.3;
                break;

//////////////// SLOT 9 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            case 'PB_BFG9000':
                pbx_image = "097GA0";
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos = (-10,32);
                adjustScale = 0.8;
                break;

            case 'PB_Railgun':
                adjustPos = (-5,15);
                adjustScale = 0.8;
                break;
                
            case 'PB_Unmaker':
                pbx_image = "UNHDA0";
                pbx_image2 = ""; //its empty for now
                pbx_image3 = ""; //its empty for now

                adjustPos = (-5,15);
                adjustScale = 0.9;
                break;

            default:
                pbx_image  = "";
                pbx_image2 = "";
                pbx_image3 = ""; 
                adjustPos    = (0,0);
                adjustPos2   = (0,0);
                adjustPos3   = (0,0);
                adjustScale  = 1.0;
                adjustScale2 = 1.0;
                adjustScale3 = 1.0;
                break;
        }
        // Send the Values
        pbx_weapon_pos          += adjustPos;
        pbx_weapon_pos2         += adjustPos2;
        pbx_weapon_pos3         += adjustPos3;
        pbx_weapon_truescale    *= adjustScale;
        pbx_weapon_truescale2   *= adjustScale2;
        pbx_weapon_truescale3   *= adjustScale3;
       
        // If akimbo then put the icon higher regardless
        if(isAkimbo || hdmrGrenMode) // Edge case for the HDMR Grenade Mode
            pbx_weapon_pos.y += AKIMBO_POSITION_WHOLE;
    }
}