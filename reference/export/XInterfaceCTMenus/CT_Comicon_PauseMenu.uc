class CT_Comicon_PauseMenu extends MenuTemplate;

var() MenuSprite    Background;

var() MenuButtonText	ReturnToGame;
var() MenuButtonText	Restart;
var() MenuButtonText	InvertLook;
//var() MenuButtonText	ControllerConfig;
var() MenuButtonText	QuitGame;


simulated function Init( String Args )
{
	Super.Init( Args );
	
	FocusOnWidget( ReturnToGame );
}

simulated function ReturnToGameSelected()
{
	GetPlayerOwner().SetPause(false);
	GetPlayerOwner().MenuClose();
}

simulated function RestartSelected()
{
	GetPlayerOwner().ConsoleCommand("restartlevel");
	GetPlayerOwner().SetPause(false);
	GetPlayerOwner().MenuClose();
}

simulated function InvertLookSelected()
{
	GetPlayerOwner().ConsoleCommand("InvertLook");
	GetPlayerOwner().SetPause(false);
	GetPlayerOwner().MenuClose();
}

/*simulated function ControllerConfigSelected()
{
	GetPlayerOwner().ClientOpenXMenu("XInterfaceCTMenus.CTControlConfigMenu");
}*/

simulated function QuitGameSelected()
{
	if (!IsOnConsole())
	{
		// TODO:  don't really wanna Exit here, go back to main menu, probably.
		GetPlayerOwner().ConsoleCommand("exit");
		GetPlayerOwner().MenuClose();
	}
}

simulated function HandleInputBack();



defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.RCTitlePage',DrawColor=(B=255,G=255,R=255,A=255),ScaleX=1,ScaleY=1,ScaleMode=MSCM_Fit,Style="FullScreen")
     ReturnToGame=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="RETURN TO GAME",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.53),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.53,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="RETURN TO GAME",OnSelect="ReturnToGameSelected")
     Restart=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="RESTART LEVEL",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.59),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.59,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="RESTART LEVEL",OnSelect="RestartSelected")
     InvertLook=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="INVERT LOOK",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.65),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.65,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="INVERT LOOK",OnSelect="InvertLookSelected")
     QuitGame=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="QUIT GAME",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.71),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.71,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="QUIT GAME",OnSelect="QuitGameSelected")
     ModulateRate=1
     BackgroundMusic=None
     bFullscreenOnly=True
}

