class CTMenuMain extends MenuTemplateTitledA;

var() MenuSprite		KaminoBorder;
var() MenuSprite		Kamino;

var() MenuSprite		GeonosisBorder;
var() MenuSprite		Geonosis;

var() MenuSprite		AssaultShipBorder;
var() MenuSprite		AssaultShip;

var() MenuSprite		KashyyykBorder;
var() MenuSprite		Kashyyyk;

var() MenuSprite		GameTitle;

var() MenuSprite		LabelBackground;
var() MenuText			Label;
var() MenuSprite		LabelConnector;

var() MenuSprite		Border;

var() MenuButtonText	MenuOptions[8];

// xbox live stuff
var() MenuSprite FriendsIcon;
var() Material FriendRequestIcon;
var() Material GameInviteIcon;
var() bool bFoundCrossTitleInvite;
var bool linkActive;

var autoload array<string> MenuNames;

var() localized String	QuitGameConfirm;
var() localized String	QuitXBoxGameConfirm;

var() bool	bLowStorage;

var() bool	bGotInitialProfile;

simulated function Init( String Args )
{
	local Array<string> Profiles;
    local xUtil.PlayerRecord pr;
	/*** SBD - REMOVED BY DESIGN
    local string DefaultName;
    ***/
	local string value;
	local bool bGotValue;
	local bool bOXMDemo;
	local bool bDVDDemo;
	local bool bMarketingDemo;
	local bool bPCDemo;
	local string DemoProfileName;
	local int controllerIndex;
	local int i;
	local bool bFoundDemoProfile;

	HostText.DrawPivot = DP_MiddleRight;
	HostText.PosX=0.87;
	HostText.PosY=0.4;
	
	if ( IsOnConsole() )
		MenuOptions[7].bHidden = 1;
    
	Super.Init( Args );
	
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "OXMDemo", value );			
	if ( bGotValue )
		bOXMDemo = bool(value);

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "DVDDemo", value );			
	if ( bGotValue )
		bDVDDemo = bool(value);

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "MarketingDemo", value );			
	if ( bGotValue )
		bMarketingDemo = bool(value);

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "PCD", value );			
	if ( bGotValue )
		bPCDemo = bool(value);

	if ( bOXMDemo || bDVDDemo || bMarketingDemo )
	{
		MenuOptions[1].bDisabled = 1;
		MenuOptions[1].Blurred.DrawColor.R = 128;
		MenuOptions[1].Blurred.DrawColor.G = 128;
		MenuOptions[1].Blurred.DrawColor.B = 128;

		MenuOptions[2].bDisabled = 1;
		MenuOptions[2].Blurred.DrawColor.R = 128;
		MenuOptions[2].Blurred.DrawColor.G = 128;
		MenuOptions[2].Blurred.DrawColor.B = 128;

		MenuOptions[3].bDisabled = 1;
		MenuOptions[3].Blurred.DrawColor.R = 128;
		MenuOptions[3].Blurred.DrawColor.G = 128;
		MenuOptions[3].Blurred.DrawColor.B = 128;
		
		MenuOptions[5].bDisabled = 1;
		MenuOptions[5].Blurred.DrawColor.R = 128;
		MenuOptions[5].Blurred.DrawColor.G = 128;
		MenuOptions[5].Blurred.DrawColor.B = 128;

		MenuOptions[6].bDisabled = 1;
		MenuOptions[6].Blurred.DrawColor.R = 128;
		MenuOptions[6].Blurred.DrawColor.G = 128;
		MenuOptions[6].Blurred.DrawColor.B = 128;
		
		bShowGamertag = False;
		HostText.bHidden = 1;
		
		MenuOptions[7].bHidden = 0;		

		bGotInitialProfile = True;
	}

	if ( !IsOnConsole() && bPCDemo )
	{
		MenuOptions[2].bDisabled = 1;
		MenuOptions[2].Blurred.DrawColor.R = 128;
		MenuOptions[2].Blurred.DrawColor.G = 128;
		MenuOptions[2].Blurred.DrawColor.B = 128;

		MenuOptions[3].bDisabled = 1;
		MenuOptions[3].Blurred.DrawColor.R = 128;
		MenuOptions[3].Blurred.DrawColor.G = 128;
		MenuOptions[3].Blurred.DrawColor.B = 128;
		
		MenuOptions[5].bDisabled = 1;
		MenuOptions[5].Blurred.DrawColor.R = 128;
		MenuOptions[5].Blurred.DrawColor.G = 128;
		MenuOptions[5].Blurred.DrawColor.B = 128;

		MenuOptions[6].bDisabled = 1;
		MenuOptions[6].Blurred.DrawColor.R = 128;
		MenuOptions[6].Blurred.DrawColor.G = 128;
		MenuOptions[6].Blurred.DrawColor.B = 128;
		
		bGotInitialProfile = True;
	}
	
	if ( !IsOnConsole() || bOXMDemo || bDVDDemo || bMarketingDemo )
	{
		// Have to make a little room for the quit option on the PC & demo
		Border.PosY += 0.02833;
		Border.ScaleY += 0.05666;
	}
	
	if ( Caps(GetPlayerOwner().GetLanguage()) != "INT" )
	{
		// Remove the extras option for foreign languages
		MenuOptions[6].bHidden = 1;
		
		MenuOptions[7].Blurred.PosY = MenuOptions[6].Blurred.PosY;
		MenuOptions[7].Focused.PosY = MenuOptions[6].Focused.PosY;
		MenuOptions[7].BackgroundBlurred.PosY = MenuOptions[6].BackgroundBlurred.PosY;
		MenuOptions[7].BackgroundFocused.PosY = MenuOptions[6].BackgroundFocused.PosY;

		Border.PosY -= 0.02833;
		Border.ScaleY -= 0.05666;
	}

    FocusOnWidget( MenuOptions[0] );

	controllerIndex = PlayerController(Owner).Player.GamePadIndex;
	if ( !bOXMDemo && !bDVDDemo && !bMarketingDemo )
	{
		if (IsOnConsole())
			SetTimer(0.1, true);

		if (ConsoleCommand("XLIVE GETAUTHSTATE") != "ONLINE")
		{
			// Calling get accounts ensures that we grocked any accounts on the stupid memory card
			// otherwise, any accounts on the memory card won't be yet available in the engine side
			// account list, and the join will fail.
			ConsoleCommand("XLIVE GETACCOUNTS"); 
			if (ConsoleCommand("XLIVE SILENTLOGON"@controllerIndex) == "SUCCESS")
				Log ("Initiating silent log on");
		}
	}
    linkActive = false;

	FriendsIcon.bHidden = 1;

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "TokyoGameShow", value );			
	if ( bGotValue && bool(value) && !bOXMDemo && !bDVDDemo && !bMarketingDemo && !bPCDemo )
	{
		CallMenuClass("XInterfaceCommon.MenuSelectProfile","INITIALSELECTION");
		// SBD - A little hack to prevent the entry level from showing through for
		//		 one frame, since this menu has already passed its background movie
		//		 to the select profile screen but renders for one frame afterwards.
		if ( BackgroundMovie.MovieTex == None )
		{
			InLevelBackgroundMovieReplacement.bHidden = 0;
			InLevelBackgroundMovieReplacement.DrawColor.A = 255;			
		}
		
		return;
	}

	if ( !bOXMDemo && !bDVDDemo && !bMarketingDemo && !bPCDemo )
	{	
		if ( GetProfileName() == "<Default>" )
		{
			bGotInitialProfile = False;
			
			CallMenuClass("XInterfaceCommon.MenuSelectProfile","INITIALSELECTION");			
			// SBD - A little hack to prevent the entry level from showing through for
			//		 one frame, since this menu has already passed its background movie
			//		 to the select profile screen but renders for one frame afterwards.
			if ( BackgroundMovie.MovieTex == None )
			{
				InLevelBackgroundMovieReplacement.bHidden = 0;
				InLevelBackgroundMovieReplacement.DrawColor.A = 255;			
			}

/*** SBD - THE OLD LAUNCH INTO GAME METHOD			
			// Get the profiles
			GetProfileList(Profiles);	
			
			if (Profiles.Length == 0)
			{
				if ( IsOnConsole() )
				{
					// Check for hard disc space
					if ( !GetPlayerOwner().HaveAdequateDiscSpace() )
					{
						CallMenuClass("XInterfaceCommon.MenuLowStorage", "");
						return;
					}
				}
			
				// Create a default profile and launch right into the game.        
				DefaultName = "Player";        
				
				pr = class'xUtil'.static.FindPlayerRecord(DefaultName);
			    
				ProfilesCommand("NEW", 0, "NAME="$DefaultName$" CHARACTER="$DefaultName$" FACE="$pr.PortraitName);
				ProfilesCommand("LOAD", 0, "NAME="$DefaultName);

				PlayerController(Owner).ProfileCallback();
				
				NewGameSelected();
			}
			else
			{
				CallMenuClass("XInterfaceCommon.MenuSelectProfile","INITIALSELECTION");
			}
******/			
		}
		else
		{
			bGotInitialProfile = True;
		}
	}
	else if ( bPCDemo )
	{
		if ( GetProfileName() == "<Default>" )
		{
			DemoProfileName = "Player";        
			
			pr = class'xUtil'.static.FindPlayerRecord( DemoProfileName );

			// Get the profiles
			GetProfileList( Profiles );	
			
			bFoundDemoProfile = False;
			for ( i = 0; i < Profiles.Length; ++i )
			{
				if ( Profiles[i] == DemoProfileName )
					bFoundDemoProfile = True;
			}

			if ( !bFoundDemoProfile )
			{
				// Create a default profile
				ProfilesCommand( "NEW", 0, "NAME="$DemoProfileName$" CHARACTER="$DemoProfileName$" FACE="$pr.PortraitName );
			}
			
			ProfilesCommand("LOAD", 0, "NAME="$DemoProfileName);
			PlayerController(Owner).ProfileCallback();
		}
	}
}

