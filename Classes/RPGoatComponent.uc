class RPGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var array<KeyBind> cachedBindings;
var vector lastVelocity;
var bool damagesEnabled;

/** Leave blank for random fantasy name */
var string mNPCName;

var float respawnTime;

var float criticalStrikeChance;

var vector mNameTagOffset;
var color mNameTagColor;
var name mNameTagBoneName;

/** Colors for the HP bar, 0, 50, 100 is lerped between on 0, 50 and 100 % health */
var color mHpBarBackgroundColor;
var color mHpBarColor0;
var color mHpBarColor50;
var color mHpBarColor100;

/** The MMO npc's have a health */
var int mHealth;
var int mHealthMax;
var bool isDead;

var bool isHardmode;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	local int slotNr;

	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		if( mHealthMax == 0 )
		{
			mHealthMax = default.mHealth;
		}

		mNPCName=class'GameEngine'.static.GetOnlineSubsystem().PlayerInterface.GetPlayerNickname(class'Engine'.static.GetEngine().GamePlayers[ 0 ].ControllerId);
		slotNr = gMe.mCachedSlotNr;
		if(slotNr > 0)
		{
			mNPCName = "Goat" @ slotNr+1;
 		}
	}
}

function EnableHardmode()
{
	isHardmode=true;
	mNameTagColor = MakeColor( 255, 0, 0, 255 );
}

/**
 * Called when you takes damage
 */
function OnDamageTaken(int damage)
{
	local int effectiveDamage;

	//myMut.WorldInfo.Game.Broadcast(myMut, "OnDamageTaken");
	effectiveDamage=Min(damage, mHealth);
	if(effectiveDamage <= 0 || !damagesEnabled)
		return;

	DisableDamages();
	//myMut.WorldInfo.Game.Broadcast(myMut, "effectiveDamage=" $ effectiveDamage);
	mHealth -= effectiveDamage * (isHardmode?2.f:1.f);
	RPGoat(myMut).mCachedCombatTextManager.AddCombatTextInt( damage * (isHardmode?2.f:1.f), VRand() * 20.0f, TC_DAMAGE, gMe.Controller );

	if(mHealth <= 0)
	{
		Die();
	}
}

//Prevent overkill
function DisableDamages()
{
	damagesEnabled=false;
	gMe.SetTimer(0.1f, false, NameOf(EnableDamages), self);
}

function EnableDamages()
{
	damagesEnabled=true;
}

/**
 * Called when you give damage
 */
function OnDamageGiven( Actor damagedActor, int damage)
{
	local GGPawn gpawn;
	local int effectiveHeal;

	if(damage <= 0)
		return;

	gpawn=GGPawn(damagedActor);
	if(gpawn != none)
	{
		if(Rand(100) < criticalStrikeChance)
		{
			damage *= 3;
		}

		//myMut.WorldInfo.Game.Broadcast(myMut, "damageGiven=" $ damage);
		if(GGGoat(damagedActor) == none)
		{
			RPGoat(myMut).mCachedCombatTextManager.AddCombatTextInt( damage, VRand() * 20.0f, TC_DAMAGE, gpawn.Controller );
		}
		if(!isHardmode)
		{
			effectiveHeal=Min(damage/2.f, mHealthMax - mHealth);
			if(effectiveHeal > 0)
			{
				mHealth += effectiveHeal;
				RPGoat(myMut).mCachedCombatTextManager.AddCombatTextInt( effectiveHeal, VRand() * 20.0f, TC_XP, gMe.Controller );
			}
		}
	}
}

function Die()
{
	if(isDead)
		return;

	isDead=true;
	if(gMe.Controller != none)
	{
		cachedBindings=PlayerController(gMe.Controller).PlayerInput.Bindings;
		PlayerController(gMe.Controller).PlayerInput.Bindings.Length=0;
	}
	mNameTagColor = MakeColor( 128, 128, 128, 255 );
	gMe.SetRagdoll(true);
	gMe.SetOnFire(false);
	gMe.WorldInfo.Game.SetGameSpeed( 0.25f );
	gMe.SetTimer(respawnTime, false, NameOf( RespawnGoat ), self );
}

