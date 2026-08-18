// ZSLightningGun by jekyllgrim 
// MIT License

// Copyright (c) 2024 Agent_Ash aka jekyllgrim

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

class PBXCore_ArcSplitController : Inventory
{
	PBXCore_ArcSplitController ac_parentController; // used by controllers created by other controllers
	array <PBXCore_ArcSplitController> ac_childControllers; // used by the first controller only
	array <Actor> lightningVictims; // used by each controller to track which victims it should be able to damage
	bool 	ac_done;			// set by the controller itself when it's time to disappear
	int		ac_stage;			// tracks which arc it is in the chain
	int		ac_maxSplits;		// maximum number of secondary arcs that one arc can split into at once
	int		ac_maxLinks;		// maximum number of links each arc can create in total ("depth")
	int		ac_duration;		// duration of the effect
	int		ac_duration_init;	// initial duration of the effect
	int		ac_delay;			// delay between the controller is given and the effect starts
	int		ac_delay_init;		// initial delay
	int		ac_damagePerArc;	// damage per a single arc
	Actor	ac_damageSource;	// tracks the source actor responsible for the attack
	double	ac_maxDistance;		// max distance an arc can cover (same for all arcs)

	Default
	{
		Inventory.MaxAmount 1;
		+Inventory.UNDROPPABLE
		+Inventory.UNTOSSABLE
	}

	PBXCore_ArcSplitController GetParentController()
	{
		PBXCore_ArcSplitController asc = self;
		while (asc && asc.ac_parentController)
		{
			asc = asc.ac_parentController;
		}
		return asc;
	}

	// Dedicated function accurately calculate the exact point
	// from which player's attack come out. Used by LineTrace()
	// in weapons.
	static double GetAttackHeight(PlayerPawn source)
	{
		if (!source || !source.player)
			return 0;
		
		let player = source.player;
		return source.height*0.5 - source.floorclip + player.mo.AttackZOffset*player.crouchFactor;
	}

	// Allows specifying a relative offset (forward/leftright/updown) and converts it
	// to proper world coordinates:
	// startpos		: initial position
	// viewangles	: angle, pitch, roll
	// offset		: forward/backward, right/left, up/down
	// isPosition	: if false, adds startPos to result (only useful for velocity); if true, doesn't
	static Vector3 RelativeToGlobalCoords(Vector3 startpos, Vector3 viewAngles, Vector3 offset, bool isPosition = true)
	{
		Quat dir = Quat.FromAngles(viewAngles.x, viewAngles.y, viewAngles.z);
		vector3 ofs = dir * (offset.x, -offset.y, offset.z);
		if (isPosition)
		{
			return Level.vec3offset(startpos, ofs);
		}
		return ofs;
	}

	static Vector3 GetViewAngles(Actor mo)
	{
		return (mo.angle, mo.pitch, mo.roll);
	}

	// Gets the position to which the beam is attached to.
	// By default it's just the center of the source.
	// If source is a player, horOfs and vertOfs are used
	// to define horizontal and vertical offset, like in A_SpawnProjectile
	static Vector3 GetBeamAttachPos(Actor source, double horOfs = 0, double vertOfs = 0)
	{
		if (!source)
			return (0,0,0);
		Vector3 spos;
		if (source.player)
		{
			spos = RelativeToGlobalCoords((source.pos.xy, source.player.viewz), GetViewAngles(source), (source.radius, horOfs, vertOfs), true);
		}
		else
		{
			spos = source.pos + (0,0,source.height * 0.5);
		}
		return spos;
	}

