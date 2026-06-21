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
    ui bool isAkimbo;
    ui vector2 akimboPosition;

    enum PBXHud_DrawImageSettings{
        DRAW_WEAPON_ICON    = 1,
        DRAW_MODE_ICON      = 2,
        DRAW_MODE2_ICON     = 3
    }

    // How many steps the whole icon should move
    const AKIMBO_POSITION_WHOLE = -15;

    const AKIMBO_POSITION_X = -10;
    const AKIMBO_POSITION_Y = -10;
    
//////////////////////////// MAIN FUNCTION ////////////////////////////////////////////////////////////////////////////////////
    override void RenderOverlay(RenderEvent e)
    {
        // Dont draw if the HUD is disabled
        if(PBXWeapons_hudsetting_filter & DisablePBX_ArmorHud) 
            return;

        // Get a pointer to the player
        let plr = players[consoleplayer];
        if (!plr) return;

        // Dont draw if the player is not in a leve or if the automap is active
        if (gamestate != GS_LEVEL || automapactive)
            return;

        // Get a pointer to the PB Hud so we can access it
        let phud = PB_Hud_ZS(StatusBar);
        if (!phud) return;

        // Dont draw if the player is dead
        if (phud.hudState == BaseStatusBar.HUD_None || phud.PlayerWasDead) 
            return;

        // If the menu is active or the console is up
        if (menuactive || consolestate == c_up)
            gatherArmorHUDCVARs(plr); // Gather the CVARs

        // Begin drawing the HUD
        phud.BeginHUD();                   // Initialize
        DrawArmorHUD(plr,phud);
        // Actually Draw the Thing

    }

    override void RenderUnderlay(RenderEvent e)
    {
        // Dont draw if the HUD is disabled
        if(PBXWeapons_hudsetting_filter & DisablePBX_WeaponHud) 
            return;

        // Get a pointer to the player
        let plr = players[consoleplayer];
        if (!plr) return;

        // Dont draw if the player is not in a leve or if the automap is active
        if (gamestate != GS_LEVEL || automapactive)
            return;

        // Get a pointer to the PB Hud so we can access it
        let phud = PB_Hud_ZS(StatusBar);
        if (!phud) return;

        // Dont draw if the player is dead
        if (phud.hudState == BaseStatusBar.HUD_None || phud.PlayerWasDead) 
            return;

        // Get a pointer to the weapon
        let weap = plr.ReadyWeapon;
        if (!weap) return;
        let pbWeap = PB_WeaponBase(weap);
        if (!pbWeap) return;

        // If the menu is active or the console is up
        if (menuactive || consolestate == c_up)
            gatherWeaponHUDCVARs(plr,phud); // Gather the CVARs

        // Begin drawing the HUD
        phud.BeginHUD();                   // Initialize
        FindHUDServices();                 // Find other mods that uses PBX HUD
        DrawPBWeapon(phud,pbWeap);         // Get the Weapon Data for PB Weapons
        DrawPBXHUD(phud,pbweap);           // Get the Weapon Data for everything else
        DrawPBXWeaponAuto(phud,pbWeap);    // Automatically get the weapon Icons

         // Actually Draw the Thing
        if(pbweap.akimboMode) 
            PBX_DrawImage(phud,DRAW_WEAPON_ICON,true); // Draw an extra icon behind the weapon if in dual wield

        PBX_DrawImage(phud, DRAW_WEAPON_ICON);

        // Dont draw the rest if the weapon mode hud is disabled
        if((PBXWeapons_hudsetting_filter & DisablePBX_WeaponModeHud)) 
            return;

        // phud.PBHud_DrawImage("EQUPBO", (-250, -17), flagsright, phud.playerBoxAlpha);

        if(pbx_image2 != "") 
            PBX_DrawImage(phud, DRAW_MODE_ICON);

        if(pbx_image3 != "") 
            PBX_DrawImage(phud,DRAW_MODE2_ICON);

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
            if (!svc) continue;

            let data = PBXHUDData(svc.GetObjectUI("PBX_HUD", objectArg: weapon));
            if (data && data.Handled){
                return data;
            }
        }
        return null;
    }

    // Get the user CVARs
    protected
    ui void gatherWeaponHUDCVARs(PlayerInfo plr, PB_Hud_ZS phud)
    {
        // Weapon Pickup Sprites
        pbx_weapon_PosX = CVar.GetCVar("pbxweapons_Weaponhud_x", plr).GetInt();
        pbx_weapon_PosY = CVar.GetCVar("pbxweapons_Weaponhud_y", plr).GetInt();
        pbx_weapon_hudscale = CVar.GetCVar("pbxweapons_Weaponhud_scale", plr).GetFloat();
        pbx_weapon_alpha = CVar.GetCVar("pbxweapons_Weaponhud_alpha", plr).GetFloat();
        pbx_weapon_boxW = CVar.GetCVar("pbxweapons_Weaponhud_boxW", plr).GetInt();
        pbx_weapon_boxH = CVar.GetCVar("pbxweapons_Weaponhud_boxH", plr).GetInt();

        pbx_weapon_pos = (pbx_weapon_PosX, pbx_weapon_PosY);
        pbx_weapon_truescale = (pbx_weapon_hudscale, pbx_weapon_hudscale);
        pbx_weapon_box1 = (pbx_weapon_boxW, pbx_weapon_boxH);

        // Weapon Modes
        pbx_weaponmode_PosX = CVar.GetCVar("pbxweapons_WeaponModehud_x", plr).GetInt();
        pbx_weaponmode_PosY = CVar.GetCVar("pbxweapons_WeaponModehud_y", plr).GetInt();
        pbx_weaponmode_hudscale = CVar.GetCVar("pbxweapons_WeaponModehud_scale", plr).GetFloat();
        pbx_weaponmode_alpha = CVar.GetCVar("pbxweapons_WeaponModehud_alpha", plr).GetFloat();
        pbx_weaponmode_boxW = CVar.GetCVar("pbxweapons_WeaponModehud_boxW", plr).GetInt();
        pbx_weaponmode_boxH = CVar.GetCVar("pbxweapons_WeaponModehud_boxH", plr).GetInt();

        pbx_weapon_pos2 = (pbx_weaponmode_PosX, pbx_weaponmode_PosY);
        pbx_weapon_truescale2 = (pbx_weaponmode_hudscale, pbx_weaponmode_hudscale);
        pbx_weapon_box2 = (pbx_weaponmode_boxW, pbx_weaponmode_boxH);

        // Special cases where weapons uses two modes at the same time
        pbx_weapon_pos3 = pbx_weapon_pos2 + (0,-10);
        pbx_weapon_truescale3 = pbx_weapon_truescale2;
        pbx_weapon_box3 = (pbx_weaponmode_boxW, pbx_weaponmode_boxH);

        // Flags
        flagsright = BaseStatusBar.DI_SCREEN_RIGHT_BOTTOM | BaseStatusBar.DI_ITEM_RIGHT_BOTTOM;
        flagssTextAlignRight = BaseStatusBar.DI_TEXT_ALIGN_RIGHT;

        // Others
        akimboPosition = (AKIMBO_POSITION_X,AKIMBO_POSITION_Y);

    }
    
    protected
    ui void gatherArmorHUDCVARs(PlayerInfo plr)
    {
        // Armor
        pbx_armor_PosX = CVar.GetCVar("PBXWeapons_Armorhud_x", plr).GetInt();
        pbx_armor_PosY = CVar.GetCVar("PBXWeapons_Armorhud_y", plr).GetInt();
        pbx_armor_hudscale = CVar.GetCVar("PBXWeapons_Armorhud_scale", plr).GetFloat();
        pbx_armor_alpha = CVar.GetCVar("PBXWeapons_Armorhud_alpha", plr).GetFloat();
        pbx_armor_boxW = CVar.GetCVar("PBXWeapons_Armorhud_boxW", plr).GetInt();
        pbx_armor_boxH = CVar.GetCVar("PBXWeapons_Armorhud_boxH", plr).GetInt();

        pbx_armor_pos = (pbx_armor_PosX, pbx_armor_PosY);
        pbx_armor_truescale = (pbx_armor_hudscale, pbx_armor_hudscale);
        pbx_armor_box = (pbx_armor_boxW, pbx_armor_boxH);

        // Flags
        flagsleft = BaseStatusBar.DI_SCREEN_LEFT_BOTTOM | BaseStatusBar.DI_ITEM_LEFT_BOTTOM;
        flagsLeftCenter = BaseStatusBar.DI_SCREEN_LEFT_BOTTOM | BaseStatusBar.DI_ITEM_CENTER;

    }

