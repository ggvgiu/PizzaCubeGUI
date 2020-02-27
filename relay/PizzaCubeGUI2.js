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

	var allEffects = [];
	var originalOptions = [];
	var ingredients = [];
	var badIngredients = false;
	
	/// INTERFACE ///
	function updateLetterCount(letters)
	{
		var adventures = LenToAdventures(letters);
		var lenToNextAdventure = LenToAdvIncrease(letters);
		var lenToMaxAdventures = (145 - letters);

		$('#valueAdv').html(adventures);
		$('#valueLetters').html(letters);
		$('#valueLettersLeftToUp').html(lenToNextAdventure);
		$('#valueLettersLeftToMax').html(lenToMaxAdventures);

		$('#pizzaAdv').val(adventures);
	}

	function updatePrice(price)
	{
		var turns = PriceToTurns(price);
		var priceForNextTurn = PriceToTurnIncrease(price);
		var priceForMaxTurns = (10000 - price);

		$('#valueTurns').html(turns);
		$('#valueMeat').html(price);
		$('#valueMeatLeftToUp').html(priceForNextTurn);
		$('#valueMeatLeftToMax').html(priceForMaxTurns);

		$('#pizzaTurn').val(turns);
	}

	function updateStats(full, drunk)
	{
		// TODO Interface as well, and log
	}

	function updateSpecial(special)
	{
		var specialPizzaText = "none";
		var specialPizzaLog = "none";

		if (special.length == 1)
		{
			specialPizzaText = "<span style=\"color:DodgerBlue;\">"+special[0]+"</span>";
			specialPizzaLog = special[0];
		}
		else if (special.length > 1)
		{
			specialPizzaText = "<span style=\"color:Tomato\">";
			specialPizzaLog = "";

			for (var i = 0; i < special.length; i++)
			{
				specialPizzaText += special[i] + " ";
				specialPizzaLog += special[i] + " ";
			}

			specialPizzaText += "</span>";
		}

		$('#specialPizza').html(specialPizzaText);
		
		$('#pizzaSpecial').val(specialPizzaLog);
	}

	function updateEffectListWithEffects(effects, initials)
	{
		$('#filtered-effects option').remove().end();
		
		for (var i = 0; i < effects.length; i++)
		{
			$('#filtered-effects').append(effects[i].clone());
		}

		var effectString = "Matches:" + effects.length + ",Initials considered:[" + initials + "]";
		if (effects.length > 5)
		{
			var effectString = effectString + "Too many matches!";
		}
		else
		{
			effects.forEach(element => {
				effectString = effectString + ",Effect:" + element.html() + " Id:" + element.attr("id");
			});
		}
		$('#pizzaEffect').val(effectString);

		$('#possible-effects').attr("style", "background-color: transparent;");
		if (effects.length > 1)
		{
			$('#possible-effects').attr("style", "background-color: tomato;");
		}
	}

	function updateEffectList(letters, len)
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
			if (allEffects[i].html().toLowerCase().startsWith(initial))
			{
				validEffects.push(allEffects[i]);
			}
		}
		
		if (validEffects.length == 0)
		{
			updateEffectList(letters, len - 1);
			return;
		}
		
		updateEffectListWithEffects(validEffects, initial);
	}

	function updatePredictions(currentIngredients)
	{

		var letterCount = 0;
		var price = 0;
		var full = 0;
		var drunk = 0;
		var special = [];
		var letters = [];

		$(currentIngredients).each(
			function()
			{
				letterCount += this.chars;
				price += this.price;
				full += this.full;
				drunk += this.drunk;

				for (var i = 0; i < this.special.length; i++)
				{
					var specialPizza = this.special[i];
					if (specialPizza != null && special.findIndex(function(a) { return a == specialPizza; }) < 0)
					{
						special.push(specialPizza);
					}
				}

				letters[this.row] = this.text[0];
			}
		);

		updateLetterCount(letterCount);
		updatePrice(price);
		updateStats(full, drunk);
		updateSpecial(special);
		updateEffectList(letters, letters.length);
	}

	function updateIngredientIcon(index, ing)
	{
		if (ing == undefined)
		{
			$('#img-' + index).attr("src", "/images/itemimages/horadricoven.gif");
			return;
		}

		$('#img-' + index).attr("src", "/images/itemimages/" + ing.img + ".gif");
	}

	function checkIngredientCounts(currentIngredients)
	{
		var ings = {};
		badIngredients = false;

		$(currentIngredients).each(
			function()
			{
				$('#item-row-' + this.row).attr("style", "background-color: transparent");

				var ing = {};
				ing.val = this.val;
				ing.maxCount = this.maxCount;
				ing.amount = 1;

				if (ings[ing.val] == undefined)
				{
					ings[ing.val] = ing;
					return;
				}

				ings[ing.val].amount++;

				if (ings[ing.val].amount > ings[ing.val].maxCount)
				{
					$('#item-row-' + this.row).attr("style", "background-color: tomato");
					badIngredients = true;
				}
			}
		);
	}

	function getIngredients()
	{
		var result = [];
		var index = [ 0, 1, 2, 3 ];

		$(index).each(
			function(i)
			{
				var option = $('#select-' + i + ' option:selected');
				result[i] = 
				{
					row: i,
					val: option.val(),
					maxCount: parseInt(option.attr("data-qty")),
					img: option.attr("data-pic"),
					price: parseInt(option.attr("data-price")),
					chars: parseInt(option.attr("data-len")),
					special: [],
					full: parseInt(option.attr("full")),
					drunk: parseInt(option.attr("drunk")),
					text: option.text().replace(/ \(\d+\)$/, ''),
				};

				for(var j = 0; j < 7; j++)
				{
					var special = option.attr("special" + j);
					if (special == undefined)
						break;
					result[i].special[j] = special;
				}
			}
		);

		return result;
	}

	function triggerIngredientChangeUpdate()
	{
		if (!ingredientsChanged) return;

		ingredientsChanged = false;

		var pizza = $('#pizza').val();

		var newPizza = $('#select-0 option:selected').val() + "," +
						$('#select-1 option:selected').val() + "," +
						$('#select-2 option:selected').val() + "," +
						$('#select-3 option:selected').val();

		if (pizza == newPizza)
		{
			return;
		}

		var currentIngredients = getIngredients();

		$(currentIngredients).each(updateIngredientIcon);

		checkIngredientCounts(currentIngredients);
		updatePredictions(currentIngredients);

		$('#pizza').val(newPizza);
	}

	// TODO maybe we can improve the logic by doing a proper chaining of this update, for now a timer solves the problem
	setInterval(triggerIngredientChangeUpdate, 50);

	var ingredientsChanged = false;
	function triggerIngredientChange()
	{
		ingredientsChanged = true;
	}	

	function updateSortingInterface(index)
	{
		var ingredient = ingredients[index];
		var sortReverseStr = ingredient.CurrentSortReverse ? "v" : "^";
		var sort = ingredient.CurrentSorting;
		$('#sort-alpha-' + index).html(sort == "alpha" ? "Alpha " + sortReverseStr : "Alpha");
		$('#sort-price-' + index).html(sort == "price" ? "Price " + sortReverseStr : "Price");
		$('#sort-letter-' + index).html(sort == "letter" ? "Letters " + sortReverseStr : "Letters");
	}

	function updateOptionsList(index, firstLetter, filter, sorting, sortReverse)
	{
		var sortingFunc;

		if (sorting == "alpha")
		{
			sortingFunc = function(a, b)
			{
				var aText = a.html().toLowerCase();
				var bText = b.html().toLowerCase();
				var sort = aText < bText ? -1 : aText > bText ? 1 : 0;
				return sort;
			};
		}
		else if (sorting == "price")
		{
			sortingFunc = function(a, b)
			{
				var aPrice = parseInt(a.attr("data-price"));
				var bPrice = parseInt(b.attr("data-price"));
				return aPrice - bPrice;
			}
		}
		else if (sorting == "letter")
		{
			sortingFunc = function(a, b)
			{
				var aPrice = parseInt(a.attr("data-len"));
				var bPrice = parseInt(b.attr("data-len"));
				return aPrice - bPrice;
			}
		}

		var selected = $('#select-' + index + ' option:selected').val();

		$('#select-' + index + ' option').remove().end();

		var optionsArray = originalOptions.filter(
			function(item)
			{
				var text = item.html().toLowerCase();
				var result = text.includes(filter);
				return result && text.startsWith(firstLetter);
			}
		);

		optionsArray.sort(sortingFunc);
		if (sortReverse)
		{
			optionsArray.reverse();
		}

		$(optionsArray).each( 
			function () 
			{
				$('#select-' + index).append($(this).clone());
			}
		);

		$('#select-' + index).val(selected);

		if ($('#select-' + index).val() != selected)
		{
			triggerIngredientChange();
		}
	}

	/// LOGICS ///
	
	function initIngredient(index)
	{
		ingredients[index] = {};
		ingredients[index].CurrentSorting = "alpha";
		ingredients[index].CurrentSortReverse = false;
		ingredients[index].Sorting = "none";
		ingredients[index].SortReverse = false;
		ingredients[index].FirstLetter = "";
		ingredients[index].Filter = "";
		ingredients[index].Selected = -1;
	}
	
	function initIngredients()
	{
		for	(var i = 0; i < 4; i++)
		{
			initIngredient(i);
		}
	}

	function refreshIngredientList(index)
	{
		var ingredient = ingredients[index];

		var firstLetter = $('#letter-' + index).val().toLowerCase();;
		var filter = $('#filter-' + index).val().toLowerCase();;
		var sorting = ingredient.CurrentSorting;
		var sortReverse = ingredient.CurrentSortReverse;

		var mustUpdate = 
			firstLetter != ingredient.FirstLetter || 
			filter != ingredient.Filter ||
			sorting != ingredient.Sorting ||
			sortReverse != ingredient.SortReverse;

		// console.log("Must=" + mustUpdate + " " + index);
		// console.log("firstLetter=" + firstLetter + " " + ingredient.FirstLetter);
		// console.log("filter=" + filter + " " + ingredient.Filter);
		// console.log("sorting=" + sorting + " " + ingredient.Sorting);
		// console.log("sortReverse=" + sortReverse + " " + ingredient.SortReverse);

		ingredient.Filter = filter;
		ingredient.FirstLetter = firstLetter;
		ingredient.Sorting = ingredient.CurrentSorting;
		ingredient.SortReverse = ingredient.CurrentSortReverse;

		if (mustUpdate)
		{
			updateOptionsList(index, firstLetter, filter, sorting, sortReverse);
		}
	}

	function refreshAllIngredientLists()
	{
		for	(var i = 0; i < 4; i++)
		{
			refreshIngredientList(i);
		}
	}

	function changeSorting(sorting, index)
	{
		var ingredient = ingredients[index];
		ingredient.CurrentSorting = sorting;
		if (ingredient.Sorting == sorting)
		{
			ingredient.CurrentSortReverse = !ingredient.SortReverse;
		}
		else
		{
			ingredient.CurrentSortReverse = false;
		}
		refreshIngredientList(index);
		updateSortingInterface(index);
	}
	
	function installListenersForIngredient(index)
	{
		function filterByText(textbox) 
		{
			$(textbox).bind('change keyup', function() 
			{
				refreshIngredientList(index);
			});
		};

		filterByText($('#letter-' + index));
		filterByText($('#filter-' + index));
		
		function sortButtonClick(sortButton, sorting, index)
		{
			$(sortButton).click(
				function()
				{
					changeSorting(sorting, index);
				}
			);
		}
		
		sortButtonClick($('#sort-alpha-' + index), "alpha", index);
		sortButtonClick($('#sort-price-' + index), "price", index);
		sortButtonClick($('#sort-letter-' + index), "letter", index);

		$('#select-' + index).change(triggerIngredientChange);
	}
	
	function installListeners()
	{
		for (var i = 0; i < 4; i++)
		{
			installListenersForIngredient(i);
		}
		
		$('#effect-help').click(
			function()
			{
				var opt = $('#all-effects option:selected');
				var descId = opt.attr('descId');
				eff(descId);
			}
		);

		$('#filtered-effects').change(() => $('#all-effects').val($('#filtered-effects').val()));
		$('#filtered-effects').dblclick(() => $('#all-effects').val($('#filtered-effects').val()));

		$('#fill-letters').click(
			function()
			{
				var opt = $('#all-effects option:selected');
				
				var broken = false;
				for (var i = 0; i < 4; i++)
				{
					var current;

					if (opt.text().length <= i)
					{
						current = '';
					}
					else
					{
						current = opt.text()[i];
					}

					if (current == ' ')
					{
						broken = true;
					}
					
					if (broken)
					{
						$('#letter-'+i).val('');
					}
					else
					{
						$('#letter-'+i).val(current);
					}
				}
				
				refreshAllIngredientLists();
			}
		);
		
		$('#bake-pizza').click(
			function()
			{
				if (badIngredients)
				{
					alert("You don't have that many of those, check your ingredients!");
					return;
				}

				$('#pizza-form').submit();
			}
		);
	}

	function init()
	{
		$('#all-effects option').each(
			function()
			{
				var clone = $(this).clone();
				allEffects.push(clone);
			}
		);

		$('#select-0 option').each(
			function()
			{
				var clone = $(this).clone();
				originalOptions.push(clone);
			}
		);

		initIngredients();
		installListeners();
		refreshAllIngredientLists();
		triggerIngredientChange();
	}
	
	init();
});
