enum PBX_eHudSettingFlags{
    DisablePBX_WeaponHud        = 1 << 0,
    DisablePBX_WeaponModeHud    = 1 << 1,
    DisablePBX_WeaponModeBG     = 1 << 2,
    DisablePBX_ArmorHud		    = 1 << 3,
    DisablePBX_ArmorHudBG		= 1 << 4
}

// HUD System
class PBXCore_HUDHandler : EventHandler
{
//////////////////////////// VARIABLES ////////////////////////////////////////////////////////////////////////////////////
    // Position
    ui int pbx_weapon_PosX, pbx_weapon_PosY, pbx_weaponmode_PosX, pbx_weaponmode_PosY, pbx_armor_PosX, pbx_armor_PosY;

    // Scale
    ui double pbx_weapon_hudscale, pbx_weaponmode_hudscale, pbx_armor_hudscale;

    // Transparency
    ui double pbx_weapon_alpha, pbx_weaponmode_alpha, pbx_armor_alpha;

    // Cut Off Range (Box)
    ui int pbx_weapon_boxW, pbx_weapon_boxH;
    ui int pbx_weaponmode_boxW, pbx_weaponmode_boxH;
    ui int pbx_armor_boxW, pbx_armor_boxH;

    // Combine all individual values into one vector2
    ui Vector2 pbx_weapon_pos, pbx_weapon_truescale, pbx_weapon_box1;
    ui Vector2 pbx_weapon_pos2, pbx_weapon_truescale2, pbx_weapon_box2;
    ui Vector2 pbx_weapon_pos3, pbx_weapon_truescale3, pbx_weapon_box3;
    ui Vector2 pbx_armor_pos, pbx_armor_truescale, pbx_armor_box;

    // Flags
    ui int flagsleft, flagsright, flagssTextAlignRight, flagsManualVisor1, flagsManualVisor2, flagsLeftCenter;

    // Icons
    ui string pbx_image, pbx_image2, pbx_image3, pbx_image4;

    // Services
    ui Array<Service> PBX_HUDServices;
    ui bool ServicesLoaded;

    // Others
    ui PlayerInfo plr;
    ui PlayerPawn mo;
    ui PB_Hud_ZS phud;
    ui bool isAkimbo;
    ui vector2 akimboPosition;
    ui vector2 powerupPosition;


    enum PBXHud_DrawImageSettings{
        DRAW_WEAPON_ICON,
        DRAW_MODE_ICON,
        DRAW_MODE2_ICON,
        DRAW_ARMOR_ICON,
        DRAW_ARMOR_BG
    }

    // Powerup Position
    const POWERUP_POSITION_X = 16;
    const POWERUP_POSITION_Y = -76;

    // How many steps the whole icon should move
    const AKIMBO_POSITION_WHOLE = -15;

    // Where should the position of the second icon be
    // if dual wield is active
    const AKIMBO_POSITION_X = -10;
    const AKIMBO_POSITION_Y = -10;
    
//////////////////////////// MAIN FUNCTION ////////////////////////////////////////////////////////////////////////////////////
    override void RenderOverlay(RenderEvent e)
    {
        // Dont bother drawing if both the Weapon and Armor HUD is off
        if(CheckFlag(DisablePBX_WeaponHud) && CheckFlag(DisablePBX_ArmorHud))
            return;

        // Dont draw if the player is not in a leve or if the automap is active
        if (gamestate != GS_LEVEL || automapactive)
            return;

        // Get a pointer to the PB Hud so we can access it
        phud = PB_Hud_ZS(StatusBar);
        if (!phud) 
            return;

        // Dont draw if the player is dead
        if (phud.hudState == BaseStatusBar.HUD_None || phud.PlayerWasDead) 
            return;

        // Get a pointer to the player
        plr = players[consoleplayer];
        mo = plr.mo;
        if (!plr || !mo) 
            return;

        // If the menu is active or the console is up
        if (!menuactive || consolestate == c_up)
            gatherHUDCVARs(plr,phud); // Gather the CVARs

        // Begin drawing the HUD
        phud.BeginHUD();                // Initialize
        DrawEveryWeapon();
        DrawArmors();
        DrawPowerups();
        

    }

//////////////////////////// GATHER DATA ////////////////////////////////////////////////////////////////////////////////////
    // Find the Services function
    private
    ui void FindHUDServices()
    {
        if (ServicesLoaded)
            return;

        let it = ServiceIterator.Find("PBXHUDService");

        Service svc;

        while ((svc = it.Next()))
        {
            PBX_HUDServices.Push(svc);
        }

        ServicesLoaded = true;
    }

