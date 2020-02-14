function writeInterface()
{
	document.write(`
	<p>Adventures: <b id="valueAdv"></b><br>
	<em>
	<span style=\"font-size:small\"><span id="valueLetters"></span> letters</span><br>
	<span style=\"font-size:x-small\"><span id="valueLettersLeftToUp"></span> letters for next adventure increase</span><br>
	<span style=\"font-size:x-small\"><span id="valueLettersLeftToMax"></span> letters for 15 adv (max)</span>
	</em>
	</p>

	<p>Effect turns: <b id="valueTurns"></b><br>
	<em>
	<span style=\"font-size:small\"><span id="valueMeat"></span> total auto-sell</span><br>
	<span style=\"font-size:x-small\"><span id="valueMeatLeftToUp"></span> for next turn increase</span><br>
	<span style=\"font-size:x-small\"><span id="valueMeatLeftToMax"></span> for max turns</span>
	</em>
	</p>

	<p>Effect initials: <b><u><span id="letter0"></span> <span id="letter1"></span> <span id="letter2"></span> <span id="letter3"></span></u></b></p>

	<p><em><b>Special pizza: <big id="specialPizza"></big></b></em></p>
	`);
}

writeInterface();

jQuery(
function ($) 
{
	function LenToAdventures(len)
	{
		var value = Math.round(len/10.0);
		return Math.min(15, Math.max(3, value));
	}

	function LenFromAdv(adv)
	{
		var len = adv * 10 - 5;
		return len;
	}

	function LenToAdvIncrease(len)
	{
		var adv = LenToAdventures(len);
		if (adv == 15)
			return 0;
		var lenForNext = LenFromAdv(adv + 1);
		return lenForNext - len;
	}
	
	function PriceToTurns(price)
	{
		return Math.min(100, Math.max(5, Math.round(Math.sqrt(price))));
	}

	function PriceForTurns(turns)
	{
		var limit = turns - .5;
		return Math.ceil(limit * limit);
	}

	function PriceToTurnIncrease(price)
	{
		var turns = PriceToTurns(price);
		if (turns == 100)
			return 0;
		var priceForTurn = PriceForTurns(turns + 1);
		return priceForTurn - price;
	}
	
	var prices = [];
	var lens = [];
	var letters = [];
	var special = [];
	var sort = "alpha";
	var sortReverse = false;
	var allEffects = [];
	var originalOptions = [];
	var allOptions = [];
	
	$('#effectList option').each(
		function()
		{
			allEffects.push(this);
		}
	);

	$('#pizzaoptions option').each(
		function()
		{
			originalOptions.push(this);
		}
	);

	function RestoreOriginalOptions()
	{
		allOptions = [];
		$(originalOptions).each(
			function()
			{
				allOptions.push(this);
			}
		)
	}

	function FilterCall(option)
	{
		var text = option.innerHTML.toLowerCase();
		var search = $('#searchInput').val().toLowerCase();
		var result = text.includes(search);
		var firstLetter = $('#firstLetterInput').val().toLowerCase();
		return result && text.startsWith(firstLetter);
	}

	function ReSort()
	{
		var sortingFunc;

		if (sort == "alpha")
		{
			sortingFunc = function(a, b)
			{
				var aText = a.text.toLowerCase();
				var bText = b.text.toLowerCase();
				var sort = aText < bText ? -1 : aText > bText ? 1 : 0;
				return sort;
			};
		}
		else if (sort == "price")
		{
			sortingFunc = function(a, b)
			{
				var aPrice = parseInt(a.getAttribute("data-price"));
				var bPrice = parseInt(b.getAttribute("data-price"));
				return aPrice - bPrice;
			}
		}
		else if (sort == "letter")
		{
			sortingFunc = function(a, b)
			{
				var aPrice = parseInt(a.getAttribute("data-len"));
				var bPrice = parseInt(b.getAttribute("data-len"));
				return aPrice - bPrice;
			}
		}

		var optionsSelect = document.getElementById("pizzaoptions");
		var selected = optionsSelect.value;
		var optionsSelectLen = optionsSelect.length;
		var len = allOptions.length;
		var optionsArray = [];

		for (var i = 0; i < len; i++)
		{
			optionsArray.push(allOptions[i]);
		}

		optionsArray.sort(sortingFunc);
		if (sortReverse)
		{
			optionsArray.reverse();
		}

		//console.log("Resort " + sort + " filter " + $('#searchInput').val() + " 1st letter " +  $('#firstLetterInput').val() + " rev " + sortReverse);

		var filteredArray = optionsArray.filter(FilterCall);
		var filteredLen = filteredArray.length;

		for (var i = 0; i < optionsSelectLen; i++)
		{
			optionsSelect.remove(0);
		}

		for (var i = 0; i < filteredLen; i++)
		{
			optionsSelect.add(filteredArray[i]);
		}

		optionsSelect.selectedOption = 0;

		updateSortInterface();
	}

	function filterByText(textbox) 
	{
		$(textbox).bind('change keyup', function() 
		{
			ReSort();
		});
	};
	
	filterByText($('#searchInput'));
	filterByText($('#firstLetterInput'));

	function updateEffectListWithEffects(validEffects, initials)
	{
		var effectList = document.getElementById("effectList");
		var effectListOptions = [];
		var len = effectList.length;
		
		for (var i = 0; i < len; i++)
		{
			effectListOptions.push(effectList[i]);
		}
		
		for (var i = 0; i < len; i++)
		{
			effectList.remove(effectListOptions[i]);
		}

		for (var i = 0; i < validEffects.length; i++)
		{
			effectList.add(validEffects[i]);
		}

		var effectString = "Matches:" + validEffects.length + ",Initials considered:[" + initials + "]";
		if (validEffects.length > 5)
		{
			var effectString = effectString + "Too many matches!";
		}
		else
		{
			validEffects.forEach(element => {
				effectString = effectString + ",Effect:" + element.text + " Id:" + element.id;
			});
		}
		$('#pizzaEffect').val(effectString);
	}

	function updateEffectList(len)
	{
		if (len <= 0)
		{
			updateEffectListWithEffects(allEffects, "");
			return;
		}
		
		var validEffects = [];

		var initial = "";
		
		for (var i = 0; i < len; i++)
		{
			initial += letters[i];
		}
		
		initial = initial.toLowerCase();
		
		for (var i = 0; i < allEffects.length; i++)
		{
			if (allEffects[i].text.toLowerCase().startsWith(initial))
			{
				validEffects.push(allEffects[i]);
			}
		}
		
		if (validEffects.length == 0)
		{
			updateEffectList(len - 1);
			return;
		}
		
		updateEffectListWithEffects(validEffects, initial);
	}

	function updateSortInterface()
	{
		var sortReverseStr = sortReverse ? "v" : "^";

		var sortAlpha = document.getElementById("sort-alpha");
		sortAlpha.innerHTML = sort == "alpha" ? "Alpha " + sortReverseStr : "Alpha";
		
		var sortPrice = document.getElementById("sort-price");
		sortPrice.innerHTML = sort == "price" ? "Price " + sortReverseStr : "Price";
		
		var sortLetter = document.getElementById("sort-letter");
		sortLetter.innerHTML = sort == "letter" ? "Letters " + sortReverseStr : "Letters";
	}

	function updateEffectTurnsInterface(totalPrice)
	{
		var turns = PriceToTurns(totalPrice);
		var priceForNextTurn = PriceToTurnIncrease(totalPrice);
		var priceForMaxTurns = (10000 - totalPrice);

		var valueTurns = document.getElementById("valueTurns");
		valueTurns.innerHTML = turns;

		var valueMeat = document.getElementById("valueMeat");
		valueMeat.innerHTML = totalPrice;

		var valueMeatLeftToMax = document.getElementById("valueMeatLeftToMax");
		valueMeatLeftToMax.innerHTML = priceForMaxTurns;

		var valueMeatLeftToUp = document.getElementById("valueMeatLeftToUp");
		valueMeatLeftToUp.innerHTML = priceForNextTurn;

		$('#pizzaTurn').val(turns);
	}

	function updateAdventureInterface(totalLen)
	{
		var adventures = LenToAdventures(totalLen);
		var lenToNextAdventure = LenToAdvIncrease(totalLen);
		var lenToMaxAdventures = (145 - totalLen);

		var valueAdv = document.getElementById("valueAdv");
		valueAdv.innerHTML = adventures;

		var valueLetters = document.getElementById("valueLetters");
		valueLetters.innerHTML = totalLen;
		
		var valueLettersLeftToUp = document.getElementById("valueLettersLeftToUp");
		valueLettersLeftToUp.innerHTML = lenToNextAdventure;

		var valueLettersLeftToMax = document.getElementById("valueLettersLeftToMax");
		valueLettersLeftToMax.innerHTML = lenToMaxAdventures;

		$('#pizzaAdv').val(adventures);
	}

	function updateSpecialPizzaInterface()
	{
		var specialPizza = document.getElementById("specialPizza");
		var specialPizzaText = "none";
		if (special.length == 1)
		{
			specialPizzaText = "<span style=\"color:DodgerBlue;\">"+special[0]+"</span>";
		}
		else if (special.length > 1)
		{
			specialPizzaText = "<span style=\"color:Tomato\">";
			for (var i = 0; i < special.length; i++)
			{
				specialPizzaText += special[i] + " ";
			}
			specialPizzaText += "</span>";
		}
		specialPizza.innerHTML = specialPizzaText;

		$('#pizzaSpecial').val(specialPizzaText);
	}

	function updateInterface()
	{
		var totalPrice = 0;
		var totalLen = 0;
		
		for (var i = 0; i < 4; i++)
		{
			if (prices.length > i)
			{
				totalLen += parseInt(lens[i]);
				totalPrice += parseInt(prices[i]);
				var letter = document.getElementById("letter"+i);
				letter.innerHTML = letters[i];
			}
			else
			{
				var letter = document.getElementById("letter"+i);
				letter.innerHTML = "_";
			}
		}
		
		updateEffectList(letters.length);
		updateAdventureInterface(totalLen);
		updateEffectTurnsInterface(totalPrice);
		updateSpecialPizzaInterface();
	}
	
	$('#empty').click(
	function ()
	{
		prices = [];
		lens = [];
		letters = [];
		special = [];
		sort = "alpha";
		sortReverse = false;

		$('#searchInput').val("");
		$('#firstLetterInput').val("");

		RestoreOriginalOptions();
		updateInterface();
		updateSortInterface();
		ReSort();
	});
	
	$('#adding').click(
	function()
	{
		var opt = $('#pizzaoptions option:selected');
		var val = opt.text().replace(/ \(\d+\)$/, '');
		var len = opt.attr('data-len');
		var price = opt.attr('data-price');
		var count = opt.attr('data-qty');

		if (count == 1)
		{
			for (var i = 0; i < allOptions.length; i++)
			{
				if (allOptions[i] == opt)
				{
					allOptions.remove(i);
					break;
				}
			}
		}

		for (var i = 0; i < 7; i++)
		{
			var att = 'special' + i;
			var specialPizza = opt.attr(att);
			
			if (specialPizza != null && special.findIndex(function(a) { return a == specialPizza; }) < 0)
			{
				special.push(specialPizza);
			}
		}

		prices.push(price);
		lens.push(len);
		letters.push(val[0]);

		updateInterface();
	});

	$('#sort-alpha').click(
		function()
		{
			if (sort == "alpha")
			{
				sortReverse = !sortReverse;
				ReSort();
			}
			else
			{
				sort = "alpha";
				sortReverse = false;
				ReSort();
			}
		}
	);

	$('#sort-price').click(
		function()
		{
			if (sort == "price")
			{
				sortReverse = !sortReverse;
				ReSort();
			}
			else
			{
				sort = "price";
				sortReverse = false;
				ReSort();
			}
		}
	);

	$('#sort-letter').click(
		function()
		{
			if (sort == "letter")
			{
				sortReverse = !sortReverse;
				ReSort();
			}
			else
			{
				sort = "letter";
				sortReverse = false;
				ReSort();
			}
		}
	);
	
	$('#effectHelp').click(
		function()
		{
			var opt = $('#effectList option:selected');
			var descId = opt.attr('descId');
			
			eff(descId);
		}
	);

	RestoreOriginalOptions();
	updateInterface();
	updateSortInterface();
});
