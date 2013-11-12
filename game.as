﻿function mainGameMenu():void {
	//Display shit that happened during time passage.
	if(eventBuffer != "") {
		clearOutput();
		output("<b>" + possessive(pc.short) + " log:</b>" + eventBuffer);
		eventBuffer = "";
		clearMenu();
		addButton(0,"Next",mainGameMenu);
		return;
	}
	//Queued events can fire off too!
	if(eventQueue.length > 0) {
		//Do the most recent:
		eventQueue[eventQueue.length-1]();
		//Strip out the most recent:
		eventQueue.splice(eventQueue.length-1,1);
	}
	//Set up all appropriate flags
	saveHere = true;
	//Display the room description
	clearOutput();
	output(rooms[location].description);
	setLocation(rooms[location].roomName,rooms[location].planet,rooms[location].system);
	
	//Standard buttons:
	clearMenu();
	//Inventory shit
	itemScreen = mainGameMenu;
	lootScreen = inventory;
	addButton(2,"Inventory",inventory);
	//Other standard buttons
	if(pc.lust() < 33) addDisabledButton(3,"Masturbate");
	else addButton(3,"Masturbate",masturbateMenu);
	if(!rooms[location].hasFlag(BED)) addButton(4,"Rest",rest);
	else addButton(4,"Sleep",sleep);
	//Display movement shits - after clear menu for extra options!
	if(rooms[location].runOnEnter != undefined) {
		if(rooms[location].runOnEnter()) return;
	}
	if(rooms[location].northExit != -1) addButton(6,"North",move,rooms[location].northExit);
	if(rooms[location].eastExit != -1) addButton(12,"East",move,rooms[location].eastExit);
	if(rooms[location].southExit != -1) addButton(11,"South",move,rooms[location].southExit);
	if(rooms[location].westExit != -1) addButton(10,"West",move,rooms[location].westExit);
	if(rooms[location].inExit != -1) addButton(5,rooms[location].inText,move,rooms[location].inExit);
	if(rooms[location].outExit != -1) addButton(7,rooms[location].outText,move,rooms[location].outExit);
	if(location == shipLocation) addButton(1,"Enter Ship",move,99);
}

function inventoryScreen():void {
	clearOutput();
	output("This is a placeholder, yo.");
	clearMenu();
	addButton(14,"Back",mainGameMenu);
}
function crew(counter:Boolean = false):Number {
	if(!counter) {
		clearOutput();
		clearMenu();
	}
	var crewMessages:String = "";
	var count:int = 0;
	if(celiseIsCrew()) {
		count++;
		if(!counter) {
			addButton(count - 1,"Celise",celiseFollowerInteractions);
			crewMessages += "\n\nCelise is onboard, if you want to go see her. The ship does seem to stay clean of spills and debris with her around.";
		}
	}
	if(!counter) {
		if(count > 0) {
			output("Who of your crew do you wish to interact with?" + crewMessages);
		}
		addButton(14,"Back",mainGameMenu);
	}
	return count;
}
function rest():void {
	clearOutput();
	if(pc.HPRaw < pc.HPMax()) {
		pc.HP(Math.round(pc.HPMax() * .2));
	}
	var minutes:int = 230 + rand(20) + 1;
	processTime(minutes);
	output("You sit down and rest for around " + num2Text(Math.round(minutes/60)) + " hours.");
	clearMenu();
	addButton(0,"Next",mainGameMenu);
}
function sleep():void {
	clearOutput();
	if(pc.HPRaw < pc.HPMax()) {
		pc.HP(Math.round(pc.HPMax()));
	}
	var minutes:int = 420 + rand(80) + 1
	processTime(minutes);
	output("You lie down and sleep for about " + num2Text(Math.round(minutes/60)) + " hours.");
	clearMenu();
	addButton(0,"Next",mainGameMenu);
}

function shipMenu():Boolean {
	rooms[99].outExit = shipLocation;
	addButton(9,"Fly",flyMenu);
	if(location == 99) {
		if(crew(true) > 0) addButton(8,"Crew",crew);
	}
	return false;
}

function flyMenu():void {
	clearOutput();
	output("Where do you want to go?");
	clearMenu();
	if(shipLocation != 105) addButton(0,"Tavros",flyTo,"Tavros");
	if(shipLocation != 0) addButton(1,"Mhen'ga",flyTo,"Mhen'ga");
	addButton(14,"Back",mainGameMenu);
}

