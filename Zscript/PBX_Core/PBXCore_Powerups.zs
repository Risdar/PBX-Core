enum PBXCore_PowerupDuration
{
    // Default Duration
    // Special Powerups
    INVISTAINT_DEFAULT_DURATION     = -75,
    DEFLECT_DEFAULT_DURATION        = -60,
    ELECTAURA_DEFAULT_DURATION      = -60,
    INVULTAINT_DEFAULT_DURATION     = -30,
    // Vanilla Powerups
    BUDDHA_DEFAULT_DURATION         = -60,
    DRAIN_DEFAULT_DURATION          = -60,
    FLIGHT_DEFAULT_DURATION         = -60,
    FRIGHTENER_DEFAULT_DURATION     = -60,
    HIGHJUMP_DEFAULT_DURATION       = -60,
    INFAMMO_DEFAULT_DURATION        = -12,
    PROTECT_DEFAULT_DURATION        = -25,
    REFLECT_DEFAULT_DURATION        = -60,
    REGEN_DEFAULT_DURATION          = -60,
    TIMEFREEZE_DEFAULT_DURATION     = -12,
    TAINTREGEN_DEFAULT_DURATION     = -30,
    // New Powerups
    FROSTAURA_DEFAULT_DURATION     	= -60,
    FIREAURA_DEFAULT_DURATION     	= -60
}

// ============================================================
// PBX Powerups - Special Powerups from Unless You Got Powah
// ============================================================
// --- BlackBur ---
class PBX_InvisTaintedGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerInvisTainted"; } }
Class PBX_PowerInvisTainted : PB_PowerInvis
{
	mixin PBX_PowerupTimer;
	Default
	{
		+SHADOW;
		+REFLECTIVE;
		Powerup.Duration INVISTAINT_DEFAULT_DURATION;
		Powerup.Strength 100;
		Powerup.Mode "Translucent";
	}
	
	override void InitEffect()
	{
		super.InitEffect();
		if(!Owner) return;
		owner.bCANTSEEK = TRUE;	
		owner.A_AttachLightDef("InvisTaintedLight","InvisTaintedLight");
	}

	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("DarkSlateBlue");
	}
	
	override void EndEffect()
	{
		super.EndEffect();
		if(!Owner) return;
		owner.bCANTSEEK = FALSE;
		EndBlend("DarkSlateBlue");
		owner.A_RemoveLight("InvisTaintedLight");
	}
}

// --- PowerDeflect ---
class PBX_DeflectGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerDeflect"; } }
class PBX_PowerDeflect : Powerup 
{
	mixin PBX_PowerupTimer;
	bool zeroTurn;	// "random" deflection direction when projectile aims directly at player
	
	Default
	{
		Powerup.Duration DEFLECT_DEFAULT_DURATION;
		Powerup.Color "LightGreen", 0.2;
	}
	
	override void InitEffect ()
	{
		Super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("DeflectLight","DeflectLight");
		zeroTurn = random(0,1);
	}

	override void DoEffect ()
	{
		Super.DoEffect();
		PowerupTimer("LightGreen");
		Actor ob;
		ThinkerIterator iter = ThinkerIterator.Create();

		while (ob = Actor(iter.Next()))
		{
			bool shouldTrack = (!ob 
				|| !ob.bMissile 
				|| ob.bSeekermissile 
				|| ob.target == Owner 
				|| !(ob is "PB_Monster_Projectile")
			);

			if (shouldTrack) continue;
			
			// console.printf("projectile tracked");
			double v = ob.vel.Length();	// speed of projectile
			double ang = VectorAngle(ob.vel.x, ob.vel.y);	// direction of projectile
			double dist = ob.Distance3D(Owner);	// distance from player

			if (dist > 35*v) continue;	// too far away, no need to deflect
			
			zeroTurn = !zeroTurn;
			
			vector2 vecToPlayer = ob.Vec2To(Owner);	
			double angleToPlayer = VectorAngle(vecToPlayer.x, vecToPlayer.y); // direction from projectile to player
			double angleDelta = deltaangle(ang, angleToPlayer);	// how much the projectile is off
			
			if (abs(angleDelta) > 60) continue;	// not going to player (too much off)
			
			double newDiff;		// new direction difference
			if (angleDelta < 0) newDiff = 3.0;
			else if (angleDelta > 0 || zeroTurn) newDiff = -3.0;
			else newDiff = 3.0;
			
			ang += newDiff;
			double flatVel = sqrt(ob.vel.x*ob.vel.x + ob.vel.y*ob.vel.y);
			ob.vel.x = flatVel * cos(ang);
			ob.vel.y = flatVel * sin(ang);
			ob.angle += newDiff;
			
		}
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("LightGreen");
		owner.A_RemoveLight("DeflectLight");
	}
}

