// #Lacey Jones's Pizza Cube GUI

// TODO PRO Remember pizza you already baked or some other way of favoriting them and make them again with one click
// TODO PRO SAVE interface options from menu and sorting of items
// TODO Lazy epic pizza (just find the best ingredients for an epic pizza and select them) (or the highest possible turn gain available)
// TODO Blacklist items to hide from the dropdown
// TODO Reload button saving interface state
// TODO Suggest simple obtainable ingredients

///////////////////// EFFECTS


///////////// MODIFIED FROM EZANDORA'S GENIE SCRIPT

boolean [string] __effect_descriptions_modifier_is_percent;
string [string] __effect_descriptions_modifier_short_description_mapping;

void initialiseGenieEffectDescriptions()
{
	__effect_descriptions_modifier_is_percent["item drop"] = true;
	__effect_descriptions_modifier_is_percent["booze drop"] = true;
	__effect_descriptions_modifier_is_percent["food drop"] = true;
	__effect_descriptions_modifier_is_percent["meat drop"] = true;
	__effect_descriptions_modifier_is_percent["initiative"] = true;
	__effect_descriptions_modifier_is_percent["combat rate"] = true;
	__effect_descriptions_modifier_short_description_mapping["item drop"] = "item";
	__effect_descriptions_modifier_short_description_mapping["meat drop"] = "meat";
	__effect_descriptions_modifier_short_description_mapping["combat rate"] = "combat";
	__effect_descriptions_modifier_short_description_mapping["initiative"] = "init";
}

static
{
	buffer [effect] __genie_saved_effect_descriptions;
	boolean [effect][string] __modifiers_for_effect;
	boolean [string][effect] __effects_for_modifiers;
	boolean [effect] __effect_contains_non_constant_modifiers; //meaning, numeric_modifier() cannot be cached
}

void initialiseModifiers()
{
	if (__modifiers_for_effect.count() != 0) return;
	//boolean [string] modifier_types;
	//boolean [string] modifier_values;
	foreach e in $effects[]
	{
		string string_modifiers = e.string_modifier("Modifiers");
        if (string_modifiers == "") continue;
        if (string_modifiers.contains_text("Avatar: ")) continue; //FIXME parse properly?
        string [int] first_level_split = string_modifiers.split_string(", ");
        
        foreach key, entry in first_level_split
        {
        	//print_html(entry);
            //if (!entry.contains_text(":"))
            
            string modifier_type;
            string modifier_value;
            if (entry.contains_text(": "))
            {
            	string [int] entry_split = entry.split_string(": ");
                modifier_type = entry_split[0];
                modifier_value = entry_split[1];
            }
            else
            	modifier_type = entry;
            
            
            string modifier_type_converted = modifier_type;
            
            //convert modifier_type to modifier_type_converted:
            //FIXME is this all of them?
            if (modifier_type_converted == "Combat Rate (Underwater)")
            	modifier_type_converted = "Underwater Combat Rate";
            else if (modifier_type_converted == "Experience (familiar)")
                modifier_type_converted = "Familiar Experience";
            else if (modifier_type_converted == "Experience (Moxie)")
                modifier_type_converted = "Moxie Experience";
            else if (modifier_type_converted == "Experience (Muscle)")
                modifier_type_converted = "Muscle Experience";
            else if (modifier_type_converted == "Experience (Mysticality)")
                modifier_type_converted = "Mysticality Experience";
            else if (modifier_type_converted == "Experience Percent (Moxie)")
                modifier_type_converted = "Moxie Experience Percent";
            else if (modifier_type_converted == "Experience Percent (Muscle)")
                modifier_type_converted = "Muscle Experience Percent";
            else if (modifier_type_converted == "Experience Percent (Mysticality)")
                modifier_type_converted = "Mysticality Experience Percent";
            else if (modifier_type_converted == "Mana Cost (stackable)")
                modifier_type_converted = "Stackable Mana Cost";
            else if (modifier_type_converted == "Familiar Weight (hidden)")
                modifier_type_converted = "Hidden Familiar Weight";
            else if (modifier_type_converted == "Meat Drop (sporadic)")
                modifier_type_converted = "Sporadic Meat Drop";
            else if (modifier_type_converted == "Item Drop (sporadic)")
                modifier_type_converted = "Sporadic Item Drop";
            
            modifier_type_converted = modifier_type_converted.to_lower_case();
            __modifiers_for_effect[e][modifier_type_converted] = true;
            __effects_for_modifiers[modifier_type_converted][e] = true;
            if (modifier_value.contains_text("[") || modifier_value.contains_text("\""))
            	__effect_contains_non_constant_modifiers[e] = true;
            if (modifier_type_converted ≈ "muscle percent")
            {
            	__modifiers_for_effect[e]["muscle"] = true;
            	__effects_for_modifiers["muscle"][e] = true;
            }
            if (modifier_type_converted ≈ "mysticality percent")
            {
                __modifiers_for_effect[e]["mysticality"] = true;
                __effects_for_modifiers["mysticality"][e] = true;
            }
            if (modifier_type_converted ≈ "moxie percent")
            {
                __modifiers_for_effect[e]["moxie"] = true;
                __effects_for_modifiers["moxie"][e] = true;
            }
            
            /*if (e.numeric_modifier(modifier_type_converted) == 0.0 && modifier_value.length() > 0 && e.string_modifier(modifier_type_converted) == "")// && !__effect_contains_non_constant_modifiers[e])
            {
            	//print_html("No match on \"" + modifier_type_converted + "\"");
                print_html("No match on \"" + modifier_type_converted + "\" for " + e + " (" + string_modifiers + ")");
            }*/
            //modifier_types[modifier_type] = true;
            //modifier_values[modifier_value] = true;
        }
        //return;
	}
	/*print_html("Types:");
	foreach type in modifier_types
	{
		print_html(type);
	}
	print_html("");
    print_html("Values:");
    foreach value in modifier_values
    {
        print_html(value);
    }*/
}
initialiseModifiers();

