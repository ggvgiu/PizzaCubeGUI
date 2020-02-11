import "relay/PizzaCubeGUI.ash";

void main()
{
	if (get_campground()[$item[Diabolic pizza cube]] > 0)
		handleRelayRequest();
	else
		write(visit_url());

}