// --- ElectricAura ---
class PBX_ElectricAuraGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerElectAura"; } }
class PBX_PowerElectAura : Powerup
{
	mixin PBX_PowerupTimer;
	actor AL;
	double arad;

	Default
	{
		Powerup.Duration ELECTAURA_DEFAULT_DURATION;
		Powerup.Color "RoyalBlue1", 0.075;
	}

	override void InitEffect()
	{
		super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("ElectAuraLight","ElectAuraLight");
//==============================================================================
		arad = 384;	//Aura Radius
//==============================================================================
		owner.A_Startsound("ElectricAura/aura",22243,CHANF_LOOPING|ATTN_NONE);
		owner.A_AttachLight(
			"ELAL1",
			DynamicLight.PulseLight,
			"FFFFFF",
			arad*0.1,
			arad*0.2,
			flags:DYNAMICLIGHT.LF_NOSHADOWMAP,
			ofs:(0,0,owner.height),
			param:2.5
		);
		owner.A_AttachLight(
			"ELAL2",
			DynamicLight.PointLight,
			"A0A0FF",
			arad,
			arad,
			flags:DYNAMICLIGHT.LF_NOSHADOWMAP,
			ofs:(0,0,owner.height)
		);

		for (int i = 0; i < 360; i += 15)
		{
			AL = spawn("PBX_ElectricAuraWarp",owner.pos);
			if (AL)
			{
				AL.target = owner;
				AL.scale.x = (arad / 360) *0.375;
				AL.scale.y = AL.scale.x/1.5;
				AL.A_SetSize(-1,owner.height/3);
				AL.reactiontime = arad;
				AL.warp(owner, arad, 0, AL.height, i, WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE);
				AL.A_AttachLight(
					"ELAL3",
					DynamicLight.FlickerLight,
					"FFFFFF",
					arad*0.1,
					arad*0.2,
					flags:DYNAMICLIGHT.LF_NOSHADOWMAP,
					ofs:(0,0,0),
					param:2.5
				);
			}
		}
	}

