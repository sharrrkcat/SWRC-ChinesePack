class CTStartPCMenu extends MenuTemplate;

var() MenuSprite    Background;

var() MenuButtonText	Start;

var() MenuText			LegalText;

var() bool				bLECIntroWasPlaying;
var() bool				bNVIDIAIntroWasPlaying;

var() Sound				StoredBG;

simulated function Init( String Args )
{
	local String Lang;
	
	Background.WidgetTexture=Material(DynamicLoadObject("GUIContent.RC_Title_BG", class'Material'));
	
	Super.Init( Args );
	
    FocusOnWidget( Start );

	// Fool the Console into thinking we don't have background music
    StoredBG = BackgroundMusic;
    BackgroundMusic = None;
    
	if ( !GetPlayerOwner().IsMoviePlaying() )
	{
		GetPlayerOwner().PlayMovie( False, True, False, False, "LECIntro.avi" );
		FocusOnNothing();
		bLECIntroWasPlaying = True;
	}
		
	Lang = Caps( GetPlayerOwner().GetLanguage() );
	
	if ( Lang == "DET" || Lang == "EST" || Lang == "ITT" )
	{
		GetPlayerOwner().Player.Console.ConsoleKey = 220;
		GetPlayerOwner().Player.Console.SaveConfig();
	}
	else if ( Lang == "FRT" )
	{
		GetPlayerOwner().Player.Console.ConsoleKey = 222;
		GetPlayerOwner().Player.Console.SaveConfig();
	}
}

simulated function Tick( float ElapsedTime )
{
	if ( !GetPlayerOwner().IsMoviePlaying() )
	{
		if ( bLECIntroWasPlaying )
		{
			bLECIntroWasPlaying = False;
			GetPlayerOwner().PlayMovie( False, True, False, False, "NVIDIAIntro.avi" );
			FocusOnNothing();
			bNVIDIAIntroWasPlaying = True;			
		}
		else if ( bNVIDIAIntroWasPlaying )
		{
			BackgroundMusic = StoredBG;
			StoredBG = None;
			GetPlayerOwner().Player.Console.ManageMenuBackgroundMusic( self );
			bNVIDIAIntroWasPlaying = False;
			FocusOnWidget( Start );
		}
	}
		
	Super.Tick( ElapsedTime );
}

simulated function StartSelected()
{
	GotoMenuClass("XInterfaceCTMenus.CTMenuMain");
}

simulated function HandleInputBack();



defaultproperties
{
     Background=(DrawColor=(B=255,G=255,R=255,A=255),ScaleX=1,ScaleY=1,ScaleMode=MSCM_Fit,Style="FullScreen")
     Start=(Blurred=(Text="CONTINUE",PosX=0.5,PosY=0.691666),BackgroundBlurred=(PosX=0.5,PosY=0.691666,ScaleX=0.27,ScaleY=0.04333),OnSelect="StartSelected",Style="ButtonTextStyle1")
     LegalText=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="LucasArts, the LucasArts logo, STAR WARS, and related properties are trademarks in the United States and/or in other countries of Lucasfilm Ltd. and/or its affiliates.  STAR WARS Republic Commando is a trademark of Lucasfilm Entertainment Company Ltd. and/or its affiliates.  © 2005 Lucasfilm Entertainment Company Ltd. or Lucasfilm Ltd.  All rights reserved.",DrawPivot=DP_UpperMiddle,PosX=0.55,PosY=0.79,MaxSizeX=0.3,bWordWrap=1,Platform=MWP_PC)
     ModulateRate=1
     BackgroundMovieName=""
     bFullscreenOnly=True
}

