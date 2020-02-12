// DONE Inject JS 
// DONE Keep track of what's in the cube
// DONE Sum character lengths and sell prices
// DONE Show this data as it's updated
// DONE Parse the data and show final adv/effect turns
// DONE Improve style
// DONE Change item sorting: by price, by letter count, alphabetical
// DONE Show possible special pizzas
// DONE Show x meat for 1 more turn of effect instead of X meat for 100 turns
// DONE Show x letters for next adventure
// DONE Better layout, adapt to size of frame, unhardcode pixel sizes
// DONE List, predict effects

// TODO Parse to possible effects

// TODO Enable/disable

// TODO Add bake log with pizza info
// TODO Filter out letters for choosing the effect
// TODO PRO Remember pizza you already baked or some other way of favoriting them and make them again with one click

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

// TODO
effect [int] GetPossibleEffects()
{
	effect [int] result;
	foreach ef in $effects[]
	{
		result[to_int(ef)] = ef;
	}
	return result;
}

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
	string replaced = "<input type=\"button\" value=\"Add\" class=\"button\" id=\"adding\" /><p align=\"right\">Sort: <button type=\"button\" class=\"button\" id=\"sort-alpha\"></button><button type=\"button\" class=\"button\" id=\"sort-price\"></button><button type=\"button\" class=\"button\" id=\"sort-letter\"></button></p>";

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
	string INSIDE_THE_BOX = "<script src=\"PizzaCubeGUI.js\"></script>";
	
	string placeToAdd = "</div><input type=\"hidden\" value=\"\" id=\"pizza\" name=\"pizza\" />";
	string textReplacement = "<div id=\"CubeInfoBox\" style=\"width:350px; margin-left:230px; overflow:hidden; text-align: left;\">"+INSIDE_THE_BOX+"</div></div><input type=\"hidden\" value=\"\" id=\"pizza\" name=\"pizza\" />";

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

buffer ParsePage(buffer page)
{
	buffer out = page;

	out = ReplaceItems(out);
	out = AddSorting(out);
	out = RepositionOven(out);
	out = AddCustomText(out);
	out = AddPossibleEffects(out);

	return out;
}

void handleRelayRequest()
{
    buffer page_text = visit_url();
	buffer out_page_text = ParsePage(page_text);
	write(out_page_text);
}

