import "relay/PizzaCubeGUI.ash";

void main()
{
	if (get_campground()[$item[Diabolic pizza cube]] > 0)
	{
		runMain();
	}
	else
	{
		write(visit_url());
	}
}