simulated function Tick( float ElapsedTime )
{
	// SBD - A little hack to prevent the entry level from showing through for
	//		 one frame, since this menu has already passed its background movie
	//		 to the select profile screen but renders for one frame afterwards.

	if ( ( BackgroundMovie.MovieTex != None ) &&
	     ( InLevelBackgroundMovieReplacement.bHidden == 0 ) )
	{
		// We've switched back and have our movie back
		InLevelBackgroundMovieReplacement.bHidden = 1;
		InLevelBackgroundMovieReplacement.DrawColor.A = 192;
	}

	Super.Tick(ElapsedTime);
}

simulated function CheckLinkStatus()
{
    local bool newActive;
    local string s;

    newActive = true;
    // check link cable connection
    s = ConsoleCommand("XLIVE GET_LINK_ACTIVE");
    if( s=="FALSE" )
    {
        newActive = false;
    }

    if( linkActive != newActive )
    {
        linkActive = newActive;
//gdr This hid or showed the systemlink button in their menu.  Not sure we want to do the same, but it's here if we need it.
/*
        if( linkActive )
            Options[1].bHidden = 0;
        else
            Options[1].bHidden = 1;
        UpdateOptions();
*/
    }
}

simulated function CheckForCrossTitleInvite()
{
	local string s;
	
	if( bFoundCrossTitleInvite )
        return;
    
	s = ConsoleCommand("XLIVE IS_CROSS_TITLE_INVITE");
    if( "TRUE" == s )
    {
        CallMenuClass("XInterfaceLive.MenuAcceptCrossTitleInvite");
        bFoundCrossTitleInvite = true;
        return;
    }
}