	override void Tick()
	{	
		super.Tick();
		if(!Owner) return;
//-------------------------------- shock monsters -------------------------------
		if(GetAge() % 5 != 0) return;
		array<actor> monsters;
		actor mon;
		let it = BlockThingsIterator.Create(owner, arad);
		while (it.Next())
		{
			actor mon = it.thing;
			mon.A_RemoveLight("ELATL");
			if (mon && mon is "PB_Monster" && mon.bISMONSTER && !mon.bKILLED && monsters.Find(mon) == monsters.Size() && owner.Distance3D(mon) <= arad  && owner.CheckSight(mon))
			{
				monsters.push(mon);
			}
		}

		if (monsters.Size()> 0)
		{
			int index = random(0,monsters.Size()-1);
			actor mon = monsters[index];
			if (mon && !mon.bKILLED && owner.Distance3D(mon) <= arad && owner.CheckSight(mon))
			{
				actor Electricdmg = spawn("PBX_ElectricAuraBeam",owner.pos+(0,0,owner.height/2));
				if (Electricdmg)
				{
					Electricdmg.angle = owner.AngleTo(mon);
					Electricdmg.pitch = owner.PitchTo(mon,owner.height/2,mon.height/2);
					double dist = owner.distance3D(mon);
					Electricdmg.scale.y = dist/355;
					Electricdmg.scale.x = 0.5;
					Electricdmg.DoMissileDamage(mon);
					if (mon.tics > 0) mon.tics += 4; //stun monster
//---------------------------------- Aura FX -----------------------------------
					int ht = mon.height/2;
					SparkParticle("FFFFFF", mon.pos, ht);
					SparkParticle("FFFFFF", mon.pos, ht);
					SparkParticle("FFFFFF", mon.pos, ht);
					SparkParticle("FFFFFF", mon.pos, ht);
					SparkParticle("FFFF00", mon.pos, ht);
					SparkParticle("FFFF00", mon.pos, ht);
					SparkParticle("FFFF00", mon.pos, ht);
					SparkParticle("FFFF00", mon.pos, ht);
					SparkParticle("C080FF", mon.pos, ht);
					SparkParticle("C080FF", mon.pos, ht);
					SparkParticle("C080FF", mon.pos, ht);
					SparkParticle("C080FF", mon.pos, ht);
					mon.A_AttachLight("ELATL",DynamicLight.PointLight,"E0E0FF",mon.radius,mon.radius,
						flags:DYNAMICLIGHT.LF_NOSHADOWMAP|DYNAMICLIGHT.LF_ATTENUATE,
						ofs:(0,0,mon.height/2));
					mon.A_Startsound("ElectricAura/electric");
				}
			}
		}
		AuraParticle();
	}

	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("RoyalBlue1");
	}

	override void EndEffect()
	{
		super.EndEffect();
		if(!Owner) return;
		EndBlend("RoyalBlue1");
		owner.A_RemoveLight("ElectAuraLight");
		owner.A_RemoveLight("ELAL1");
		owner.A_RemoveLight("ELAL2");
		owner.A_Stopsound(22243);
	}

	void SparkParticle(color col, vector3 mpos, double mz)
	{
		A_SpawnParticle(col,
		flags: SPF_FULLBRIGHT,
		lifetime:15,
		size:random(3,5),
		xoff:mpos.x+random(-5,5),
		yoff:mpos.y+random(-5,5),
		zoff:mz,
		velx:random(-5,5),
		vely:random(-5,5),
		velz:random(-5,5),
		startalphaf:1.0,fadestepf:-1);
	}

	void AuraParticle()
	{
		int rnd = random(1,4);
		TextureID ptx;
		if (rnd == 1) ptx = TexMan.CheckForTexture ("VSPRA0");
		else if (rnd == 2) ptx = TexMan.CheckForTexture ("VSPRB0");
		else if (rnd == 3) ptx = TexMan.CheckForTexture ("VSPRC0");
		else if (rnd == 4) ptx = TexMan.CheckForTexture ("VSPRD0");
		owner.A_SpawnParticleEx("FFFFFF",ptx,
		style: STYLE_Add,
		flags: SPF_FULLBRIGHT,
		lifetime:4,
		size:random(5,30),
		xoff:random(-arad,arad),
		yoff:random(-arad,arad),
		zoff:0,
		startalphaf:0.8,fadestepf:0);
	}
}

class PBX_ElectricAuraWarp : Actor
{
	int dist;
	Default
	{
		+WALLSPRITE;
		+NOBLOCKMAP;
		+NOINTERACTION;
		RenderStyle "Add";
		Alpha 0.8;
	}
	States
	{
	Spawn:
		TNT1 A 0 Nodelay
		{
			dist = reactiontime;
		}
		TNT1 A 0 A_Jump (256, 1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33);
	Warp:
		VLGB AABBCCDDEEFFGGHHIIJJHHGGFFEEDDCCBB 2 bright 
		{
			angle += 2;
			if (!random(0,1)) bXFLIP = !bXFLIP;
			if (target) warp(target, dist, 0, height, angle, WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE);
			if (!target || !target.FindInventory("PBX_PowerElectAura")) destroy();
		}
		Loop;
	}
}

class PBX_ElectricAuraBeam : Actor
{
	Default
	{
		+FLATSPRITE;
		+NOBLOCKMAP;
		+NOGRAVITY;
		+BLOODLESSIMPACT;
		+FORCEPAIN;
//==============================================================================
		DamageFunction 15; //Aura Damage
//==============================================================================
		DamageType "Stun";
		RenderStyle "Add";
		Alpha 0.8;
	}
	States
	{
	Spawn:
		TNT1 A 0 Nodelay
		{
			if (!random(0,1)) bXFLIP = !bXFLIP;
			if (!random(0,1)) bYFLIP = !bYFLIP;
		}
		TNT1 A 0 A_Jump (256, 1,2,3,4,5,6,7,8,9,10);
		VLGA A 5 bright;
		Stop;
		VLGA B 5 bright;
		Stop;
		VLGA C 5 bright;
		Stop;
		VLGA D 5 bright;
		Stop;
		VLGA E 5 bright;
		Stop;
		VLGA F 5 bright;
		Stop;
		VLGA G 5 bright;
		Stop;
		VLGA H 5 bright;
		Stop;
		VLGA I 5 bright;
		Stop;
		VLGA J 5 bright;
		Stop;
	}
}

