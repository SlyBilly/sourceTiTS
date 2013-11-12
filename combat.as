﻿//Tracks what NPC in combat we are on. 0 = PC, 1 = first NPC, 2 = second NPC, 3 = fourth NPC... totalNPCs + 1 = status tic
var combatStage:int = 0;

function inCombat():Boolean {
	return (pc.hasStatusEffect("Round"));
}

function combatMainMenu():void {
	clearOutput();
	//Track round, expires on combat exit.
	if(!pc.hasStatusEffect("Round")) pc.createStatusEffect("Round",1,0,0,0,true,"","",true,0);
	else pc.addStatusValue("Round",1,1);
	//Show what you're up against.
	if(foes[0] == celise) showBust(CELISE);
	for(var x:int = 0; x < foes.length; x++) {
		if(x > 0) output("\n\n");
		displayMonsterStatus(foes[x]);
	}
	//Check to see if combat should be over or not.
	//Victory check first, because PC's are OP.
	if(allFoesDefeated()) {
		//new PG for start of victory text, overrides normal menus.
		output("\n");
		//Route to victory menus and GTFO.		
		victoryRouting();
		return;
	}
	else if(pc.HP() <= 0 || pc.lust() >= 100) {
		//YOU LOSE! GOOD DAY SIR!
		output("\n");
		defeatRouting();
		return;
	}
	//Tutorial menus
	if(foes[0].short == "Celise") {
		celiseMenu();
		return;
	}
	//Combat menu
	clearMenu();
	addButton(0,"Attack",attackRouter,playerAttack);
	addButton(1,upperCase(pc.rangedWeapon.attackVerb),attackRouter,playerRangedAttack);
	addButton(5,"Tease",tease);
	//addButton(2,"
}
function celiseMenu():void {
	clearMenu();
	if(pc.statusEffectv1("Round") == 1) addButton(0,"Attack",attackRouter,playerAttack);
	else if(pc.statusEffectv1("Round") == 2) addButton(1,upperCase(pc.rangedWeapon.attackVerb),attackRouter,playerRangedAttack);
	else addButton(5,"Tease",tease);
}

function processCombat():void {
	combatStage++;
	trace("COMBAT STAGE:" + combatStage);
	//Check to see if combat should be over or not.
	//Victory check first, because PC's are OP.
	if(allFoesDefeated()) {
		//Go back to main menu for victory announcement.
		clearMenu();
		addButton(0,"Victory",combatMainMenu);
		return;
	}
	if(pc.HP() <= 0 || pc.lust() >= 100) {
		//YOU LOSE! GOOD DAY SIR!
		clearMenu();
		addButton(0,"Defeat",combatMainMenu);
		return;
	}
	//If enemies still remain, do their AI routine.
	if(combatStage-1 < foes.length) {
		output("\n");
		trace("CELISE TURN");
		enemyAI(foes[combatStage-1]);
		return;
	}
	//If we are 1 past enemies, update statuses.
	if(combatStage == foes.length+1) {
		statusAffectUpdates();
		return;
	}
	combatStage = 0;
	clearMenu();
	addButton(0,"Next",combatMainMenu);
}

function allFoesDefeated():Boolean {
	for(var x:int = 0; x < foes.length; x++) {
		//If a foe is up, fail.
		if(foes[x].HP() > 0 && foes[x].lust() < 100) return false;
	}
	//If we get through them all, check! All foes down.
	return true;
}

function attackRouter(destinationFunc):void {
	clearOutput();
	output("Who do you target?\n");
	for(var x:int = 0; x < foes.length; x++) {
		output(foes[x].capitalA + foes[x].short + ": " + foes[x].HP() + " HP, " + foes[x].lust() + " Lust\n");
	}
	var button:int = 0;
	var counter:int = 0;
	if(foes.length == 1) {
		destinationFunc(foes[0]);
		return;
	}
	clearMenu();
	while(counter < foes.length) {
		addButton(button,foes[0].short,destinationFunc,foes[counter]);
		counter++;
		button++;
	}
	if(button < 14) button = 14;
	addButton(button,"Back",combatMainMenu);
}


function enemyAttack(attacker:creature):void {
	attack(attacker,pc);
}
function playerAttack(target:creature):void {
	attack(pc,target);
}
function playerRangedAttack(target:creature):void {
	rangedAttack(pc,target);
}

