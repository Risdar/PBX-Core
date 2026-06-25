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
		if(!Owner) return;
		owner.bCANTSEEK = FALSE;
		EndBlend("DarkSlateBlue");
		owner.A_RemoveLight("InvisTaintedLight");
		super.EndEffect();
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
			if (!ob || !ob.bMissile || ob.bSeekermissile || ob.target == Owner) continue;
			
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
		owner.A_AttachLight("ELAL1",DynamicLight.PulseLight,"FFFFFF",arad*0.1,arad*0.2,
			flags:DYNAMICLIGHT.LF_NOSHADOWMAP,
			ofs:(0,0,owner.height),param:2.5);
			owner.A_AttachLight("ELAL2",DynamicLight.PointLight,"A0A0FF",arad,arad,
			flags:DYNAMICLIGHT.LF_NOSHADOWMAP,
			ofs:(0,0,owner.height));

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
				AL.A_AttachLight("ELAL3",DynamicLight.FlickerLight,"FFFFFF",arad*0.1,arad*0.2,
					flags:DYNAMICLIGHT.LF_NOSHADOWMAP,
					ofs:(0,0,0),param:2.5);
			}
		}
	}

	override void Tick()
	{	
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

		super.Tick();
	}

	override void DoEffect()
	{
		Super.DoEffect();
		PowerupTimer("RoyalBlue1");
	}

	override void EndEffect()
	{
		if(!Owner) return;
		EndBlend("RoyalBlue1");
		owner.A_RemoveLight("ElectAuraLight");
		owner.A_RemoveLight("ELAL1");
		owner.A_RemoveLight("ELAL2");
		owner.A_Stopsound(22243);
		super.EndEffect();
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
		if(!Owner) return;
		owner.bREFLECTIVE = FALSE;
		owner.bAIMREFLECT = FALSE;
		owner.bNOBLOOD = false;
		Shader.SetEnabled(Owner.Player,"Invulnerability",false);
		EndBlend("PaleGoldenrod");	
		owner.A_RemoveLight("InvulTaintedLight");
		super.EndEffect();
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