//////////////////////////// AUTOMATIC DRAW ////////////////////////////////////////////////////////////////////////////////////
    protected
    ui void DrawPBXWeaponAuto(PB_Hud_ZS phud, PB_WeaponBase pbWeap)
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
            "PB_Flamethrower",
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

    protected
    ui void DrawPBXHUD(PB_Hud_ZS phud, PB_WeaponBase pbWeap)
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

    protected
    ui void DrawArmorHUD(PlayerInfo plr, PB_Hud_ZS phud)
    {
        // Draw the BG if its enabled
        if(!(PBXWeapons_hudsetting_filter & DisablePBX_ArmorHudBG)) 
            phud.PBHud_DrawImage(
                "ARMRBO", 
                pbx_armor_pos, // This is so the BG always follow the icon
                flagsLeftCenter,
                pbx_armor_alpha,
                scale:pbx_armor_truescale*4
            );

        // Big thanks to vortex for this code, I've modified it a bit to fit what I need
        let barmor = BasicArmor(plr.mo.FindInventory("BasicArmor", true));
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

        // Actually Draw the thing
        phud.PBHud_DrawImage(
            pbx_image4, 
            pbx_armor_pos, 
            flagsLeftCenter,
            pbx_armor_alpha,
            scale:pbx_armor_truescale
        );
    }

//////////////////////////// HELPER FUNCTIONS ////////////////////////////////////////////////////////////////////////////////////
    protected
    ui void PBX_DrawImage(PB_Hud_ZS phud, PBXHud_DrawImageSettings whatimage, bool drawAkimbo = false)
    {
        string image; 
        Vector2 pos, scale, box; 
        double transparency;

        switch (whatimage)
        {
            default:
            case DRAW_WEAPON_ICON : image = pbx_image;  pos = pbx_weapon_pos;  scale = pbx_weapon_truescale;  transparency = pbx_weapon_alpha;     box = pbx_weapon_box1; break;
            case DRAW_MODE_ICON   : image = pbx_image2; pos = pbx_weapon_pos2; scale = pbx_weapon_truescale2; transparency = pbx_weaponmode_alpha; box = pbx_weapon_box2; break;
            case DRAW_MODE2_ICON  : image = pbx_image3; pos = pbx_weapon_pos3; scale = pbx_weapon_truescale3; transparency = pbx_weaponmode_alpha; box = pbx_weapon_box3; break;
        }
        phud.PBHud_DrawImage(
            image, 
            drawAkimbo ? pos + akimboPosition : pos,
            flagsright, 
            transparency, 
            scale:scale 
            // box:box
        );
    }

    static clearscope bool PBX_PlayerHasInventory(name inv)
    {
        return PlayerPawn(players[consoleplayer].mo).CountInv(inv) > 0;
    }

}