function attack(attacker:creature, target:creature):void {
	trace("Attacking in melee...");
	if(!attacker.hasStatusEffect("Multiple Attacks") && attacker == pc) clearOutput();
	//Run with multiple attacks!
	if (attacker.hasPerk("Multiple Attacks")) {
		//Start up
		if (!attacker.hasStatusEffect("Multiple Attacks")) 
		{
			attacker.createStatusEffect("Multiple Attacks",attacker.perkv1("Multiple Attacks"),0,0,0,true,"","",true,0);		
		}
		//Remove if last attack, otherwise decrement.
		else 
		{
			if(attacker.statusEffectv1("Multiple Attacks") <= 0) attacker.removeStatusEffect("Multiple Attacks");
			attacker.addStatusValue("Multiple Attacks",1,-1);
		}
	}
	//Attack missed!
	if(rand(100) + attacker.physique()/5 + attacker.meleeWeapon.attack - target.reflexes()/5 < 10) {
		if(target.customDodge == "") {
			if(attacker == pc) output("You " + pc.meleeWeapon.attackVerb + " at " + target.a + target.short + " with your " + pc.meleeWeapon.longName + ", but just can't connect.");
			else output("You manage to avoid " + attacker.a + possessive(attacker.short) + " " + attacker.meleeWeapon.attackVerb + ".");
		}
		else output(target.customDodge);
	}
	//Celise autoblocks
	else if(target.short == "Celise") {
		output(target.customBlock);
	}
	//Attack connected!
	else {
		if(attacker == pc) output("You land a hit on " + target.a + target.short + " with your " + pc.meleeWeapon.longName + "!");
		else output(attacker.capitalA + attacker.short + " connects with " + attacker.mfn("his","her","its") + " " + attacker.meleeWeapon.longName + "!");
		//Damage bonuses:
		var damage:int = attacker.meleeWeapon.damage + attacker.physique()/2;
		//Randomize +/- 15%
		var randomizer = (rand(31)+ 85)/100;
		var sDamage:int = 0;
		//Apply damage reductions
		if(target.shieldsRaw > 0) {
			sDamage = shieldDamage(target,damage,attacker.meleeWeapon.damageType);
			if(attacker == pc) {
				if(target.shieldsRaw > 0) output(" The shield around " + target.a + target.short + " crackles under your assault, but it somehow holds. (<b>" + sDamage + "</b>)");
				else output(" There is a concussive boom and tingling aftershock of energy as you disperse " + target.a + possessive(target.short) + " defenses. (<b>" + sDamage + "</b>)");
			}
			else {
				if(target.shieldsRaw > 0) output(" Your shield cracles but holds. (<b>" + sDamage + "</b>)");
				else output(" There is a concussive boom and tingling aftershock of energy as your shield is breached. (<b>" + sDamage + "</b>)");
			}
			damage -= sDamage;
		}
		if(damage >= 1) {
			damage = HPDamage(target,damage,attacker.meleeWeapon.damageType);
			if(attacker == pc) {
				if(sDamage > 0) output(" Your " + attacker.meleeWeapon.damageType + " has enough momentum to carry through and strike your target! (<b>" + damage + "</b>)");
				else output(" (<b>" + damage + "</b>)");			
			}
			else {
				if(sDamage > 0) output(" The hit carries on through to hit you! (<b>" + damage + "</b>)");
				else output(" (<b>" + damage + "</b>)");	
			}
		}
	}
	//Do multiple attacks if more are queued.
	if(attacker.hasStatusEffect("Multiple Attacks")) {
		output("\n");
		attack(attacker,target);
		return;
	}
	output("\n");
	processCombat();
}
function rangedAttack(attacker:creature, target:creature):void {
	trace("Ranged shot...");
	if(!attacker.hasStatusEffect("Multiple Shots") && attacker == pc) clearOutput();
	//Run with multiple attacks!
	if (attacker.hasPerk("Multiple Shots")) {
		//Start up
		if (!attacker.hasStatusEffect("Multiple Shots")) 
		{
			attacker.createStatusEffect("Multiple Shots",attacker.perkv1("Multiple Shots"),0,0,0,true,"","",true,0);		
		}
		//Remove if last attack, otherwise decrement.
		else 
		{
			if(attacker.statusEffectv1("Multiple Shots") <= 0) attacker.removeStatusEffect("Multiple Shots");
			attacker.addStatusValue("Multiple Shots",1,-1);
		}
	}
	//Attack missed!
	if(rand(100) + attacker.aim()/5 + attacker.rangedWeapon.attack - target.reflexes()/5 < 10) {
		if(target.customDodge == "") {
			if(attacker == pc) output("You " + pc.rangedWeapon.attackVerb + " at " + target.a + target.short + " with your " + pc.rangedWeapon.longName + ", but just can't connect.");
			else output("You manage to avoid " + attacker.a + possessive(attacker.short) + " " + attacker.rangedWeapon.attackVerb + ".");
		}
		else output(target.customDodge)
	}
	//Celise autoblocks
	else if(target.short == "Celise") {
		output("Celise takes the hit, wound instantly closing in with fresh, green goop. Her surface remains perfectly smooth and unmarred after.");
	}
	//Attack connected!
	else {
		if(attacker == pc) output("You land a hit on " + target.a + target.short + " with your " + pc.rangedWeapon.longName + "!");
		else output(attacker.capitalA + attacker.short + " connects with " + attacker.mfn("his","her","its") + " " + attacker.rangedWeapon.longName + "!");
		//Damage bonuses:
		var damage:int = attacker.rangedWeapon.damage + attacker.aim()/2;
		//Randomize +/- 15%
		var randomizer = (rand(31)+ 85)/100;
		var sDamage:int = 0;
		//Apply damage reductions
		if(target.shieldsRaw > 0) {
			sDamage = shieldDamage(target,damage,attacker.rangedWeapon.damageType);
			if(attacker == pc) {
				if(target.shieldsRaw > 0) output(" The shield around " + target.a + target.short + " crackles under your assault, but it somehow holds. (<b>" + sDamage + "</b>)");
				else output(" There is a concussive boom and tingling aftershock of energy as you disperse " + target.a + possessive(target.short) + " defenses. (<b>" + sDamage + "</b>)");
			}
			else {
				if(target.shieldsRaw > 0) output(" Your shield cracles but holds. (<b>" + sDamage + "</b>)");
				else output(" There is a concussive boom and tingling aftershock of energy as your shield is breached. (<b>" + sDamage + "</b>)");
			}
			damage -= sDamage;
		}
		if(damage >= 1) {
			damage = HPDamage(target,damage,attacker.rangedWeapon.damageType);
			if(attacker == pc) {
				if(sDamage > 0) output(" Your " + attacker.rangedWeapon.damageType + " has enough momentum to carry through and strike your target! (<b>" + damage + "</b>)");
				else output(" (<b>" + damage + "</b>)");			
			}
			else {
				if(sDamage > 0) output(" The hit carries on through to hit you! (<b>" + damage + "</b>)");
				else output(" (<b>" + damage + "</b>)");	
			}
		}
	}
	//Do multiple attacks if more are queued.
	if(attacker.hasStatusEffect("Multiple Shots")) {
		output("\n");
		rangedAttack(attacker,target);
		return;
	}
	output("\n");
	processCombat();
}