initialiseGenieEffectDescriptions();
buffer genieGenerateEffectDescription(effect e)
{
	if (__genie_saved_effect_descriptions contains e) return __genie_saved_effect_descriptions[e];
	buffer out;
	boolean first = true;
	//foreach modifier in __numeric_modifier_names
	foreach modifier in __modifiers_for_effect[e]
	{
		float v = e.numeric_modifier(modifier);
		if (v == 0.0) continue;
		if (first)
		{
			first = false;
		}
		else
		{
			out.append(",");
		}
		if (v > 0)
			out.append("+");
		out.append(v.round());
		if (__effect_descriptions_modifier_is_percent[modifier] || modifier.contains_text("Percent"))
			out.append("%");
		out.append(" ");
		if (__effect_descriptions_modifier_short_description_mapping contains modifier)
			out.append(__effect_descriptions_modifier_short_description_mapping[modifier]);
		else
		{
			string description = modifier;
			if (description.contains_text(" Percent"))
				description = description.replace_string(" Percent", "");
			if (description.contains_text("Mysticality"))
				description = description.replace_string("Mysticality", " Myst");
			if (description.contains_text("Maximum "))
				description = description.replace_string("Maximum ", "");
			if (description.contains_text("Resistance"))
				description = description.replace_string("Resistance", "res");
			if (description.contains_text("Damage"))
				description = description.replace_string("Damage", "dmg");
			
			description = description.to_lower_case();
			out.append(description);
		}
	}
	if (!__effect_contains_non_constant_modifiers[e]) //always regenerate dynamic effects
		__genie_saved_effect_descriptions[e] = out;
	return out;
}

/////////////

// Stolen from Ezandora's genie relay script, maybe mafia coders could incorporate a better way to check this (like effect.isWishable, effect.isAvatarPotion, things like that)
boolean [effect] __genie_invalid_effects = $effects[jukebox hero,Juicy Boost,Meteor Showered,Steely-eyed squint,Blue Eyed Devil,Cereal Killer,Nearly All-Natural,Amazing,Throwing some shade,A rose by any other material,Gaze of the Gazelle,East of Eaten,Robot Friends,Smart Drunk,Margamergency,Pajama Party,Rumpel-Pumped,Song of Battle,Song of Solitude,Buy!\  Sell!\  Buy!\  Sell!,eldritch attunement,The Inquisitor's unknown effect,Filthworm Drone Stench,Filthworm Guard Stench,Filthworm Larva Stench,Green Peace,Red Menace,Video... Games?,things man was not meant to eat,Whitesloshed,thrice-cursed,bendin' hell,Synthesis: Hot,Synthesis: Cold,Synthesis: Pungent,Synthesis: Scary,Synthesis: Greasy,Synthesis: Strong,Synthesis: Smart,Synthesis: Cool,Synthesis: Hardy,Synthesis: Energy,Synthesis: Greed,Synthesis: Collection,Synthesis: Movement,Synthesis: Learning,Synthesis: Style,The Good Salmonella,Giant Growth,Lovebotamy,Open Heart Surgery,Wandering Eye Surgery,gar-ish,Puissant Pressure,Perspicacious Pressure,Pulchritudinous Pressure,It's Good To Be Royal!,The Fire Inside,Puzzle Champ,The Royal We,Hotform,Coldform,Sleazeform,Spookyform,Stenchform,A Hole in the World,Bored With Explosions,thanksgetting,Barrel of Laughs,Beer Barrel Polka,Superdrifting,Covetin' Drunk,All Wound Up,Driving Observantly,Driving Waterproofly,Bow-Legged Swagger,First Blood Kiwi,You've Got a Stew Going!,Shepherd's Breath,Of Course It Looks Great,Doing The Hustle,Fortune of the Wheel,Shelter of Shed,Hot Sweat,Cold Sweat,Rank Sweat,Black Sweat,Flop Sweat,Mark of Candy Cain,Black Day,What Are The Odds!?,Dancin' Drunk, School Spirited,Muffled,Sour Grapes,Song of Fortune,Pork Barrel,Ashen,Brooding,Purple Tongue,Green Tongue,Orange Tongue,Red Tongue,Blue Tongue,Black Tongue,Cupcake of Choice,The Cupcake of Wrath,Shiny Happy Cupcake,Your Cupcake Senses Are Tingling,Tiny Bubbles in the Cupcake,Broken Heart,Fiery Heart,Cold Hearted,Sweet Heart,Withered Heart,Lustful Heart,Pasta Eyeball,Cowlick,It's Ridiculous,Dangerous Zone Song,Tiffany's Breakfast,Flashy Dance Song,Pet Shop Song,Dark Orchestral Song,Bounty of Renenutet,Octolus Gift,Magnetized Ears,Lucky Struck,Drunk and Avuncular,Ministrations in the Dark,Record Hunger,SuperStar,Everything Looks Blue,Everything Looks Red,Everything Looks Yellow,Snow Fortified,Bubble Vision,High-Falutin',Song of Accompaniment,Song of Cockiness,Song of the Glorious Lunch,Song of the Southern Turtle,Song of Sauce,Song of Bravado,Song of Slowness,Song of Starch,Song of the North,It's a Good Life!,I'll Have the Soup,Why So Serious?,&quot;The Disease&quot;,Unmuffled,Overconfident,Shrieking Weasel,Biker Swagger,Punchable Face,ChibiChanged&trade;,Avatar of She-Who-Was,Behind the Green Curtain,Industrially Frosted,Mer-kinkiness,Hotcaked,[1553]Slicked-Back Do,Eggscitingly Colorful,Party on Your Skin,Blessing of the Spaghetto,Force of Mayo Be With You,Ear Winds,Desenfantasmada,Skull Full of Hot Chocolate,Hide of Sobek,Wassailing You,Barrel Chested,Mimeoflage,Tainted Love Potion,Avatar of the Storm Tortoise,Fortunate\, Son,Avatar of the War Snapper,Faerie Fortune,Heroic Fortune,Fantasy Faerie Blessing,Brewed Up,Poison For Blood,Fantastical Health,Spirit of Galactic Unity,Inner Elf,The Best Hair You've Ever Had,Hardened Sweatshirt,Yeast-Hungry,More Mansquito Than Man,Spiced Up,Warlock\, Warstock\, and Warbarrel,Tomes of Opportunity,Temporary Blindness,Rolando's Rondo of Resisto,Shielded Unit,Mist Form]; //'
//Works: Driving Wastefully, Driving Stealthily, rest untested
// Seems to not work: gunther than thou