simulated function Timer()
{
	// this is all xbox live stuff, and won't be executing on PC.

	local string s;
	local PlayerController PC;

	s = ConsoleCommand("XLIVE GETAUTHSTATE");

	FriendsIcon.bHidden = 1;

    CheckLinkStatus();

	if (bGotInitialProfile)
		CheckForCrossTitleInvite();

	if (s == "ONLINE")
	{    
//		SetTimer(0,false);
		PC = PlayerController(Owner);
		if( PC != None )
		{
			if( PC.GetNumFriendRequests() > 0 )
			{
				FriendsIcon.bHidden = 0;
				FriendsIcon.PosX = MenuOptions[3].ActiveArea.X1;
				FriendsIcon.PosX += 0.02;
				FriendsIcon.PosY = MenuOptions[3].Blurred.PosY;
				FriendsIcon.WidgetTexture = FriendRequestIcon;
			}
			else if( PC.GetNumGameInvites() > 0 )
			{
				FriendsIcon.bHidden = 0;
				FriendsIcon.PosX = MenuOptions[3].ActiveArea.X1;
				FriendsIcon.PosX += 0.02;
				FriendsIcon.PosY = MenuOptions[3].Blurred.PosY;
				FriendsIcon.WidgetTexture = GameInviteIcon;
			}
			else
			{
				FriendsIcon.bHidden = 1;
			}
		}
	}
	else if( s == "SIGNING_ON" || s == "CHANGING_LOGON" )
		return;
	else if( s == "OFFLINE")
	{
//		SetTimer(0,false);
		return;
	}
	else
	{
		// can't logoff right here, it messed up the stupid message at the top
//		ConsoleCommand("XLIVE LOGOFF -1");
//		SetTimer(0,false);
	}
}

