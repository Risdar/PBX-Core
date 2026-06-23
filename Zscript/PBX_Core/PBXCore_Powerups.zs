// ============================================================
// PBX Powerups - Auto-generated from PBX_PowerGeneric template
// One pair per ZDoom built-in Powerup subclass
// ============================================================

// --- PowerBuddha ---
class PBX_BuddhaGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerBuddha"; } }
class PBX_PowerBuddha : PowerBuddha
{
	mixin PBX_PowerupTimer;
	Default { Powerup.Duration BUDDHA_DEFAULT_DURATION; }

	override void InitEffect()
	{
		Super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("BuddhaLight","BuddhaLight");
	}

	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("DarkOrange");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("DarkOrange");
		owner.A_RemoveLight("BuddhaLight");
	}
}

// --- PowerDoubleFiringSpeed --- (This is bugged)
class PBX_DoubleFiringSpeedGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerDoubleFiringSpeed"; } }
class PBX_PowerDoubleFiringSpeed : PowerDoubleFiringSpeed
{
	mixin PBX_PowerupTimer;
	Default { Powerup.Duration BUDDHA_DEFAULT_DURATION; }

	override void InitEffect()
	{
		Super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("DoubleFiringSpeedLight","DoubleFiringSpeedLight");
	}

	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("DoubleFiringSpeed");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("DoubleFiringSpeed");
		owner.A_RemoveLight("DoubleFiringSpeedLight");
	}
}

// --- PowerDrain ---
class PBX_DrainGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerDrain"; } }
class PBX_PowerDrain : PowerDrain
{
	mixin PBX_PowerupTimer;
	Default { Powerup.Duration DRAIN_DEFAULT_DURATION;}

	override void InitEffect()
	{
		Super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("DrainLight","DrainLight");
	}

	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("firebrick");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("firebrick");
		owner.A_RemoveLight("DrainLight");
	}
}

// --- PowerFlight ---
class PBX_FlightGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerFlight"; } }
class PBX_PowerFlight : PowerFlight
{
	mixin PBX_PowerupTimer;
	Default { Powerup.Duration FLIGHT_DEFAULT_DURATION; }

	override void InitEffect()
	{
		Super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("FlightLight","FlightLight");
	}

	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("SteelBlue1");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("SteelBlue1");
		owner.A_RemoveLight("FlightLight");
	}
}

// --- PowerFrightener ---
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

// --- PowerHighJump ---
class PBX_HighJumpGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerHighJump"; } }
class PBX_PowerHighJump : PowerHighJump
{
	mixin PBX_PowerupTimer;
	Default { Powerup.Duration HIGHJUMP_DEFAULT_DURATION;}

	override void InitEffect()
	{
		Super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("HighJumpLight","HighJumpLight");
	}

	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("DeepSkyBlue1");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("DeepSkyBlue1");
		owner.A_RemoveLight("HighJumpLight");
	}
}

// --- PowerInfiniteAmmo ---
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
		PowerupTimer("yellow");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("yellow");
		owner.A_RemoveLight("InfAmmoLight");
	}
}

// --- PowerProtection --- (Just Because)
class PBX_ProtectionGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerProtection"; } }
class PBX_PowerProtection : PowerProtection
{
	mixin PBX_PowerupTimer;
	Default { Powerup.Duration PROTECT_DEFAULT_DURATION; }

	override void InitEffect()
	{
		Super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("ProtectLight","ProtectLight");
	}

	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("PaleTurquoise1");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("PaleTurquoise1");
		owner.A_RemoveLight("ProtectLight");
	}
}

// --- PowerReflection ---
class PBX_ReflectionGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerReflection"; } }
class PBX_PowerReflection : PowerReflection
{
	mixin PBX_PowerupTimer;
	Default { Powerup.Duration REFLECT_DEFAULT_DURATION;}

	override void InitEffect()
	{
		Super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("ReflectLight","ReflectLight");
	}

	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("DarkOrchid1");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("DarkOrchid1");
		owner.A_RemoveLight("ReflectLight");
	}
}

// --- PowerRegeneration ---
class PBX_RegenerationGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerRegeneration"; } }
class PBX_PowerRegeneration : PowerRegeneration
{
	mixin PBX_PowerupTimer;
	Default { Powerup.Duration REGEN_DEFAULT_DURATION;}

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

// --- PowerTimeFreezer ---
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