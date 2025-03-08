class RPGoatHardmode extends GGMutator;

var array<GGGoat> mGoats;

function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;

	goat = GGGoat( other );

	if( goat != none )
	{
		if( IsValidForPlayer( goat ) )
		{
			mGoats.AddItem(goat);
			ClearTimer(NameOf(InitRPGoatHardmode));
			SetTimer(1.f, false, NameOf(InitRPGoatHardmode));
		}
	}

	super.ModifyPlayer( other );
}

function InitRPGoatHardmode()
{
	local GGGoat goat;
	local RPGoatComponent rpComp;

	//Find RPGoat component
	foreach mGoats(goat)
	{
		rpComp=RPGoatComponent(GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).FindMutatorComponent(class'RPGoatComponent', goat.mCachedSlotNr));
		if(rpComp != none)
		{
			rpComp.EnableHardmode();
		}
		else
		{
			DisplayUnavailableMessage();
		}
	}
}

function DisplayUnavailableMessage()
{
	WorldInfo.Game.Broadcast(self, "RPGoat - Hardmode only works if combined with RPGoat.");
	SetTimer(3.f, false, NameOf(DisplayUnavailableMessage));
}

DefaultProperties
{

}