class CTExtrasMenu extends MenuTemplateTitledBA;

var() MenuText			Label;

var() MenuSprite		KaminoBorder;
var() MenuSprite		Kamino;

var() MenuSprite		GeonosisBorder;
var() MenuSprite		Geonosis;

var() MenuSprite		AssaultShipBorder;
var() MenuSprite		AssaultShip;

var() MenuSprite		KashyyykBorder;
var() MenuSprite		Kashyyyk;

var() MenuSprite		Border;

var() MenuText			UnlockText[5];
var() MenuButtonText	Extras[5];
var() MenuSprite		UnlockedLeftBars[5];
var() MenuSprite		UnlockedRightBars[5];

var() MenuButtonText	Credits;

var() bool				bMovieWasPlaying;

simulated function Init( String Args )
{
	//local int i;
	
	Super.Init( Args );

    FocusOnWidget( Extras[0] );

/**************************************************************
    // Disable stuff they haven't got to yet
    for ( i = 4; i >= 0; --i )
    {
		// NOT DONE...put some check in for this item...
		if ( i > 1 ) /// BOGUS
		{
			UnlockedLeftBars[i].bHidden = 1;
			UnlockedRightBars[i].bHidden = 1;
			Extras[i].bDisabled = 1;
			Extras[i].Blurred.DrawColor.R = 128;
			Extras[i].Blurred.DrawColor.G = 128;
			Extras[i].Blurred.DrawColor.B = 128;
			Extras[i].Blurred.PosY += 0.01;

			UnlockText[i].bHidden=0;
		}
		else
		{
			UnlockText[i].bHidden=1;
		}
	}
****************************************************************/


	if ( !GetPlayerOwner().HasReachedLevel( "RAS_01Briefing" ) )
	{
		UnlockedLeftBars[2].bHidden = 1;
		UnlockedRightBars[2].bHidden = 1;
		Extras[2].bDisabled = 1;
		Extras[2].Blurred.DrawColor.R = 128;
		Extras[2].Blurred.DrawColor.G = 128;
		Extras[2].Blurred.DrawColor.B = 128;
		Extras[2].Blurred.PosY += 0.01;

		UnlockText[2].bHidden=0;
	}
	else
	{
		UnlockText[2].bHidden=1;
	}
	
	if ( !GetPlayerOwner().HasReachedLevel( "YYY_01Briefing" ) )
	{
		UnlockedLeftBars[3].bHidden = 1;
		UnlockedRightBars[3].bHidden = 1;
		Extras[3].bDisabled = 1;
		Extras[3].Blurred.DrawColor.R = 128;
		Extras[3].Blurred.DrawColor.G = 128;
		Extras[3].Blurred.DrawColor.B = 128;
		Extras[3].Blurred.PosY += 0.01;

		UnlockText[3].bHidden=0;
	}
	else
	{
		UnlockText[3].bHidden=1;
	}	
	
	if ( !GetPlayerOwner().HasReachedLevel( "Epilogue" ) )
	{
		UnlockedLeftBars[4].bHidden = 1;
		UnlockedRightBars[4].bHidden = 1;
		Extras[4].bDisabled = 1;
		Extras[4].Blurred.DrawColor.R = 128;
		Extras[4].Blurred.DrawColor.G = 128;
		Extras[4].Blurred.DrawColor.B = 128;
		Extras[4].Blurred.PosY += 0.01;

		UnlockText[4].bHidden=0;
	}
	else
	{
		UnlockText[4].bHidden=1;
	}
}

simulated function Extra0Selected()
{
	if ( !GetPlayerOwner().IsMoviePlaying() )
	{
		GetPlayerOwner().Player.Console.StopMenuBackgroundMusic(BackgroundMusic);
		GetPlayerOwner().PlayMovie( False, True, False, False, "ExtrasAsh.xmv" );
		if ( IsOnConsole() )
			StopBackgroundMovie();
		FocusOnNothing();
		bMovieWasPlaying = True;
	}
}

simulated function Extra1Selected()
{
	if ( !GetPlayerOwner().IsMoviePlaying() )
	{
		GetPlayerOwner().Player.Console.StopMenuBackgroundMusic(BackgroundMusic);
		GetPlayerOwner().PlayMovie( False, True, False, False, "ExtrasConcept.xmv" );
		if ( IsOnConsole() )
			StopBackgroundMovie();
		FocusOnNothing();
		bMovieWasPlaying = True;
	}
}

simulated function Extra2Selected()
{
	if ( !GetPlayerOwner().IsMoviePlaying() )
	{
		GetPlayerOwner().Player.Console.StopMenuBackgroundMusic(BackgroundMusic);
		GetPlayerOwner().PlayMovie( False, True, False, False, "ExtrasFoley.xmv" );
		if ( IsOnConsole() )
			StopBackgroundMovie();
		FocusOnNothing();
		bMovieWasPlaying = True;
	}
}

simulated function Extra3Selected()
{
	if ( !GetPlayerOwner().IsMoviePlaying() )
	{
		GetPlayerOwner().Player.Console.StopMenuBackgroundMusic(BackgroundMusic);
		GetPlayerOwner().PlayMovie( False, True, False, False, "ExtrasTraining.xmv" );
		if ( IsOnConsole() )
			StopBackgroundMovie();
		FocusOnNothing();
		bMovieWasPlaying = True;
	}
}