simulated function NewGameSelected()
{
	local string value;
	local bool bGotValue;
	local bool bOXMDemo;
	local bool bDVDDemo;
	local bool bMarketingDemo;
	local bool bPCDemo;
    
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "OXMDemo", value );			
	if ( bGotValue )
		bOXMDemo = bool(value);

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "DVDDemo", value );			
	if ( bGotValue )
		bDVDDemo = bool(value);

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "MarketingDemo", value );			
	if ( bGotValue )
		bMarketingDemo = bool(value);

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "PCD", value );			
	if ( bGotValue )
		bPCDemo = bool(value);

	if ( IsOnConsole() && !bOXMDemo && !bDVDDemo && !bMarketingDemo)
	{
		// Check for hard disc space
		if ( !GetPlayerOwner().HaveAdequateDiscSpace( True, False ) )
		{
			bLowStorage = True;
			OverlayMenuClass("XInterfaceCommon.MenuLowStorage", "SAVEONLY");
			return;
		}
	}

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "TokyoGameShow", value );
	if ( bGotValue && bool(value) )
	{
		ConsoleCommand("open GEO_05B_Tokyo");
		return;
	}
	else if ( bOXMDemo || bDVDDemo )
	{
		ConsoleCommand("open GEO_05B_Demo");	
		return;
	}
	else if ( bMarketingDemo )
	{
		bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "MarketingDemoLevel", value );
		if (bGotValue)
			ConsoleCommand("open "$value);
		return;
	}
	else if ( bPCDemo )
	{
		ConsoleCommand("open YYY_01Briefing_Demo");
		return;
	}

	GetPlayerOwner().ConsoleCommand("open PRO");
	//CloseMenu();
}

simulated function MultiplayerSelected()
{
	local string value;
	local bool bGotValue;

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "TokyoGameShow", value );
	if ( bGotValue && bool(value) )
	{
		return;
	}

    if (IsOnConsole())
		CallMenuClass("XInterfaceCTMenus.CTMultiplayerXBoxMenu");
    else
    	CallMenuClass("XInterfaceCTMenus.CTMultiplayerPCMenu");
}

