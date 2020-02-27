
void main()
{
	print("You baked a pizza!", "blue");

	string [string] form_fields = form_fields();

	string[int] pizzaSplit;
	string[int] effectSplit;
	string pizza = form_fields["pizza"];
	string adv = form_fields["pizzaAdv"];
	string turn = form_fields["pizzaTurn"];
	string special = form_fields["pizzaSpecial"];
	string effectString = form_fields["pizzaEffect"];

	pizzaSplit = pizza.split_string(",");
	effectSplit = effectString.split_string(",");

	print("Ingredients: {" + pizza + "}", "red");

	foreach key, value in pizzaSplit
	{
		item it = value.to_item();
		print ("[" + key + "] " + it.to_string(), "blue");
	}

	print("Adventures:", "red");
	print(adv, "blue");

	print("Effect turns:", "red");
	print(turn, "blue");

	print("Special features:", "red");
	print(special, "blue");

	print("Possible effects:", "red");
	foreach key, value in effectSplit
	{
		print(value, "blue");
	}
}