	// Starts a lightning chain. Arguments:
	// damageSource	: the actor responsible for the damage (will be passed to further arcs)
	// victim		: the first victim of the lightning
	// damage		: the damage to deal per one iteration
	// range		: the range of the lightning (will be passed to further arcs)
	// duration		: how long a single arc persists
	// delay		: delay between further arcs are created from the victim
	// maxSplits	: maximum number of arcs that can be fired from a single victim
	// maxlinks		: how many total victims can be hit by a single lightning chain
	// parent		: this is used only by ExtendChain(), to create a new lightning parented to the same controller
	static PBXCore_ArcSplitController StartChain(Actor damageSource, Actor victim, int damage, double range, int duration = 1, int delay = 0, int maxSplits = 1, int maxLinks = 0, PBXCore_ArcSplitController parent = null)
	{
		if (!damageSource || !victim)
			return null;

		PBXCore_ArcSplitController c = PBXCore_ArcSplitController(victim.FindInventory('PBXCore_ArcSplitController'));
		if (!c)
		{
			c = PBXCore_ArcSplitController(victim.GiveInventoryType('PBXCore_ArcSplitController'));
		}
		if (c)
		{
			c.ac_parentController = parent;
			c.ac_stage 			  = parent? parent.ac_stage + 1 : 1;
			c.ac_damageSource	  = damageSource;
			c.owner				  = victim;
			c.ac_maxDistance	  = range;
			c.ac_duration		  = duration;
			c.ac_duration_init	  = c.ac_duration;
			c.ac_damagePerArc	  = damage;
			c.ac_delay			  = delay;
			c.ac_delay_init		  = c.ac_delay;
			c.ac_maxSplits		  = Clamp(maxSplits, 1, 300);
			c.ac_maxLinks		  = Clamp(maxLinks, 1, 300);

			let ac = c.GetParentController();
			ac.ac_childControllers.Push(c);

			//Console.Printf("PBXCore_ArcSplitController created (\cd%d\c-). First victim: \cd%s\c- | ac_duration: \cd%d\c- | ac_delay: \cd%d\c-", Level.maptime, c.owner? c.owner.GetClassName() : 'none', c.ac_duration_init, c.ac_delay_init);
		}
		return c;
	}

	// Extends the lightning chain from the owner of this item
	// to the other actor:
	void ExtendChainTo(Actor nextVictim)
	{
		if (!nextVictim || !ac_damageSource)
			return;

		StartChain(ac_damagesource, nextVictim, ac_damagePerArc, ac_maxDistance, ac_duration_init, ac_delay_init, ac_maxSplits, ac_maxLinks, self);
	}

	// Gets a bunch of randomly offset points from one position to a nother,
	// then calls DrawLightningSegment() between each of those points to create
	// a jagged particle-based lightning.
	// Arguments are the same as in DrawLightningSegment(), just passed to it.
	static void DrawLightning(Vector3 from, Vector3 to, bool spawnSpark = true, PlayerInfo playersource = null)
	{
		let diff = Level.Vec3Diff(from, to);
		let dir = diff.Unit();
		let dist = diff.Length();
		double nodeDist = Clamp(dist / 10, min(8, dist), min(80, dist));
		int steps = nodeDist < dist? floor(dist / nodeDist) : 1;
		double ofss = nodeDist / 4.0;

		array <double> litPosX;
		array <double> litPosY;
		array <double> litPosZ;
		Vector3 partPos = from;
		Vector3 node;
		for (int i = 1; i <= steps; i++)
		{
			partPos += dir*nodeDist;
			node = partPos;
			if (i < steps)
			{
				node += (frandom[lightningpart](-ofss, ofss), 
						frandom[lightningpart](-ofss, ofss), 
						frandom[lightningpart](-ofss, ofss));
			}
			litPosX.Push(node.x);
			litPosY.Push(node.y);
			litPosZ.Push(node.z);
		}

		steps = min(litPosX.Size(), litPosY.Size(), litPosZ.Size());
		for (int i = 0; i < steps; i++)
		{
			node.x = litPosX[i];
			node.y = litPosY[i];
			node.z = litPosZ[i];
			PBXCore_ArcSplitController.DrawLightningSegment(from, node, density: 1, size: 4, posOfs: 0, spawnSpark: (spawnSpark && i == steps - 1), playersource: playersource);
			from = node;
		}
	}
	