simulated function LoadGameSelected()
{
	local string value;
	local bool bGotValue;
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "TokyoGameShow", value );
	if ( bGotValue && bool(value) )
	{
		return;
	}

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "FocusGroup", value );
	if ( bGotValue && bool(value) )
		CallMenuClass("XInterfaceCTMenus.CT_Focus_LoadGameMenu");
	else
		CallMenuClass("XInterfaceCTMenus.CTLoadGameMenu");
}

simulated function CampaignMapSelected()
{
	local string value;
	local bool bGotValue;
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "TokyoGameShow", value );
	if ( bGotValue && bool(value) )
	{
		return;
	}

	CallMenuClass("XInterfaceCTMenus.CTCampaignMenu");
}

simulated function OptionsSelected()
{
	if ( IsOnConsole() )
		CallMenuClass("XInterfaceCTMenus.CTOptionsXboxMenu");
	else
		CallMenuClass("XInterfaceCTMenus.CTGameOptionsPCMenu");
}

simulated function ProfilesSelected()
{
	CallMenuClass("XInterfaceCommon.MenuSelectProfile");
}

simulated function ExtrasSelected()
{
	local string value;
	local bool bGotValue;
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "TokyoGameShow", value );
	if ( bGotValue && bool(value) )
	{
		return;
	}

	CallMenuClass("XInterfaceCTMenus.CTExtrasMenu");
}

simulated function QuitSelected()
{
	if ( IsOnConsole() )
		OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(QuitXboxGameConfirm) );
	else
		OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(QuitGameConfirm) );
}

simulated function bool MenuClosed( Menu closingMenu )
{
	local bool bDVDDemo;
	local bool bGotValue;
	local string value;	
    local MenuQuestionYesNo QuestionMenu;
    local MenuLowStorage lowStorageMenu;

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "DVDDemo", value );			
	if ( bGotValue )
		bDVDDemo = bool(value);

    QuestionMenu = MenuQuestionYesNo( closingMenu );
    lowStorageMenu = MenuLowStorage( closingMenu );
    if( QuestionMenu != None )
    {
        if( QuestionMenu.bSelectedYes )
        {
			if ( bDVDDemo )
			{
				GotoMenuClass("XInterfaceCTMenus.CT_DVDDemo_InitialXboxMenu");
			}
			else
			{
				GetPlayerOwner().ConsoleCommand("exit");
				GetPlayerOwner().MenuClose();
			}
        }
        
        return true;
    }
    else if ( lowStorageMenu != None )
    {
		if ( bLowStorage )
		{
			bLowStorage = False;
			GetPlayerOwner().ConsoleCommand("open PRO");			
		}
		
		return True;
    }
    else if ( !bGotInitialProfile && ( MenuLoadingProfile( closingMenu ) != None ) )
    {
		bGotInitialProfile = True;
    }
    else if ( !bGotInitialProfile && ( CTControllerDisconnect( closingMenu ) != None ) )
    {
		// We have switched to the controller disconnect menu before launching the
		// profile menu.
		CallMenuClass("XInterfaceCommon.MenuSelectProfile","INITIALSELECTION");		
    }
    
    return false;
}

simulated function HandleInputBack();



