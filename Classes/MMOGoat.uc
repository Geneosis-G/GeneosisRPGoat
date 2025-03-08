class MMOGoat extends GGMutator
	config(Geneosis);

var array<GGGoat> mGoats;
var float timeElapsed;
var float managementTimer;
var float SRTimeElapsed;
var float spawnRemoveTimer;
var float spawnRadius;
var int minGoatCount;
var int minSheepCount;
var int maxGoatCount;
var int maxSheepCount;
var GGChatManager mChatManager;
var Array< Pathnode > mScriptedPath;

var array<GGNpc> mRemovableNPCs;
var int mGoatNPCCount;
var int mSheepNPCCount;
var array<int> mGoatNPCsToSpawnForPlayer;
var array<int> mSheepNPCsToSpawnForPlayer;

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;
	local GGGameInfoMMO gameInfoMMO;
	local Pathnode node;

	goat = GGGoat( other );

	if( goat != none )
	{
		if( IsValidForPlayer( goat ) )
		{
			mGoats.AddItem(goat);
			if( mChatManager == none )
			{
				gameInfoMMO = GGGameInfoMMO( WorldInfo.Game );
				mChatManager = gameInfoMMO != none ? gameInfoMMO.mChatManager : none;
				if(mChatManager == none)
				{
					mChatManager = new class'GGChatManager';
					mChatManager.GenerateFakeChatNicks();
				}
				InitMMOInteraction();
			}
			if(mScriptedPath.Length == 0)
			{
				foreach AllActors(class'Pathnode', node)
				{
					mScriptedPath.AddItem(node);
				}
			}
		}
	}

	super.ModifyPlayer( other );
}

function InitMMOInteraction()
{
	local MMOInteraction mi;

	mi = new class'MMOInteraction';
	mi.InitMMOInteraction(self);
	GetALocalPlayerController().Interactions.AddItem(mi);
}

simulated event Tick( float deltaTime )
{
	super.Tick( deltaTime );

	timeElapsed=timeElapsed+deltaTime;
	if(timeElapsed > managementTimer)
	{
		timeElapsed=0.f;
		GenerateMMONPCLists();
	}
	SRTimeElapsed=SRTimeElapsed+deltaTime;
	if(SRTimeElapsed > spawnRemoveTimer)
	{
		SRTimeElapsed=0.f;
		SpawnMMONPCFromList();
		RemoveMMONPCFromList();
	}
}

function GenerateMMONPCLists()
{
	local GGNPCMMOPlayerBot goatNPC;
	local GGNpcSheepContent sheepNPC;
	local array<int> goatNPCsForPlayer;
	local array<int> sheepNPCsForPlayer;
	local bool isRemovable;
	local int nbPlayers, i;
	local vector dist;

	mRemovableNPCs.Length=0;

	nbPlayers=mGoats.Length;
	mGoatNPCsToSpawnForPlayer.Length = 0;
	mGoatNPCsToSpawnForPlayer.Length = nbPlayers;
	mSheepNPCsToSpawnForPlayer.Length = 0;
	mSheepNPCsToSpawnForPlayer.Length = nbPlayers;
	goatNPCsForPlayer.Length = nbPlayers;
	sheepNPCsForPlayer.Length = nbPlayers;
	mGoatNPCCount=0;
	mSheepNPCCount=0;
	//Find all goat NPCs close to each player
	foreach AllActors(class'GGNPCMMOPlayerBot', goatNPC)
	{
		//WorldInfo.Game.Broadcast(self, MMONPCAI $ " possess " $ GoatNPC);
		mGoatNPCCount++;
		isRemovable=true;

		for(i=0 ; i<nbPlayers ; i++)
		{
			dist=mGoats[i].Location - goatNPC.Location;
			if(VSize2D(dist) < spawnRadius)
			{
				goatNPCsForPlayer[i]++;
				isRemovable=false;
			}
		}

		if(isRemovable)
		{
			mRemovableNPCs.AddItem(goatNPC);
		}
	}
	//Find all sheep NPCs close to each player
	foreach AllActors(class'GGNpcSheepContent', sheepNPC)
	{
		mSheepNPCCount++;
		isRemovable=true;

		for(i=0 ; i<nbPlayers ; i++)
		{
			dist=mGoats[i].Location - sheepNPC.Location;
			if(VSize2D(dist) < spawnRadius)
			{
				sheepNPCsForPlayer[i]++;
				isRemovable=false;
			}
		}

		if(isRemovable)
		{
			mRemovableNPCs.AddItem(sheepNPC);
		}
	}

	for(i=0 ; i<nbPlayers ; i++)
	{
		mGoatNPCsToSpawnForPlayer[i]=minGoatCount-goatNPCsForPlayer[i];
		mSheepNPCsToSpawnForPlayer[i]=minSheepCount-sheepNPCsForPlayer[i];
	}
	//WorldInfo.Game.Broadcast(self, "MMONPCs to spawn " $ mGoatNPCsToSpawnForPlayer[0]);
}

