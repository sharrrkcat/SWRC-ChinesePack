class CTSavingSettingsMenu extends MenuWarningTransition;

simulated function Init(string Args)
{
    Super.Init(Args);
}

simulated function DoWork()
{
}

simulated function Done()
{
	CloseMenu();
}


defaultproperties
{
     Message=(Text="SAVING SETTINGS")
     Background=(bHidden=1)
}

