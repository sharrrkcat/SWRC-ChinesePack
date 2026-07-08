// ====================================================================
//  Republic Commando Multiplayer for xbox Menu
// ====================================================================

class CTMultiplayerXBoxMenu extends MenuTemplateTitledBA;

var() MenuSprite		KaminoBorder;
var() MenuSprite		Kamino;

var() MenuSprite		GeonosisBorder;
var() MenuSprite		Geonosis;

var() MenuSprite		AssaultShipBorder;
var() MenuSprite		AssaultShip;

var() MenuSprite		KashyyykBorder;
var() MenuSprite		Kashyyyk;

var() MenuSprite		LabelBackground;
var() MenuText			Label;
var() MenuSprite		LabelConnector;

var() MenuSprite		Border;

var() MenuButtonText	MenuOptions[5];

// xbox live stuff
var() MenuSprite FriendsIcon;
var() Material FriendRequestIcon;
var() Material GameInviteIcon;


simulated function Init( String Args )
{
	local string s;

	HostText.DrawPivot = DP_MiddleRight;
	HostText.PosX=0.87;
	HostText.PosY=0.4;

	Super.Init( Args );

	// Tighten up the border
	Border.PosY -= 0.02833;
	Border.ScaleY -= 0.05666;

	FriendsIcon.bHidden = 1;

	FocusOnWidget( MenuOptions[0] );

	s = ConsoleCommand("XLIVE GETAUTHSTATE");
	if (s == "ONLINE")
		SetTimer(0.1, true);
}

simulated function Timer()
{
	// this is all xbox live stuff, and won't be executing on PC.

	local PlayerController PC;

	FriendsIcon.bHidden = 1;

	PC = PlayerController(Owner);
	if( PC != None )
	{
		if( PC.GetNumFriendRequests() > 0 )
		{
			FriendsIcon.bHidden = 0;
			FriendsIcon.PosX = MenuOptions[1].ActiveArea.X1;
			FriendsIcon.PosX += 0.02;
			FriendsIcon.PosY = MenuOptions[1].Blurred.PosY;
			FriendsIcon.WidgetTexture = FriendRequestIcon;
		}
		else if( PC.GetNumGameInvites() > 0 )
		{
			FriendsIcon.bHidden = 0;
			FriendsIcon.PosX = MenuOptions[1].ActiveArea.X1;
			FriendsIcon.PosX += 0.02;
			FriendsIcon.PosY = MenuOptions[1].Blurred.PosY;
			FriendsIcon.WidgetTexture = GameInviteIcon;
		}
		else
		{
			FriendsIcon.bHidden = 1;
		}
	}
}

simulated function SystemLinkSelected()
{
	GotoMenuClass("XInterfaceMP.MenuLanGames");
}

simulated function PlayLiveSelected()
{
	local string s;
	
	s = ConsoleCommand("XLIVE GETAUTHSTATE");
	if ( s == "ONLINE" )
		CallMenuClass("XInterfaceLive.MenuLiveMain");
	else if( s == "SIGNING_ON" || s == "CHANGING_LOGON" )
		CallMenuClass( "XInterfaceLive.MenuLivePasscode", "!SILENT!" @ "SILENT" );
	else if ( s == "FAILED_MUST_UPDATE" )
        OverlayMenuClass( "XInterfaceLive.MenuLiveAutoUpdate", MakeQuotedString(""));
 	else
	{
		ConsoleCommand("XLIVE LOGOFF -1");
		CallMenuClass("XInterfaceLive.MenuLiveSignIn");
	}
}

simulated function SplitScreenSelected()
{
//	ConsoleCommand("open mp_geo_canyonsmall?game=mpgame.dmgame");
	CallMenuClass( "XInterfaceMP.MenuSplitSCreenPlayers" );
}


simulated function CustomizeSelected()
{
	// entry?menu=XInterfaceMP.MenuCustomizeCharacter
	
	ConsoleCommand("open MPCustom?game=Engine.GameInfo?menu=XInterfaceMP.MenuCustomizeCharacter");
	
	//CallMenuClass("XInterfaceMP.MenuCustomizeCharacter");
}


