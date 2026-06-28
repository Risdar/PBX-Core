class PBXCore_Handler : EventHandler
{
    // Parallel arrays: These three Arrays are basically paired

    // Contains the name of classes to check
    static const string CHECKED_CLASSES[] =
    {
        "PBX_PlasmaBlaster",
        "PBX_SGLEdited",
        "PBX_PinkArmor",
        "PBX_Blackblur"
    };

    // Contains the name of the CVar that should be set
    static const name LOADED_CVARS[] =
    {
        'PBXCore_WeaponsLoaded',
        'PBXCore_AddonsLoaded',
        'PBXCore_ArmorsLoaded',
        'PBXCore_ItemsLoaded'
    };

    // What will be printed
    static const string VERSION_STRINGS[] =
    {
        "$PBXWeapons_Version",
        "$PBXAddons_Version",
        "$PBXArmors_Version",
        "$PBXItems_Version"
    };

    // When the world has been loaded (basically on the titlemap)
    // Check the existing classes and if they exist and set the CVars accordingly
    override void WorldLoaded(WorldEvent e)
    {
        for (int i = 0; i < CHECKED_CLASSES.Size(); i++)
        {
            bool loaded = (class<Actor>)(CHECKED_CLASSES[i]) != null;
            CVar.FindCVar(LOADED_CVARS[i]).SetBool(loaded);
        }
    }

    // When the player entered a map
    override void PlayerEntered(PlayerEvent e)
    {
        if (level.MapName == "TITLEMAP") return;

        let plr = players[consoleplayer];
        if (!plr) return;

        // Dont print the versiongs if the option is disabled
        if (!CVar.GetCVar('PBXCore_PrintVersion', plr).GetBool()) return;
        PB_HelpNotificationsHandler.PB_SendTip("$PBXCore_Version", "PBXCore_ThrowawayFlag", 0);

        // Print the other PBX Versions
        for (int i = 0; i < LOADED_CVARS.Size(); i++)
        {
            if (CVar.FindCVar(LOADED_CVARS[i]).GetBool())
                PB_HelpNotificationsHandler.PB_SendTip(VERSION_STRINGS[i], "PBXCore_ThrowawayFlag", 0);
        }
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
class PBXCore_TipsManager : inventory
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

    static void SendTipArrayIfNeeded(Array<String> tipStrings, string cvarName, int tipFlag)
	{
		if(!PB_HelpNotificationsHandler.CheckTipEvent(tipFlag, CVar.GetCvar(cvarName)))
		{
			PB_HelpNotificationsHandler.PB_SendTipArray(tipStrings, cvarName, tipFlag);
		}
	}
}