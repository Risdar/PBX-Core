class PBXCore_Handler : StaticEventHandler
{
    bool hasPrintedVersion;

    // Parallel arrays: These three Arrays are basically paired
    // Contains the name of classes to check
    static const string CHECKED_CLASSES[] =
    {
        "PBX_PlasmaBlaster",
        "PBX_SGLEdited",
        "PBX_PinkArmor",
        "PBX_Blackblur",
        "PB_Baron1GK"
    };
    // Contains the name of the CVar that should be set
    static const name LOADED_CVARS[] =
    {
        'PBXCore_WeaponsLoaded',
        'PBXCore_AddonsLoaded',
        'PBXCore_ArmorsLoaded',
        'PBXCore_ItemsLoaded',
        'PBXCore_GlorykillLoaded'
    };
    // What will be printed
    static const string VERSION_STRINGS[] =
    {
        "$PBXWeapons_Version",
        "$PBXAddons_Version",
        "$PBXArmors_Version",
        "$PBXItems_Version",
        "$PBXCore_Glorykill"
    };

    // So it only prints the version once per session
    override void OnRegister()
    {
        hasPrintedVersion = false;
    }

    // When the world has been loaded (basically on the titlemap)
    // Check the existing classes and if they exist and set the CVars accordingly
    override void WorldLoaded(WorldEvent e)
    {
        if(hasPrintedVersion || e.IsSaveGame || e.IsReopen) return;
        for (int i = 0; i < CHECKED_CLASSES.Size(); i++)
        {
            bool loaded = (class<Actor>)(CHECKED_CLASSES[i]) != null;
            CVar.FindCVar(LOADED_CVARS[i]).SetBool(loaded);
        }
    }

    // When the player entered a map
    override void PlayerEntered(PlayerEvent e)
    {
        if(hasPrintedVersion) return;
        if (level.MapName == "TITLEMAP") return;

        let plr = players[consoleplayer];
        if (!plr) return;

        // Dont print the versiongs if the option is disabled
        if (!CVar.GetCVar('PBXCore_PrintVersion', plr).GetBool()) return;

        // Print the Core version
        PB_HelpNotificationsHandler.PB_SendTip("$PBXCore_Version", "PBXCore_ThrowawayFlag", 0);

        // Print the other PBX Modules
        for (int i = 0; i < LOADED_CVARS.Size(); i++)
        {
            if (CVar.FindCVar(LOADED_CVARS[i]).GetBool())
                PB_HelpNotificationsHandler.PB_SendTip(VERSION_STRINGS[i], "PBXCore_ThrowawayFlag", 0);
        }

        hasPrintedVersion = true;
    }

    // Used to give the player an inventory when they dont have them yet
    static play void TryGiveInventory(PlayerPawn pm, name hasInventory = "", name whatToGive = "", int giveAmount = 1, bool diffCheck = true)
    {
        if (!pm) return;

        // Only give once — skip if the player already has it
        if (pm.CountInv(diffCheck ? hasInventory : whatToGive) < 1)
            pm.GiveInventory(whatToGive, giveAmount);
    }
}

// Inventory item given to the player that handles every Tooltips
class PBXCore_TipsManager : inventory abstract
{
    Default
	{
		// These are just some useful values for an inventory token
		// that make sure it can't be taken away or dropped:
		inventory.maxamount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.PERSISTENTPOWER
	}

    static clearscope void SendTipArrayIfNeeded(Array<String> tipStrings, string cvarName, int tipFlag)
	{
        CVAR shouldSend = CVar.GetCVar("PBXCore_SendTip");
        if(!shouldSend) return;
        bool send = shouldSend.GetBool();
        if(!send) return;

        CVar name = CVar.GetCvar(cvarName);
        if(!name) return;

		if(!PB_HelpNotificationsHandler.CheckTipEvent(tipFlag, name))
		{
			PB_HelpNotificationsHandler.PB_SendTipArray(tipStrings, cvarName, tipFlag);
		}
	}
}

class PBXCore_ArmorBase : PB_Armor abstract
{
    name armortoken;
    property ArmorToken : armortoken;

    Default
    {
        PBXCore_ArmorBase.ArmorToken '';
        Inventory.PickupSound "ARMOR"; 
        Scale 0.2; 
    }

    override bool TryPickup(in out Actor toucher)
    {
        bool pickup = Super.TryPickup(toucher);
        if (pickup && armortoken != '')
            toucher.GiveInventory(armortoken, 1);

        return pickup;
    }

    override string PickupMessage()
    {
        return String.Format(StringTable.Localize("$PBXCore_ArmorPickup"), StringTable.Localize(pickupMsg),int(self.SavePercent),int(self.SaveAmount));
    }

}

class PBXCore_UpgradeBase : inventory abstract
{
    name upgradetoken, upgradetype, s;
    property UpgradeToken : upgradetoken;
	property Sprite : upgradetype;
	mixin PBX_BetterPickupSound;

	Default
	{
        PBXCore_UpgradeBase.upgradetoken '';
        PBXCore_UpgradeBase.Sprite '';
		+inventory.alwayspickup;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		PBX_SetUpgradeSprite();
	}

    override bool TryPickup(in out Actor toucher)
    {
        bool pickup = Super.TryPickup(toucher);
        if (pickup && upgradetoken != '')
            toucher.GiveInventory(upgradetoken, 1);

        return pickup;
    }

	virtual void PBX_SetUpgradeSprite()
	{
		switch(upgradetype)
		{
            default: s = "TNT1"; break;
		}

        if(upgradetype != "TNT1")
		    sprite = GetSpriteIndex(s);
	}

	States
	{
		Spawn:
			TNT1 A -1 bright light("WeaponUpgradeSpawner");
			stop;

		LoadSprites:
			TNT1 A 0;
	}
}
