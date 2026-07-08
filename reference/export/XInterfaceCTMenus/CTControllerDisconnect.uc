class CTControllerDisconnect extends MenuTemplateTitledA;

var() MenuText			Label;
var() bool				Paused;

simulated function Init( string Args )
{
	local string PortNum;

	Super.Init( Args );
	
	PortNum = ParseToken(Args);
	
    UpdateTextField( Label.Text, "%s", PortNum );
	
	if ( !GetPlayerOwner().IsPaused() )
	{
		GetPlayerOwner().SetPause( True );
		Paused = True;
	}
	else
	{
		Paused = False;
	}
	
	GetPlayerOwner().IgnoreOtherViewportInput( True );	
	
	if ( int(ConsoleCommand("NUMVIEWPORTS")) > 1 )
		InLevelBackgroundMovieReplacement.DrawColor.A = 255;
}

simulated function Tick( float fElapsedTime )
{
	// We need to check to see if another disconnect menu
	// has disabled our input...if so, re-enable it.
	if ( GetPlayerOwner().IgnoringViewportInput() )
		GetPlayerOwner().IgnoreViewportInput( False );
}

simulated function HandleInputBack();

simulated function OnAButton()
{
	if ( Paused )
		GetPlayerOwner().SetPause( False );
		
	// Enable input on the other controllers
	GetPlayerOwner().IgnoreOtherViewportInput( False );
	
	CloseMenu();
}

simulated function HandleInputStart()
{
    OnAButton();
}

simulated function bool HandleInputGamePad( String ButtonName )
{
    if( ButtonName ~= "A" )
    {
        OnAButton();
        return( true );
    }
    
	return( Super.HandleInputGamePad( ButtonName ) );
}


defaultproperties
{
     Label=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="PLEASE RECONNECT THE CONTROLLER TO CONTROLLER PORT %s AND PRESS START TO CONTINUE.",DrawPivot=DP_MiddleLeft,PosX=0.075,PosY=0.55,ScaleX=1,ScaleY=1,MaxSizeX=0.85,bWordWrap=1,Pass=2,Style="LabelText")
     Background=(bHidden=1)
     MenuTitle=(Text="WARNING",bHidden=0)
     FullscreenPriority=1
}