/*
https://docs.google.com/spreadsheets/d/1TWJvOVp8UpMOuEQMzWrBcfYnv2Egev3tBhq47fpHt9A/edit#gid=372450893

Military/Warlike/Violent
Combat Items

For Kids/ For Pets/ With a toy surprise	
Familiar hatchlings & familiar equips

with extra cheese	
"Milk" & "Cheese"

Fortunate/Lucky/Sneaky Pete's
"Green" & "Luck"

Cosmic/Galactic/Stellar/astral/space
"Star" & "Dot"

Fake	
"Cloak"

Medical/Drugged	
Spleen Item

Base Adv		Range of Character Sum
3				34		4
4				44		35
5				54		45
6				64		55
7				74		65
8				84		75
9				94		85
10				104		95
11				114		105
12				124		115
13				134		125
14				144		135
15				145+


It appears to be that duration is the rounded square of the autosell value of all four items,
 with a low of 5 and high of 100. There are some outliers in the data on Spicy Spading, but I'd chalk that up to transcription errors.


<html><head><script language=Javascript><!--if (parent.frames.length == -1) location.href="game.php";//--></script><script language=Javascript src="https://s3.amazonaws.com/images.kingdomofloathing.com/scripts/keybinds.min.2.js"></script><script language=Javascript src="https://s3.amazonaws.com/images.kingdomofloathing.com/scripts/window.20111231.js"></script><script language="javascript">function chatFocus(){if(top.chatpane.document.chatform.graf) top.chatpane.document.chatform.graf.focus();}if (typeof defaultBind != 'undefined') { defaultBind(47, 2, chatFocus); defaultBind(190, 2, chatFocus);defaultBind(191, 2, chatFocus); defaultBind(47, 8, chatFocus);defaultBind(190, 8, chatFocus); defaultBind(191, 8, chatFocus); }</script><script language="javascript"> function updateParseItem(iid, field, info) { var tbl = $('#ic'+iid); var data = parseItem(tbl); if (!data) return; data[field] = info; var out = []; for (i in data) { if (!data.hasOwnProperty(i)) continue; out.push(i+'='+data[i]); } tbl.attr('rel', out.join('&')); } function parseItem(tbl) { tbl = $(tbl); var rel = tbl.attr('rel'); var data = {}; if (!rel) return data; var parts = rel.split('&'); for (i in parts) { if (!parts.hasOwnProperty(i)) continue; var kv = parts[i].split('='); tbl.data(kv[0], kv[1]); data[kv[0]] = kv[1]; } return data; }</script><script language=Javascript src="https://s3.amazonaws.com/images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script><script type="text/javascript" src="https://s3.amazonaws.com/images.kingdomofloathing.com/scripts/pop_query.20130705.js"></script><script type="text/javascript" src="https://s3.amazonaws.com/images.kingdomofloathing.com/scripts/ircm.20161111.js"></script><script type="text/javascript">var tp = top;function pop_ircm_contents(i, some) { var contents = '', shown = 0, da = ' <a href="#" rel="?" class="small dojaxy">[some]</a> <a href="#" rel="', db = '" class="small dojaxy">[all]</a>', dc = '<div style="width:100%; padding-bottom: 3px;" rel="', dd = '<a href="#" rel="1" class="small dojaxy">['; one = 'one'; ss=some;if (i.d==1 && i.s>0) { shown++; contents += dc + 'sellstuff.php?action=sell&ajax=1&type=quant&whichitem%5B%5D=IID&howmany=NUM&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Auto-Sell ('+i.s+' meat):</b> '+dd+one+']</a>';if (ss) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.q==0) { shown++; contents += dc + 'inventory.php?action=closetpush&ajax=1&whichitem=IID&qty=NUM&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Closet:</b> '+dd+one+']</a>';if (ss) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.q==0 && i.g==0 && i.t==1) { shown++; contents += dc + 'managestore.php?action=additem&qty1=NUM&item1=IID&price1=&limit1=&ajax=1&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Stock in Mall:</b> '+dd+one+']</a>';if (ss) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.q==0) { shown++; contents += dc + 'managecollection.php?action=put&ajax=1&whichitem1=IID&howmany1=NUM&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Add to Display Case:</b> '+dd+one+']</a>';if (ss) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.q==0 && i.t==1) { shown++; contents += dc + 'clan_stash.php?action=addgoodies&ajax=1&item1=IID&qty1=NUM&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Contribute to Clan:</b> '+dd+one+']</a>';if (ss) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.q==0 && i.p==0 && i.u=="q" && i.d==1 && i.t==1) { shown++; contents += dc + 'craft.php?action=pulverize&ajax=1&smashitem=IID&qty=NUM&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Pulverize:</b> '+dd+one+']</a>';if (ss) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.u && i.u != "." && !i.ac) { shown++; contents += dc + 'inv_'+(i.u=="a"?"redir":(lab=(i.u=="u"?"use":(i.u=="e"?"eat":(i.u=="b"?"booze":(i.u=="s"?"spleen":"equip"))))))+'.php?ajax=1&whichitem=IID&itemquantity=NUM&quantity=NUM'+(i.u=="q"?"&action=equip":"")+'&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>'+ucfirst(unescape(i.ou ? i.ou.replace(/\+/g," ") : (lab=="booze"?"drink":lab)))+':</b> '+dd+one+']</a>';if (ss && i.u != 'q' && !(i.u=='u' && i.m==0)) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.u && i.u != "." && i.ac) { shown++; contents += dc + 'inv_equip.php?slot=1&ajax=1&whichitem=IID&action=equip&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Equip (slot 1):</b> '+dd+one+']</a>';if (ss && i.u != 'q' && !(i.u=='u' && i.m==0)) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.u && i.u != "." && i.ac) { shown++; contents += dc + 'inv_equip.php?slot=2&ajax=1&whichitem=IID&action=equip&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Equip (slot 2):</b> '+dd+one+']</a>';if (ss && i.u != 'q' && !(i.u=='u' && i.m==0)) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.u && i.u != "." && i.ac) { shown++; contents += dc + 'inv_equip.php?slot=3&ajax=1&whichitem=IID&action=equip&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Equip (slot 3):</b> '+dd+one+']</a>';if (ss && i.u != 'q' && !(i.u=='u' && i.m==0)) { contents += da + i.n + db;}contents += '</div>';} return [contents, shown];}tp=topvar todo = [];function nextAction() { var next_todo = todo.shift(); if (next_todo) { eval(next_todo); }}function dojax(dourl, afterFunc, hoverCaller, failureFunc, method, params) { $.ajax({ type: method || 'GET', url: dourl, cache: false, data: params || null, global: false, success: function (out) { nextAction(); if (out.match(/no\|/)) { var parts = out.split(/\|/); if (failureFunc) failureFunc(parts[1]); else if (window.dojaxFailure) window.dojaxFailure(parts[1]); else if (tp.chatpane.handleMessage) tp.chatpane.handleMessage({type: 'event', msg: 'Oops! Sorry, Dave, you appear to be ' + parts[1]}); else $('#ChatWindow').append('<font color="green">Oops! Sorry, Dave, you appear to be ' + parts[1] + '.</font><br />' + "\n"); return; } if (hoverCaller) { float_results(hoverCaller, out); if (afterFunc) { afterFunc(out); } return; }$(tp.mainpane.document).find("#effdiv").remove(); if(!window.dontscroll || (window.dontscroll && dontscroll==0)) { window.scroll(0,0);} var $eff = $(tp.mainpane.document).find('#effdiv'); if ($eff.length == 0) { var d = tp.mainpane.document.createElement('DIV'); d.id = 'effdiv'; var b = tp.mainpane.document.body; if ($('#content_').length > 0) { b = $('#content_ div:first')[0]; } b.insertBefore(d, b.firstChild); $eff = $(d); } $eff.find('a[name="effdivtop"]').remove().end() .prepend('<a name="effdivtop"></a><center>' + out + '</center>').css('display','block'); if (!window.dontscroll || (window.dontscroll && dontscroll==0)) { tp.mainpane.document.location = tp.mainpane.document.location + "#effdivtop"; } if (afterFunc) { afterFunc(out); } } });}</script><script type="text/javascript"> var timersfunc;jQuery(function (j) {j("area[href^='adventure.php'], a[href^='adventure.php'], a[href^='barrel.php?smash=']").click(timersfunc = function () {return confirm("You have a timer with 1 turn remaining. Click OK to adventure as you intended. Cancel if you want to change your mind."); });j("form[action='dungeon.php']").submit(timersfunc);});</script> <link rel="stylesheet" type="text/css" href="https://s3.amazonaws.com/images.kingdomofloathing.com/styles.20151006.css"><style type='text/css'>.faded { zoom: 1; filter: alpha(opacity=35); opacity: 0.35; -khtml-opacity: 0.35; -moz-opacity: 0.35;}</style><script language="Javascript" src="/basics.js"></script><link rel="stylesheet" href="/basics.1.css" /></head><body><centeR><table width=95% cellspacing=0 cellpadding=0><tr><td style="color: white;" align=center bgcolor=blue><b>Results:</b></td></tr><tr><td style="padding: 5px; border: 1px solid blue;"><center><table><tr><td><center>Your rickety workshed contains:<p><img style='vertical-align: middle' class=hand src='https://s3.amazonaws.com/images.kingdomofloathing.com/itemimages/horadricoven.gif' onclick='descitem(234341716)' alt="diabolic pizza cube" title="diabolic pizza cube"><b>diabolic pizza cube</b><form method="post" action="campground.php"><input type="hidden" value="makepizza" name="action" />Add Ingredient: <select id="pizzaoptions">
<option data-pic="jug" data-qty="1" value="2842">accidental cider (1)</option>
<option data-pic="bladder" data-qty="2" value="2056">adder bladder (2)</option>
<option data-pic="dinner" data-qty="2" value="1778">ancient frozen dinner (2)</option>
<option data-pic="condiment" data-qty="1" value="2841">antique packet of ketchup (1)</option>
<option data-pic="machinegun" data-qty="2" value="2684">armgun (2)</option>
<option data-pic="knife" data-qty="1" value="19">asparagus knife (1)</option>
<option data-pic="baseball" data-qty="1" value="181">baseball (1)</option>
<option data-pic="guano" data-qty="1" value="188">bat guano (1)</option>
<option data-pic="batwing" data-qty="2" value="183">bat wing (2)</option>
<option data-pic="pill2" data-qty="2" value="9703">beefy pill (2)</option>
<option data-pic="candy" data-qty="1" value="1962">Bit O' Ectoplasm (1)</option>
<option data-pic="compact" data-qty="1" value="7510">black eye shadow (1)</option>
<option data-pic="blackcake" data-qty="2" value="2342">black forest cake (2)</option>
<option data-pic="ham" data-qty="1" value="2343">black forest ham (1)</option>
<option data-pic="blacklabel" data-qty="1" value="7508">black label (1)</option>
<option data-pic="blackdye" data-qty="1" value="2059">Black No. 2 (1)</option>
<option data-pic="blackcheck" data-qty="2" value="2057">black pension check (2)</option>
<option data-pic="blpepper" data-qty="1" value="2341">black pepper (1)</option>
<option data-pic="blackbasket" data-qty="2" value="2058">black picnic basket (2)</option>
<option data-pic="bsnakeskin" data-qty="1" value="2055">black snake skin (1)</option>
<option data-pic="wine2" data-qty="1" value="2339">Blackfly Chardonnay (1)</option>
<option data-pic="pixel5" data-qty="2" value="463">blue pixel (2)</option>
<option data-pic="beerbottle" data-qty="1" value="1774">bottle of popskull (1)</option>
<option data-pic="bottle" data-qty="3" value="787">bottle of rum (3)</option>
<option data-pic="bottle" data-qty="1" value="1004">bottle of tequila (1)</option>
<option data-pic="bottle" data-qty="1" value="328">bottle of whiskey (1)</option>
<option data-pic="brokeskull" data-qty="1" value="741">broken skull (1)</option>
<option data-pic="librarycard" data-qty="1" value="4699">bus pass (1)</option>
<option data-pic="butterfly" data-qty="2" value="615">chaos butterfly (2)</option>
<option data-pic="core" data-qty="2" value="365">chrome ore (2)</option>
<option data-pic="napkin" data-qty="2" value="2956">cocktail napkin (2)</option>
<option data-pic="fragment" data-qty="12" value="589">cocoa eggshell fragment (12)</option>
<option data-pic="coconut" data-qty="2" value="1007">coconut shell (2)</option>
<option data-pic="demonskin" data-qty="2" value="2479">demon skin (2)</option>
<option data-pic="punkjacket" data-qty="1" value="9969">denim jacket (1)</option>
<option data-pic="meatstack" data-qty="4" value="258">dense meat stack (4)</option>
<option data-pic="dcane" data-qty="2" value="472">diamond-studded cane (2)</option>
<option data-pic="fudgesicle" data-qty="1" value="2843">dire fudgesicle (1)</option>
<option data-pic="discoball" data-qty="1" value="10">disco ball (1)</option>
<option data-pic="quillpen" data-qty="2" value="1957">disintegrating quill pen (2)</option>
<option data-pic="camera" data-qty="1" value="7266">disposable instant camera (1)</option>
<option data-pic="dorkglasses" data-qty="1" value="9954">dorky glasses (1)</option>
<option data-pic="pasta" data-qty="2" value="304">dry noodles (2)</option>
<option data-pic="scale1" data-qty="2" value="3486">dull fish scale (2)</option>
<option data-pic="electronicskit" data-qty="2" value="9952">electronics kit (2)</option>
<option data-pic="junglefruit" data-qty="1" value="6724">exotic jungle fruit (1)</option>
<option data-pic="mittens" data-qty="1" value="399">eXtreme mittens (1)</option>
<option data-pic="scarf" data-qty="1" value="355">eXtreme scarf (1)</option>
<option data-pic="gascan" data-qty="3" value="9947">gas can (3)</option>
<option data-pic="ricepeeler" data-qty="1" value="6280">giant artisanal rice peeler (1)</option>
<option data-pic="giantfork" data-qty="1" value="1151">giant discarded plastic fork (1)</option>
<option data-pic="ringa" data-qty="1" value="1351">giant pinky ring (1)</option>
<option data-pic="safetypin" data-qty="1" value="6292">giant safety pin (1)</option>
<option data-pic="glarkcable" data-qty="1" value="7246">glark cable (1)</option>
<option data-pic="grapes" data-qty="2" value="358">gr8ps (2)</option>
<option data-pic="sandgrain" data-qty="8" value="10259">grain of sand (8)</option>
<option data-pic="pixel4" data-qty="2" value="462">green pixel (2)</option>
<option data-pic="cube" data-qty="2" value="476">hellion cube (2)</option>
<option data-pic="turtle" data-qty="1" value="3">helmet turtle (1)</option>
<option data-pic="hollanhelm" data-qty="1" value="4719">Hollandaise helmet (1)</option>
<option data-pic="hotblade" data-qty="1" value="350">hot katana blade (1)</option>
<option data-pic="hotplate" data-qty="1" value="4665">hot plate (1)</option>
<option data-pic="batwing" data-qty="9" value="471">hot wing (9)</option>
<option data-pic="cannedair" data-qty="5" value="4698">imp air (5)</option>
<option data-pic="beer" data-qty="10" value="470">Imp Ale (10)</option>
<option data-pic="rankring2" data-qty="1" value="4666">imp unity ring (1)</option>
<option data-pic="inkwell" data-qty="2" value="1958">inkwell (2)</option>
<option data-pic="deadbootlet" data-qty="3" value="9968">jam band bootleg (3)</option>
<option data-pic="berry5" data-qty="1" value="9817">Jamocha berry (1)</option>
<option data-pic="pants" data-qty="1" value="38">Knob Goblin pants (1)</option>
<option data-pic="pasty" data-qty="1" value="2593">Knob pasty (1)</option>
<option data-pic="leftovers" data-qty="1" value="1777">leftovers of indeterminate origin (1)</option>
<option data-pic="lime" data-qty="1" value="333">lime (1)</option>
<option data-pic="lore" data-qty="3" value="363">linoleum ore (3)</option>
<option data-pic="paperumb" data-qty="2" value="635">little paper umbrella (2)</option>
<option data-pic="allyearsucker" data-qty="1" value="9735">Lolsipop (1)</option>
<option data-pic="spraycan" data-qty="1" value="16">magicalness-in-a-can (1)</option>
<option data-pic="martini" data-qty="1" value="251">martini (1)</option>
<option data-pic="metallica" data-qty="2" value="628">metallic A (2)</option>
<option data-pic="middlewhiskey" data-qty="3" value="9948">Middle of the Road™ brand whiskey (3)</option>
<option data-pic="percent" data-qty="2" value="836">mind flayer corpse (2)</option>
<option data-pic="mohawk" data-qty="2" value="597">Mohawk wig (2)</option>
<option data-pic="croissant" data-qty="1" value="7509">Mornington crescent roll (1)</option>
<option data-pic="soda" data-qty="4" value="357">Mountain Stream soda (4)</option>
<option data-pic="candybar" data-qty="1" value="907">Mr. Mediocrebar (1)</option>
<option data-pic="walletchain" data-qty="1" value="9949">neverending wallet chain (1)</option>
<option data-pic="tent1" data-qty="1" value="69">Newbiesport™ tent (1)</option>
<option data-pic="lovemepumps" data-qty="1" value="9964">noticeable pumps (1)</option>
<option data-pic="opensauce" data-qty="1" value="6274">open sauce (1)</option>
<option data-pic="overcookie" data-qty="2" value="4955">overcookie (2)</option>
<option data-pic="partyballoon" data-qty="1" value="9975">party balloon (1)</option>
<option data-pic="pastaspoon" data-qty="1" value="5">pasta spoon (1)</option>
<option data-pic="pbjnocrust" data-qty="2" value="9953">PB&J with the crusts cut off (2)</option>
<option data-pic="feather" data-qty="3" value="593">phonics down (3)</option>
<option data-pic="torpedo" data-qty="2" value="630">photoprotoneutron torpedo (2)</option>
<option data-pic="blankoutglob" data-qty="1" value="8526">pink slime (1)</option>
<option data-pic="hole" data-qty="1" value="613">plot hole (1)</option>
<option data-pic="ponytailclip" data-qty="2" value="9955">ponytail clip (2)</option>
<option data-pic="poolcue" data-qty="1" value="1793">pool cue (1)</option>
<option data-pic="potion1" data-qty="1" value="610">procrastination potion (1)</option>
<option data-pic="purplebeast" data-qty="3" value="9958">Purple Beast energy drink (3)</option>
<option data-pic="ravioli" data-qty="1" value="6">ravioli hat (1)</option>
<option data-pic="canlid" data-qty="3" value="559">razor-sharp can lid (3)</option>
<option data-pic="pixel3" data-qty="5" value="461">red pixel (5)</option>
<option data-pic="w" data-qty="1" value="468">ruby W (1)</option>
<option data-pic="mascara2" data-qty="2" value="9962">runproof mascara (2)</option>
<option data-pic="rocks" data-qty="2" value="248">salty dog (2)</option>
<option data-pic="sanddollar" data-qty="5" value="3575">sand dollar (5)</option>
<option data-pic="saucepan" data-qty="1" value="7">saucepan (1)</option>
<option data-pic="pasta" data-qty="3" value="8406">savory dry noodles (3)</option>
<option data-pic="scroll2" data-qty="1" value="595">scroll of drastic healing (1)</option>
<option data-pic="reagent" data-qty="4" value="346">scrumptious reagent (4)</option>
<option data-pic="blueberry" data-qty="1" value="3691">sea blueberry (1)</option>
<option data-pic="cucumber" data-qty="1" value="3556">sea cucumber (1)</option>
<option data-pic="club" data-qty="1" value="1">seal-clubbing club (1)</option>
<option data-pic="skullhelm" data-qty="1" value="2283">seal-skull helmet (1)</option>
<option data-pic="shortwrit" data-qty="2" value="6711">short writ of habeas corpus (2)</option>
<option data-pic="sk8board" data-qty="1" value="410">sk8board (1)</option>
<option data-pic="snifter" data-qty="4" value="1956">snifter of thoroughly aged brandy (4)</option>
<option data-pic="snowpants" data-qty="2" value="356">snowboarder pants (2)</option>
<option data-pic="powder" data-qty="4" value="588">soft green echo eyedrop antidote (4)</option>
<option data-pic="spice" data-qty="10" value="8">spices (10)</option>
<option data-pic="baguette" data-qty="1" value="1776">stale baguette (1)</option>
<option data-pic="stalk" data-qty="2" value="560">stalk of asparagus (2)</option>
<option data-pic="firewood" data-qty="10" value="10293">stick of firewood (10)</option>
<option data-pic="accordion" data-qty="1" value="11">stolen accordion (1)</option>
<option data-pic="sushipiece" data-qty="1" value="6293">stolen sushi (1)</option>
<option data-pic="cog" data-qty="1" value="1346">Sugar Cog (1)</option>
<option data-pic="balm" data-qty="1" value="587">super-spiky hair gel (1)</option>
<option data-pic="npartyhandbag" data-qty="1" value="9965">surprisingly capacious handbag (1)</option>
<option data-pic="tots" data-qty="2" value="359">t8r tots (2)</option>
<option data-pic="sardinecan" data-qty="1" value="8731">tin of submardines (1)</option>
<option data-pic="house" data-qty="10" value="592">tiny house (10)</option>
<option data-pic="umbrella" data-qty="1" value="596">titanium assault umbrella (1)</option>
<option data-pic="cass" data-qty="2" value="225">tofu casserole (2)</option>
<option data-pic="totem" data-qty="1" value="4">turtle totem (1)</option>
<option data-pic="unnamedcock" data-qty="1" value="7187">unnamed cocktail (1)</option>
<option data-pic="tinydress" data-qty="3" value="9963">very small red dress (3)</option>
<option data-pic="vikinghat" data-qty="1" value="37">viking helmet (1)</option>
<option data-pic="limerickscroll" data-qty="2" value="6277">Ye Olde Bawdy Limerick (2)</option>
<option data-pic="yeinsult" data-qty="2" value="6278">Ye Olde Medieval Insult (2)</option>
<option data-pic="yetifur" data-qty="3" value="388">yeti fur (3)</option></select><input type="button" value="Add" class="button" id="adding" /><div id="pizzaingredients" style="background-image: url(https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/horadricoven_large.gif); width:200px; height: 200px; position: relative; margin-left: 30px"><a href="#" value="Empty Oven" style="position: absolute; bottom: 10px; left: 44px; font-size: 0.8em; display: none" id="empty" >Empty Oven</a></div><input type="hidden" value="" id="pizza" name="pizza" /><input type="submit" value="Bake Pizza" class="button disabled" disabled id="makeathepizza" /></form><script>var ibase="https://s3.amazonaws.com/images.kingdomofloathing.com/";</script><script>jQuery(function ($) {var ing = [];var orig_opts = $('#pizzaoptions option').clone();$('#empty').click(function () { ing = []; $('#pizzaingredients img').remove(); $('#empty').hide(); $('#pizzaoptions').empty().append(orig_opts); $('#pizzaoptions').val(''); $('#adding').removeClass('disabled').attr('disabled', false); $('#pizza').val(ing.join(','));});$('#adding').click(function () { var opt = $('#pizzaoptions option:selected'); var val = opt.text().replace(/ \(\d+\)$/, ''); var id = opt.attr('value'); var qty = parseInt(opt.attr('data-qty')); qty--; opt.attr('data-qty', qty); if (qty < 1) opt.remove(); else opt.text(opt.text().replace('('+(qty+1)+')', '('+qty+')')); var img = $('<img />') .data('id', id) .css({position: 'absolute', top: ing.length < 2 ? '32px' : '82px', left: ing.length==0 || ing.length==2 ? '40px' : '92'}) .attr('title', val) .attr('alt', val) .attr('src', ibase+'itemimages/'+opt.attr('data-pic')+'.gif'); $('#pizzaingredients').append(img); ing.push(id); $('#pizza').val(ing.join(',')); $('#empty').show(); if (ing.length == 4) { $('#adding').addClass('disabled').attr('disabled', true); $('#makeathepizza').removeClass('disabled').attr('disabled', false); } else { $('#makeathepizza').addClass('disabled').attr('disabled', true); $('#adding').removeClass('disabled').attr('disabled', false); }});});</script></center></td></tr></table></center></td></tr><tr><td height=4></td></tr></table><table width=95% cellspacing=0 cellpadding=0><tr><td style="color: white;" align=center bgcolor=blue><b>Your Campsite</b></td></tr><tr><td style="padding: 5px; border: 1px solid blue;"><center><table><tr><td><center><table cellspacing=0 cellpadding=0><tr><td height=15 align=center><a href="campground.php?action=inspectdwelling"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/tinyglass.gif" width=15 height=15 border=0></a></td><td></td><td></td><td></td><td></td></tr><tr><td width=100 height=100><a href="campground.php?action=rest"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/rest4.gif" width=100 height=100 border=0 alt="Rest in Your Dwelling (1)" title="Rest in Your Dwelling (1)"></a></td><td width=100 height=100><a href=campground.php?action=workshed><img src=https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/workshed.gif width=100 height=100 border=0 alt="Your Workshed" title="Your Workshed"></a></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains1.gif" width=100 height=100></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains2.gif" width=100 height=100></td><td width=100 height=100><a href="closet.php"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/closet.gif" width=100 height=100 border=0 alt="Your Colossal Closet" title="Your Colossal Closet"></a></td></tr><tr><td width=100 height=100><a href="campground.php?action=telescope"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/telescope.gif" width=100 height=100 border=0 alt="A Telescope" title="A Telescope"></a></td><td width=100 height=50><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/smallblank1.gif" width=100 height=50></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains2.gif" width=100 height=100></td><td width=100 height=100><a href="trophies.php"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/trophycase.gif" width=100 height=100 border=0 alt="Trophy Case" title="Trophy Case"></a></td><td width=100 height=100><a href="campground.php?action=bookshelf"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/bookshelf.gif" width=100 height=100 border=0 alt="Your Mystical Bookshelf" title="Your Mystical Bookshelf"></a></td></tr><tr><td width=100 height=100><img src=https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/grassgarden0.gif width=100 height=100 border=0 alt="Tall Grass (no growth)" title="Tall Grass (no growth)"></td><td width=100 height=100><a href=campground.php?action=inspectkitchen><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/kitchen.gif" width=100 height=100 border=0 alt="Your Kitchen" title="Your Kitchen"></a></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains1.gif" width=100 height=100></td><td width=100 height=100><a href="familiar.php"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/bigterrarium.gif" width=100 height=100 border=0 alt="Familiar-Gro Terrarium" title="Familiar-Gro Terrarium"></a></td><td width=100 height=100><a href="questlog.php"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/questlog2.gif" width=100 height=100 border=0 alt="Your Quest Log" title="Your Quest Log"></a></td></tr><tr><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains8.gif" width=100 height=100></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains1.gif" width=100 height=100></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains7.gif" width=100 height=100></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains9.gif" width=100 height=100></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains3.gif" width=100 height=100></td></tr></table></center><center><p><a href="main.php">Back to the Main Map</a></center></td></tr></table></center></td></tr><tr><td height=4></td></tr></table></center></body><script src="/ircm_extend.js"></script><script src="/onfocus.1.js"></script></html>

<html>
<head>
<script language=Javascript>
<!--if (parent.frames.length == -1) location.href="game.php";//--></script>
<script language=Javascript src="https://s3.amazonaws.com/images.kingdomofloathing.com/scripts/keybinds.min.2.js"></script>
<script language=Javascript src="https://s3.amazonaws.com/images.kingdomofloathing.com/scripts/window.20111231.js"></script>
<script language="javascript">
function chatFocus(){if(top.chatpane.document.chatform.graf) top.chatpane.document.chatform.graf.focus();}
if (typeof defaultBind != 'undefined') { defaultBind(47, 2, chatFocus); defaultBind(190, 2, chatFocus);
defaultBind(191, 2, chatFocus); defaultBind(47, 8, chatFocus);defaultBind(190, 8, chatFocus); defaultBind(191, 8, chatFocus); }</script>
<script language="javascript"> function updateParseItem(iid, field, info) { var tbl = $('#ic'+iid); var data = parseItem(tbl); 
if (!data) return; data[field] = info; var out = []; for (i in data) { if (!data.hasOwnProperty(i)) continue; out.push(i+'='+data[i]); }
 tbl.attr('rel', out.join('&')); } function parseItem(tbl) { tbl = $(tbl); var rel = tbl.attr('rel'); var data = {};
 if (!rel) return data; var parts = rel.split('&'); for (i in parts) { if (!parts.hasOwnProperty(i)) continue;
 var kv = parts[i].split('='); tbl.data(kv[0], kv[1]); data[kv[0]] = kv[1]; } return data; }</script>
 <script language=Javascript src="https://s3.amazonaws.com/images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js">
 </script><script type="text/javascript" src="https://s3.amazonaws.com/images.kingdomofloathing.com/scripts/pop_query.20130705.js">
 </script><script type="text/javascript" src="https://s3.amazonaws.com/images.kingdomofloathing.com/scripts/ircm.20161111.js">
 </script><script type="text/javascript">var tp = top;function pop_ircm_contents(i, some) { var contents = '', shown = 0, da = ' <a href="#" rel="?" class="small dojaxy">[some]</a> 
 <a href="#" rel="', db = '" class="small dojaxy">[all]</a>', dc = '<div style="width:100%; padding-bottom: 3px;" rel="', dd = '<a href="#" rel="1" class="small dojaxy">
 ['; one = 'one'; ss=some;if (i.d==1 && i.s>0) { shown++; contents += dc + 'sellstuff.php?action=sell&ajax=1&type=quant&whichitem%5B%5D=IID&howmany=NUM&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Auto-Sell ('+i.s+' meat):</b> '+dd+one+']</a>';
 if (ss) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.q==0) { shown++; contents += dc + 'inventory.php?action=closetpush&ajax=1&whichitem=IID&qty=NUM&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Closet:</b> '+dd+one+']</a>';if (ss) 
 { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.q==0 && i.g==0 && i.t==1) { shown++; contents += dc + 'managestore.php?action=additem&qty1=NUM&item1=IID&price1=&limit1=&ajax=1&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'">
 <b>Stock in Mall:</b> '+dd+one+']</a>';if (ss) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.q==0) { shown++; contents += dc + 
 'managecollection.php?action=put&ajax=1&whichitem1=IID&howmany1=NUM&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Add to Display Case:</b> '+dd+one+']</a>';if (ss)
 { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.q==0 && i.t==1) { shown++; contents += dc + 
 'clan_stash.php?action=addgoodies&ajax=1&item1=IID&qty1=NUM&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Contribute to Clan:</b>
 '+dd+one+']</a>';if (ss) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.q==0 && i.p==0 && i.u=="q" && i.d==1 && i.t==1) 
 { shown++; contents += dc + 'craft.php?action=pulverize&ajax=1&smashitem=IID&qty=NUM&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Pulverize:</b> 
 '+dd+one+']</a>';if (ss) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.u && i.u != "." && !i.ac) { shown++; 
 contents += dc + 'inv_'+(i.u=="a"?"redir":(lab=(i.u=="u"?"use":(i.u=="e"?"eat":(i.u=="b"?"booze":(i.u=="s"?"spleen":"equip"))))))+'.php?ajax=1&whichitem=IID&itemquantity=NUM&quantity=NUM'+(i.u=="q"?"&action=equip":"")
 +'&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>'+ucfirst(unescape(i.ou ? i.ou.replace(/\+/g," ") : 
 (lab=="booze"?"drink":lab)))+':</b> '+dd+one+']</a>';if (ss && i.u != 'q' && !(i.u=='u' && i.m==0)) { contents += da + i.n + db;}contents
 += '</div>';}one = 'one'; ss=some;if (i.u && i.u != "." && i.ac) { shown++; contents += dc + 'inv_equip.php?slot=1&ajax=1&whichitem=IID&action=equip&pwd=39a078bbaa9c196955c048fcd485030c" 
 id="pircm_'+i.id+'"><b>Equip (slot 1):</b> '+dd+one+']</a>';if (ss && i.u != 'q' && !(i.u=='u' && i.m==0)) { contents += da + i.n + db;}contents += '</div>';}one 
 = 'one'; ss=some;if (i.u && i.u != "." && i.ac) { shown++; contents += dc + 'inv_equip.php?slot=2&ajax=1&whichitem=IID&action=equip&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'">
 <b>Equip (slot 2):</b> '+dd+one+']</a>';if (ss && i.u != 'q' && !(i.u=='u' && i.m==0)) { contents += da + i.n + db;}contents += '</div>';}one = 'one'; ss=some;if (i.u && i.u != "." && i.ac)
 { shown++; contents += dc + 'inv_equip.php?slot=3&ajax=1&whichitem=IID&action=equip&pwd=39a078bbaa9c196955c048fcd485030c" id="pircm_'+i.id+'"><b>Equip (slot 3):</b> '+dd+one+']</a>';if
 (ss && i.u != 'q' && !(i.u=='u' && i.m==0)) { contents += da + i.n + db;}contents += '</div>';} return [contents, shown];}tp=topvar todo = [];function nextAction() { var next_todo = todo.shift();
 if (next_todo) { eval(next_todo); }}function dojax(dourl, afterFunc, hoverCaller, failureFunc, method, params) { $.ajax({ type: method || 'GET', url: dourl, cache: false, data: params || null,
 global: false, success: function (out) { nextAction(); if (out.match(/no\|/)) { var parts = out.split(/\|/); if (failureFunc) failureFunc(parts[1]); else if (window.dojaxFailure) 
 window.dojaxFailure(parts[1]); else if (tp.chatpane.handleMessage) tp.chatpane.handleMessage({type: 'event', msg: 'Oops! Sorry, Dave, you appear to be ' + parts[1]});
 else $('#ChatWindow').append('<font color="green">Oops! Sorry, Dave, you appear to be ' + parts[1] + '.</font><br />' + "\n"); return; } if (hoverCaller) { float_results(hoverCaller, out); 
 if (afterFunc) { afterFunc(out); } return; }$(tp.mainpane.document).find("#effdiv").remove(); if(!window.dontscroll || (window.dontscroll && dontscroll==0)) { window.scroll(0,0);}
 var $eff = $(tp.mainpane.document).find('#effdiv'); if ($eff.length == 0) { var d = tp.mainpane.document.createElement('DIV'); d.id = 'effdiv'; var b = tp.mainpane.document.body; 
 if ($('#content_').length > 0) { b = $('#content_ div:first')[0]; } b.insertBefore(d, b.firstChild); $eff = $(d); } $eff.find('a[name="effdivtop"]').remove().end() .prepend('<a name="effdivtop">
 </a><center>' + out + '</center>').css('display','block'); if (!window.dontscroll || (window.dontscroll && dontscroll==0)) { tp.mainpane.document.location = tp.mainpane.document.location + 
 "#effdivtop"; } if (afterFunc) { afterFunc(out); } } });}</script><script type="text/javascript"> var timersfunc;jQuery(function (j) {j("area[href^='adventure.php'], a[href^='adventure.php'], 
 a[href^='barrel.php?smash=']").click(timersfunc = function () {return confirm("You have a timer with 1 turn remaining. Click OK to adventure as you intended.
 Cancel if you want to change your mind."); });j("form[action='dungeon.php']").submit(timersfunc);});</script>
 <link rel="stylesheet" type="text/css" href="https://s3.amazonaws.com/images.kingdomofloathing.com/styles.20151006.css">
 <style type='text/css'>.faded { zoom: 1; filter: alpha(opacity=35); opacity: 0.35; -khtml-opacity: 0.35; -moz-opacity: 0.35;}</style>
 <script language="Javascript" src="/basics.js"></script>
 <link rel="stylesheet" href="/basics.1.css" />
 </head>
 <body>
 <centeR>
 <table width=95% cellspacing=0 cellpadding=0>
 <tr>
 <td style="color: white;" align=center bgcolor=blue><b>Results:</b></td>
 </tr>
 <tr>
 <td style="padding: 5px; border: 1px solid blue;"><center><table><tr><td>
 <center>Your rickety workshed contains:<p><img style='vertical-align: middle' class=hand src='https://s3.amazonaws.com/images.kingdomofloathing.com/itemimages/horadricoven.gif' onclick='descitem(234341716)' alt="diabolic pizza cube" title="diabolic pizza cube">
 <b>diabolic pizza cube</b>
 <form method="post" action="campground.php">
 <input type="hidden" value="makepizza" name="action" />
 Add Ingredient: <select id="pizzaoptions">
 
<option data-pic="jug" data-qty="1" value="2842">accidental cider (1)</option>
 
<option data-pic="bladder" data-qty="2" value="2056">adder bladder (2)</option>
<option data-pic="dinner" data-qty="2" value="1778">ancient frozen dinner (2)</option>
<option data-pic="condiment" data-qty="1" value="2841">antique packet of ketchup (1)</option>
<option data-pic="machinegun" data-qty="2" value="2684">armgun (2)</option>
<option data-pic="knife" data-qty="1" value="19">asparagus knife (1)</option>
<option data-pic="baseball" data-qty="1" value="181">baseball (1)</option>
<option data-pic="guano" data-qty="1" value="188">bat guano (1)</option>
<option data-pic="batwing" data-qty="2" value="183">bat wing (2)</option>
<option data-pic="pill2" data-qty="2" value="9703">beefy pill (2)</option>
<option data-pic="candy" data-qty="1" value="1962">Bit O' Ectoplasm (1)</option>
<option data-pic="compact" data-qty="1" value="7510">black eye shadow (1)</option>
<option data-pic="blackcake" data-qty="2" value="2342">black forest cake (2)</option>
<option data-pic="ham" data-qty="1" value="2343">black forest ham (1)</option>
<option data-pic="blacklabel" data-qty="1" value="7508">black label (1)</option>
<option data-pic="blackdye" data-qty="1" value="2059">Black No. 2 (1)</option>
<option data-pic="blackcheck" data-qty="2" value="2057">black pension check (2)</option>
<option data-pic="blpepper" data-qty="1" value="2341">black pepper (1)</option>
<option data-pic="blackbasket" data-qty="2" value="2058">black picnic basket (2)</option>
<option data-pic="bsnakeskin" data-qty="1" value="2055">black snake skin (1)</option>
<option data-pic="wine2" data-qty="1" value="2339">Blackfly Chardonnay (1)</option>
<option data-pic="pixel5" data-qty="2" value="463">blue pixel (2)</option>
<option data-pic="beerbottle" data-qty="1" value="1774">bottle of popskull (1)</option>
<option data-pic="bottle" data-qty="3" value="787">bottle of rum (3)</option>
<option data-pic="bottle" data-qty="1" value="1004">bottle of tequila (1)</option>
<option data-pic="bottle" data-qty="1" value="328">bottle of whiskey (1)</option>
<option data-pic="brokeskull" data-qty="1" value="741">broken skull (1)</option>
<option data-pic="librarycard" data-qty="1" value="4699">bus pass (1)</option>
<option data-pic="butterfly" data-qty="2" value="615">chaos butterfly (2)</option>
<option data-pic="core" data-qty="2" value="365">chrome ore (2)</option>
<option data-pic="napkin" data-qty="2" value="2956">cocktail napkin (2)</option>
<option data-pic="fragment" data-qty="12" value="589">cocoa eggshell fragment (12)</option>
<option data-pic="coconut" data-qty="2" value="1007">coconut shell (2)</option>
<option data-pic="demonskin" data-qty="2" value="2479">demon skin (2)</option>
<option data-pic="punkjacket" data-qty="1" value="9969">denim jacket (1)</option>
<option data-pic="meatstack" data-qty="4" value="258">dense meat stack (4)</option>
<option data-pic="dcane" data-qty="2" value="472">diamond-studded cane (2)</option>
<option data-pic="fudgesicle" data-qty="1" value="2843">dire fudgesicle (1)</option>
<option data-pic="discoball" data-qty="1" value="10">disco ball (1)</option>
<option data-pic="quillpen" data-qty="2" value="1957">disintegrating quill pen (2)</option>
<option data-pic="camera" data-qty="1" value="7266">disposable instant camera (1)</option>
<option data-pic="dorkglasses" data-qty="1" value="9954">dorky glasses (1)</option>
<option data-pic="pasta" data-qty="2" value="304">dry noodles (2)</option>
<option data-pic="scale1" data-qty="2" value="3486">dull fish scale (2)</option>
<option data-pic="electronicskit" data-qty="2" value="9952">electronics kit (2)</option>
<option data-pic="junglefruit" data-qty="1" value="6724">exotic jungle fruit (1)</option>
<option data-pic="mittens" data-qty="1" value="399">eXtreme mittens (1)</option>
<option data-pic="scarf" data-qty="1" value="355">eXtreme scarf (1)</option>
<option data-pic="gascan" data-qty="3" value="9947">gas can (3)</option>
<option data-pic="ricepeeler" data-qty="1" value="6280">giant artisanal rice peeler (1)</option>
<option data-pic="giantfork" data-qty="1" value="1151">giant discarded plastic fork (1)</option>
<option data-pic="ringa" data-qty="1" value="1351">giant pinky ring (1)</option>
<option data-pic="safetypin" data-qty="1" value="6292">giant safety pin (1)</option>
<option data-pic="glarkcable" data-qty="1" value="7246">glark cable (1)</option>
<option data-pic="grapes" data-qty="2" value="358">gr8ps (2)</option>
<option data-pic="sandgrain" data-qty="8" value="10259">grain of sand (8)</option>
<option data-pic="pixel4" data-qty="2" value="462">green pixel (2)</option>
<option data-pic="cube" data-qty="2" value="476">hellion cube (2)</option>
<option data-pic="turtle" data-qty="1" value="3">helmet turtle (1)</option>
<option data-pic="hollanhelm" data-qty="1" value="4719">Hollandaise helmet (1)</option>
<option data-pic="hotblade" data-qty="1" value="350">hot katana blade (1)</option>
<option data-pic="hotplate" data-qty="1" value="4665">hot plate (1)</option>
<option data-pic="batwing" data-qty="9" value="471">hot wing (9)</option>
<option data-pic="cannedair" data-qty="5" value="4698">imp air (5)</option>
<option data-pic="beer" data-qty="10" value="470">Imp Ale (10)</option>
<option data-pic="rankring2" data-qty="1" value="4666">imp unity ring (1)</option>
<option data-pic="inkwell" data-qty="2" value="1958">inkwell (2)</option>
<option data-pic="deadbootlet" data-qty="3" value="9968">jam band bootleg (3)</option>
<option data-pic="berry5" data-qty="1" value="9817">Jamocha berry (1)</option>
<option data-pic="pants" data-qty="1" value="38">Knob Goblin pants (1)</option>
<option data-pic="pasty" data-qty="1" value="2593">Knob pasty (1)</option>
<option data-pic="leftovers" data-qty="1" value="1777">leftovers of indeterminate origin (1)</option>
<option data-pic="lime" data-qty="1" value="333">lime (1)</option>
<option data-pic="lore" data-qty="3" value="363">linoleum ore (3)</option>
<option data-pic="paperumb" data-qty="2" value="635">little paper umbrella (2)</option>
<option data-pic="allyearsucker" data-qty="1" value="9735">Lolsipop (1)</option>
<option data-pic="spraycan" data-qty="1" value="16">magicalness-in-a-can (1)</option>
<option data-pic="martini" data-qty="1" value="251">martini (1)</option>
<option data-pic="metallica" data-qty="2" value="628">metallic A (2)</option>
<option data-pic="middlewhiskey" data-qty="3" value="9948">Middle of the Road™ brand whiskey (3)</option>
<option data-pic="percent" data-qty="2" value="836">mind flayer corpse (2)</option>
<option data-pic="mohawk" data-qty="2" value="597">Mohawk wig (2)</option>
<option data-pic="croissant" data-qty="1" value="7509">Mornington crescent roll (1)</option>
<option data-pic="soda" data-qty="4" value="357">Mountain Stream soda (4)</option>
<option data-pic="candybar" data-qty="1" value="907">Mr. Mediocrebar (1)</option>
<option data-pic="walletchain" data-qty="1" value="9949">neverending wallet chain (1)</option>
<option data-pic="tent1" data-qty="1" value="69">Newbiesport™ tent (1)</option>
<option data-pic="lovemepumps" data-qty="1" value="9964">noticeable pumps (1)</option>
<option data-pic="opensauce" data-qty="1" value="6274">open sauce (1)</option>
<option data-pic="overcookie" data-qty="2" value="4955">overcookie (2)</option>
<option data-pic="partyballoon" data-qty="1" value="9975">party balloon (1)</option>
<option data-pic="pastaspoon" data-qty="1" value="5">pasta spoon (1)</option>
<option data-pic="pbjnocrust" data-qty="2" value="9953">PB&J with the crusts cut off (2)</option>
<option data-pic="feather" data-qty="3" value="593">phonics down (3)</option>
<option data-pic="torpedo" data-qty="2" value="630">photoprotoneutron torpedo (2)</option>
<option data-pic="blankoutglob" data-qty="1" value="8526">pink slime (1)</option>
<option data-pic="hole" data-qty="1" value="613">plot hole (1)</option>
<option data-pic="ponytailclip" data-qty="2" value="9955">ponytail clip (2)</option>
<option data-pic="poolcue" data-qty="1" value="1793">pool cue (1)</option>
<option data-pic="potion1" data-qty="1" value="610">procrastination potion (1)</option>
<option data-pic="purplebeast" data-qty="3" value="9958">Purple Beast energy drink (3)</option>
<option data-pic="ravioli" data-qty="1" value="6">ravioli hat (1)</option>
<option data-pic="canlid" data-qty="3" value="559">razor-sharp can lid (3)</option>
<option data-pic="pixel3" data-qty="5" value="461">red pixel (5)</option>
<option data-pic="w" data-qty="1" value="468">ruby W (1)</option>
<option data-pic="mascara2" data-qty="2" value="9962">runproof mascara (2)</option>
<option data-pic="rocks" data-qty="2" value="248">salty dog (2)</option>
<option data-pic="sanddollar" data-qty="5" value="3575">sand dollar (5)</option>
<option data-pic="saucepan" data-qty="1" value="7">saucepan (1)</option>
<option data-pic="pasta" data-qty="3" value="8406">savory dry noodles (3)</option>
<option data-pic="scroll2" data-qty="1" value="595">scroll of drastic healing (1)</option>
<option data-pic="reagent" data-qty="4" value="346">scrumptious reagent (4)</option>
<option data-pic="blueberry" data-qty="1" value="3691">sea blueberry (1)</option>
<option data-pic="cucumber" data-qty="1" value="3556">sea cucumber (1)</option>
<option data-pic="club" data-qty="1" value="1">seal-clubbing club (1)</option>
<option data-pic="skullhelm" data-qty="1" value="2283">seal-skull helmet (1)</option>
<option data-pic="shortwrit" data-qty="2" value="6711">short writ of habeas corpus (2)</option>
<option data-pic="sk8board" data-qty="1" value="410">sk8board (1)</option>
<option data-pic="snifter" data-qty="4" value="1956">snifter of thoroughly aged brandy (4)</option>
<option data-pic="snowpants" data-qty="2" value="356">snowboarder pants (2)</option>
<option data-pic="powder" data-qty="4" value="588">soft green echo eyedrop antidote (4)</option>
<option data-pic="spice" data-qty="10" value="8">spices (10)</option>
<option data-pic="baguette" data-qty="1" value="1776">stale baguette (1)</option>
<option data-pic="stalk" data-qty="2" value="560">stalk of asparagus (2)</option>
<option data-pic="firewood" data-qty="10" value="10293">stick of firewood (10)</option>
<option data-pic="accordion" data-qty="1" value="11">stolen accordion (1)</option>
<option data-pic="sushipiece" data-qty="1" value="6293">stolen sushi (1)</option>
<option data-pic="cog" data-qty="1" value="1346">Sugar Cog (1)</option>
<option data-pic="balm" data-qty="1" value="587">super-spiky hair gel (1)</option>
<option data-pic="npartyhandbag" data-qty="1" value="9965">surprisingly capacious handbag (1)</option>
<option data-pic="tots" data-qty="2" value="359">t8r tots (2)</option>
<option data-pic="sardinecan" data-qty="1" value="8731">tin of submardines (1)</option>
<option data-pic="house" data-qty="10" value="592">tiny house (10)</option>
<option data-pic="umbrella" data-qty="1" value="596">titanium assault umbrella (1)</option>
<option data-pic="cass" data-qty="2" value="225">tofu casserole (2)</option>
<option data-pic="totem" data-qty="1" value="4">turtle totem (1)</option>
<option data-pic="unnamedcock" data-qty="1" value="7187">unnamed cocktail (1)</option>
<option data-pic="tinydress" data-qty="3" value="9963">very small red dress (3)</option>
<option data-pic="vikinghat" data-qty="1" value="37">viking helmet (1)</option>
<option data-pic="limerickscroll" data-qty="2" value="6277">Ye Olde Bawdy Limerick (2)</option>
<option data-pic="yeinsult" data-qty="2" value="6278">Ye Olde Medieval Insult (2)</option>
<option data-pic="yetifur" data-qty="3" value="388">yeti fur (3)</option>
</select>
<input type="button" value="Add" class="button" id="adding" />
<div id="pizzaingredients" style="background-image: url(https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/horadricoven_large.gif); width:200px; height: 200px; position: relative; margin-left: 30px">
<a href="#" value="Empty Oven" style="position: absolute; bottom: 10px; left: 44px; font-size: 0.8em; display: none" id="empty" >Empty Oven</a>
</div><input type="hidden" value="" id="pizza" name="pizza" />
<input type="submit" value="Bake Pizza" class="button disabled" disabled id="makeathepizza" />
</form>
<script>var ibase="https://s3.amazonaws.com/images.kingdomofloathing.com/";</script>
<script>
jQuery(
function ($) {
	var ing = [];
	var orig_opts = $('#pizzaoptions option').clone();
	
	$('#empty').click(
		function ()
		{
			ing = [];
			$('#pizzaingredients img').remove();
			$('#empty').hide();
			$('#pizzaoptions').empty().append(orig_opts);
			$('#pizzaoptions').val('');
			$('#adding').removeClass('disabled').attr('disabled', false);
			$('#pizza').val(ing.join(','));
		});
	
	$('#adding').click(
		function () 
		{
			var opt = $('#pizzaoptions option:selected'); 
			var val = opt.text().replace(/ \(\d+\)$/, '');
			var id = opt.attr('value');
			var qty = parseInt(opt.attr('data-qty'));
			qty--;
			opt.attr('data-qty', qty);
			if (qty < 1)
				opt.remove();
			else
				opt.text(opt.text().replace('('+(qty+1)+')', '('+qty+')'));
			
			var img = $('<img />')
				.data('id', id)
				.css({position: 'absolute', top: ing.length < 2 ? '32px' : '82px', left: ing.length==0 || ing.length==2 ? '40px' : '92'})
				.attr('title', val)
				.attr('alt', val)
				.attr('src', ibase+'itemimages/'+opt.attr('data-pic')+'.gif');
			
			$('#pizzaingredients').append(img); ing.push(id);
			$('#pizza').val(ing.join(','));
			$('#empty').show();
			if (ing.length == 4) 
			{ 
				$('#adding').addClass('disabled').attr('disabled', true);
				$('#makeathepizza').removeClass('disabled').attr('disabled', false);
			} 
			else 
			{ 
				$('#makeathepizza').addClass('disabled').attr('disabled', true);
				$('#adding').removeClass('disabled').attr('disabled', false); 
			}
		}
	);
});
 
 </script>
 </center>
 </td></tr></table></center></td></tr><tr><td height=4></td></tr></table><table width=95% cellspacing=0 cellpadding=0><tr><td style="color: white;" align=center bgcolor=blue><b>Your Campsite</b></td></tr><tr><td style="padding: 5px; border: 1px solid blue;"><center><table><tr><td><center><table cellspacing=0 cellpadding=0><tr><td height=15 align=center><a href="campground.php?action=inspectdwelling"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/tinyglass.gif" width=15 height=15 border=0></a></td><td></td><td></td><td></td><td></td></tr><tr><td width=100 height=100><a href="campground.php?action=rest"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/rest4.gif" width=100 height=100 border=0 alt="Rest in Your Dwelling (1)" title="Rest in Your Dwelling (1)"></a></td><td width=100 height=100><a href=campground.php?action=workshed><img src=https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/workshed.gif width=100 height=100 border=0 alt="Your Workshed" title="Your Workshed"></a></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains1.gif" width=100 height=100></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains2.gif" width=100 height=100></td><td width=100 height=100><a href="closet.php"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/closet.gif" width=100 height=100 border=0 alt="Your Colossal Closet" title="Your Colossal Closet"></a></td></tr><tr><td width=100 height=100><a href="campground.php?action=telescope"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/telescope.gif" width=100 height=100 border=0 alt="A Telescope" title="A Telescope"></a></td><td width=100 height=50><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/smallblank1.gif" width=100 height=50></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains2.gif" width=100 height=100></td><td width=100 height=100><a href="trophies.php"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/trophycase.gif" width=100 height=100 border=0 alt="Trophy Case" title="Trophy Case"></a></td><td width=100 height=100><a href="campground.php?action=bookshelf"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/bookshelf.gif" width=100 height=100 border=0 alt="Your Mystical Bookshelf" title="Your Mystical Bookshelf"></a></td></tr><tr><td width=100 height=100><img src=https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/grassgarden0.gif width=100 height=100 border=0 alt="Tall Grass (no growth)" title="Tall Grass (no growth)"></td><td width=100 height=100><a href=campground.php?action=inspectkitchen><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/kitchen.gif" width=100 height=100 border=0 alt="Your Kitchen" title="Your Kitchen"></a></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains1.gif" width=100 height=100></td><td width=100 height=100><a href="familiar.php"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/bigterrarium.gif" width=100 height=100 border=0 alt="Familiar-Gro Terrarium" title="Familiar-Gro Terrarium"></a></td><td width=100 height=100><a href="questlog.php"><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/campground/questlog2.gif" width=100 height=100 border=0 alt="Your Quest Log" title="Your Quest Log"></a></td></tr><tr><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains8.gif" width=100 height=100></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains1.gif" width=100 height=100></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains7.gif" width=100 height=100></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains9.gif" width=100 height=100></td><td width=100 height=100><img src="https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/plains/plains3.gif" width=100 height=100></td></tr></table></center><center><p><a href="main.php">Back to the Main Map</a></center></td></tr></table></center></td></tr><tr><td height=4></td></tr>
 </table>
 </center>
 </body>
 <script src="/ircm_extend.js"></script>
 <script src="/onfocus.1.js"></script>
 </html>

*/