function HPDamage(victim:creature,damage:Number = 0, damageType = KINETIC):Number {
	//Reduce damage by defense value
	damage -= victim.defense();
	
	//Apply type reductions!
	damage *= victim.getResistance(damageType);
	//None yet!
	
	damage = Math.round(damage);
	
	//Damage cannot exceed HP amount.
	if(damage > victim.HP()) {
		damage = victim.HP();
	}
	//If we're this far, damage can't be less than one. You did get hit, after all.
	if(damage < 1) damage = 1;
	//Apply the damage
	victim.HP(-1 * damage);
	//Pass back how much was done.
	return damage;
}

function shieldDamage(victim:creature,damage:Number = 0, damageType = KINETIC):Number {
	//Reduce damage by shield defense value
	damage -= victim.shieldDefense();
	
	//Apply type reductions!
	//Kinetic does 40% damage to shields
	if(damageType == KINETIC) damage *= 4;
	//Slashing does 55% damage to shields
	else if(damageType == SLASHING) damage *= .55;
	//Piercing does 75% damage to shields
	else if(damageType == PIERCING) damage *= .75;
	
	//Apply victim resistances vs damage
	damage *= victim.getShieldResistance(damageType);
	
	damage = Math.round(damage);
	
	//Damage cannot exceed shield amount.
	if(damage > victim.shieldsRaw) {
		damage = victim.shieldsRaw;
	}
	//If we're this far, damage can't be less than one. You did get hit, after all.
	if(damage < 1) damage = 1;
	//Apply the damage
	victim.shieldsRaw -= damage;
	//Pass back how much was done.
	return damage;
}