simulated function ProfilesSelected()
{
	CallMenuClass("XInterfaceCommon.MenuSelectProfile");
}

simulated function HandleInputBack()
{
	GotoMenuClass("XInterfaceCTMenus.CTMenuMain");
}



defaultproperties
{
     KaminoBorder=(PosX=0.1375,PosY=0.16,ScaleX=0.125,ScaleY=0.1666,Style="PlanetBorderStyle")
     Kamino=(WidgetTexture=Texture'GUIContent.Menu.CT_Kamino',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.1375,PosY=0.16)
     GeonosisBorder=(DrawColor=(B=96,G=96,R=96,A=255),PosX=0.32625,PosY=0.238333,ScaleX=0.22125,ScaleY=0.295,Style="PlanetBorderStyle")
     Geonosis=(WidgetTexture=Texture'GUIContent.Menu.CT_Geonosis',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.32625,PosY=0.238333)
     AssaultShipBorder=(DrawColor=(B=96,G=96,R=96,A=255),PosX=0.565,PosY=0.23,ScaleX=0.2325,ScaleY=0.31,Style="PlanetBorderStyle")
     AssaultShip=(WidgetTexture=Texture'GUIContent.Menu.CT_RAS',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.565,PosY=0.23)
     KashyyykBorder=(DrawColor=(B=96,G=96,R=96,A=255),PosX=0.82875,PosY=0.215,ScaleX=0.26375,ScaleY=0.351666,Style="PlanetBorderStyle")
     Kashyyyk=(WidgetTexture=Texture'GUIContent.Menu.CT_Kashyyyk',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.82875,PosY=0.215)
     LabelBackground=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=192,G=192,R=192,A=32),DrawPivot=DP_MiddleMiddle,PosX=0.24,PosY=0.48,ScaleX=0.38,ScaleY=0.0617854,ScaleMode=MSCM_FitStretch)
     Label=(Text="MULTIPLAYER",DrawPivot=DP_MiddleMiddle,PosX=0.24,PosY=0.48,ScaleX=1.1,ScaleY=1.1,Style="LabelText")
     LabelConnector=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=192,G=192,R=192,A=32),DrawPivot=DP_MiddleMiddle,PosX=0.4425,PosY=0.48,ScaleX=0.015,ScaleY=0.0617854,ScaleMode=MSCM_FitStretch)
     Border=(PosX=0.6825,PosY=0.621666,ScaleX=0.45,ScaleY=0.41,ScaleMode=MSCM_FitStretch,Style="BorderStyle1")
     MenuOptions(0)=(Blurred=(Text="SYSTEM LINK",PosX=0.68375,PosY=0.48),BackgroundBlurred=(PosX=0.68375,PosY=0.48,ScaleX=0.38,ScaleY=0.04333),OnSelect="SystemLinkSelected",Style="ButtonTextStyle1")
     MenuOptions(1)=(Blurred=(Text="XBOX LIVE",PosY=0.53666),BackgroundBlurred=(PosY=0.53666),OnSelect="PlayLiveSelected")
     MenuOptions(2)=(Blurred=(Text="SPLITSCREEN"),OnSelect="SplitScreenSelected")
     MenuOptions(3)=(Blurred=(Text="CUSTOMIZE"),OnSelect="CustomizeSelected")
     MenuOptions(4)=(Blurred=(Text="PROFILES"),OnSelect="ProfilesSelected")
     FriendsIcon=(DrawPivot=DP_MiddleLeft,PosX=0.79,ScaleX=0.5,ScaleY=0.5,Pass=2)
     FriendRequestIcon=Texture'GUIContent.Menu.XBLplayer_add'
     GameInviteIcon=Texture'GUIContent.Menu.XBLinvite_receive'
     Background=(WidgetTexture=Texture'GUIContent.Menu.CT_MainMenuGraphics',Style="FullScreen")
     HostText=(PosX=0.68375,PosY=0.4)
     bShowGamertag=True
     ModulateRate=1
}

