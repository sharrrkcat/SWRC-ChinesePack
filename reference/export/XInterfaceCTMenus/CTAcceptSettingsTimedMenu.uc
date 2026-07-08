class CTAcceptSettingsTimedMenu extends MenuTemplateTitledBA;

var() MenuText			Label;
var() MenuText			CountdownLabel;

var() bool				bYes;
var() bool				bNo;
var() bool				bTimedOut;

var() float				fTimeoutTime;
var() float				fElapsedSeconds;


simulated function Init( string Args )
{
	Super.Init( Args );
	
	bYes = False;
	bNo = False;
	bTimedOut = False;
	
	fTimeoutTime = 15.0;
	fElapsedSeconds = 0.0;
	
	CountdownLabel.Text = string(int(fTimeoutTime));
	
    SetTimer( 1.0, true );	
}

simulated function Timer()
{
	fElapsedSeconds += 1.0;
	if ( fElapsedSeconds >= fTimeoutTime )
	{
		SetTimer( 0, false );
		bTimedOut = True;
		
		CloseMenu();
	}
	
	CountdownLabel.Text = string(int(fTimeoutTime - fElapsedSeconds));
}

simulated function OnAButton()
{
	SetTimer( 0, false );
	bYes = True;
	CloseMenu();
}

simulated function OnBButton()
{
	SetTimer( 0, false );
	bNo = True;
	CloseMenu();
}


simulated function HandleInputBack()
{
	OnBButton();
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
     Label=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="ACCEPT THESE SETTINGS?",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.125,ScaleX=1.75,ScaleY=1.75,Pass=2,Style="LabelText")
     CountdownLabel=(MenuFont=Font'OrbitFonts.OrbitBold15',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.5,Pass=2,Style="LabelText")
     ALabel=(Text="YES :")
     AButton=(Blurred=(Text="YES"),bHidden=0)
     BLabel=(Text=": NO")
     BButton=(Blurred=(Text="NO"))
     Background=(bHidden=1)
}