function flyTo(arg:String):void {
	clearOutput();	
	if(arg == "Mhen'ga") {
		shipLocation = 0;
		location = 0;
		output("You fly to Mhen'ga");
	}
	else if(arg == "Tavros") {
		shipLocation = 105;
		location = 105;
		output("You fly to Tavros");
	}
	output(" and step out of your ship.");
	processTime(30270 + rand(10));
	clearMenu();
	addButton(0,"Next",mainGameMenu);
}

function move(arg:int = 100):void {
	processTime(rooms[location].moveMinutes);
	location = arg;
	//process time here, then back to mainGameMenu!
	mainGameMenu();
}

function processTime(arg:int):void {
	var x:int = 0;
	var tightnessChanged:Boolean = false;
	if(pc.ballFullness < 100) pc.cumProduced(arg);
	var productionFactor:Number = 100/(1920 * ((pc.libido() * 3 + 100)/100));
	//Double time
	if(pc.hasPerk("Extra Ardor")) productionFactor *= 2;
	//Half time.
	else if(pc.hasPerk("Ice Cold")) productionFactor /= 2;
	//Actually apply lust.
	pc.lust(arg * productionFactor);
	while(arg > 0) {
		//Check for shit that happens.
		//Actually move time!
		minutes++;
		
		//Tick hours!
		if(minutes >= 60) {
			minutes = 0;
			hours++;
			//Hours checks here!
			//Cunt stretching stuff
			if(pc.hasVagina()) {
				for(x = 0; x < pc.totalVaginas(); x++) {
					//Count da stretch cooldown or reset if at minimum.
					if(pc.vaginas[x].looseness > pc.vaginas[x].minLooseness) pc.vaginas[x].shrinkCounter++;
					else pc.vaginas[x].shrinkCounter = 0;
					//Reset for this cunt.
					tightnessChanged = false;
					if(pc.vaginas[x].looseness < 2) {}
					else if(pc.vaginas[x].looseness <= 2 && pc.vaginas[x].shrinkCounter >= 200) tightnessChanged = true;
					else if(pc.vaginas[0].looseness < 4 && pc.vaginas[x].shrinkCounter >= 150) tightnessChanged = true;
					else if(pc.vaginas[0].looseness < 5 && pc.vaginas[x].shrinkCounter >= 110) tightnessChanged = true;
					else if(pc.vaginas[0].looseness >= 5 && pc.vaginas[x].shrinkCounter >= 75) tightnessChanged = true;
					if(tightnessChanged) {
						pc.vaginas[x].looseness--;
						eventBuffer += "\n\n<b>Your </b>";
						if(pc.totalVaginas() > 1) eventBuffer += "<b>" + num2Text2(x+1) + "</b> ";
						eventBuffer += "<b>" + pc.vaginaDescript(x) + " has recovered from its ordeals, tightening up a bit.</b>";
					}
				}
			}
			//Butt stretching stuff
			//Count da stretch cooldown or reset if at minimum.
			if(pc.ass.looseness > pc.ass.minLooseness) pc.ass.shrinkCounter++;
			else pc.ass.shrinkCounter = 0;
			//Reset for this cunt.
			tightnessChanged = false;
			if(pc.ass.looseness < 2) {}
			if(pc.ass.looseness == 2 && pc.ass.shrinkCounter >= 72) tightnessChanged = true;
			if(pc.ass.looseness == 3 && pc.ass.shrinkCounter >= 48) tightnessChanged = true;
			if(pc.ass.looseness == 4 && pc.ass.shrinkCounter >= 24) tightnessChanged = true;
			if(pc.ass.looseness == 5 && pc.ass.shrinkCounter >= 12) tightnessChanged = true;
			if(tightnessChanged) {
				pc.ass.looseness--;
				if(pc.ass.looseness <= 4) eventBuffer += "\n\n<b>Your " + pc.assholeDescript() + " has recovered from its ordeals and is now a bit tighter.</b>";
				else eventBuffer += "\n\n<b>Your " + pc.assholeDescript() + " recovers from the brutal stretching it has received and tightens up.</b>";
			}
			//Days ticks here!
			if(hours >= 24) {
				days++;
				hours = 0;
			}
		}
		arg--;
	}
	//updatePCStats();
}