defaultproperties
{
     KaminoBorder=(PosX=0.1375,PosY=0.16,ScaleX=0.125,ScaleY=0.1666,Style="PlanetBorderStyle")
     Kamino=(WidgetTexture=Texture'GUIContent.Menu.CT_Kamino',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.1375,PosY=0.16)
     GeonosisBorder=(DrawColor=(B=96,G=96,R=96,A=255),PosX=0.32625,PosY=0.238333,ScaleX=0.22125,ScaleY=0.295,Style="PlanetBorderStyle")
     Geonosis=(WidgetTexture=Texture'GUIContent.Menu.CT_Geonosis',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.32625,PosY=0.238333)
     AssaultShipBorder=(DrawColor=(B=96,G=96,R=96,A=255),PosX=0.565,PosY=0.23,ScaleX=0.2325,ScaleY=0.31,Pass=2,Style="PlanetBorderStyle")
     AssaultShip=(WidgetTexture=Texture'GUIContent.Menu.CT_RAS',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.565,PosY=0.23,Pass=1)
     KashyyykBorder=(DrawColor=(B=96,G=96,R=96,A=255),PosX=0.82875,PosY=0.215,ScaleX=0.26375,ScaleY=0.351666,Style="PlanetBorderStyle")
     Kashyyyk=(WidgetTexture=Texture'GUIContent.Menu.CT_Kashyyyk',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.82875,PosY=0.215)
     GameTitle=(WidgetTexture=Texture'GUIContent.Menu.CT_Title_Camp',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.24,PosY=0.5,ScaleX=1.2,ScaleY=1.2)
     LabelBackground=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=192,G=192,R=192,A=32),DrawPivot=DP_MiddleMiddle,PosX=0.24,PosY=0.575,ScaleX=0.38,ScaleY=0.0617854,ScaleMode=MSCM_FitStretch)
     Label=(Text="MAIN MENU",DrawPivot=DP_MiddleMiddle,PosX=0.24,PosY=0.575,ScaleX=1.1,ScaleY=1.1,Style="LabelText")
     LabelConnector=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=192,G=192,R=192,A=32),DrawPivot=DP_MiddleMiddle,PosX=0.4425,PosY=0.575,ScaleX=0.015,ScaleY=0.0617854,ScaleMode=MSCM_FitStretch)
     Border=(PosX=0.6825,PosY=0.649996,ScaleX=0.45,ScaleY=0.46666,ScaleMode=MSCM_FitStretch,Style="BorderStyle1")
     MenuOptions(0)=(Blurred=(Text="NEW GAME",PosX=0.68375,PosY=0.48),BackgroundBlurred=(PosX=0.68375,PosY=0.48,ScaleX=0.38,ScaleY=0.04333),OnSelect="NewGameSelected",Style="ButtonTextStyle1")
     MenuOptions(1)=(Blurred=(Text="LOAD GAME",PosY=0.53666),BackgroundBlurred=(PosY=0.53666),OnSelect="LoadGameSelected")
     MenuOptions(2)=(Blurred=(Text="CAMPAIGN MAP"),OnSelect="CampaignMapSelected")
     MenuOptions(3)=(Blurred=(Text="MULTIPLAYER"),OnSelect="MultiplayerSelected")
     MenuOptions(4)=(Blurred=(Text="OPTIONS"),OnSelect="OptionsSelected")
     MenuOptions(5)=(Blurred=(Text="PROFILES"),OnSelect="ProfilesSelected")
     MenuOptions(6)=(Blurred=(Text="EXTRAS"),OnSelect="ExtrasSelected")
     MenuOptions(7)=(Blurred=(Text="QUIT"),OnSelect="QuitSelected")
     FriendsIcon=(DrawPivot=DP_MiddleLeft,PosX=0.79,ScaleX=0.5,ScaleY=0.5,Pass=2)
     FriendRequestIcon=Texture'GUIContent.Menu.XBLplayer_add'
     GameInviteIcon=Texture'GUIContent.Menu.XBLinvite_receive'
     MenuNames(0)="XInterfaceCommon.MenuSelectProfile"
     MenuNames(1)="XInterfaceCTMenus.CTLoadGameMenu"
     QuitGameConfirm="ARE YOU SURE YOU WANT TO QUIT TO WINDOWS?"
     QuitXBoxGameConfirm="ARE YOU SURE YOU WANT TO QUIT?"
     AButtonIcon=(DrawPivot=DP_MiddleRight,PosX=0.105)
     ALabel=(Text=": SELECT",DrawPivot=DP_MiddleLeft,PosX=0.095)
     AButton=(Blurred=(PosX=0.15),BackgroundBlurred=(PosX=0.15))
     Background=(WidgetTexture=Texture'GUIContent.Menu.CT_MainMenuGraphics',Style="FullScreen")
     HostText=(PosX=0.68375,PosY=0.4)
     bShowGamertag=True
     ModulateRate=1
}

