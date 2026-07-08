class CTControlConfigMenu extends MenuTemplate;

var() MenuSprite    Background;

var() MenuButtonText AltCtrl1;
var() MenuButtonText AltCtrl2;
var() MenuButtonText AltCtrl3;
var() MenuButtonText AltCtrl4;
var() MenuButtonText AltCtrl5;
var() MenuButtonText AltCtrl6;
var() MenuButtonText InvertLook;
var() MenuButtonText Back;

simulated function Init( String Args )
{
    FocusOnWidget( Back );
}

simulated function AltCtrl1Selected()
{
	GetPlayerOwner().ConsoleCommand("UseControllerConfig AltCtrl1.ini");
	GetPlayerOwner().ClientOpenXMenu("XInterfaceCTMenus.CTPauseMenu");
}

simulated function AltCtrl2Selected()
{
	GetPlayerOwner().ConsoleCommand("UseControllerConfig AltCtrl2.ini");
	GetPlayerOwner().ClientOpenXMenu("XInterfaceCTMenus.CTPauseMenu");
}

simulated function AltCtrl3Selected()
{
	GetPlayerOwner().ConsoleCommand("UseControllerConfig AltCtrl3.ini");
	GetPlayerOwner().ClientOpenXMenu("XInterfaceCTMenus.CTPauseMenu");
}

simulated function AltCtrl4Selected()
{
	GetPlayerOwner().ConsoleCommand("UseControllerConfig AltCtrl4.ini");
	GetPlayerOwner().ClientOpenXMenu("XInterfaceCTMenus.CTPauseMenu");
}

simulated function AltCtrl5Selected()
{
	GetPlayerOwner().ConsoleCommand("UseControllerConfig AltCtrl5.ini");
	GetPlayerOwner().ClientOpenXMenu("XInterfaceCTMenus.CTPauseMenu");
}

simulated function AltCtrl6Selected()
{
	GetPlayerOwner().ConsoleCommand("UseControllerConfig AltCtrl6.ini");
	GetPlayerOwner().ClientOpenXMenu("XInterfaceCTMenus.CTPauseMenu");
}

simulated function BackSelected()
{
	GetPlayerOwner().ClientOpenXMenu("XInterfaceCTMenus.CTPauseMenu");
}

simulated function HandleInputBack();



defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.RCLoadLevel',DrawColor=(B=255,G=255,R=255,A=255),ScaleX=1,ScaleY=1,ScaleMode=MSCM_Fit,Style="FullScreen")
     AltCtrl1=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="Controller Config 1",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.292),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.292,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="Controller Config 1",OnSelect="AltCtrl1Selected")
     AltCtrl2=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="Controller Config 2",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.352),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.352,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="Controller Config 2",OnSelect="AltCtrl2Selected")
     AltCtrl3=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="Controller Config 3",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.412),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.412,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="Controller Config 3",OnSelect="AltCtrl3Selected")
     AltCtrl4=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="Controller Config 4",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.472),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.472,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="Controller Config 4",OnSelect="AltCtrl4Selected")
     AltCtrl5=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="Controller Config 5",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.532),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.532,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="Controller Config 5",OnSelect="AltCtrl5Selected")
     AltCtrl6=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="Controller Config 6",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.592),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.592,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="Controller Config 6",OnSelect="AltCtrl6Selected")
     back=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="BACK",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.652),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.652,ScaleX=1.75,ScaleMode=MSCM_Stretch),HelpText="Back",OnSelect="BackSelected")
     ModulateRate=1
     BackgroundMusic=None
     bFullscreenOnly=True
}