function RespawnGoat()
{
	gMe.Respawn();
	if(cachedBindings.Length > 0 && gMe.Controller != none)
	{
		PlayerController(gMe.Controller).PlayerInput.Bindings=cachedBindings;
		cachedBindings.Length=0;
	}
	mNameTagColor = isHardmode?MakeColor( 255, 0, 0, 255 ):MakeColor( 255, 255, 255, 255 );
	mHealth=mHealthMax;
	gMe.WorldInfo.Game.SetGameSpeed( 1.f );
	isDead=false;
}

function Tick(float deltaTime)
{

	TakeAccelerationDamages();

	if(isDead && gMe.Controller != none)
	{
		GGPlayerInput( PlayerController( gMe.Controller ).PlayerInput ).ResetInput();
	}

	if(gMe.mIsBurning && !gMe.IsTimerActive(NameOf(DoBurnDOT), self))
	{
		DoBurnDOT();
	}

	lastVelocity=gMe.Velocity;
}

function TakeAccelerationDamages()
{
	local float deltaSpeed;

	deltaSpeed=Abs(VSize(gMe.Velocity) - VSize(lastVelocity));
	if(deltaSpeed <= gMe.JumpZ)
	{
		return;
	}
	//myMut.WorldInfo.Game.Broadcast(myMut, "deltaSpeed=" $ deltaSpeed);

	OnDamageTaken(Min(deltaSpeed/500.f, 100));
}

function DoBurnDOT()
{
	if(!gMe.mIsBurning)
		return;

	OnDamageTaken(1);
	gMe.SetTimer(1.f, false, NameOf(DoBurnDOT), self);
}

simulated event PostRenderFor( PlayerController PC, Canvas c, vector cameraPosition, vector cameraDir )
{
	local vector nameTagLocation, locationToUse;
	local bool isCloseEnough, isOnScreen, isVisible;
	local float cameraDistScale, cameraDist, cameraDistMax, cameraDistMin, cameraFadeDistMin, cameraFade;

	locationToUse = gMe.mesh.GetBoneLocation( mNameTagBoneName );

	if( IsZero( locationToUse ) )
	{
		locationToUse = gMe.Location;
	}

	if( gMe.mesh.DetailMode > class'WorldInfo'.static.GetWorldInfo().GetDetailMode() )
	{
		return;
	}

	cameraDist = VSize( cameraPosition - locationToUse );
	cameraDistMin = 500.0f;
	cameraDistMax = 4000.0f;
	cameraDistScale = GetScaleFromDistance( cameraDist, cameraDistMin, cameraDistMax );
	cameraFadeDistMin = 3000.0f;
	cameraFade = GetScaleFromDistance( cameraDist, cameraFadeDistMin, cameraDistMax ) * 255;

	isCloseEnough = cameraDist < cameraDistMax;
	isOnScreen = cameraDir dot Normal( locationToUse - cameraPosition ) > 0.0f;
	isVisible = false;

	if( isOnScreen && isCloseEnough )
	{
		// An extra check here as LastRenderTime is for all viewports (coop).
		isVisible = gMe.FastTrace( locationToUse + mNameTagOffset, cameraPosition );
	}

	c.Font = Font'UI_Fonts.InGameFont';
	c.PushDepthSortKey( int( cameraDist ) );

	if( isOnScreen && isCloseEnough && isVisible )
	{
		nameTagLocation = c.Project( locationToUse + mNameTagOffset );

		RenderNameTag( c, nameTagLocation, cameraDistScale, cameraFade );
		RenderHpBar( c, nameTagLocation, cameraDistScale, cameraFade );
	}

	c.PopDepthSortKey();
}

