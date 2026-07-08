class CT_Comicon_MenuMain extends MenuTemplate;

var() MenuSprite    Background;

var() MenuButtonText	GEO_05_B;
var() MenuButtonText	Exit;

simulated function Init( String Args )
{
	Super.Init( Args );

    FocusOnWidget( GEO_05_B );
}

simulated function GEO_05_BSelected()
{
	GetPlayerOwner().ConsoleCommand("open GEO_05_B");
}

simulated function ExitSelected()
{
	if (!IsOnConsole())
	{
		GetPlayerOwner().ConsoleCommand("exit");
		GetPlayerOwner().MenuClose();
	}
}

simulated function HandleInputBack();



defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.RCTitlePage',DrawColor=(B=255,G=255,R=255,A=255),ScaleX=1,ScaleY=1,ScaleMode=MSCM_Fit,Style="FullScreen")
     GEO_05_B=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="SABOTAGE SEPARATIST CORESHIP",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.59),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.59,ScaleX=2,ScaleMode=MSCM_Stretch),HelpText="SABOTAGE SEPARATIST CORESHIP",OnSelect="GEO_05_BSelected")
     Exit=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="EXIT",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.65),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.65,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="EXIT",OnSelect="ExitSelected")
     ModulateRate=1
     bFullscreenOnly=True
}