    // Function to get the Data from those Services
    private
    ui PBXHUDData GetExternalHUD(PB_WeaponBase weapon)
    {
        for (int i = 0; i < PBX_HUDServices.Size(); i++)
        {
            if(!weapon) 
                return null;

            let svc = PBX_HUDServices[i];
            if (!svc) 
                continue;

            let data = PBXHUDData(svc.GetObjectUI("PBX_HUD", objectArg: weapon));
            if (data && data.Handled){
                return data;
            }
        }
        return null;
    }

    // Get the user CVARs
    private
    ui void gatherHUDCVARs(PlayerInfo plr, PB_Hud_ZS phud)
    {
        // Weapon Pickup Sprites
        pbx_weapon_PosX         = CVar.GetCVar("pbxweapons_Weaponhud_x", plr).GetInt();
        pbx_weapon_PosY         = CVar.GetCVar("pbxweapons_Weaponhud_y", plr).GetInt();
        pbx_weapon_hudscale     = CVar.GetCVar("pbxweapons_Weaponhud_scale", plr).GetFloat();
        pbx_weapon_alpha        = CVar.GetCVar("pbxweapons_Weaponhud_alpha", plr).GetFloat();
        pbx_weapon_boxW         = CVar.GetCVar("pbxweapons_Weaponhud_boxW", plr).GetInt();
        pbx_weapon_boxH         = CVar.GetCVar("pbxweapons_Weaponhud_boxH", plr).GetInt();

        pbx_weapon_pos          = (pbx_weapon_PosX, pbx_weapon_PosY);
        pbx_weapon_truescale    = (pbx_weapon_hudscale, pbx_weapon_hudscale);
        pbx_weapon_box1         = (pbx_weapon_boxW, pbx_weapon_boxH);

        // Weapon Modes
        pbx_weaponmode_PosX     = CVar.GetCVar("pbxweapons_WeaponModehud_x", plr).GetInt();
        pbx_weaponmode_PosY     = CVar.GetCVar("pbxweapons_WeaponModehud_y", plr).GetInt();
        pbx_weaponmode_hudscale = CVar.GetCVar("pbxweapons_WeaponModehud_scale", plr).GetFloat();
        pbx_weaponmode_alpha    = CVar.GetCVar("pbxweapons_WeaponModehud_alpha", plr).GetFloat();
        pbx_weaponmode_boxW     = CVar.GetCVar("pbxweapons_WeaponModehud_boxW", plr).GetInt();
        pbx_weaponmode_boxH     = CVar.GetCVar("pbxweapons_WeaponModehud_boxH", plr).GetInt();

        pbx_weapon_pos2         = (pbx_weaponmode_PosX, pbx_weaponmode_PosY);
        pbx_weapon_truescale2   = (pbx_weaponmode_hudscale, pbx_weaponmode_hudscale);
        pbx_weapon_box2         = (pbx_weaponmode_boxW, pbx_weaponmode_boxH);

        // Armor
        pbx_armor_PosX          = CVar.GetCVar("PBXWeapons_Armorhud_x", plr).GetInt();
        pbx_armor_PosY          = CVar.GetCVar("PBXWeapons_Armorhud_y", plr).GetInt();
        pbx_armor_hudscale      = CVar.GetCVar("PBXWeapons_Armorhud_scale", plr).GetFloat();
        pbx_armor_alpha         = CVar.GetCVar("PBXWeapons_Armorhud_alpha", plr).GetFloat();
        pbx_armor_boxW          = CVar.GetCVar("PBXWeapons_Armorhud_boxW", plr).GetInt();
        pbx_armor_boxH          = CVar.GetCVar("PBXWeapons_Armorhud_boxH", plr).GetInt();

        pbx_armor_pos           = (pbx_armor_PosX, pbx_armor_PosY);
        pbx_armor_truescale     = (pbx_armor_hudscale, pbx_armor_hudscale);
        pbx_armor_box           = (pbx_armor_boxW, pbx_armor_boxH);

        // Special cases where weapons uses two modes at the same time
        pbx_weapon_pos3         = pbx_weapon_pos2 + (0,-10);
        pbx_weapon_truescale3   = pbx_weapon_truescale2;
        pbx_weapon_box3         = (pbx_weaponmode_boxW, pbx_weaponmode_boxH);

        // Flags
        flagsright              = BaseStatusBar.DI_SCREEN_RIGHT_BOTTOM | BaseStatusBar.DI_ITEM_RIGHT_BOTTOM;
        flagssTextAlignRight    = BaseStatusBar.DI_TEXT_ALIGN_RIGHT;
        flagsleft               = BaseStatusBar.DI_SCREEN_LEFT_BOTTOM | BaseStatusBar.DI_ITEM_LEFT_BOTTOM;
        flagsLeftCenter         = BaseStatusBar.DI_SCREEN_LEFT_BOTTOM | BaseStatusBar.DI_ITEM_CENTER;

        // Others
        akimboPosition          = (AKIMBO_POSITION_X,AKIMBO_POSITION_Y);
        powerupPosition         = (POWERUP_POSITION_X,POWERUP_POSITION_Y);
        
    }


//////////////////////////// WEAPONS ////////////////////////////////////////////////////////////////////////////////////
    // Automatically get weapon icons
    private
    ui void GetWeaponDataAuto(PB_WeaponBase pbWeap)
    {
        // Dont draw if SkipAutoDraw is true
        let ext = GetExternalHUD(pbWeap);
        if (ext && ext.SkipAutoDraw) return;

        // Add exceptions here
        static const string exceptionWeapons[] = {
            // Slot 2
            "PB_Pistol", "PB_SMG",
            // Slot 3
            "PB_Shotgun", "PB_Autoshotgun", "PB_QuadSG",
            // Slot 4
            "PB_DMR", "PB_LMG", "PB_ChexRifle"
            // Slot 5
            "PB_Minigun",
            // Slot 7
            "PB_M2Plasma",
            // Slot 8
            "PB_Flamethrower","PB_CryoRifle",
            // Slot 9
            "PB_BFG9000","PB_Unmaker"
        };

        // Handle exceptions
        string weaponClass = pbWeap.GetClassName();
        for (int i = 0; i < exceptionWeapons.Size(); i++)
        {
            if (weaponClass == exceptionWeapons[i]) return; // do not draw HUD for these weapons
        }

        // Use default Icons
        TextureID iconID = pbWeap.AltHudIcon.IsValid() ? pbWeap.AltHudIcon : pbWeap.Icon;
        pbx_image = TexMan.GetName(iconID);

    }