/**
 * Renders an name tag for this npc.
 * @param c - Canvas to draw on.
 * @param screenLocation - Location on screen to draw the name (center/bottom of the text).
 * @param sceenScale - Scale of name, valid range is [0, 1] where 0 is smallest and 1 is biggest.
 * @param screenAlpha - How transparent the name tag should be, valid range is [0, 255] where 0 is invisible and 255 is visible.
 */
function RenderNameTag( Canvas c, vector screenLocation, float screenScale, float screenAlpha )
{
	local FontRenderInfo renderInfo;
	local float textScale;

	renderInfo.bClipText = true;
	textScale =  1.0f; //Lerp( .0f, 2.0f, screenScale );

	c.SetPos( screenLocation.X, screenLocation.Y );
	c.DrawColor = mNameTagColor;
	c.DrawColor.A = screenAlpha;
	c.DrawAlignedShadowText( mNPCName,, textScale, textScale, renderInfo,,, 0.5f, 1.0f );
}

/**
 * Renders an HP bar for this npc.
 * @param c - Canvas to draw on.
 * @param screenLocation - Location on screen to draw the HP bar (center/top of the bar).
 * @param sceenScale - Scale of the HP bar, valid range is [0, 1] where 0 is smallest and 1 is biggest.
 * @param screenAlpha - How transparent the name tag should be, valid range is [0, 255] where 0 is invisible and 255 is visible.
 */
function RenderHpBar( Canvas c, vector screenLocation, float screenScale, float screenAlpha )
{
	local int barHeight, barWidth;
	local vector adjustedScreenLocation;
	local float adjustedScreenScale, percent;

	adjustedScreenScale = Lerp( 1.0f, 2.0f, screenScale );

	barHeight = 4 * adjustedScreenScale;
	barWidth = 50 * adjustedScreenScale;

	adjustedScreenLocation.X = screenLocation.X - barWidth / 2;
	adjustedScreenLocation.Y = screenLocation.Y;

	// Background.
	c.DrawColor = mHpBarBackgroundColor;
	c.DrawColor.A = screenAlpha;
	c.SetPos( adjustedScreenLocation.X, adjustedScreenLocation.Y );
	c.DrawRect( barWidth, barHeight );

	// Bar.
	percent = GetHP();
	c.DrawColor = percent > 0.5f	? LerpColor( mHpBarColor50, mHpBarColor100, ( percent - 0.5f ) * 2.0f )
									: LerpColor( mHpBarColor0, mHpBarColor50, percent * 2.0f );
	c.DrawColor.A = screenAlpha;
	c.SetPos( adjustedScreenLocation.X + 1, adjustedScreenLocation.Y + 1 );
	c.DrawRect( FMax( percent > 0.0f ? 1.0f : 0.0f, ( barWidth - 2 ) * percent ), barHeight - 2 );
}

/**
 * Get the hp of this NPC in percent.
 *@return - Returns a value in the range [0, 1], 1 is max health and 0 is dead!
 */
function float GetHP()
{
	return float( mHealth ) / float( mHealthMax );
}

function float GetScaleFromDistance( float cameraDist, float cameraDistMin, float cameraDistMax )
{
	return FClamp( 1.0f - ( ( FMax( cameraDist, cameraDistMin ) - cameraDistMin ) / ( cameraDistMax - cameraDistMin ) ), 0.0f, 1.0f );
}

defaultproperties
{
	mHealth=100
	respawnTime=1.5f
	damagesEnabled=true

	mNameTagBoneName=Head

	criticalStrikeChance=5

	mNameTagOffset=(X=0.0f,Y=0.0f,Z=40.0f)
	mNameTagColor=(R=255,G=255,B=255,A=255)

	mHpBarBackgroundColor=(R=0,G=0,B=0,A=255)
	mHpBarColor0=(R=255,G=0,B=0,A=255)
	mHpBarColor50=(R=255,G=255,B=0,A=255)
	mHpBarColor100=(R=0,G=255,B=0,A=255)
}