simulated function Extra4Selected()
{
	if ( !GetPlayerOwner().IsMoviePlaying() )
	{
		GetPlayerOwner().Player.Console.StopMenuBackgroundMusic(BackgroundMusic);
		GetPlayerOwner().PlayMovie( False, True, False, False, "ExtrasInterview.xmv" );
		if ( IsOnConsole() )
			StopBackgroundMovie();
		FocusOnNothing();
		bMovieWasPlaying = True;
	}
}

simulated function CreditsSelected()
{
	CallMenuClass("XInterfaceCTMenus.CTCreditsMenu", "FROMEXTRAS");
}

simulated function Tick( float ElapsedTime )
{
	if ( !GetPlayerOwner().IsMoviePlaying() && bMovieWasPlaying )
	{
		GetPlayerOwner().Player.Console.StartMenuBackgroundMusic(BackgroundMusic);
		
		if ( ( GetPlayerOwner().Player.Console.CurMenu == self ) &&
			 ( GetPlayerOwner().ControllerAttached( GetPlayerOwner().Player.GamePadIndex ) ) )
		{
			if ( IsOnConsole() )
				StartBackgroundMovie();
		}
		
		bMovieWasPlaying = False;
	}
	
	Super.Tick( ElapsedTime );
}


defaultproperties
{
     Label=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="EXTRAS",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.108333,ScaleX=1.75,ScaleY=1.75,Style="LabelText")
     KaminoBorder=(DrawColor=(B=96,G=96,R=96,A=255),PosX=0.1375,PosY=0.16,ScaleX=0.125,ScaleY=0.1666,Style="PlanetBorderStyle")
     Kamino=(WidgetTexture=Texture'GUIContent.Menu.CT_Kamino',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.1375,PosY=0.16)
     GeonosisBorder=(DrawColor=(B=96,G=96,R=96,A=255),PosX=0.32625,PosY=0.238333,ScaleX=0.22125,ScaleY=0.295,Style="PlanetBorderStyle")
     Geonosis=(WidgetTexture=Texture'GUIContent.Menu.CT_Geonosis',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.32625,PosY=0.238333)
     AssaultShipBorder=(DrawColor=(B=96,G=96,R=96,A=255),PosX=0.565,PosY=0.23,ScaleX=0.2325,ScaleY=0.31,Style="PlanetBorderStyle")
     AssaultShip=(WidgetTexture=Texture'GUIContent.Menu.CT_RAS',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.565,PosY=0.23)
     KashyyykBorder=(DrawColor=(B=96,G=96,R=96,A=255),PosX=0.82875,PosY=0.215,ScaleX=0.26375,ScaleY=0.351666,Style="PlanetBorderStyle")
     Kashyyyk=(WidgetTexture=Texture'GUIContent.Menu.CT_Kashyyyk',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.82875,PosY=0.215)
     Border=(PosX=0.5,PosY=0.5,ScaleX=0.8075,ScaleY=0.64333,ScaleMode=MSCM_FitStretch,Style="BorderStyle1")
     UnlockText(0)=(MenuFont=Font'OrbitFonts.OrbitBold15',DrawColor=(B=128,G=128,R=128,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.25,ScaleY=0.8,Style="LabelText")
     UnlockText(1)=(PosY=0.36)
     UnlockText(2)=(Text="COMPLETE GEONOSIS CAMPAIGN FOR")
     UnlockText(3)=(Text="COMPLETE ASSAULT SHIP CAMPAIGN FOR")
     UnlockText(4)=(Text="COMPLETE KASHYYYK CAMPAIGN FOR")
     Extras(0)=(Blurred=(Text="ASH VIDEO",PosX=0.5,PosY=0.27666),BackgroundBlurred=(PosX=0.5,PosY=0.27666,ScaleX=0.715,ScaleY=0.08333),OnSelect="Extra0Selected",Style="ButtonTextStyle1")
     Extras(1)=(Blurred=(Text="CONCEPT ART MONTAGE",PosY=0.385),BackgroundBlurred=(PosY=0.385),OnSelect="Extra1Selected")
     Extras(2)=(Blurred=(Text="FOLEY FEATURETTE"),OnSelect="Extra2Selected")
     Extras(3)=(Blurred=(Text="SPEC OPS FEATURETTE"),OnSelect="Extra3Selected")
     Extras(4)=(Blurred=(Text="TEMUERA MORRISON INTERVIEW"),OnSelect="Extra4Selected")
     UnlockedLeftBars(0)=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.13125,PosY=0.27666,ScaleX=0.00625,ScaleY=0.08333,ScaleMode=MSCM_FitStretch)
     UnlockedLeftBars(1)=(PosY=0.385)
     UnlockedRightBars(0)=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.87625,PosY=0.27666,ScaleX=0.00625,ScaleY=0.08333,ScaleMode=MSCM_FitStretch)
     UnlockedRightBars(1)=(PosY=0.385)
     Credits=(Blurred=(Text="VIEW CREDITS",PosX=0.5,PosY=0.785),BackgroundBlurred=(PosX=0.5,PosY=0.785,ScaleX=0.715,ScaleY=0.04333),OnSelect="CreditsSelected",Style="ButtonTextStyle1")
     Background=(WidgetTexture=Texture'GUIContent.Menu.CT_MainMenuGraphics',Style="FullScreen")
     ModulateRate=1
}