// --- GoldInv ---
class PBX_InvulTaintedGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerInvulTainted"; } }
Class PBX_PowerInvulTainted : PowerInvulnerable
{
	mixin PBX_PowerupTimer;
	Default
	{	
		Powerup.Duration INVULTAINT_DEFAULT_DURATION;
	}
	
	override void InitEffect()
	{
		super.InitEffect();
		if(!Owner) return;
		owner.bREFLECTIVE = TRUE;
		owner.bAIMREFLECT = TRUE;
		owner.bNOBLOOD = true;
		owner.A_AttachLightDef("InvulTaintedLight","InvulTaintedLight");
	}

	override void DoEffect()
	{
		Super.DoEffect();
		if(CVar.GetCVar("pb_powerup_shaders",Owner.Player).GetBool())
		{
			Shader.SetEnabled(Owner.Player,"Invulnerability",true);
			PPShader.SetUniform1f("Invulnerability","intensity",1.0);
		}
		else
		{
			Shader.SetEnabled(Owner.Player,"Invulnerability",false);
		}
		PowerupTimer("PaleGoldenrod");
	}
	
	override void EndEffect()
	{
		super.EndEffect();
		if(!Owner) return;
		owner.bREFLECTIVE = FALSE;
		owner.bAIMREFLECT = FALSE;
		owner.bNOBLOOD = false;
		Shader.SetEnabled(Owner.Player,"Invulnerability",false);
		EndBlend("PaleGoldenrod");	
		owner.A_RemoveLight("InvulTaintedLight");
	}
}


// ============================================================
// PBX Powerups - Based on Vanilla Doom's Powerups
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
		owner.bNOBLOOD = true;
	}

	override void DoEffect()
	{
		Super.DoEffect();
		if(CVar.GetCVar("pb_powerup_shaders",Owner.Player).GetBool())
		{
			Shader.SetEnabled(Owner.Player,"Invulnerability",true);
			PPShader.SetUniform1f("Invulnerability","intensity",1.0);
		}
		else
		{
			Shader.SetEnabled(Owner.Player,"Invulnerability",false);
		}
		PowerupTimer("DarkOrange");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		Shader.SetEnabled(Owner.Player,"Invulnerability",false);
		EndBlend("DarkOrange");
		owner.A_RemoveLight("BuddhaLight");
		owner.bNOBLOOD = false;
	}
}

// --- PowerDoubleFiringSpeed --- (This is bugged)
// class PBX_DoubleFiringSpeedGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerDoubleFiringSpeed"; } }
// class PBX_PowerDoubleFiringSpeed : PowerDoubleFiringSpeed
// {
// 	mixin PBX_PowerupTimer;
// 	Default { Powerup.Duration BUDDHA_DEFAULT_DURATION; }

// 	override void InitEffect()
// 	{
// 		Super.InitEffect();
// 		if(!Owner) return;
// 		owner.A_AttachLightDef("DoubleFiringSpeedLight","DoubleFiringSpeedLight");
// 	}

// 	override void DoEffect()
// 	{
// 		Super.DoEffect();
// 		PowerupTimer("peru");
// 	}

// 	override void EndEffect()
// 	{
// 		Super.EndEffect();
// 		if(!Owner) return;
// 		EndBlend("peru");
// 		owner.A_RemoveLight("DoubleFiringSpeedLight");
// 	}
// }

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

// --- TaintedRegen ---
class PBX_TaintedRegenGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_TaintedRegen"; } }
class PBX_TaintedRegen : Powerup
{
	mixin PBX_PowerupTimer;
	Default { Powerup.Duration TAINTREGEN_DEFAULT_DURATION; /*Powerup.Color "Cyan";*/}

	override void InitEffect()
	{
		Super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("RegenTnLight","RegenTnLight");
	}
	