function tease():void {
	clearOutput();
	output("You put a hand on your hips and lewdly expose your groin, wiggling to and fro in front of the captivated goo-girl.\n");
	processCombat();
}

//Name, long descript, lust descript, and 
function displayMonsterStatus(targetFoe):void {
	if(targetFoe.HP() <= 0) {
		output("<b>You've knocked the resistance out of " + targetFoe.a + targetFoe.short + ".\n");
	}
	else if(targetFoe.lust() >= 100) {
		output("<b>" + targetFoe.capitalA + targetFoe.short + " </b>");
		if(targetFoe.plural) output("<b>are </b>");
		else output("<b>is </b>");
		output("<b>too turned on to fight.</b>\n");
	}
	else if(pc.lust() >= 100 || pc.HP() <= 0) {
		if(pc.HP() <= 0) output("<b>" + targetFoe.capitalA + targetFoe.short + " has knocked you off your " + pc.feet() + "!</b>\n");
		else output("<b>" + targetFoe.capitalA + targetFoe.short + " has turned you on too much to keep fighting. You give in...</b>\n");
		return;
	}
	else {
		output("<b>You're fighting " + targetFoe.a + targetFoe.short  + ".</b>\n" + targetFoe.long + "\n");
		showMonsterArousalFlavor(targetFoe);
	}
	//Celise intro specials.
	if(targetFoe.short == "Celise") {
		//Round specific dad addons!
		if(pc.statusEffectv1("Round") == 1) output("\nVictor instructs, <i>“<b>Try and strike her, " + pc.short + ". Use a melee attack.</b>”</i>\n");
		else if(pc.statusEffectv1("Round") == 2) output("\n<i>“Some foes are more vulnerable to ranged attacks than melee attacks or vice versa. <b>Why don’t you try using your gun?</b> Don’t worry, it won’t kill her.”</i> Victor suggests.\n");
		else if(pc.statusEffectv1("Round") == 3) output("\n<i>“Didn’t work, did it? Celise’s race does pretty well against kinetic damage. Thermal weapons would work, but you don’t have any of those. You’ve still got one more weapon that galotians can’t handle - sexual allure. They’re something of a sexual predator, but their libidos are so high that teasing them back often turns them on to the point where they masturbate into a puddle of quivering sex.”</i>  Victor chuckles. <i>“<b>Go ahead, try teasing her.</b> Fighting aliens is about using the right types of attacks in the right situations.”</i>\n");
	}
}

function showMonsterArousalFlavor(targetFoe):void {
	if(targetFoe.lust < 50) { 
		return; 
	}
	else if(targetFoe.plural) {
		if(targetFoe.lust < 60) output(targetFoe.capitalA + possessive(targetFoe.short) + " skins remain flushed with the beginnings of arousal.");
		else if(targetFoe.lust < 70) output(targetFoe.capitalA + possessive(targetFoe.short) + " eyes constantly dart over your most sexual parts, betraying their lust.");
		else if(targetFoe.lust < 85) {
			if(targetFoe.hasCock()) output(targetFoe.capitalA + targetFoe.short + " are having trouble moving due to the rigid protrusions in " + targetFoe.pronoun3 + " groins.");
			if(targetFoe.hasVagina()) output(targetFoe.capitalA + targetFoe.short + " are obviously turned on; you can smell " + targetFoe.pronoun3 + " arousal in the air.");
		}
		else {
			if(targetFoe.hasCock()) output(targetFoe.capitalA + targetFoe.short + " are panting and softly whining, each movement seeming to make " + targetFoe.pronoun3 + " bulges more pronounced.  You don't think " + targetFoe.pronoun1 + " can hold out much longer.");
			if(targetFoe.hasVagina()) output(targetFoe.capitalA + possessive(targetFoe.short) + " " + plural(targetFoe.vaginaDescript()) + " are practically soaked with their lustful secretions.");
		}
	}
	else {
		if(targetFoe.lust < 60) output(targetFoe.capitalA + possessive(targetFoe.short) + " " + targetFoe.skin() + " remains flushed with the beginnings of arousal.");
		else if(targetFoe.lust < 70) output(targetFoe.capitalA + possessive(targetFoe.short) + " eyes constantly dart over your most sexual parts, betraying " + targetFoe.mfn("his","her","its") + " lust.");
		else if(targetFoe.lust < 85) {
			if(targetFoe.hasCock()) output(targetFoe.capitalA + targetFoe.short + " is having trouble moving due to the rigid protrusion in " + targetFoe.mfn("his","her","its") + " groin.");
			if(targetFoe.hasVagina()) output(targetFoe.capitalA + targetFoe.short + " is obviously turned on, you can smell " + targetFoe.mfn("his","her","its") + " arousal in the air.");
		}
		else {
			if(targetFoe.hasCock()) output(targetFoe.capitalA + targetFoe.short + " is panting and softly whining, each movement seeming to make " + targetFoe.mfn("his","her","its") + " bulge more pronounced.  You don't think " + targetFoe.mfn("he","she","it") + " can hold out much longer.");
			if(targetFoe.hasVagina()) output(targetFoe.capitalA + possessive(targetFoe.short) + " " + targetFoe.vaginaDescript() + " is practically soaked with " + targetFoe.mfn("his","her","its") + " lustful secretions.  ");
		}
	}
	output("\n");
}
function statusAffectUpdates():void {
	processCombat();
}

