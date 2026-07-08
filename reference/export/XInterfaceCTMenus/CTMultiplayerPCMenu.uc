class CTMultiplayerPCMenu extends MenuTemplateTitledB;

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

simulated function Init( String Args )
{
	Super.Init( Args );

	// Tighten up the border
	Border.PosY -= 0.05666;
	Border.ScaleY -= 0.11332;

	FocusOnWidget( MenuOptions[2] );
}

simulated function TestConnSelected()
{
	GetPlayerOwner().ConsoleCommand("open lecpro-1138ref4.lucasfilm.com");
}

simulated function TestLocalSelected()
{
	//GetPlayerOwner().ConsoleCommand("open 172.24.128.207"); // scritch's machine
	GetPlayerOwner().ConsoleCommand("open 127.0.0.1"); //local dedicated server
}

simulated function ProfilesSelected()
{
	CallMenuClass("XInterfaceCommon.MenuSelectProfile");
}

function GameSpyLANSelected()
{
	CallMenuClass("XInterfaceGamespy.GamespyCreateJoinLAN");
}

function GameSpyInternetSelected()
{
	CallMenuClass("XInterfaceGamespy.GamespyCreateJoinInternet");
}

function ConnectToIPSelected()
{
	CallMenuClass("XInterfaceCommon.MenuPCConnectToIP");
}

simulated function CustomizeSelected()
{
	CallMenuClass("XInterfaceMP.MenuCustomizeCharacter");
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
     Border=(PosX=0.6825,PosY=0.649996,ScaleX=0.45,ScaleY=0.46666,ScaleMode=MSCM_FitStretch,Style="BorderStyle1")
     MenuOptions(0)=(Blurred=(Text="LAN",PosX=0.68375,PosY=0.48),BackgroundBlurred=(PosX=0.68375,PosY=0.48,ScaleX=0.38,ScaleY=0.04333),OnSelect="GameSpyLANSelected",Style="ButtonTextStyle1")
     MenuOptions(1)=(Blurred=(Text="INTERNET",PosY=0.53666),BackgroundBlurred=(PosY=0.53666),OnSelect="GameSpyInternetSelected")
     MenuOptions(2)=(Blurred=(Text="CONNECT TO IP"),OnSelect="ConnectToIPSelected")
     MenuOptions(3)=(Blurred=(Text="CUSTOMIZE"),OnSelect="CustomizeSelected")
     MenuOptions(4)=(Blurred=(Text="PROFILES"),OnSelect="ProfilesSelected")
     Background=(WidgetTexture=Texture'GUIContent.Menu.CT_MainMenuGraphics',Style="FullScreen")
     ModulateRate=1
}