boolean [string] __genie_invalid_effect_strings = $strings[Double Negavision, Gettin' the Goods,Moose-Warmed Belly,Crimbeau'd,Haunted Liver,Bats Form]; //' because errors on older versions

boolean effectIsAvatarPotion(effect e)
{
	return e.string_modifier("Avatar") != "";
}

effect [int] GetPossibleEffects()
{
	effect [int] result;

	boolean [effect] additional_invalid_effects;
	foreach s in __genie_invalid_effect_strings
	{
		effect e = s.to_effect();
		if (e != $effect[none])
		{
			additional_invalid_effects[e] = true;
		}
	}

	foreach ef in $effects[]
	{
		if (ef.attributes.contains_text("nohookah")) continue;
		if (__genie_invalid_effects contains ef) continue;
		if (additional_invalid_effects contains ef) continue;
		if (ef.effectIsAvatarPotion()) continue;
		
		result[to_int(ef)] = ef;
	}

	return result;
}

// TODO COMPLETE THESE LISTS https://docs.google.com/spreadsheets/d/1pcwFNLGE-q4T7BlpaemLgzCgj_FKdUgOGHxVgUUlkTs/edit#gid=0
//Ones that the spreadsheet doesn't have:
//Noncom: PRED -10%, INKE -10%
//Sleaze: PAI* is typically superior to FIF

//Possible feature requests:
//-only inserting as many letters as necessary, CER works just as well as CERT for Certainty
//-statgain and adv should possibly check for Pizza Lover [write as 9 advs +3, double statgain]