	// Dedicated function to draw a particle beam between two points.
	// YOU CAN COMPLETELY REPLACE THIS to change the visuals of your lightning.
	// This function is just an example of how a lightning can look (mostly because
	// I just wanted to make a decently-looking lightning using only particles).
	// from			: starting position
	// to			: end position
	// density		: per how many units to draw a particle
	// size			: particle size
	// posOfs		: if non-zero, each particle will be randomly offset within this range
	// spawnSpark	: spawn a spark at the 'from' position, if true
	// playerSource	: pass a PlayerInfo pointer here if this is being fired by the player.
	// (If playerSouce is non-null, PlayerPawn's velocity will be added to particles for
	// interpolatin purposes.)
	static void DrawLightningSegment(Vector3 from, Vector3 to, double density = 8, double size = 10, double posOfs = 2, bool spawnSpark = true, PlayerInfo playerSource = null)
	{
		let diff = Level.Vec3Diff(from, to); // difference between two points
		let dir = diff.Unit(); // direction from point 1 to point 2
		int steps = floor(diff.Length() / density); // how many steps to take:

		// Generic particle properties:
		posOfs = abs(posOfs);
		FSpawnParticleParams pp;
		pp.color1 = 0xFFCCCCFF;
		pp.flags = SPF_FULLBRIGHT|SPF_REPLACE;
		pp.lifetime = 1;
		pp.size = size; // size
		pp.style = STYLE_Add; //additive renderstyle
		pp.startalpha = 1;
		if (playerSource && playerSource.mo)
		{
			pp.vel = playerSource.mo.vel;
		}
		Vector3 partPos = from; //initial position
		for (int i = 0; i <= steps; i++)
		{
			pp.pos = partPos;
			if (posOfs > 0)
			{
				pp.pos + (frandom[lightningpart](-posOfs,posOfs), frandom[lightningpart](-posOfs,posOfs), frandom[lightningpart](-posOfs,posOfs));
			}
			// spawn the particle:
			Level.SpawnParticle(pp);
			// Move position from point 1 topwards point 2:
			partPos += dir*density;
		}

		if (!spawnSpark)
		{
			return;
		}

		// If spawnspark is true, spawn some sparks at the end position:
		pp.size = size * 0.3;
		pp.lifetime = 30;
		pp.sizestep = -(pp.size / pp.lifetime);
		pp.pos = to;
		pp.accel.z = -0.5;
		for (int i = 5; i > 0; i--)
		{
			pp.vel.x = frandom[lightningpart](-3, 3);
			pp.vel.y = frandom[lightningpart](-3, 3);
			pp.vel.z = frandom[lightningpart](2, 6);
			pp.accel.xy = -(pp.vel.xy / pp.lifetime);
			Level.SpawnParticle(pp);
		}
	}

	static void DrawLightningSegment2(Vector3 from, Vector3 to, double density = 8, double size = 10, double posOfs = 2, bool spawnSpark = true, PlayerInfo playerSource = null)
	{
		let diff = Level.Vec3Diff(from, to); // difference between two points
		let dir = diff.Unit(); // direction from point 1 to point 2
		int steps = floor(diff.Length() / density); // how many steps to take:

		// Generic particle properties:
		posOfs = abs(posOfs);
		FSpawnParticleParams pp;
		pp.color1 = "FFFFFF";
		pp.flags = SPF_ROLL|SPF_FULLBRIGHT;
		pp.lifetime = random(5,8);
		pp.size = size; // size
		pp.style = STYLE_Add; //additive renderstyle
		pp.startalpha = 1;
		if (playerSource && playerSource.mo)
		{
			pp.vel = playerSource.mo.vel;
		}
		Vector3 partPos = from; //initial position
		for (int i = 0; i <= steps; i++)
		{
			pp.pos = partPos;
			if (posOfs > 0)
			{
				pp.pos + (frandom[lightningpart](-posOfs,posOfs), frandom[lightningpart](-posOfs,posOfs), frandom[lightningpart](-posOfs,posOfs));
			}
			int fm = random(6,9);
			pp.Texture = TexMan.CheckForTexture("DLI"..fm.."G0R0");
			// actor p = Spawn("LightningGunPuff",partPos);
			// if(p) p.target = playerSource.mo;
			// spawn("BlueFlare",partPos);

			// spawn the particle:
			Level.SpawnParticle(pp);
			// Move position from point 1 topwards point 2:
			partPos += dir*density;
		}

		if (!spawnSpark)
		{
			return;
		}

		// If spawnspark is true, spawn some sparks at the end position:
		pp.size = size * 0.3;
		pp.lifetime = 30;
		pp.sizestep = -(pp.size / pp.lifetime);
		pp.pos = to;
		pp.accel.z = -0.5;
		for (int i = 5; i > 0; i--)
		{
			pp.vel.x = frandom[lightningpart](-3, 3);
			pp.vel.y = frandom[lightningpart](-3, 3);
			pp.vel.z = frandom[lightningpart](2, 6);
			pp.accel.xy = -(pp.vel.xy / pp.lifetime);
			Level.SpawnParticle(pp);
		}
	}

