class CT_MSEval_PauseMenu extends MenuTemplate;

var() MenuSprite    Background;

var() MenuButtonText GEO_03_A;
var() MenuButtonText YYY_01_B;
var() MenuButtonText YYY_01_E;
var() MenuButtonText RAS_02_E;
var() MenuButtonText RAS_03_B;
var() MenuButtonText InvertLook;
var() MenuButtonText ReturnToGame;

simulated function Init( String Args )
{
    FocusOnWidget( ReturnToGame );
}

simulated function GEO_03_ASelected()
{
	GetPlayerOwner().ConsoleCommand("open GEO_03A");
}

simulated function YYY_01_BSelected()
{
	GetPlayerOwner().ConsoleCommand("open YYY_01_B_Approach");
}

simulated function YYY_01_ESelected()
{
	GetPlayerOwner().ConsoleCommand("open YYY_01_E_Rescue");
}

simulated function RAS_02_ESelected()
{
	GetPlayerOwner().ConsoleCommand("open RAS_02_E_Bridge");
}

simulated function RAS_03_BSelected()
{
	GetPlayerOwner().ConsoleCommand("open RAS_03_B_Detention");
}

simulated function InvertLookSelected()
{
	GetPlayerOwner().ConsoleCommand("InvertLook");
	GetPlayerOwner().SetPause(false);
}

simulated function ReturnToGameSelected()
{
	GetPlayerOwner().SetPause(false);
	GetPlayerOwner().MenuClose();
}

simulated function HandleInputBack();



defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.RCLoadLevel',DrawColor=(B=255,G=255,R=255,A=255),ScaleX=1,ScaleY=1,ScaleMode=MSCM_Fit,Style="FullScreen")
     GEO_03_A=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="E3 - Geonosian Catacombs",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.292),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.292,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="GEO_03_A",OnSelect="GEO_03_ASelected")
     YYY_01_B=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="Kashyyyk Approach",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.352),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.352,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="YYY_01_B",OnSelect="YYY_01_BSelected")
     YYY_01_E=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="Kashyyyk Rescue",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.412),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.412,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="YYY_01_E",OnSelect="YYY_01_ESelected")
     RAS_02_E=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="Republic Assault Ship Bridge",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.472),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.472,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="RAS_02_E",OnSelect="RAS_02_ESelected")
     RAS_03_B=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="Republic Detention Center",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.532),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.532,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="RAS_03_B",OnSelect="RAS_03_BSelected")
     InvertLook=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="INVERT LOOK",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.592),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.592,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="Invert Look",OnSelect="InvertLookSelected")
     ReturnToGame=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="RETURN TO GAME",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.652),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.652,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="Return to Game",OnSelect="ReturnToGameSelected")
     ModulateRate=1
     bFullscreenOnly=True
}

