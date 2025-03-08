class RPGoat extends GGMutator;

var array<RPGoatComponent> mComponents;
var bool postRenderSet;
/** The MMO combat text. */
var instanced GGCombatTextManager mCachedCombatTextManager;

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;
	local RPGoatComponent rpComp;
	local GGGameInfoMMO gameInfoMMO;

	super.ModifyPlayer( other );

	goat = GGGoat( other );
	if( goat != none )
	{
		rpComp=RPGoatComponent(GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).FindMutatorComponent(class'RPGoatComponent', goat.mCachedSlotNr));
		if(rpComp != none && mComponents.Find(rpComp) == INDEX_NONE)
		{
			mComponents.AddItem(rpComp);
		}
		if(mCachedCombatTextManager == none)
		{
			gameInfoMMO = GGGameInfoMMO( WorldInfo.Game );
			if( gameInfoMMO != none )
			{
				mCachedCombatTextManager = gameInfoMMO.mCombatTextManager;
			}
			else
			{
				mCachedCombatTextManager = Spawn( class'GGCombatTextManager' );
			}

			InitRPGInteraction();

			if( !WorldInfo.bStartup )
			{
				SetPostRenderFor();
			}
			else
			{
				SetTimer( 1.0f, false, NameOf( SetPostRenderFor ));
			}
		}
	}
}

function InitRPGInteraction()
{
	local RPGInteraction ri;

	ri = new class'RPGInteraction';
	ri.InitRPGInteraction(self);
	GetALocalPlayerController().Interactions.AddItem(ri);
}

/**
 * Sets post render for on all local player controllers.
 */
function SetPostRenderFor()
{
	local PlayerController PC;

	if(postRenderSet)
		return;

	postRenderSet=true;
	foreach WorldInfo.LocalPlayerControllers( class'PlayerController', PC )
	{
		if( GGHUD( PC.myHUD ) == none )
		{
			// OKAY! THIS IS REALLY LAZY! This assume all PC's is initialized at the same time
			SetTimer( 0.5f, false, NameOf( SetPostRenderFor ));
			postRenderSet=false;
			break;
		}
		GGHUD( PC.myHUD ).mPostRenderActorsToAdd.AddItem( self );
	}
}

simulated event PostRenderFor( PlayerController PC, Canvas c, vector cameraPosition, vector cameraDir )
{
	local RPGoatComponent RPGC;

	foreach mComponents(RPGC)
	{
		RPGC.PostRenderFor(PC, c, cameraPosition, cameraDir);
	}
}

/**
 * Called when an actor takes damage
 */
function OnTakeDamage( Actor damagedActor, Actor damageCauser, int damage, class< DamageType > dmgType, vector momentum )
{
	local RPGoatComponent RPGC;
	local int RPGdamage;

	foreach mComponents(RPGC)
	{
		RPGdamage=damage/100;
		if(RPGC.gMe == damagedActor)
		{
			if(RPGdamage == 0)
			{
				if(GGInterpActor(damageCauser) != none)
				{
					//WorldInfo.Game.Broadcast(self, "interp velocity=" $ VSize(damageCauser.Velocity));
					RPGdamage=VSize(damageCauser.Velocity)/1000;
				}
			}
			//WorldInfo.Game.Broadcast(self, "OnDamageTaken(" $ damage $ ", " $ dmgType $ ", " $ momentum $ ")");
			RPGC.OnDamageTaken(RPGdamage);
		}
		if(RPGC.gMe == damageCauser)
		{
			//WorldInfo.Game.Broadcast(self, "OnDamageGiven(" $ damage $ ", " $ dmgType $ ", " $ momentum $ ")");
			RPGC.OnDamageGiven(damagedActor, RPGdamage);
		}
	}
}

simulated event Tick( float deltaTime )
{
	local RPGoatComponent RPGC;

	super.Tick( deltaTime );

	foreach mComponents(RPGC)
	{
		RPGC.Tick( deltaTime );
	}
}

DefaultProperties
{
	mMutatorComponentClass=class'RPGoatComponent'

	bPostRenderIfNotVisible=true
}