    // Get data from any PBXHUDData
    private
    ui void GetPBXData(PB_WeaponBase pbWeap)
    {
        let ext = GetExternalHUD(pbWeap);
        if (ext)
        {
            if(ext.Image1 != "") pbx_image = ext.Image1; // This way it will only draw if theres actually something there
            pbx_image2 = ext.Image2;
            pbx_image3 = ext.Image3;

            pbx_weapon_pos += ext.Offset1;
            pbx_weapon_pos2 += ext.Offset2;
            pbx_weapon_pos3 += ext.Offset3;

            pbx_weapon_truescale *= ext.Scale1;
            pbx_weapon_truescale2 *= ext.Scale2;
            pbx_weapon_truescale3 *= ext.Scale3;

        }
    }

    // Draw Function
    private
    ui void DrawEveryWeapon()
    {
        // Dont draw if its disabled
        if(CheckFlag(DisablePBX_WeaponHud)) return;

        let weap = plr.ReadyWeapon;
        if (!weap) return;
        let pbWeap = PB_WeaponBase(weap);
        if (!pbWeap) return;

        FindHUDServices();              // Find other mods that uses PBX HUD
        GetPBWeaponData(pbWeap);        // Get the Weapon Data for PB Weapons
        GetPBXData(pbweap);             // Get the Weapon Data for any PBXHUDData
        GetWeaponDataAuto(pbWeap);      // Automatically get the weapon Icons

        // Draw Function
        if(pbweap.akimboMode) 
            PBX_DrawImage(DRAW_WEAPON_ICON,true); // Draw an extra icon behind the weapon if in dual wield
        PBX_DrawImage(DRAW_WEAPON_ICON);

        // Dont draw the Weapon Mode if its disabled
        if(CheckFlag(DisablePBX_WeaponModeHud)) return;
        if(pbx_image2 != "") 
                PBX_DrawImage(DRAW_MODE_ICON);
        if(pbx_image3 != "") 
            PBX_DrawImage(DRAW_MODE2_ICON);
    }

//////////////////////////// ARMORS ////////////////////////////////////////////////////////////////////////////////////
    // Get Armor Icon and Draw Function 
    private
    ui void DrawArmors()
    {
        // Dont draw if its disabled
        if(CheckFlag(DisablePBX_ArmorHud)) return;


        // Draw the Armor Box if Enabled
        if(!CheckFlag(DisablePBX_ArmorHudBG))
            PBX_DrawImage(DRAW_ARMOR_BG);

        // Get the data for the armors
        let barmor = BasicArmor(mo.FindInventory("BasicArmor", true));
        if(!barmor) return;

        if (barmor.Amount > 0)
        {
            TextureID iconID = barmor.Icon;
            class<Inventory> armorClass = (class<Inventory>)(barmor.ArmorType);
            if (armorClass)
            {
                name armorType = armorClass.GetClassName();
                if (armorType == 'PB_GreenArmor') 
                {
                    iconID = TexMan.CheckForTexture("4RM1A0", TexMan.Type_Any);
                    pbx_armor_truescale *= 5.0;
                }
                else if (armorType == 'PB_BlueArmor')  
                {
                    iconID = TexMan.CheckForTexture("4RM2A0", TexMan.Type_Any);
                    pbx_armor_truescale *= 5.0;
                }
                else
                {
                    let def = GetDefaultByType(armorClass);
                    iconID = def.AltHUDIcon.IsValid() ? def.AltHUDIcon : def.Icon;
                }
                // Uncomment this when Vampy's Build has been merged
                // // Hardcoded scale stuff because PB's Icons doesnt have the same scale
                // // as the rest of the PBX - Armors
                // if (armorType == 'PB_GreenArmor' || armorType == 'PB_BlueArmor') 
                // {
                //     pbx_armor_truescale *= 5.0;
                // }
                // let def = GetDefaultByType(armorClass);
                // iconID = def.AltHUDIcon.IsValid() ? def.AltHUDIcon : def.Icon;
            }
            pbx_image4 = TexMan.GetName(iconID);
        }
        else
        {
            // Draw a No Armor Text if the player didnt have any
            pbx_image4 = "ARMRNO";
            pbx_armor_truescale *= 6;

        }

        // Draw
        PBX_DrawImage(DRAW_ARMOR_ICON);
    }

//////////////////////////// POWERUPS ////////////////////////////////////////////////////////////////////////////////////
    // Custom powerups in PBX
    private 
    ui bool IsPBXPowerup(name powerName)
    {
        static const name PBXPowerups[] =
        {
            // Special Powerups
            'PBX_PowerInvisTainted',
            'PBX_PowerDeflect',
            'PBX_PowerElectAura',
            'PBX_PowerInvulTainted',
            // Vanilla Powerups
            'PBX_PowerBuddha',
            'PBX_PowerDrain',
            'PBX_PowerFlight',
            'PBX_PowerFrightener',
            'PBX_PowerHighJump',
            'PBX_PowerInfiniteAmmo',
            'PBX_PowerProtection',
            'PBX_PowerReflection',
            'PBX_PowerRegeneration',
            'PBX_PowerTimeFreezer',
            'PBX_TaintedRegen'
        };

        for (int i = 0; i < PBXPowerups.Size(); i++)
            if (PBXPowerups[i] == powerName) return true;

        return false;
    }

