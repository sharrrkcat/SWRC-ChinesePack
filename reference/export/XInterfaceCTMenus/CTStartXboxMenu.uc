class CTStartXboxMenu extends MenuTemplate;

var() MenuSprite    Background;

var() MenuButtonText	Start;

var() bool				bLECIntroWasPlaying;

var() Sound				StoredBG;

var() bool				bStartSelected;

simulated function Init( String Args )
{
	Background.WidgetTexture=Material(DynamicLoadObject("GUIContent.RC_Title_Xbox", class'Material'));
	
	Super.Init( Args );
	
	if ( Caps(GetPlayerOwner().GetLanguage()) != "INT" )
	{
		Start.BackgroundBlurred.ScaleX=0.4;
		Start.BackgroundFocused.ScaleX=0.4;
	}
	
	//StopBackgroundMovie();
	
    FocusOnWidget( Start );
    
	// Fool the Console into thinking we don't have background music
    StoredBG = BackgroundMusic;
    BackgroundMusic = None;
    
	if ( !GetPlayerOwner().IsMoviePlaying() )
	{
		GetPlayerOwner().PlayMovie( False, True, False, False, "LECIntro.xmv", True );
		FocusOnNothing();
		bLECIntroWasPlaying = True;
	}    
}

simulated function Tick( float ElapsedTime )
{
	local array<BYTE> buttons;
	local Vector LJoy;
	local Vector RJoy;
	local byte vpGamePadIdx;
	local int i;
	local bool bGoodButtonDown;
	local bool bOtherButtonDown;
	const BUTTON_START = 12;
	const BUTTON_A = 0;

	if ( !GetPlayerOwner().IsMoviePlaying() )
	{
		if ( bLECIntroWasPlaying )
		{
			BackgroundMusic = StoredBG;
			StoredBG = None;
			GetPlayerOwner().Player.Console.ManageMenuBackgroundMusic( self );
			bLECIntroWasPlaying = False;
			FocusOnWidget( Start );
		}
	}
		
	Super.Tick( ElapsedTime );
	
	if ( bStartSelected )
		return;
		
	if ( !GetPlayerOwner().IsMoviePlaying() )
	{
		vpGamePadIdx = GetPlayerOwner().Player.GamePadIndex;
		if ( vpGamePadIdx < 251 )
		{
			// There's a pad associated with the viewport...
			buttons.Length = 16;
			
			// Let's make double-sure it's initialized to zero
			for ( i = 0; i < 16; ++i )
				buttons[i] = 0;
				
			GetPlayerOwner().GetPadInput( vpGamePadIdx, buttons, LJoy, RJoy  );
			
			bGoodButtonDown = False;
			bOtherButtonDown = False;
			for ( i = 0; i < 16; ++i )
			{
				if ( buttons[i] != 0 )
				{
					if ( ( BUTTON_A == i ) || ( BUTTON_START == i ) )
						bGoodButtonDown = True;
					else
						bOtherButtonDown = True;
				}
			}		

			// If the "A" or "Start" button isn't down and there's another
			// button down, then disassociate the pad
			if ( !bGoodButtonDown && bOtherButtonDown )
			{
log("CTSTARTMENUXBOX:  DISASSOCIATE PADS");
				GetPlayerOwner().DisassociateViewportPads();
			}
		}
	}
}

simulated function StartSelected()
{
	bStartSelected = True;
	GotoMenuClass("XInterfaceCTMenus.CTMenuMain");
}

simulated function HandleInputBack();



defaultproperties
{
     Background=(DrawColor=(B=255,G=255,R=255,A=255),ScaleX=1,ScaleY=1,ScaleMode=MSCM_Fit,Pass=1,Style="FullScreen")
     Start=(Blurred=(Text="PRESS START",PosX=0.5,PosY=0.851667),BackgroundBlurred=(PosX=0.5,PosY=0.851667,ScaleX=0.27,ScaleY=0.04333),OnSelect="StartSelected",Pass=2,Style="ButtonTextStyle1")
     ModulateRate=1
     BackgroundMovieName=""
     bFullscreenOnly=True
}