	override void DoEffect()
	{
		Super.DoEffect();
		if(owner && owner.health < 200 && GetAge() % 3 == 0)
			owner.GiveBody(1,200);
		PowerupTimer("MediumPurple");
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if(!Owner) return;
		EndBlend("MediumPurple");
		owner.A_RemoveLight("RegenTnLight");
	}
}

// --- FrostAura ---
class PBX_FrostAuraGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerFrostAura"; } }
class PBX_PowerFrostAura : Powerup
{
	mixin PBX_PowerupTimer;
	int arad;

	Default
	{
		Powerup.Duration FROSTAURA_DEFAULT_DURATION;
		Powerup.Color "LightCyan", 0.075;
	}

	override void InitEffect()
	{
		super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("FrostAuraLight","FrostAuraLight");
//==============================================================================
		arad = 448;	//Aura Radius
//==============================================================================
		owner.A_StartSound("FrostAura/aura", 3, CHANF_LOOPING | ATTN_NONE);
		owner.A_AttachLight(
			"FRAL1", 
			DynamicLight.PulseLight, 
			"C0C0FF", 
			arad * 1.0, 
			arad * 1.1,
			flags: DYNAMICLIGHT.LF_NOSHADOWMAP | DYNAMICLIGHT.LF_ATTENUATE,
			ofs: (0, 0, owner.height), 
			param: 1.0
		);
		owner.A_AttachLight(
			"FRAL2", 
			DynamicLight.PulseLight, 
			"4040FF", 
			arad * 0.15, 
			arad * 0.3,
			flags: DYNAMICLIGHT.LF_NOSHADOWMAP | DYNAMICLIGHT.LF_ATTENUATE,
			ofs: (0, 0, owner.height), 
			param: 2.5
		);
	}

	override void Tick()
	{
		super.Tick();

		if (!owner) return;
		if (GetAge() % 10 != 0) return;
		
		let it = BlockThingsIterator.Create(owner, arad + 128);
		while (it.Next())
		{
			actor mon = it.thing;
			if (mon && mon.bIsMonster && mon is "PB_Monster") 
				mon.speed = mon.default.speed;
			if (mon && mon.bIsMonster 
				&& mon is "PB_Monster" 
				&& owner.Distance3D(mon) <= arad 
				&& owner.CheckSight(mon)
			)
			{
				if (!mon.bKilled)
				{
					if (mon.tics > 0)
					{
						double shp = mon.spawnhealth();
						double hpcur = mon.health;
						if (hpcur < 1)
							hpcur = 1;
						int hpfactor = int(shp / hpcur * 3);
						hpfactor = clamp(hpfactor, 2, 5);
						mon.tics  += hpfactor;
						mon.speed -= hpfactor;
					}
					actor frostdmg = Spawn("FrostAuraFreeze", mon.pos);
					if (frostdmg)
					{
						int stxW = 0, stxH = 0;
						TextureID stx;
						if (mon.CurState != null)
						{
							stx = mon.CurState.GetSpriteTexture(0);
							if (stx.IsValid()) [stxW, stxH] = TexMan.GetSize(stx);
						}
						frostdmg.target = owner;
						if (stxW > 0 && stxH > 0)
						{
							frostdmg.A_SetSize(stxW / 3 * mon.scale.x, stxH / 1.2 * mon.scale.y);
						}
						frostdmg.DoMissileDamage(mon);
					}
				}
				if (mon.bKilled && !mon.bICECORPSE && !mon.bNOICEDEATH && GetAge() % 20 == 0)
					mon.SetStateLabel("GenericFreezeDeath");
				if (mon.bICECORPSE)
				{
					actor frozen = Spawn("FrostAuraFrozen", mon.pos);
					if (frozen) frozen.A_SetSize(mon.radius, mon.height);
				}
			}
		}

		static const String smokeColors[] = {"FFFFFF", "F0F0EF", "E0E0DF", "D0D0CF", "C0C0BF"};
		for (int i = 0; i < smokeColors.Size(); i++)
		{
			owner.A_SpawnParticle(smokeColors[i], lifetime: 280, size: random(1, 3),
				xoff: random(-arad, arad), yoff: random(-arad, arad), zoff: 128,
				velx: frandom(-0.3, 0.3), vely: frandom(-0.3, 0.3), velz: frandom(-4.0, -2.0),
				startalphaf: 0.5
			);
		}
	}

	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("LightCyan");
	}

	override void EndEffect()
	{
		super.EndEffect();
		if(!Owner) return;
		EndBlend("LightCyan");
		owner.A_RemoveLight("FrostAuraLight");
		owner.A_RemoveLight("FRAL1");
		owner.A_RemoveLight("FRAL2");
		owner.A_StopSound(3);
		let it = BlockThingsIterator.Create(owner, arad);
		while (it.Next())
		{
			actor mon = it.thing;
			if (mon && mon.bIsMonster && mon is "PB_Monster") 
				mon.speed = mon.default.speed;
		}
	}
}