string [effect] _itemEffects = {
	$effect[Certainty]: "cer",
	$effect[Thanksgot]: "than",
	$effect[Heightened Senses]: "heig",
	$effect[Aykrophobia]: "ay",
	$effect[Let's Go Shopping!]: "let",
};

string [effect] _meatEffects = {
	$effect[Sinuses For Miles]: "sinu",
	$effect[Thanksgot]: "than",
	$effect[Let's Go Shopping!]: "let",
	$effect[Heightened Senses]: "heig",
	$effect[Low on the Hog]: "low",
	$effect[Cravin' for a Ravin']: "crav",
	$effect[Leisurely Amblin']: "lei",
};

string [effect] _mlEffects = {
	$effect[Polonoia]: "polo",
	$effect[Truthful]: "trut",
	$effect[Aykrophobia]: "ay",
	$effect[Koyaaniskumquatsi]: "koy",
};

string [effect] _initEffects = {
	$effect[Hare-o-dynamic]: "hare",
	$effect[Ruby-ous]: "rub",
};

string [effect] _statEffects = {
	$effect[HGH-charged]: "hg",
	$effect[Different Way of Seeing Things]: "dif",
};

string [effect] _dmgEffects = {
	$effect[Cruisin' for a Bruisin']: "crui",
	$effect[Drunk With Power]: "drun",
};

string [effect] _elementEffects = {
	$effect[Dirty Pear]: "dirt",
	$effect[Painted-On Bikini]: "pai",
	$effect[Fifty Ways to Bereave Your Lover]: "fif",
	$effect[Gutterminded]: "gutt",
	$effect[Cholestoriffic]: "chol",
	$effect[Yeah, It's Just Gasoline]: "yea",
	$effect[Staying Frosty]: "stay",
	$effect[Bored Stiff]: "bor",
	$effect[Sewer-Drenched]: "sew",
};

string [effect] _combatEffects = {
	$effect[Disquiet Riot]: "disq",
	$effect[Taunt of Horus]: "taun",
	$effect[Waking the Dead]: "waki",
	$effect[Lion in Ambush]: "lio",
	$effect[Inked Well]: "inke",
	$effect[Predjudicetidigitation]: "pred",
};

string [effect] _questEffects = {
	$effect[Ultrahydrated]: "ult",
	$effect[Stone-Faced]: "ston",
};

string [effect] _famEffects = {
	$effect[Whole Latte Love]: "who",
	$effect[Down With Chow]: "dow",
	$effect[Chorale of Companionship]: "chor",
	$effect[Bureaucratized]: "bure",
};

string [effect] _moreEffects = {
	$effect[One Very Clear Eye]: "one",
	$effect[Action]: "acti",
	$effect[Adrenaline Rush]: "adre",
	$effect[Annoyed by Threats]: "anno",
	$effect[Army of One]: "army",
	$effect[Arresistible]: "arre",
	$effect[Assaulted with Pepper]: "assa",
	$effect[Bananas!]: "bana",
	$effect[Banono]: "bano",
	$effect[Bent Knees]: "bent",
	$effect[Beta Carotene Overdose]: "beta",
	$effect[Blade Rolling]: "blad",
	$effect[Blinking Belly]: "blin",
	$effect[Booooooze]: "booo",
	$effect[Boschface]: "bosc",
	$effect[Broberry Brotality]: "brob",
	$effect[Brocolate Brostidigitation]: "broc",
	$effect[Buff as a Baobab]: "buff",
	$effect[Carlweather's Cantata of Confrontation]: "carl",
	$effect[Category]: "cate",
	$effect[Cautious Prowl]: "caut",
	$effect[Ceaseless Snarling]: "ceas",
	$effect[Chihuahua Underfoot]: "chih",
	$effect[Citronella Armpits]: "citr",
	$effect[Cloak of Shadows]: "cloa",
	$effect[Clyde's Blessing]: "clyd",
	$effect[Crotchety, Pining]: "crot",
	$effect[Crying, Dying]: "cryi",
	$effect[Dexteri Tea]: "dext",
	$effect[Earthen Fist]: "eart",
	$effect[Extended Toes]: "exte",
	$effect[Feroci Tea]: "fero",
	$effect[Fightin' Drunk]: "figh",
	$effect[Flyin' Drunk]: "flyi",
	$effect[Fresh Scent]: "fres",
	$effect[Frown]: "frow",
	$effect[Glasshole]: "glas",
	$effect[Goldentongue]: "gold",
	$effect[Grimace]: "grim",
	$effect[Gristlesphere]: "gris",
	$effect[Grrrrrrreat!]: "grrr",
	$effect[Hagnk's Gratitude]: "hagn",
	$effect[Hiding in Plain Sight]: "hidi",
	$effect[Hulkien]: "hulk",
	$effect[Incredibly Hulking]: "incr",
	$effect[Inky Camouflage]: "inky",
	$effect[Intuition of the God Lobster]: "intu",
	$effect[Irritabili Tea]: "irri",
	$effect[Jokin' Drunk]: "joki",
	$effect[Keep Free Hate in your Heart]: "keep",
	$effect[Kicked in the Sinuses]: "kick",
	$effect[Knightlife]: "knig",
	$effect[Koyaaniskumquatsi]: "koya",
	$effect[Lapdog]: "lapd",
	$effect[Larger]: "larg",
	$effect[License to Punch]: "lice",
	$effect[Lifted Spirits]: "lift",
	$effect[Limber as Mortimer]: "limb",
	$effect[Manbait]: "manb",
	$effect[Marbles in Your Mouth]: "marb",
	$effect[Marco Polarity]: "marc",
	$effect[Meadulla Oblongota]: "mead",
	$effect[Meet the Meat]: "meet",
	$effect[Melancholy Burden]: "mela",
	$effect[Mighty Shout]: "migh",
	$effect[Minerva's Zen]: "mine",
	$effect[Mitre Cut]: "mitr",
	$effect[Morninja]: "morn",
	$effect[Motion]: "moti",
	$effect[Nasty, Nasty Breath]: "nast",
	$effect[Obscuri Tea]: "obsc",
	$effect[Orcmouth]: "orcm",
	$effect[Para-lyzed Jaw]: "para",
	$effect[Perfect Hair]: "perf",
	$effect[Pharmaceutically Cool]: "phar",
	$effect[Phoenix, Right?]: "phoe",
	$effect[Phorcefullness]: "phor",
	$effect[Prince of Seaside Town]: "prin",
	$effect[Proficient Pressure]: "prof",
	$effect[Purity of Spirit]: "puri",
	$effect[Racing!]: "raci",
	$effect[Rational Thought]: "rati",
	$effect['Roids of the Rhinoceros]: "'",
	$effect[Ruby-ous]: "ruby",
	$effect[Sacr&eacute; Mental]: "sacr",
	$effect[Salsa Satanica]: "sals",
	$effect[Screaming! \ SCREAMING! \ AAAAAAAH!]: "scre",
	$effect[Sensation]: "sens",
	$effect[Simulation Stimulation]: "simu",
	$effect[Sneaky Serpentine Subtlety]: "snea",
	$effect[stats.enq]: "stat",
	$effect[Stogied]: "stog",
	$effect[Sucrose-Colored Glasses]: "sucr",
	$effect[Tapped In]: "tapp",
	$effect[That's Just Cloud-Talk, Man]: "that",
	$effect[Thaumodynamic]: "thau",
	$effect[Towering Strength]: "towe",
	$effect[Triple-Sized]: "trip",
	$effect[Trivia Master]: "triv",
	$effect[Unbarking Dogs]: "unba",
	$effect[Uncucumbered]: "uncu",
	$effect[Unpopular]: "unpo",
	$effect[Void Between the Stars]: "void",
	$effect[WAKKA WAKKA WAKKA]: "wakk",
	$effect[Zomg WTF]: "zomg",
};

///////////////////// END EFFECTS

///////////////////// SPECIAL PIZZA

item [int] _familiarHatchlings;

string [int] CheckItemSpecialPizza(item it)
{
	int currIdx = 0;

	if (_familiarHatchlings.count() == 0)
	{
		foreach fam in $familiars[]
		{
			_familiarHatchlings[currIdx++] = fam.hatchling;
		}
	}

	boolean isFamHatch = to_slot(it) == $slot[familiar];
	foreach idx, famItem in _familiarHatchlings
	{
		if (it == famItem)
		{
			isFamHatch = true;
			break;
		}
	}

	string [int] special;
	currIdx = 0;

	if (it.combat)
	{
		special[currIdx++] = "combat";
	}


	if (isFamHatch)
	{
		special[currIdx++] = "familiar";
	}

	if (it.spleen > 0)
	{
		special[currIdx++] = "spleen";
	}

	string itemName = it.name.to_lower_case();

	if (itemName.contains_text("green") || itemName.contains_text("luck"))
	{
		special[currIdx++] = "clover";
	}

	if (itemName.contains_text("milk") || itemName.contains_text("cheese"))
	{
		special[currIdx++] = "cheese";
	}

	if (itemName.contains_text("star") || itemName.contains_text("dot"))
	{
		special[currIdx++] = "star";
	}

	if (itemName.contains_text("cloak"))
	{
		special[currIdx++] = "mimic";
	}

	return special;
}

///////////////////// END SPECIAL PIZZA

///////////////////////////////// PRO

string ElementNameFor(int index)
{
	switch(index)
	{
		case 0:
			return "Crust";
		case 1:
			return "Sauce";
		case 2:
			return "Cheese";
		case 3:
			return "Topping";
	}

	return "Element " + index;
}

void AppendIngredientRow(buffer result, int itemIndex, string [int] data)
{
		result.append("<tr id=\"item-row-" + itemIndex + "\">");
			result.append("<td style=\"font-weight:bold;text-align:right;\"> " + ElementNameFor(itemIndex) + "</td>");
			result.append("<td><select id=\"select-"+ itemIndex + "\" style=\"width: 100%;\">");
				foreach key, value in data
				{
					result.append(value);
				}
			result.append("</select></td>");
			result.append("<td><input type=\"text\" id=\"letter-" + itemIndex + "\" minlength=\"0\" maxlength=\"1\" size=\"2\"></td>");
			result.append("<td><input type=\"text\" id=\"filter-" + itemIndex + "\"></td>");
		result.append("</tr>");
		result.append("<tr>");
			result.append("<td/>");
			result.append("<td/>");
			result.append("<td/>");
			result.append("<td>");
				result.append("<button type=\"button\" class=\"button\" style=\"font-size:x-small;\" id=\"sort-alpha-" + itemIndex + "\">Alpha ^</button>");
				result.append("<button type=\"button\" class=\"button\" style=\"font-size:x-small;\" id=\"sort-price-" + itemIndex + "\">Price</button>");
				result.append("<button type=\"button\" class=\"button\" style=\"font-size:x-small;\" id=\"sort-letter-" + itemIndex + "\">Letters</button>");
				result.append("<button type=\"button\" class=\"button\" style=\"font-size:x-small;\" id=\"sort-amount-" + itemIndex + "\">Amount</button>");
			result.append("</td>");
		result.append("</tr>");
}

void AppendIngredientsTable(buffer result, string [int] data)
{
	result.append("<table>");

		result.append("<thead>");
		result.append("<tr>");
			result.append("<th/>");
			result.append("<th>Ingredient</th>");
			result.append("<th>Letter</th>");
			result.append("<th>Filter/Sort</th>");
		result.append("</tr>");
		result.append("</thead>");

		result.append("<tbody>");

		AppendIngredientRow(result, 0, data);
		AppendIngredientRow(result, 1, data);
		AppendIngredientRow(result, 2, data);
		AppendIngredientRow(result, 3, data);

		result.append("</tbody>");

	result.append("</table>");
}

string EffectFriendlyName(effect e)
{
	string effName = e.to_string();

	if (effName.char_at(0) == "[")
	{
		int nameStart = effName.index_of("]") + 1;
		effName = effName.substring(nameStart, effName.length()) + effName.substring(0, nameStart);
	}

	return effName;
}

void AddAllEffects(buffer result)
{
	effect [int] effects = GetPossibleEffects();

	sort effects by (EffectFriendlyName(value).to_lower_case());
	
	foreach id, eff in effects
	{
		string effName = EffectFriendlyName(eff);
		string effElement = "<option id=\"" + to_int(eff) + "\" descId=\""+ eff.descid + "\">" + effName + "</option>";
		if (effElement.contains_text("$"))
		{
			effElement = effElement.replace_string("$", "\\$");
		}
		result.append(effElement);
	}
}

void AppendInfoPanel(buffer result)
{
	result.append("<td><div style=\"margin-left: 20px\">");

		result.append("<p>Adventures: <b id=\"valueAdv\">999</b><br><em>");
		result.append("<span style=\"font-size:small\"><span id=\"valueLetters\">999</span> letters</span><br>");
		result.append("<span style=\"font-size:x-small\"><span id=\"valueLettersLeftToUp\">999</span> letters for next adventure increase</span><br>");
		result.append("<span style=\"font-size:x-small\"><span id=\"valueLettersLeftToMax\">999</span> letters for 15 adv (max)</span>");
		result.append("</em></p>");

		result.append("<p>Effect turns: <b id=\"valueTurns\">999</b><br><em>");
		result.append("<span style=\"font-size:small\"><span id=\"valueMeat\">99999</span> total auto-sell</span><br>");
		result.append("<span style=\"font-size:x-small\"><span id=\"valueMeatLeftToUp\">9999</span> for next turn increase</span><br>");
		result.append("<span style=\"font-size:x-small\"><span id=\"valueMeatLeftToMax\">9999</span> for max turns</span>");
		result.append("</em></p>");

		result.append("<p>Stat gains:<br><em>");
		result.append("<span style=\"font-size:small\"><span id=\"valueMus\">99999</span> mus substats</span><br>");
		result.append("<span style=\"font-size:small\"><span id=\"valueMox\">9999</span> mox substats</span><br>");
		result.append("</em></p>");

		result.append("<p><em><b>Special pizza: <big id=\"specialPizza\"><span style=\"color:Tomato;\">spleen star combat familiar</span></big></b></em></p>");
	
	result.append("</div></td>");
}

void AppendEffectsPanel(buffer result)
{
	result.append("<td style=\"vertical-align: top;\"> <div style=\"width: 100%;\"><center>");

		result.append("<div style=\"width: 100%;\">");
			result.append("<button type=\"button\" class=\"button\" style=\"\" id=\"fill-letters\">Fill ^</button><br>");
			result.append("<select id=\"all-effects\">");
				AddAllEffects(result);
			result.append("</select><button type=\"button\" class=\"button\" id=\"effect-help\">?</button><br><br>");

			result.append("<div id=\"possible-effects\"> Possible effects:<br><select id=\"filtered-effects\" size=\"5\" style=\"width: 100%;\">");
				AddAllEffects(result);
			result.append("</select></div>");

		result.append("</div>");

	result.append("</center></div></td>");
}

void AppendOven(buffer result)
{
	result.append("<td><div style=\"background-image: url(/images/otherimages/horadricoven_large.gif); min-height: 230px; width: 210px; position: relative; margin-left: 30px; background-repeat: no-repeat; background-position: left top;\">");

		result.append("<img id=\"img-0\" title=\"" + ElementNameFor(0) + "\" src=\"/images/itemimages/8ball.gif\" style=\"position: absolute; top: 32px; left: 40px;\">");
		result.append("<img id=\"img-1\" title=\"" + ElementNameFor(1) + "\" src=\"/images/itemimages/8ball.gif\" style=\"position: absolute; top: 32px; left: 92px;\">");
		result.append("<img id=\"img-2\" title=\"" + ElementNameFor(2) + "\" src=\"/images/itemimages/8ball.gif\" style=\"position: absolute; top: 82px; left: 40px;\">");
		result.append("<img id=\"img-3\" title=\"" + ElementNameFor(3) + "\" src=\"/images/itemimages/8ball.gif\" style=\"position: absolute; top: 82px; left: 92px;\">");

		result.append("<button type=\"button\" class=\"button\" style=\"position: absolute; top: 200px; left: 40px;\" id=\"bake-pizza\">Bake Pizza</button>");

	result.append("</div></td>");
}

void AppendOverview(buffer result, string [int] data)
{
	result.append("<div><table style=\"\"><tr>");

		AppendOven(result);
		AppendEffectsPanel(result);
		AppendInfoPanel(result);

	result.append("</tr></table></div>");
}

void AppendForm(buffer result, string [int] data)
{
	result.append("<form method=\"post\" action=\"campground.php\" id=\"pizza-form\">");
	result.append("<input type=\"hidden\" value=\"makepizza\" name=\"action\" />");
	result.append("<input type=\"hidden\" value=\"\" id=\"pizza\" name=\"pizza\" />");
	result.append("<input type=\"hidden\" value=\"\" id=\"pizzaAdv\" name=\"pizzaAdv\" />");
	result.append("<input type=\"hidden\" value=\"\" id=\"pizzaTurn\" name=\"pizzaTurn\" />");
	result.append("<input type=\"hidden\" value=\"\" id=\"pizzaSpecial\" name=\"pizzaSpecial\" />");
	result.append("<input type=\"hidden\" value=\"\" id=\"pizzaEffect\" name=\"pizzaEffect\" />");
	result.append("</form>");
}

void AppendScript(buffer result, string [int] data)
{
	result.append("<script src=\"PizzaCubeGUI2.js\"></script>");
}

int _menuEffectIndex = 0;

void AppendMenuEffects(buffer result, string [effect] effectList, string id)
{
	result.append("<div id='" + id + "' style='display: none;'>"); // Change this property to block when hidding, showing stuff!
	result.append("<table style='width:100%;'>");
	int col = 0;
	foreach eff, initials in effectList
	{
		if (col == 0)
		{
			result.append("<tr>");
		}

		result.append("<td style='width:33%;'>");
		result.append("<button class='button' title='" + eff + "' id='menu-item-" + _menuEffectIndex++ + "' value='" + initials + "'>");
		result.append("<img src='/images/itemimages/" + eff.image + "' style='vertical-align: middle;' /></button> ");
		result.append(eff);
		result.append("<button class='button' style='border-style:none;font-size:10px;vertical-align:super;' onclick='eff(\"" + eff.descid + "\");'>?</button>");
		result.append("<br><div style='font-style:italic;font-size:small;'>");
		result.append(genieGenerateEffectDescription(eff));
		result.append("<div></td>");
		col++;

		if (col == 3)
		{
			col = 0;
			result.append("</tr>");
		}
	}

	if (col != 0 && effectList.length() > 0)
	{
		result.append("</tr>");
	}

	result.append("</table></div>");
}

void AppendMenu(buffer result)
{
	result.append("<link href='https://fonts.googleapis.com/css?family=Alex Brush' rel='stylesheet'>");
	result.append("<p style=\"font-family:'Alex Brush';font-size:32px;margin-left:60px\">Menu</p>");
	result.append("<button type=\"toggle\" class=\"button\" id=\"carte-item\" value=\"true\">Item</button> ");
	result.append("<button type=\"button\" class=\"button\" id=\"carte-meat\" >Meat</button> ");
	result.append("<button type=\"button\" class=\"button\" id=\"carte-ml\" >ML</button> ");
	result.append("<button type=\"button\" class=\"button\" id=\"carte-init\" >Init</button> ");
	result.append("<button type=\"button\" class=\"button\" id=\"carte-stat\" >Stat</button> ");
	result.append("<button type=\"button\" class=\"button\" id=\"carte-dmg\" >Dmg</button> ");
	result.append("<button type=\"button\" class=\"button\" id=\"carte-ele\" >Elemental Dmg</button> ");
	result.append("<button type=\"button\" class=\"button\" id=\"carte-combat\" >Combat Freq</button> ");
	result.append("<button type=\"button\" class=\"button\" id=\"carte-quest\" >Questing</button> ");
	result.append("<button type=\"button\" class=\"button\" id=\"carte-fam\" >Familiar</button> ");
	result.append("<button type=\"button\" class=\"button\" id=\"carte-more\" >More</button> ");
	result.append("<br><br>");

	_menuEffectIndex = 0;

	AppendMenuEffects(result, _itemEffects, "menu-item");
	AppendMenuEffects(result, _meatEffects, "menu-meat");
	AppendMenuEffects(result, _mlEffects, "menu-ml");
	AppendMenuEffects(result, _initEffects, "menu-init");
	AppendMenuEffects(result, _statEffects, "menu-stat");
	AppendMenuEffects(result, _dmgEffects, "menu-dmg");
	AppendMenuEffects(result, _elementEffects, "menu-ele");
	AppendMenuEffects(result, _combatEffects, "menu-combat");
	AppendMenuEffects(result, _questEffects, "menu-quest");
	AppendMenuEffects(result, _famEffects, "menu-fam");
	AppendMenuEffects(result, _moreEffects, "menu-more");

	result.append("<input type='hidden' id='menuEffectsCount' value='" + _menuEffectIndex + "'/>");
}

/// Main HTML Thing
buffer GenerateGUI(string [int] data)
{
	buffer result;
	result.append("<center><table style=\"width: 100%; margin-left:5px; margin-right:5px;\"><tbody><tr><td>");
	//result.append("<center>");

	AppendIngredientsTable(result, data);
	AppendOverview(result, data);
	AppendForm(result, data);
	AppendScript(result, data);
	AppendMenu(result);

	//result.append("</center>");
	result.append("</td></tr></tbody></table></center>");
	return result;
}

string [int] GetAvailableItems(buffer page)
{
	string [int] result;

	string itemExpression = "<option data-pic=\"(.+?)\" data-qty=\"(.+?)\" value=\"(.+?)\">(.*?) \\(.+?\\)<\/option>";

	matcher items = create_matcher(itemExpression, page);

	int index = 0;
	while (items.find())
	{
		string dataPic = items.group(1);
		string amount = items.group(2);
		int itemId = items.group(3).to_int();
		string itemName = items.group(4);

		item it = itemId.to_item();
		int sellPrice = it.autosell_price();
		int charLen = itemName.length();

		int full = it.fullness;
		int drunk = it.inebriety;

		string[int] specialPizza = CheckItemSpecialPizza(it);
		string innerData = "data-price=" + sellPrice + " data-len=" + charLen + " full=" + full + " drunk=" + drunk;

		string specialPizzaString;
		
		foreach id, eff in specialPizza
		{
			specialPizzaString += ", " + eff;
			innerData += " special" + id + "=" + eff;
		}

		string replacement = "<option data-pic=\"" + dataPic + "\" data-qty=\"" + amount +
			"\" " + innerData + " value=\"" + itemId + "\">" + itemName + "(" + amount + ") " +
			sellPrice + " Meat, " + charLen + " letters" + specialPizzaString + "</option>";

		result[index++] = replacement;
	}

	return result;
}

buffer GenerateFull(buffer gui)
{
	buffer result;
	result.append("<b>Diabolic Pizza Cube a la Carte</b></td></tr><tr><td style=\"padding: 5px; border: 1px solid " + get_property("defaultBorderColor") + ";\">");
	result.append(gui);
	result.append("<br><center>DISABLE_GUI</center></td></tr><tr><td height=4></td></tr></table><table");
	return result;
}

///////////////////////////////// END PRO

///////////////////////////////// BASIC

buffer ReplaceItems(buffer page)
{
	string ItemExpression = "<option data-pic=\"(.+?)\" data-qty=\"(.+?)\" value=\"(.+?)\">(.*?) \\(.+?\\)<\/option>";

	string ItemReplacementPre = "<option data-pic=\"$1\" data-qty=\"$2\" ";
	string ItemReplacementInner = " value=\"$3\">$4 \($2\) ";
	string ItemReplacementPos = "<\/option>";

	matcher items = create_matcher(ItemExpression, page);
	
	buffer out;
	
	while (items.find())
	{
		int itemId = items.group(3).to_int();
	
		item it = itemId.to_item();
		int sellPrice = it.autosell_price();
		int charLen = items.group(4).length();
		string[int] specialPizza = CheckItemSpecialPizza(it);
		string innerData = "data-price="+sellPrice+" data-len="+charLen;

		string specialPizzaString;
		
		foreach id, eff in specialPizza
		{
			specialPizzaString += ", " + eff;
			innerData += " special" + id + "=" + eff;
		}
		
		string replacement = ItemReplacementPre + innerData + ItemReplacementInner + 
			sellPrice + " Meat, " + 
			charLen + " letters" + specialPizzaString + ItemReplacementPos;
		
		items.append_replacement(out, replacement);
	}
	
	items.append_tail(out);
	
	return out;
}

buffer AddSorting(buffer page)
{
	string addPlace = "<input type=\"button\" value=\"Add\" class=\"button\" id=\"adding\" />";
	string replaced = "<input type=\"button\" value=\"Add\" class=\"button\" id=\"adding\" /><br>" +
					"<div align=\"right\">" +
					"Starts With: <input type=\"text\" id=\"firstLetterInput\" minlength=\"0\" maxlength=\"1\" size=\"2\">" +
					" Filter: <input type=\"text\" id=\"searchInput\"><br>" +
					"Sort: <button type=\"button\" class=\"button\" id=\"sort-alpha\"></button><button type=\"button\" class=\"button\" id=\"sort-price\"></button><button type=\"button\" class=\"button\" id=\"sort-letter\"></button><button type=\"button\" class=\"button\" id=\"sort-amount\"></button><br>" + 
					"</div><br>";

	matcher addButton = create_matcher(addPlace, page);

	buffer out;
	out.append(addButton.replace_first(replaced));
	return out;
}

buffer RepositionOven(buffer page)
{
	string ovenRegex = "<div id=\"pizzaingredients\" style=\"background-image: url\\(https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/horadricoven_large.gif\\); width:200px; height: 200px; position: relative; margin-left: 30px\">";
	string ovenReplacement = "<div id=\"pizzaingredients\" style=\"background-image: url(https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/horadricoven_large.gif); width:550px; position: relative; margin-left: 30px; background-repeat: no-repeat; background-position: left top;\">";

	matcher oven = create_matcher(ovenRegex, page);

	buffer out;
	out.append(oven.replace_first(ovenReplacement));
	return out;
}

buffer AddCustomText(buffer page)
{
	string placeToAdd = "</div><input type=\"hidden\" value=\"\" id=\"pizza\" name=\"pizza\" />";
	string textReplacement = "<div id=\"CubeInfoBox\" style=\"width:350px; margin-left:230px; overflow:hidden; text-align: left;\">"+
							"<script src=\"PizzaCubeGUI.js\"></script>"+"</div></div>"+
							"<input type=\"hidden\" value=\"\" id=\"pizza\" name=\"pizza\" />" +
							"<input type=\"hidden\" value=\"\" id=\"pizzaAdv\" name=\"pizzaAdv\" />" +
							"<input type=\"hidden\" value=\"\" id=\"pizzaTurn\" name=\"pizzaTurn\" />" +
							"<input type=\"hidden\" value=\"\" id=\"pizzaSpecial\" name=\"pizzaSpecial\" />" +
							"<input type=\"hidden\" value=\"\" id=\"pizzaEffect\" name=\"pizzaEffect\" />";

	matcher place = create_matcher(placeToAdd, page);

	buffer out;
	out.append(place.replace_first(textReplacement));
	return out;
}

buffer AddPossibleEffects(buffer page)
{
	string placeToAdd = "<input type=\"submit\" value=\"Bake Pizz";
	string replacementPre = "<select id=\"effectList\">";
	string effectList = "";
	string replacementPos = "</select><button type=\"button\" class=\"button\" id=\"effectHelp\">?</button><br><br><input type=\"submit\" value=\"Bake Pizz";
	
	effect [int] effects = GetPossibleEffects();
	
	sort effects by ("" + value);
	
	foreach id, eff in effects
	{
		effectList += "<option id=\"" + to_int(eff) + "\" descId=\""+ eff.descid + "\">"+eff+"</option>";
	}
	
	matcher place = create_matcher(placeToAdd, page);
	
	effectList = effectList.replace_string("$","\\$");
	
	buffer out;
	out.append(place.replace_first(replacementPre + effectList + replacementPos));
	return out;
}

buffer AddControlGui(buffer page, boolean tampered, boolean pro)
{
	string disableGui = "<button class='button' onclick=\"var form_data = 'relay_request=true&type=disable_gui'; var request = new XMLHttpRequest(); request.onreadystatechange = function() { if (request.readyState == 4) { if (request.status == 200) { location.reload() } } }; request.open('POST', 'PizzaCubeGUI.ash'); request.send(form_data);\" style=\"border-style:none;text-decoration:underline;cursor:pointer;\">Disable GUI</button><br>";
	string basicGui = "<button class='button' onclick=\"var form_data = 'relay_request=true&type=enable_basic_gui'; var request = new XMLHttpRequest(); request.onreadystatechange = function() { if (request.readyState == 4) { if (request.status == 200) { location.reload() } } }; request.open('POST', 'PizzaCubeGUI.ash'); request.send(form_data);\" style=\"border-style:none;text-decoration:underline;cursor:pointer;\">Enable Basic GUI</button><br>";
	string proGui = "<button class='button' onclick=\"var form_data = 'relay_request=true&type=enable_pro_gui'; var request = new XMLHttpRequest(); request.onreadystatechange = function() { if (request.readyState == 4) { if (request.status == 200) { location.reload() } } }; request.open('POST', 'PizzaCubeGUI.ash'); request.send(form_data);\" style=\"border-style:none;text-decoration:underline;cursor:pointer;\">Enable Pro GUI</button><br>";

	string final = (tampered ? disableGui : "") + ((!tampered || pro) ? basicGui : "") + ((!tampered || !pro) ? proGui : "");

	string search = "</td></tr></table></center></td></tr><tr><td height=4></td></tr></table><table";
	string replacePre = "</td></tr></table><p>";
	string replacePos = "</p></center></td></tr><tr><td height=4></td></tr></table><table";

	if (pro)
	{
		search = "DISABLE_GUI";
		replacePre = "";
		replacePos = "";
	}

	page.replace_string(search, replacePre + final + replacePos);
	return page;
}

buffer ParsePage(buffer page)
{
	buffer out = page;

	out = ReplaceItems(out);
	out = AddSorting(out);
	out = RepositionOven(out);
	out = AddCustomText(out);
	out = AddPossibleEffects(out);
	out = AddControlGui(out, true, false);

	return out;
}

///////////////////////////////// END BASIC

void handleBasicRelayRequest()
{
    buffer page_text = visit_url();
	buffer out_page_text = ParsePage(page_text);
	write(out_page_text);
}

void handleOffRelayRequest()
{
    buffer page_text = visit_url();
	buffer out_page_text = AddControlGui(page_text, false, false);
	write(out_page_text);
}

void handleProRelayRequest()
{
	buffer page_text = visit_url();

	string [int] avaliableItems = GetAvailableItems(page_text);

	buffer gui = GenerateGUI(avaliableItems);
	buffer replacement = GenerateFull(gui);

	matcher matchr = create_matcher("<b>Results:</b></td></tr><tr><td style=.padding: 5px; border: 1px [^;]*;.>(.*?)</td></tr><tr><td height=4></td></tr></table><table", page_text);

	string out_page_text = replace_first(matchr, replacement);
	buffer out;
	out = out.append(out_page_text);

	out = AddControlGui(out, true, true);

	write(out);
}

void handleFormRelayRequest()
{
	string [string] fields = form_fields();
	string type = fields["type"];

	if (type == "enable_basic_gui")
	{
		set_property("pizza_cube_gui_mode", "basic");
	}
	else if (type == "enable_pro_gui")
	{
		set_property("pizza_cube_gui_mode", "pro");
	}
	else
	{
		set_property("pizza_cube_gui_mode", "off");
	}

	string [string] response;
	write(response.to_json());
}

void runMain()
{
    if (form_fields()["relay_request"] != "")
    {
        handleFormRelayRequest();
        return;
    }

	string mode = get_property("pizza_cube_gui_mode");
	
	if (mode == "pro")
	{
		handleProRelayRequest();
		return;
	}

	if (mode == "basic")
	{
		handleBasicRelayRequest();
		return;
	}

	handleOffRelayRequest();
}

void main()
{
	runMain();
}