function SpawnMMONPCFromList()
{
	local GGNPCMMOAbstract newNpc;
	local int nbPlayers, i;

	//Spawn new goat and sheeps NPCs if needed
	nbPlayers=mGoats.Length;
	for(i=0 ; i<nbPlayers ; i++)
	{
		if(mGoatNPCsToSpawnForPlayer.Length > 0 && mGoatNPCsToSpawnForPlayer[i] > 0)
		{
			mGoatNPCsToSpawnForPlayer[i]--;
			newNpc = Spawn( class'GGNPCMMOPlayerBot',,, GetRandomSpawnLocation(mGoats[i].Location), GetRandomRotation());
			if(newNpc != none)
			{
				SetupSpawnedPawn(newNpc);
				mGoatNPCCount++;
			}
			break;
		}

		if(mSheepNPCsToSpawnForPlayer.Length > 0 && mSheepNPCsToSpawnForPlayer[i] > 0)
		{
			mSheepNPCsToSpawnForPlayer[i]--;
			newNpc = Spawn( class'GGNpcSheepContent',,, GetRandomSpawnLocation(mGoats[i].Location), GetRandomRotation());
			if(newNpc != none)
			{
				SetupSpawnedPawn(newNpc);
				mSheepNPCCount++;
			}
			break;
		}
	}
}

function RemoveMMONPCFromList()
{
	local GGNpc NPCToRemove;
	local int nbPlayers, goatsToRemove, sheepsToRemove;

	//Remove old MMONPCs and infected NPCs if needed
	nbPlayers=mGoats.Length;
	goatsToRemove=mGoatNPCCount-(maxGoatCount*nbPlayers);
	sheepsToRemove=mSheepNPCCount-(maxSheepCount*nbPlayers);
	if(mRemovableNPCs.Length > 0 && (goatsToRemove > 0 || sheepsToRemove > 0))
	{
		NPCToRemove=mRemovableNPCs[0];
		mRemovableNPCs.Remove(0, 1);

		if(goatsToRemove > 0 && GGNPCMMOPlayerBot(NPCToRemove) != none)
		{
			DestroyNPC(NPCToRemove);
			mGoatNPCCount--;
		}
		if(sheepsToRemove > 0 && GGNpcSheepContent(NPCToRemove) != none)
		{
			DestroyNPC(NPCToRemove);
			mSheepNPCCount--;
		}
	}
}

function SetupSpawnedPawn(GGNPCMMOAbstract newNpc)
{
	SetNpcRandomName(newNpc);
	newNpc.SetPhysics( PHYS_Falling );
	AssignScriptedPath(newNpc);
}

function SetNpcRandomName(GGNPCMMOAbstract npc)
{
  	npc.mNPCName = mChatManager.mAllFakeNickNames[ Rand( mChatManager.mAllFakeNickNames.Length ) ];
}

function AssignScriptedPath( GGNPC spawnedNPC )
{
	spawnedNPC.mAutoPathToNewObjects = false;
	spawnedNPC.mUseScriptedRoute = true;
	spawnedNPC.mScriptedRouteType = SRT_RANDOM;
	spawnedNPC.mScriptedPath = mScriptedPath;

	GGAIController( spawnedNPC.Controller ).ResumeScriptedRoute();
}

function DestroyNPC(GGPawn gpawn)
{
	local int i;

	for( i = 0; i < gpawn.Attached.Length; i++ )
	{
		if(GGGoat(gpawn.Attached[i]) == none)
		{
			gpawn.Attached[i].ShutDown();
			gpawn.Attached[i].Destroy();
		}
	}
	gpawn.ShutDown();
	gpawn.Destroy();
}

function vector GetRandomSpawnLocation(vector center)
{
	local vector dest;
	local rotator rot;
	local float dist;
	local Actor hitActor;
	local vector hitLocation, hitNormal, traceEnd, traceStart;

	rot=GetRandomRotation();

	dist=spawnRadius;
	dist=RandRange(dist/2.f, dist);

	dest=center+Normal(Vector(rot))*dist;
	traceStart=dest;
	traceEnd=dest;
	traceStart.Z=10000.f;
	traceEnd.Z=-3000;

	hitActor = Trace( hitLocation, hitNormal, traceEnd, traceStart, true);
	if( hitActor == none )
	{
		hitLocation = traceEnd;
	}

	hitLocation.Z+=30;

	return hitLocation;
}

function rotator GetRandomRotation()
{
	local rotator rot;

	rot=Rotator(vect(1, 0, 0));
	rot.Yaw+=RandRange(0.f, 65536.f);

	return rot;
}

DefaultProperties
{
	managementTimer=1.f
	spawnRemoveTimer=0.1f
	spawnRadius=5000.f
	minGoatCount=20
	minSheepCount=20
	maxGoatCount=40
	maxSheepCount=40
}