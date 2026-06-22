class PBX_RegenerationGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerRegeneration"; } }
class PBX_PowerRegeneration : PowerRegeneration
{
	mixin PBX_PowerupTimer;
	Default { Powerup.Duration REGEN_DEFAULT_DURATION; }

	override void InitEffect()
	{
		Super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("RegenLight","RegenLight");
	}
	
	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("Cyan");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("Cyan");
		owner.A_RemoveLight("RegenLight");
	}
}

class PBX_FrightenerGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerFrightener"; } }
class PBX_PowerFrightener : PowerFrightener
{
	mixin PBX_PowerupTimer;
	Default { Powerup.Duration FRIGHTENER_DEFAULT_DURATION; }

	override void InitEffect()
	{
		Super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("FrightenerLight","FrightenerLight");
	}
	
	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("DarkRed");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("DarkRed");
		owner.A_RemoveLight("FrightenerLight");
	}
}

class PBX_TimeFreezeGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerTimeFreezer"; } }
class PBX_PowerTimeFreezer : PowerTimeFreezer
{
	mixin PBX_PowerupTimer;
	Default { Powerup.Duration TIMEFREEZE_DEFAULT_DURATION; }

	override void InitEffect()
	{
		Super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("TimeFreezeLight","TimeFreezeLight");
	}
	
	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("Orange");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("Orange");
		owner.A_RemoveLight("TimeFreezeLight");
	}
}

class PBX_InfiniteAmmoGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerInfiniteAmmo"; } }
class PBX_PowerInfiniteAmmo : PowerInfiniteAmmo
{
	mixin PBX_PowerupTimer;
	Default { Powerup.Duration INFAMMO_DEFAULT_DURATION; }

	override void InitEffect()
	{
		Super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("InfAmmoLight","InfAmmoLight");
	}
	
	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("Yellow");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("Yellow");
		owner.A_RemoveLight("InfAmmoLight");
	}
}