class MMOInteraction extends Interaction;

var MMOGoat myMut;

function InitMMOInteraction(MMOGoat newMut)
{
	myMut=newMut;
}

exec function ShowMMOGoatSpawnCount()
{
	myMut.WorldInfo.Game.Broadcast(myMut, "MMOGoatSpawnCount = " $ myMut.minGoatCount);
}

exec function ShowMMOSheepSpawnCount()
{
	myMut.WorldInfo.Game.Broadcast(myMut, "MMOSheepSpawnCount = " $ myMut.minSheepCount);
}

exec function SetMMOGoatSpawnCount(int newSpawnCount)
{
	myMut.minGoatCount=newSpawnCount;
	myMut.maxGoatCount=newSpawnCount*2;
}

exec function SetMMOSheepSpawnCount(int newSpawnCount)
{
	myMut.minSheepCount=newSpawnCount;
	myMut.maxSheepCount=newSpawnCount*2;
}

exec function ResetMMOGoatSpawnCount()
{
	myMut.minGoatCount=myMut.default.minGoatCount;
	myMut.maxGoatCount=myMut.default.maxGoatCount;
}

exec function ResetMMOSheepSpawnCount()
{
	myMut.minSheepCount=myMut.default.minSheepCount;
	myMut.maxSheepCount=myMut.default.maxSheepCount;
}