	// Adds an actor to the specified array so they're ordered by their distance 
	// from the 'from' actor:
	static void AddByDistance(Actor toAdd, Actor from, out array<Actor> arr)
	{
		if (arr.Size() <= 0)
		{
			arr.Push(toAdd);
			return;
		}

		double dist = from.Distance3D(toAdd)**2;
		for (int i = 0; i < arr.Size(); i++)
		{
			let v = arr[i];
			if (!v) 
				continue;
			
			if (dist <= from.Distance3DSquared(v))
			{
				arr.Insert(i, toAdd);
				break;
			}
		}
	}

	// Generic check used by lightning to determine if the specified actor
	// is a valid victim for the lightning:
	static bool IsValidVictim(Actor who, Actor source)
	{
		return who && who.bSHOOTABLE && (who.bISMONSTER || who.player) && who.health > 0 && !who.isFriend(source);
	}

	// Called by this controller continuously to find more valid victims:
	void FindVictimsAround()
	{
		let bti = BlockThingsIterator.Create(owner, ac_maxDistance);
		Actor thing;
		double distanceSq = ac_maxDistance**2;
		while (bti.Next())
		{
			thing = bti.thing;
			if (!thing)
				continue;
			// skip conditions:
			if (thing == owner || //is the owner
				thing == ac_damageSource || //is the shooter
				!(thing.bISMONSTER || thing.player) || //not a monster or a player
				thing.health <= 0 || //dead
				thing.FindInventory(self.GetClass()) || // already being hit by lightning
				thing.IsFriend(ac_damageSource) || //not hostile to owner
				owner.Distance3DSquared(thing) > distanceSq || //too far
				!owner.CheckSight(thing) )// owner has no LoS to thing
			{
				continue;
			}
			AddByDistance(thing, owner, lightningVictims);
		}
		// Limit the size of array to maxsplits:
		if (lightningVictims.Size() > ac_maxSplits)
		{
			lightningVictims.Delete(ac_maxSplits, lightningVictims.Size());
			lightningVictims.ShrinkToFit();
		}
	}

	// Updates the array of victims to remove the ones that
	// no longer fit the criteria, then find new ones:
	void UpdateVictims()
	{
		if (lightningVictims.Size() > 0)
		{
			Actor thing;
			double distanceSq = ac_maxDistance**2;
			for (int i = lightningVictims.Size() - 1; i >= 0; i--)
			{
				if (!lightningVictims[i])
				{
					lightningVictims.Delete(i);
					continue;
				}
				thing = lightningVictims[i];
				if (!thing || // null pointer
					owner.Distance3DSquared(thing) > distanceSq || // too far
					!owner.CheckSight(thing) ) // out of LoS
				{
					lightningVictims.Delete(i);
				}
			}
			lightningVictims.ShrinkToFit();
		}
		FindVictimsAround();
	}

	override void Tick()
	{
		if (!owner || !ac_damageSource)
		{
			Destroy();
			return;
		}
		if (owner.IsFrozen())
		{
			return;
		}
		// The first controller gets a signal from child controllers
		// that it's time to disappear:
		if (ac_done && !ac_parentController)
		{
			bool alldone = true;
			for (int i = ac_childControllers.Size() - 1; i >= 0; i--)
			{
				let asc = ac_childControllers[i];
				if (!asc)
				{
					ac_childControllers.Delete(i);
					continue;
				}
				if (!asc.ac_done)
				{
					alldone = false;
					break;
				}
			}
			if (alldone)
			{
				for (int i = ac_childControllers.Size() - 1; i >= 0; i--)
				{
					let asc = ac_childControllers[i];
					if (asc)
					{
						asc.Destroy();
					}
				}
				Destroy();
				return;
			}
		}

		if (!ac_done)
		{
			owner.DamageMobj(self, ac_damageSource, ac_damagePerArc, 'Lightning', DMG_THRUSTLESS);
		}

		if (ac_delay > 0)
		{
			ac_delay--;
		}
		
		else if (ac_duration > 0)
		{
			if (ac_maxLinks <= 0 || ac_stage <= ac_maxLinks)
			{
				UpdateVictims();
				Actor v;
				for (int i = 0; i < lightningVictims.Size(); i++)
				{
					v = lightningVictims[i];
					if (v)
					{
						ExtendChainTo(v);
						DrawLightning(GetBeamAttachPos(owner), GetBeamAttachPos(v));
					}
				}
			}
			ac_duration--;
		}
		// Only the final controller is allowed to trigger
		// destruction of all controllers:
		else
		{
			ac_done = true;
		}
	}
}

