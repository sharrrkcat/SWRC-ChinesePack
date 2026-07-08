class CT_DVDDemo_InitialXboxMenu extends MenuTemplate;

var() MenuSprite		Background;

var() MenuButtonSprite	Movie;
var() MenuButtonSprite	Demo;

var() bool				bMovieSelected;
var() bool				bDemoSelected;

simulated function Init( String Args )
{
	Background.WidgetTexture=Material(DynamicLoadObject("GUIContent.RC_DVDDemo_Initial_Xbox", class'Material'));

	Movie.Blurred.WidgetTexture=Material(DynamicLoadObject("GUIContent.menus.RC_DVDDemo_Movieunselect", class'Material'));
	Movie.Focused.WidgetTexture=Material(DynamicLoadObject("GUIContent.menus.RC_DVDDemo_Movieselect", class'Material'));
	
	Demo.Blurred.WidgetTexture=Material(DynamicLoadObject("GUIContent.menus.RC_DVDDemo_Demounselect", class'Material'));
	Demo.Focused.WidgetTexture=Material(DynamicLoadObject("GUIContent.menus.RC_DVDDemo_Demoselect", class'Material'));
	
	Super.Init( Args );
	
    FocusOnWidget( Movie );
}

simulated function Tick( float ElapsedTime )
{
	local array<BYTE> buttons;
	local Vector LJoy;
	local Vector RJoy;
	local byte vpGamePadIdx;
	local int i;
	local bool bGoodButtonDown;
	local bool bOtherButtonDown;
	const BUTTON_START = 12;
	const BUTTON_A = 0;

	Super.Tick( ElapsedTime );
	
	if ( bMovieSelected || bDemoSelected )
		return;
		
	vpGamePadIdx = GetPlayerOwner().Player.GamePadIndex;
	if ( vpGamePadIdx < 251 )
	{
		// There's a pad associated with the viewport...
		buttons.Length = 16;
		
		// Let's make double-sure it's initialized to zero
		for ( i = 0; i < 16; ++i )
			buttons[i] = 0;
			
		GetPlayerOwner().GetPadInput( vpGamePadIdx, buttons, LJoy, RJoy  );
		
		bGoodButtonDown = False;
		bOtherButtonDown = False;
		for ( i = 0; i < 16; ++i )
		{
			if ( buttons[i] != 0 )
			{
				if ( ( BUTTON_A == i ) || ( BUTTON_START == i ) )
					bGoodButtonDown = True;
				else
					bOtherButtonDown = True;
			}
		}		

		// If the "A" or "Start" button isn't down and there's another
		// button down, then disassociate the pad
		if ( !bGoodButtonDown && bOtherButtonDown )
		{
log("CT_DVDDEMO_INITIALXBOXMENU:  DISASSOCIATE PADS");
			GetPlayerOwner().DisassociateViewportPads();
		}
	}
}

simulated function DemoSelected()
{
	bDemoSelected = True;
	log("CT_DVDDEMO_INITIALXBOXMENU:  DemoSelected:  DISASSOCIATE PADS");	
	GetPlayerOwner().DisassociateViewportPads();	
	GotoMenuClass("XInterfaceCTMenus.CT_DVDDemo_WarningXboxMenu");
}

simulated function MovieSelected()
{
	bMovieSelected = True;
	GetPlayerOwner().ConsoleCommand("exit");
}

simulated function HandleInputBack();



defaultproperties
{
     Background=(DrawColor=(B=255,G=255,R=255,A=255),ScaleX=1,ScaleY=1,ScaleMode=MSCM_Fit,Style="FullScreen")
     Movie=(Blurred=(DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.51,Pass=1),OnSelect="MovieSelected")
     Demo=(Blurred=(DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.76,Pass=1),OnSelect="DemoSelected")
     ModulateRate=1
     BackgroundMovieName=""
     BackgroundMusic=None
     bFullscreenOnly=True
}

