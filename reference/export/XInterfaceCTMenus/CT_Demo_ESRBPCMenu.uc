class CT_Demo_ESRBPCMenu extends MenuTemplate;

var() MenuSprite    Background;
var() MenuSprite	ESRBLogo;

simulated function Init( String Args )
{
	Super.Init( Args );
	
	SetTimer(5.0, False);
}

simulated function Timer()
{
	GotoMenuClass("XInterfaceCTMenus.CTStartPCMenu");
}

simulated function HandleInputBack();


defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.blacksquare',DrawColor=(B=255,G=255,R=255,A=255),ScaleX=1,ScaleY=1,ScaleMode=MSCM_Fit,Style="FullScreen")
     ESRBLogo=(DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.5,Pass=1)
     ModulateRate=1
     BackgroundMovieName=""
     BackgroundMusic=None
     bFullscreenOnly=True
}