// BEAMZ by Lewis3k
class PBXCore_PulseLaser : PBXCore_LaserBeam
 {
	Default
	{
		PBXCore_LaserBeam.LaserColor "Red";
	}
	
	override void BeamTick()
	{
		alpha = sin(GetAge() * 60) + 0.5;
		aimAtCrosshair();
	}
 }
 
 
 class TestBeam : Inventory
 {
	PBXCore_LaserBeam beam;
	
	override void DoEffect()
	{
		uint btns = Owner.player.cmd.buttons;
		uint obtns = Owner.player.oldbuttons;
	
		// Create Laser
		if(!beam) 
		{
			beam = beam.Create(Owner, 5, 0, -2, 0, 2, type:"PBXCore_PulseLaser");
			beam.SetEnabled(true);
		}
		
		// Toggle laser
		if( btns & BT_RELOAD && !(obtns & BT_RELOAD) ) 
			beam.SetEnabled(!beam.enabled);
		
		// Update laser if tracking target
		if(beam.isTracking())
		{
			Actor aim = Owner.AimTarget();
			if(aim) beam.targetPos = (aim.pos.xy, aim.pos.z + aim.height * 0.5);
		}
		
		// Toggle tracking
		if( btns & BT_ALTATTACK && !(obtns & BT_ALTATTACK) )
			beam.trackingPos = !beam.trackingPos;
	}
 }
 
 class PBXCore_LaserBeam : Actor
{
	Color shade;

	double maxDist;
	int ontics;
	bool enabled;
	Actor source;
	vector3 curPos;
	vector3 offsets;
	vector2 angleOffsets;
	vector3 curOffs;
	transient FLineTraceData hitData;
	
	bool trackingPos;
	vector3 targetPos;
	
	bool aimWithWeapon;
	bool trackPSprite;
	uint trackPSLayer;
	
	bool followAngles, continuousHit;
	Property TrackAngles : followAngles;
	Property TrackWeapon : trackPSprite, trackPSLayer;
	Property AimFromWeapon : aimWithWeapon; 
	Property LaserColor : shade;
	Property ContinuousImpact : continuousHit;
	
	Default
	{
		Scale 1.0;
		+NOINTERACTION;
		+INTERPOLATEANGLES;
		RenderStyle "AddShaded";
		
		PBXCore_LaserBeam.LaserColor "Blue";
		PBXCore_LaserBeam.TrackAngles true;				// Update with player's view.
		PBXCore_LaserBeam.TrackWeapon true, PSP_WEAPON; // Offset by PSprite offsets.
		PBXCore_LaserBeam.AimFromWeapon true;			// Fire from weapon "muzzle", only used if TrackWeapon is enabled.
		PBXCore_LaserBeam.ContinuousImpact false; 		// If true, calls the OnImpact function every tick the laser is enabled, instead of just once after the laser is fired.
	}
	
	static PBXCore_LaserBeam Create(Actor source, double fw, double lr, double ud, double angleOffs = 0, double pitchOffs = 0, double maxDist = 2048, class<PBXCore_LaserBeam> type = "PBXCore_LaserBeam")
	{
		let laser = PBXCore_LaserBeam(Spawn(type, source.pos));
		if(laser) 
		{
			laser.source = source;
			laser.maxDist = maxDist;
			laser.offsets = (fw, lr, ud);
			laser.angleOffsets = (angleOffs, pitchOffs);
		}
		
		return laser;
	}
	
	void setEnabled(bool set)
	{
		enabled = set;
	}
	
	void startTracking(vector3 toPos)
	{
		trackingPos = true;
		targetPos = toPos;
	}
	