class FrostAuraFreeze : Actor
{
	Default
	{
		+NOBLOCKMAP;
		+NOGRAVITY;
		+PAINLESS;
		+BLOODLESSIMPACT;
		DamageFunction 5;
		DamageType "Ice";
	}

	States
	{
		Spawn:
			TNT1 A 0;
			TNT1 AAAAAAAAAA 1
			{
				A_SpawnParticle("BFBFFF",
					lifetime: 70,
					size: random(3, 6),
					xoff: random(int(-radius), int(radius)),
					yoff: random(int(-radius), int(radius)),
					zoff: random(int(height / 4), int(height)),
					velx: frandom(-1.0, 1.0),
					vely: frandom(-1.0, 1.0),
					velz: frandom(-1.0, 1.0),
					startalphaf: 0.3, fadestepf: -1, sizestep: 0.4
				);
			}
			Stop;
	}
}

class FrostAuraFrozen : Actor
{
	Default
	{
		+NOBLOCKMAP;
		+NOINTERACTION;
	}

	States
	{
		Spawn:
			TNT1 A 0;
			TNT1 AAAAAAAAAAA 1{
				A_SpawnParticle("BFBFFF",
					lifetime: 70,
					size: random(6, 12),
					xoff: random(int(-radius), int(radius)),
					yoff: random(int(-radius), int(radius)),
					zoff: random(int(height / 4), int(height)),
					velx: frandom(-1.1, 1.1),
					vely: frandom(-1.1, 1.1),
					velz: frandom(-1.1, 1.1),
					startalphaf: 0.3, fadestepf: -1, sizestep: 0.5
				);
			}
			Stop;
	}
}

// --- FireAura ---
class PBX_FireAuraGiver : PB_PowerupGiver { Default { Powerup.Type "PBX_PowerFireAura"; } }
class PBX_PowerFireAura : Powerup
{
	mixin PBX_PowerupTimer;
	int arad;

	Default
	{
		Powerup.Duration FIREAURA_DEFAULT_DURATION;
		Powerup.Color "firebrick4", 0.075;
	}

	override void InitEffect()
	{
		super.InitEffect();
		if(!Owner) return;
		owner.A_AttachLightDef("FireAuraLight","FireAuraLight");
//==============================================================================
		arad = 160; //Aura Radius
//==============================================================================
		owner.A_StartSound("FireAura/aura", 2, CHANF_LOOPING | ATTN_NONE);
		owner.A_AttachLight(
			"FIAL1", 
			DynamicLight.FlickerLight, 
			"FF8000", 
			arad * 1.0, 
			arad * 1.05,
			flags: DYNAMICLIGHT.LF_NOSHADOWMAP,
			ofs: (0, 0, owner.height / 2), 
			param: 0.5
		);
		owner.A_AttachLight(
			"FIAL2", 
			DynamicLight.PulseLight, 
			"FFE000", 
			arad * 1.0, 
			arad * 1.05,
			flags: DYNAMICLIGHT.LF_NOSHADOWMAP | DYNAMICLIGHT.LF_ATTENUATE,
			ofs: (0, 0, owner.height / 2), 
			param: 0.5
		);
		owner.A_AttachLight(
			"FIAL3", 
			DynamicLight.PulseLight, 
			"FFFFFF", 
			arad * 0.1, 
			arad * 0.4,
			flags: DYNAMICLIGHT.LF_NOSHADOWMAP | DYNAMICLIGHT.LF_ATTENUATE,
			ofs: (0, 0, owner.height / 2), 
			param: 2.5
		);
	}