    // Set what icon to use here
    // Make sure to update it everytime pb added new powerups
    private 
    ui string GetPowerupImage(name powerName)
    {
        switch (powerName)
        {
            // PB Powerups
            case 'PB_PowerInvul':           return "PWRINVUL";
            case 'PB_PowerIronFeet':        return "PWRRADSU";
            case 'PB_PowerInvis':           return "PWRINVIS";
            case 'PB_PowerLightAmp':        return "PWRINFRA";
            case 'PB_PowerDoomDamage':      return "PWRQUADD";
            case 'PB_PowerSpeed':           return "PWRHASTE";
            // PBX Powerups
            // Special Powerups
            case 'PBX_PowerInvisTainted':   return "PWRVISTN";
            case 'PBX_PowerDeflect':        return "PWRDEFLE";
            case 'PBX_PowerElectAura':      return "PWRELECT";
            case 'PBX_PowerInvulTainted':   return "PWRVULTN";
            // Vanilla Powerups
            case 'PBX_PowerBuddha':         return "PWRBUDHA";
            case 'PBX_PowerDrain':          return "PWRDRAIN";
            case 'PBX_PowerFlight':         return "PWRFLIGH";
            case 'PBX_PowerFrightener':     return "PWRFRGHT";
            case 'PBX_PowerHighJump':       return "PWRHIJMP";
            case 'PBX_PowerInfiniteAmmo':   return "PWRINFAM";
            case 'PBX_PowerProtection':     return "PWRPRTCK";
            case 'PBX_PowerReflection':     return "PWRRFLCT";
            case 'PBX_PowerRegeneration':   return "PWRREGEN";
            case 'PBX_PowerTimeFreezer':    return "PWRTMFRZ";
            case 'PBX_TaintedRegen':        return "PWRRGNTN";
            default:                        return "";
        }
    }