	void aimAtCrosshair()
	{
		double zoffs = source.height*0.5;
		if(source.player) zoffs = source.player.viewz - source.pos.z;
	
		FLineTraceData lt;
		source.LineTrace(source.angle, maxDist, source.pitch, offsetz:zoffs, offsetforward:source.radius, data:lt);
		if(lt.HitType != TRACE_HitNone) 
		{
			vector3 aimAngles = level.SphericalCoords(curPos, lt.HitLocation, (source.angle,source.pitch));
			angleOffsets.x = aimAngles.x;
			angleOffsets.y = aimAngles.y;
		}
	}
	
	void stopTracking()
	{
		if(trackingPos) ontics = 0;
		trackingPos = false;
	}
	
	bool isTracking()
	{
		return trackingPos;
	}
	
	virtual vector3 getSourcePos()
	{
		vector3 srcPos = (source.pos.xy, source.pos.z + (source.height * 0.5));
		if(source.player) srcPos.z = source.player.viewz;
		
		return srcPos;
	}
	
	virtual void BeamTick()
	{
		// Implement custom laser logic here.
	}
	
	virtual void OnImpact(vector3 hitPos, Actor hitActor)
	{
		// On impact with something
	}
	
	override void Tick()
	{
		if(isFrozen()) return;
		if(!enabled || !source) 
		{
			ontics = 0;
			bInvisible = true;
			return;
		}
		ontics++;
		bInvisible = ontics < 3;
		if(shade) SetShade(shade);
		
		if( ontics == 2 || (ontics >= 2 && continuousHit) )
		{ 
			OnImpact(hitData.hitLocation, hitdata.hitActor);
		}
				
		// PSprite tracking?
		vector2 bob = (0,0);
		if(trackPSprite && PlayerPawn(source))
		{
			let psp = source.player.GetPSprite(trackPSLayer);
			bob = PlayerPawn(source).BobWeapon(1.0);
			
			bob.x += psp.x;
			bob.y += (psp.y - 32);
			bob.x *= 0.031;
			bob.y *= 0.035;
		}
		
		// Update laser and tracking.
		let aimDir = Quat.FromAngles(source.angle, source.pitch, source.roll);
		curOffs = aimDir * (
			offsets.x, 
		  -(offsets.y + bob.x), 
			offsets.z - bob.y
		);
		
		vector3 finalPos = level.vec3offset(getSourcePos(), curOffs);
		SetOrigin(finalPos, true);
		curPos = finalPos;
		
		double toAngle = source.angle + angleOffsets.x;
		double toPitch = source.pitch + angleOffsets.y;
		if(aimWithWeapon) 
		{
			toAngle -= (bob.x * 10);
			toPitch += (bob.y * 10);  
		}	
		
		// Track target and source's angles.
		if(trackingPos)
		{
			vector3 diff = level.vec3diff(finalPos, targetPos);
			vector3 dir = diff.Unit();
			
			toAngle = angleOffsets.x + atan2(dir.y, dir.x) + 180; 
			toPitch = angleOffsets.y + asin(dir.z);
			A_SetAngle(toAngle, SPF_INTERPOLATE);
			A_SetPitch(toPitch - 90, SPF_INTERPOLATE);		
		} 
		else if(followAngles)
		{
			A_SetAngle(toAngle, SPF_INTERPOLATE);
			A_SetPitch(toPitch+90, SPF_INTERPOLATE);
		}
		
		// View Interpolation.	
		if(source.player) 
		{
			if(source.player.cheats & CF_PREDICTING) return;
			source.player.cheats |= CF_INTERPVIEW;
		}
		
		// Do linetrace to determine aim distance.
		double zoffs = source.player ? (source.player.viewz-source.pos.z) : source.height * 0.5;
		source.LineTrace(angle, maxDist, pitch - 90, 0, zoffs+offsets.z-bob.y, offsets.x, offsets.y-bob.x, data:hitData);
		
		// Scale to Distance.
		double dist = min(hitData.Distance, maxDist);
		double dirPitch = pitch - 90;
		scale.y = dist * level.pixelstretch;
					
		BeamTick();
	}
	
	States
	{
		Spawn:
			MODL A -1 Bright;
		stop;
	}
}