	override void Tick()
	{
		super.Tick();

		if (!owner) return;
		if (GetAge() % 5 != 0) return;

		array<actor> monsters;
		let it = BlockThingsIterator.Create(owner, arad);
		while (it.Next())
		{
			actor mon = it.thing;
			if (mon) 
				mon.A_RemoveLight("FIATL");
			if (mon && mon.bIsMonster && mon is "PB_Monster" 
				&& !mon.bKilled && monsters.Find(mon) == monsters.Size()
				&& owner.Distance3D(mon) <= arad 
				&& owner.CheckSight(mon)
			)
			{
				monsters.Push(mon);
			}
		}

		if (monsters.Size() > 0)
		{
			int index = random(0, monsters.Size() - 1);
			actor mon = monsters[index];
			if (mon && !mon.bKilled && owner.Distance3D(mon) <= arad && owner.CheckSight(mon))
			{
				int ht = int(mon.height / 2);
				for (int i = 0; i < 4; i++) SparkParticle("FFFFFF", mon.pos, ht);
				for (int i = 0; i < 4; i++) SparkParticle("FFE060", mon.pos, ht);
				for (int i = 0; i < 4; i++) SparkParticle("FF8040", mon.pos, ht);

				mon.A_AttachLight(
					"FIATL", 
					DynamicLight.PointLight, 
					"FFB060", 
					mon.radius, 
					mon.radius,
					flags: DYNAMICLIGHT.LF_NOSHADOWMAP | DYNAMICLIGHT.LF_ATTENUATE,
					ofs: (0, 0, mon.height / 2)
				);

				mon.A_StartSound("FireAura/fire");

				if (mon.tics > 0) mon.tics += 4;

				if (mon.health > 6)
				{
					actor firedmg = Spawn("PBX_FireAuraFire", mon.pos);
					if (firedmg)
					{
						firedmg.target = owner;
						firedmg.scale.x = 0.8 + (mon.radius * 0.005 * mon.scale.x);
						firedmg.scale.y = 0.4 + (mon.height * 0.0075 * mon.scale.y);
						firedmg.DoMissileDamage(mon);
					}
				}
				if (mon.health <= 6)
				{
					int stxW = 0, stxH = 0;
					TextureID stx;
					if (mon.CurState != null)
					{
						stx = mon.CurState.GetSpriteTexture(0);
						if (stx.IsValid()) [stxW, stxH] = TexMan.GetSize(stx);
					}
					let monScale = mon.scale;
					let monSprite = mon.sprite;
					let monFrame = mon.frame;

					mon.A_Die();
					if (mon.bBossDeath || mon.bBoss) mon.A_BossDeath();
					actor burned;
					if (!mon.bNOICEDEATH) burned = Spawn("PBX_FireAuraVictim", mon.pos);
					if (burned)
					{
						burned.scale = monScale;
						burned.sprite = monSprite;
						burned.frame = monFrame;
						if (stxW > 0 && stxH > 0)
						{
							burned.A_SetSize(stxW / 3 * monScale.x, stxH / 1.2 * monScale.y);
						}
						double ptch = 1 - (stxW * 0.002 * monScale.x);
						burned.A_StartSound("FireAura/firedeath", pitch: ptch);
						mon.destroy();
					}
				}
			}
			AuraParticle();
		}
	}

	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("firebrick4");
	}

	override void EndEffect()
	{
		super.EndEffect();
		if (!owner) return;
		EndBlend("firebrick4");
		owner.A_RemoveLight("FireAuraLight");
		owner.A_RemoveLight("FIAL1");
		owner.A_RemoveLight("FIAL2");
		owner.A_RemoveLight("FIAL3");
		owner.A_StopSound(2);
	}

	void SparkParticle(color col, vector3 mpos, double mz)
	{
		A_SpawnParticle(col,
			flags: SPF_FULLBRIGHT,
			lifetime: 15,
			size: random(3, 5),
			xoff: mpos.x + random(-5, 5),
			yoff: mpos.y + random(-5, 5),
			zoff: mz,
			velx: random(-5, 5),
			vely: random(-5, 5),
			velz: random(-5, 5),
			startalphaf: 1.0, fadestepf: -1
		);
	}

	void AuraParticle()
	{
		int rnd = random(1, 4);
		TextureID ptx;
		if (rnd == 1)      ptx = TexMan.CheckForTexture("VFIRD0");
		else if (rnd == 2) ptx = TexMan.CheckForTexture("VFIRE0");
		else if (rnd == 3) ptx = TexMan.CheckForTexture("VFIRF0");
		else               ptx = TexMan.CheckForTexture("VFIRG0");

		owner.A_SpawnParticleEx("FFA060", ptx,
			style: STYLE_Add,
			flags: SPF_FULLBRIGHT,
			lifetime: 4,
			size: random(5, 30),
			xoff: random(-arad, arad),
			yoff: random(-arad, arad),
			zoff: 0,
			startalphaf: 0.8, fadestepf: 0
		);
	}
}

