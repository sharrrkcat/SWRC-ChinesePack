class CT_dev_LoadGameMenu extends MenuTemplate;

//var() MenuSprite    Background;

var() MenuButtonText CharacterDemoMap;
var() MenuButtonText GEO_01;
//var() MenuButtonText GEO_02;
var() MenuButtonText GEO_03;
var() MenuButtonText GEO_04;
var() MenuButtonText GEO_05;
var() MenuButtonText mp_geo_canyonsmall;
var() MenuButtonText mpserver1;
var() MenuButtonText mpserver2;
var() MenuButtonText RAS_01;
var() MenuButtonText RAS_02;

var() MenuButtonText RAS_03;
var() MenuButtonText RAS_04;
//var() MenuButtonText RAS_05;
var() MenuButtonText YYY_01;
//var() MenuButtonText YYY_02;
var() MenuButtonText YYY_35;
var() MenuButtonText YYY_04;
var() MenuButtonText YYY_05;
var() MenuButtonText YYY_06;

var() MenuButtonText GEO_05B;
var() MenuButtonText YYY_35B;

var() MenuButtonText Back;


simulated function Init( String Args )
{
	Super.Init( Args );
    FocusOnWidget( CharacterDemoMap );
}

simulated function CharacterDemoMapSelected()
{
	GetPlayerOwner().ConsoleCommand("open CharacterDemoMap");
}

simulated function GEO_01Selected()
{
	GetPlayerOwner().ConsoleCommand("open GEO_01A");
}

//simulated function GEO_02Selected()
//{
//	GetPlayerOwner().ConsoleCommand("open GEO_02A_Start");
//}

simulated function GEO_03Selected()
{
	GetPlayerOwner().ConsoleCommand("open GEO_03A");
}

simulated function GEO_04Selected()
{
	GetPlayerOwner().ConsoleCommand("open GEO_04A");
}

simulated function GEO_05Selected()
{
	GetPlayerOwner().ConsoleCommand("open GEO_05A");
}

simulated function mp_geo_canyonsmallSelected()
{
	GetPlayerOwner().ConsoleCommand("open mp_geo_canyonsmall?game=mpgame.dmgame");
}

simulated function mpserver1Selected()
{
	GetPlayerOwner().ConsoleCommand("open lecpro-1138ref4.lucasarts.com");
}

simulated function mpserver2Selected()
{
	GetPlayerOwner().ConsoleCommand("open 172.24.128.175");
}

simulated function RAS_01Selected()
{
	GetPlayerOwner().ConsoleCommand("open RAS_01A");
}

simulated function RAS_02Selected()
{
	GetPlayerOwner().ConsoleCommand("open RAS_02A");
}

simulated function RAS_03Selected()
{
	GetPlayerOwner().ConsoleCommand("open RAS_03A");
}

simulated function RAS_04Selected()
{
	GetPlayerOwner().ConsoleCommand("open RAS_04A");
}

//simulated function RAS_05Selected()
//{
//	//GetPlayerOwner().ConsoleCommand("open ");
//}

simulated function YYY_01Selected()
{
	GetPlayerOwner().ConsoleCommand("open YYY_01Briefing");
}

//simulated function YYY_02Selected()
//{
//	GetPlayerOwner().ConsoleCommand("open YYY_02_A_Scout");
//}

simulated function YYY_35Selected()
{
	GetPlayerOwner().ConsoleCommand("open YYY_35A");
}

simulated function YYY_04Selected()
{
	GetPlayerOwner().ConsoleCommand("open YYY_04Briefing");
}

simulated function YYY_05Selected()
{
	GetPlayerOwner().ConsoleCommand("open YYY_05A");
}

simulated function YYY_06Selected()
{
	GetPlayerOwner().ConsoleCommand("open YYY_06A");
}

simulated function GEO_05BSelected()
{
	GetPlayerOwner().ConsoleCommand("open GEO_05B");
}

simulated function YYY_35BSelected()
{
	GetPlayerOwner().ConsoleCommand("open YYY_35B");
}

simulated function BackSelected()
{
	CloseMenu();
}

simulated function HandleInputBack()
{
	BackSelected();
}



defaultproperties
{
     CharacterDemoMap=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="CharacterDemoMap",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.2),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.2,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="CharacterDemoMap",OnSelect="CharacterDemoMapSelected")
     GEO_01=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="GEO_01",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.26),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.26,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="GEO_01",OnSelect="GEO_01Selected")
     GEO_03=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="GEO_03",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.38),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.38,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="GEO_03",OnSelect="GEO_03Selected")
     GEO_04=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="GEO_04",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.44),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.44,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="GEO_04",OnSelect="GEO_04Selected")
     GEO_05=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="GEO_05",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.5),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.5,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="GEO_05",OnSelect="GEO_05Selected")
     mp_geo_canyonsmall=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="mp_geo_canyonsmall",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.56),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.56,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="mp_geo_canyonsmall",OnSelect="mp_geo_canyonsmallSelected")
     mpserver1=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="mpserver1",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.62),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.62,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="mpserver1",OnSelect="mpserver1Selected")
     mpserver2=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="mpserver2",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.68),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.68,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="mpserver2",OnSelect="mpserver2Selected")
     RAS_01=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="RAS_01",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.74),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.74,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="RAS_01",OnSelect="RAS_01Selected")
     RAS_02=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="RAS_02",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.8),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.32,PosY=0.8,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="RAS_02",OnSelect="RAS_02Selected")
     RAS_03=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="RAS_03",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.2),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.2,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="RAS_03",OnSelect="RAS_03Selected")
     RAS_04=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="RAS_04",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.26),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.26,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="RAS_04",OnSelect="RAS_04Selected")
     YYY_01=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="YYY_01",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.38),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.38,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="YYY_01",OnSelect="YYY_01Selected")
     YYY_35=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="YYY_35",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.5),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.5,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="YYY_35",OnSelect="YYY_35Selected")
     YYY_04=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="YYY_04",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.56),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.56,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="YYY_04",OnSelect="YYY_04Selected")
     YYY_05=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="YYY_05",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.62),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.62,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="YYY_05",OnSelect="YYY_05Selected")
     YYY_06=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="YYY_06",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.68),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.68,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="YYY_06",OnSelect="YYY_06Selected")
     GEO_05B=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="Sabotage Separatist Coreship",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.74),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.74,ScaleX=2,ScaleMode=MSCM_Stretch),HelpText="Sabotage Separatist Coreship",OnSelect="GEO_05BSelected")
     YYY_35B=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="Infiltrate Trandoshan Encampment",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.8),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.8,ScaleX=2.25,ScaleMode=MSCM_Stretch),HelpText="Infiltrate Trandoshan Encampment",OnSelect="YYY_35BSelected")
     back=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="BACK",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.86),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.65,PosY=0.86,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="BACK",OnSelect="BackSelected")
     ModulateRate=1
     bFullscreenOnly=True
}

