function writeInterface()
{
	document.write(`
	<p>Adventures: <b id="valueAdv"></b> <small>(<span id="valueLetters"></span>) letters</small><br>
	<small><em><span id="valueLettersLeft"></span> letters for 15 adv (max)</em></small></p>

	<p>Effect turns: <b id="valueTurns"></b><br>
	<small><em><span id="valueMeat"></span> total auto-sell, <span id="valueMeatLeftToUp"></span> for next turn increase, <span id="valueMeatLeftToMax"></span> for max turns.</em></small></p>

	<p>Effect initials: <b><u><span id="letter0"></span> <span id="letter1"></span> <span id="letter2"></span> <span id="letter3"></span></u></b></p>

	<p><em><b>Special effects: <big id="specialEffects"></big></b></em></p>
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
	var effects = [];
	var sort = "alpha";
	var sortReverse = false;

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
		var len = optionsSelect.length;
		var optionsArray = [];

		for (var i = 0; i < len; i++)
		{
			optionsArray.push(optionsSelect.item(i));
		}

		optionsArray.sort(sortingFunc);
		if (sortReverse)
		{
			optionsArray.reverse();
		}

		for (var i = 0; i < len; i++)
		{
			optionsSelect.remove(optionsArray[i]);
		}

		for (var i = 0; i < len; i++)
		{
			optionsSelect.add(optionsArray[i]);
		}

		optionsSelect.selectedOption = selected;

		updateSortInterface();
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

		var specialEffects = document.getElementById("specialEffects");
		var effectsText = "none";
		if (effects.length == 1)
		{
			effectsText = "<span style=\"color:DodgerBlue;\">"+effects[0]+"</span>";
		}
		else if (effects.length > 1)
		{
			effectsText = "<span style=\"color:Tomato\">";
			for (var i = 0; i < effects.length; i++)
			{
				effectsText += effects[i] + " ";
			}
			effectsText += "</span>";
		}
		specialEffects.innerHTML = effectsText;

		var valueAdv = document.getElementById("valueAdv");
		valueAdv.innerHTML = LenToAdventures(totalLen);

		var valueLetters = document.getElementById("valueLetters");
		valueLetters.innerHTML = totalLen;
		
		var valueLettersLeft = document.getElementById("valueLettersLeft");
		valueLettersLeft.innerHTML = (145 - totalLen);

		var valueTurns = document.getElementById("valueTurns");
		valueTurns.innerHTML = PriceToTurns(totalPrice);

		var valueMeat = document.getElementById("valueMeat");
		valueMeat.innerHTML = totalPrice;

		var valueMeatLeftToMax = document.getElementById("valueMeatLeftToMax");
		valueMeatLeftToMax.innerHTML = (10000 - totalPrice);

		var valueMeatLeftToUp = document.getElementById("valueMeatLeftToUp");
		valueMeatLeftToUp.innerHTML = PriceToTurnIncrease(totalPrice);
	}
	
	$('#empty').click(
	function ()
	{
		prices = [];
		lens = [];
		letters = [];
		effects = [];
		sort = "alpha";
		sortReverse = false;

		updateInterface();
		updateSortInterface();
	});
	
	$('#adding').click(
	function()
	{
		var opt = $('#pizzaoptions option:selected');
		var val = opt.text().replace(/ \(\d+\)$/, '');
		var len = opt.attr('data-len');
		var price = opt.attr('data-price');

		for (var i = 0; i < 7; i++)
		{
			var att = 'effect' + i;
			var effect = opt.attr('effect' + i);
			
			if (effect != null && effects.findIndex(function(a) { return a == effect; }) < 0)
			{
				effects.push(effect);
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

	updateInterface();
	updateSortInterface();
});
