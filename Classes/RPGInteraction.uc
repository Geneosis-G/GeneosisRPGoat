class RPGInteraction extends Interaction;

var RPGoat myMut;

function InitRPGInteraction(RPGoat newMut)
{
	myMut=newMut;
}

exec function RenamePlayer(int playerID, string newName)
{
	local RPGoatComponent rpgc;

	foreach myMut.mComponents(rpgc)
	{
		if(playerID == rpgc.gMe.mCachedSlotNr)
		{
			rpgc.mNPCName=newName;
			break;
		}
	}
}
