Class PBXCore_CheatsHandler : Eventhandler
{	
	override void NetworkProcess(ConsoleEvent e)
	{
		let pm = players[e.player].mo;
		if(!pm)
			return;
			
		if (e.Name ~== "PBX_AllPowerups")
		{
			pm.giveinventory("PB_PowerInvul",1);
			pm.giveinventory("PB_PowerIronFeet",1);
			pm.giveinventory("PB_PowerInvis",1);
			pm.giveinventory("PB_PowerLightAmp",1);
			pm.giveinventory("PB_PowerDoomDamage",1);
			pm.giveinventory("PB_PowerSpeed",1);

			pm.giveinventory("PBX_PowerInvisTainted",1);
			pm.giveinventory("PBX_PowerDeflect",1);
			pm.giveinventory("PBX_PowerElectAura",1);
			pm.giveinventory("PBX_PowerInvulTainted",1);

			pm.giveinventory("PBX_PowerBuddha",1);
			pm.giveinventory("PBX_PowerDrain",1);
			pm.giveinventory("PBX_PowerFlight",1);
			pm.giveinventory("PBX_PowerFrightener",1);
			pm.giveinventory("PBX_PowerHighJump",1);
			pm.giveinventory("PBX_PowerInfiniteAmmo",1);
			pm.giveinventory("PBX_PowerProtection",1);
			pm.giveinventory("PBX_PowerReflection",1);
			pm.giveinventory("PBX_PowerRegeneration",1);
			pm.giveinventory("PBX_PowerTimeFreezer",1);
			pm.giveinventory("PBX_TaintedRegen",1);

			pm.giveinventory("PBX_PowerFrostAura",1);
			pm.giveinventory("PBX_PowerFireAura",1);
		}
		
	}
}