class PBX_FireAuraFire : Actor
{
	Default
	{
		+NOBLOCKMAP;
		+NOGRAVITY;
		+BLOODLESSIMPACT;
		DamageFunction random(2, 12);
		DamageType "Fire";
		RenderStyle "Add";
		Alpha 0.8;
		Translation "0:255=%[0,0,0]:[2.0,0.8,0.4]";
	}

	States
	{
		Spawn:
			TNT1 A 0 NoDelay {
				if (!random(0, 1)) 
					bXFLIP = !bXFLIP;
				A_StartSound("FireAura/fire");
			}
			VFIR ABCDEFGH 3 bright;
			Stop;
	}
}

class PBX_FireAuraVictim : Actor
{
	actor fadecopy;

	Default
	{
		+NOBLOCKMAP;
		+NOINTERACTION;
		Renderstyle "Stencil";
		Alpha 0.0;
	}

	States
	{
		Spawn:
			#### # 0 NoDelay {
				fadecopy = Spawn("PBX_FireAuraVictimFade", pos);
				if (fadecopy)
				{
					fadecopy.scale  = scale;
					fadecopy.sprite = sprite;
					fadecopy.frame  = frame;
				}
			}
		Fadein:
			#### # 1 {
				A_Smoke();
				A_FadeIn(0.075);
				if (alpha >= 1.0)
				{
					if (fadecopy) fadecopy.destroy();
					destroy();
				}
			}
			Loop;
	}

	void A_Smoke()
	{
		int ht = random(int(height / 2), int(height));
		int loops = int(radius / 10);
		for (int i = 0; i < loops; i += 1)
		{
			A_SpawnParticle("Black",
				lifetime: 280,
				size: random(2, 4),
				xoff: random(int(-radius), int(radius)),
				yoff: random(int(-radius), int(radius)),
				zoff: ht,
				velx: frandom(-1.0, 1.0),
				vely: frandom(-1.0, 1.0),
				velz: frandom(3.0, 5.0),
				startalphaf: 0.4,
				fadestepf: -1,
				sizestep: 1.0
			);
			actor ashes = Spawn("PBX_FireAuraAshes", pos + (random(int(-radius), int(radius)), random(int(-radius), int(radius)), ht));
		}
	}
}

class PBX_FireAuraVictimFade : Actor
{
	Default
	{
		+NOBLOCKMAP;
		+NOINTERACTION;
		Renderstyle("Translucent");
		Alpha 1.0;
	}

	States
	{
		Spawn:
			#### # 1 {
				A_FadeOut(0.075);
			}
			Loop;
	}
}

class PBX_FireAuraAshes : Actor
{
	Default
	{
		+NOBLOCKMAP;
		RenderStyle "Translucent";
		Alpha 0.4;
	}

	States
	{
		Spawn:
			TNT1 A 0 NoDelay {
				if (!random(0, 1)) 
					bXFLIP = !bXFLIP;
				if (!random(0, 1)) 
					bYFLIP = !bYFLIP;
				vel.x = frandom(-1.0, 1.0);
				vel.y = frandom(-1.0, 1.0);
				vel.z = frandom(0.0, 0.5);
			}
			VASH A 5;
		See:
			VASH B 5 {
				if (pos.z == floorz) 
					SetStateLabel("Death");
			}
			Loop;
		Death:
			VASH CDE 5;
		Fadeout:
			VASH F 1 {
				if (!random(0, 4)) 
					A_FadeOut(0.001);
			}
			Loop;
	}
}