function enemyAI(aggressor:creature):void {	
	//Foe specific AIs
	switch(foes[0].short) {
		case "Celise":
			celiseAI();
			break;
		default:
			enemyAttack(aggressor);
			break;
	}
}

function victoryRouting():void {
	hideNPCStats();
	if(foes[0].short == "Celise") {
		defeatCelise();
	}
	else genericVictory();
}
function genericVictory():void {
	getCombatPrizes();
}
function getCombatPrizes(newScreen:Boolean = false):void {
	if(newScreen) clearOutput();
	
	//Add credits and XP
	var XPBuffer:int = 0;
	var creditBuffer:int = 0;
	for(var x:int = 0; x < foes.length; x++) {
		XPBuffer = foes[x].XP;
		creditBuffer += foes[x].credits;
	}
	pc.XP += XPBuffer;
	pc.credits += creditBuffer;
	
	//Queue up items for looting
	for(var x:int = 0; x < foes.length; x++) 
	{
		for(var y:int = 0; y < foes[x].inventory.length; y++) 
		{
			lootList[lootList.length] = clone(foes[x].inventory[y]);
		}
	}
	//Exit combat as far as the game is concerned.
	pc.removeStatusEffect("Round");
	//Talk about who died and what you got.
	output("You defeated ");
	clearList();
	for(x = 0; x < foes.length; x++) {
		addToList(foes[x].a + foes[x].short);
	}
	output(formatList() + "!");
	//Monies!
	if(creditBuffer > 0) {
		if(foes.length > 1) output(" They had ");
		else output(foes[0].mfn(" He"," She", " It") + " had ");
		output(num2Text(creditBuffer) + " credit");
		if(creditBuffer > 1) output("s");
		output(" loaded on an anonymous credit chit that you appropriate.");
	}
	clearMenu();
	//Fill wallet and GTFO
	if(lootList.length > 0) {
		output(" You also find ");
		clearList();
		for(x = 0; x < lootList.length; x++) {
			addToList(lootList[x].description + " (x" + lootList[x].quantity + ")");
		}
		output(formatList());
		itemScreen = mainGameMenu;
		lootScreen = mainGameMenu;
		useItemFunction = mainGameMenu;
		//Start loot
		itemCollect();
	}
	//Just leave if no items.
	else {
		addButton(0,"Next",mainGameMenu);
	}
}

function defeatRouting():void {
	if(foes[0].shortName == "BONERS") {}
	else {
		output("You lost!  You rouse yourself after an hour and a half quite bloodied.");
		pc.removeStatusEffect("Round");
		processTime(90);
		clearMenu();
		addButton(0,"Next",mainGameMenu);
	}
}
function startCombat(encounter:String):void {
	showNPCStats();
	foes = new Array();
	switch(encounter) {
		case "celise":
			showBust(CELISE);
			setLocation("FIGHT:\nCELISE","TAVROS STATION","SYSTEM: KALAS");
			foes[0] = clone(characters[CELISE]);
			break;
		default:
			foes[0] = new creature();
			break;
	}
	combatMainMenu();
}