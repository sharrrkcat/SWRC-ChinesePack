class CTSavingMenu extends MenuTemplateTitled;

var() MenuText			Label;
var() MenuText			XbLabel;

var() float				fMinTime;
var() float				fElapsedSeconds;

var() string			SaveGameName;

simulated function Init( string Args )
{
	Super.Init( Args );
	
	SaveGameName = ParseToken( Args );
	
	if ( IsOnConsole() )
		fMinTime = 3.0;
	else
		fMinTime = 0;

	fElapsedSeconds = 0.0;
	
    SetTimer( 0.1, true );
}

simulated function Timer()
{
	if ( fElapsedSeconds == 0.0 )
		ConsoleCommand( "SaveGame "$SaveGameName );	
	
	fElapsedSeconds += 0.1;
	
	if ( ( fElapsedSeconds >= fMinTime ) &&  ( GetPlayerOwner().Player.Console.CurMenu == self ) )
	{
		SetTimer( 0, false );
		
		CloseMenu();
	}
}


simulated function HandleInputBack();



defaultproperties
{
     Label=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="SAVING",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.5,ScaleX=1,ScaleY=1,Pass=2,Style="LabelText")
     XbLabel=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="PLEASE DON'T TURN OFF YOUR XBOX CONSOLE",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.6,ScaleX=1,ScaleY=1,Pass=2,Platform=MWP_Console,Style="LabelText")
     Background=(bHidden=1)
}