    // Draw Function
    private 
    ui void DrawPowerups()
    {
        vector2 initialpos = powerupPosition;
        string image;
		string powerTime;
		name powerName;
		int fontCol;
        int step = 22;

        // Count PB powerups first so we can start above them
        int baseCount = 0;
        for (let i = mo.inv; i != null; i = i.inv)
        {
            powerName = i.GetClassName();
            let power = Powerup(i);
            
            if (!power || IsPBXPowerup(powerName)) continue;
            if (GetPowerupImage(powerName) != "") baseCount++;
        }

        initialpos.y -= baseCount * step;

        // Draw PBX Powerups
        for (let i = mo.inv; i != null; i = i.inv)
        {
            powerName = i.GetClassName();
            let power = Powerup(i);

            if (!power || !IsPBXPowerup(powerName)) continue;

            image = GetPowerupImage(powerName);
            if (image == "") continue;

            powerTime = phud.FormatPowerupTime(power);
            fontCol = Font.FindFontColor(powerName);

            phud.PBHud_DrawImage(image, initialpos, flagsleft, phud.playerBoxAlpha);
            phud.PBHud_DrawString(phud.mBoldFont, powerTime, (initialpos.x + 28, initialpos.y - 20), flagsleft, fontCol);
            initialpos.y -= step;
        }
    }

//////////////////////////// HELPER FUNCTIONS ////////////////////////////////////////////////////////////////////////////////////
    private
    ui void PBX_DrawImage(PBXHud_DrawImageSettings whatimage, bool drawAkimbo = false)
    {
        int flags;
        string image; 
        Vector2 pos, scale, box; 
        double transparency;

        vector2 armorBGScale = pbx_armor_truescale*4;

        switch (whatimage)
        {
            default:
            case DRAW_WEAPON_ICON: 
                image           = pbx_image;  
                pos             = pbx_weapon_pos;  
                scale           = pbx_weapon_truescale;  
                transparency    = pbx_weapon_alpha;     
                box             = pbx_weapon_box1;   
                flags           = flagsright;     
                break;

            case DRAW_MODE_ICON: 
                image           = pbx_image2; 
                pos             = pbx_weapon_pos2; 
                scale           = pbx_weapon_truescale2; 
                transparency    = pbx_weaponmode_alpha; 
                box             = pbx_weapon_box2;   
                flags           = flagsright;     
                break;

            case DRAW_MODE2_ICON: 
                image           = pbx_image3; 
                pos             = pbx_weapon_pos3; 
                scale           = pbx_weapon_truescale3; 
                transparency    = pbx_weaponmode_alpha; 
                box             = pbx_weapon_box3;   
                flags           = flagsright;     
                break;

            case DRAW_ARMOR_ICON: 
                image           = pbx_image4; 
                pos             = pbx_armor_pos;   
                scale           = pbx_armor_truescale;   
                transparency    = pbx_armor_alpha;      
                box             = pbx_armor_box;     
                flags           = flagsLeftCenter;
                break;

            case DRAW_ARMOR_BG: 
                image           = "ARMRBO";   
                pos             = pbx_armor_pos;   
                scale           = armorBGScale; 
                transparency    = pbx_armor_alpha;      
                box             = pbx_armor_box;     
                flags           = flagsLeftCenter;
                break;

        }
        phud.PBHud_DrawImage(
            image, 
            drawAkimbo ? pos + akimboPosition : pos,
            flags, 
            transparency, 
            scale:scale 
            // box:box
        );
    }

    // Just a non verbose way to check flags
    // will always check PBXWeapons_hudsetting_filter
    private 
    ui bool CheckFlag(int tipFlag)
    {
        let check = CVar.FindCVar("PBXWeapons_hudsetting_filter");
        return (check.GetInt() & tipflag) == tipflag;
    }

    static clearscope bool PBX_PlayerHasInventory(name inv)
    {
        return PlayerPawn(players[consoleplayer].mo).CountInv(inv) > 0;
    }

}

