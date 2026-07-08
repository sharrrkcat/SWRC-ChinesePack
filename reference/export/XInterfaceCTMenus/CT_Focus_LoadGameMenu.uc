class CT_Focus_LoadGameMenu extends MenuTemplate;

//var() MenuSprite    Background;

var() MenuButtonText GEO_04_C;
var() MenuButtonText GEO_05_B;
var() MenuButtonText YYY_035_B;
var() MenuButtonText YYY_06_C;

var() MenuButtonText MainMenu;


simulated function Init( String Args )
{
	Super.Init( Args );
    FocusOnWidget( GEO_05_B );
}


simulated function GEO_04_CSelected()
{
	GetPlayerOwner().ConsoleCommand("open GEO_04_C");
}

simulated function GEO_05_BSelected()
{
	GetPlayerOwner().ConsoleCommand("open GEO_05_B");
}

simulated function YYY_06_CSelected()
{
	GetPlayerOwner().ConsoleCommand("open YYY_06_C");
}

simulated function YYY_035_BSelected()
{
	GetPlayerOwner().ConsoleCommand("open YYY_035_B_Compound");
}

simulated function MainMenuSelected()
{
	GetPlayerOwner().ClientOpenXMenu("XInterfaceCTMenus.CTMenuMain");
}

simulated function HandleInputBack();



defaultproperties
{
     GEO_04_C=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="02 - DISMANTLE ENEMY AIR DEFENSES (GEO_04_C)",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.44),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.44,ScaleX=6,ScaleMode=MSCM_Stretch),HelpText="GEO_04_C",OnSelect="GEO_04_CSelected")
     GEO_05_B=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="01 - INFILTRATE ENEMY CAPITAL SHIP (GEO_05_B)",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.38),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.38,ScaleX=6,ScaleMode=MSCM_Stretch),HelpText="GEO_05_B",OnSelect="GEO_05_BSelected")
     YYY_035_B=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="04 - SABOTAGE ENEMY ENCAMPMENT (YYY_035_B)",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.56),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.56,ScaleX=6,ScaleMode=MSCM_Stretch),HelpText="YYY_035_B",OnSelect="YYY_035_BSelected")
     YYY_06_C=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="03 - AID WOOKIEE RESISTANCE (YYY_06_C)",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.5),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.5,ScaleX=6,ScaleMode=MSCM_Stretch),HelpText="YYY_06_C",OnSelect="YYY_06_CSelected")
     MainMenu=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="MAIN MENU",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.68),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.68,ScaleX=2,ScaleMode=MSCM_Stretch),HelpText="Main Menu",OnSelect="MainMenuSelected")
     ModulateRate=1
     bFullscreenOnly=True
}

