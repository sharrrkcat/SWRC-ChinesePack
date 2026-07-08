class CTPausePCMenu extends MenuTemplate;

var() MenuSprite		Background;

const NUM_OPTIONS = 11;

var() MenuButtonText	MenuOptions[NUM_OPTIONS];

var() localized String EndMissionConfirm;
var() localized String	QuitGameConfirm;
var() localized String	RestartMissionConfirm;
var() localized String	LoadLastConfirm;

var() localized String EndMissionDemoConfirm;
var() localized String RestartMissionDemoConfirm;


var() bool				bEndMissionSelected;
var() bool				bQuitGameSelected;
var() bool				bRestartMissionSelected;
var() bool				bLoadLastSelected;

var() bool				bLoadOrSaveSelected;

simulated function Init( String Args )
{
	local int i;
	local String LevelName;
	local string value;
	local bool bGotValue;
	local bool bMarketingDemo;

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "MarketingDemo", value );			
	if ( bGotValue )
		bMarketingDemo = bool(value);
	
	Super.Init( Args );
	
	if ( Caps(GetPlayerOwner().GetLanguage()) == "FRT" ||
		 Caps(GetPlayerOwner().GetLanguage()) == "EST" ||
		 Caps(GetPlayerOwner().GetLanguage()) == "ITT" )
	{
		for ( i = 0; i < NUM_OPTIONS; ++i )
		{
			MenuOptions[i].BackgroundBlurred.ScaleX = 0.65;
			MenuOptions[i].BackgroundFocused.ScaleX = 0.65;
		}
	}
	
	MenuOptions[0].bHidden = 1;
	
	if ( !GetPlayerOwner().HasQuickSave() )
		MenuOptions[2].bHidden = 1;
	
	GetPlayerOwner().GetCurrentMapName( LevelName );
	LevelName = Caps( LevelName );
	// Strip any extension off the level name
	if ( Caps(Right(LevelName, 4)) == ".CTM" )
		LevelName = Left(LevelName, Len(LevelName) - 4);

	
	if ( (GetPlayerOwner().Pawn == None) || (GetPlayerOwner().Pawn.Health <= 0) ||
	     GetPlayerOwner().bBriefing || (LevelName == "PRO") )
	{
		MenuOptions[1].bHidden = 1;
		MenuOptions[5].bHidden = 1;
	}

	if ( bMarketingDemo )
	{
		MenuOptions[0].bHidden = 1;
		MenuOptions[1].bHidden = 1;
		MenuOptions[2].bHidden = 1;
		MenuOptions[5].bHidden = 1;
		MenuOptions[6].bHidden = 1;
		
		if ( MenuOptions[1].bHidden != 0 )
			FocusOnNothing();
	}

	if ( (GetPlayerOwner().Pawn == None) ||
		 (GetPlayerOwner().Pawn.Health <= 0) ||
		  GetPlayerOwner().Pawn.bIncapacitated ||
		  GetPlayerOwner().Pawn.bIncapacitatedOnTurret )
	{
		// They're dead or incapacitated
		MenuOptions[0].bHidden = 0;
		
		FocusOnWidget( MenuOptions[3] );		
		
		if ( (GetPlayerOwner().Pawn.Health <= 0) && 
			 !GetPlayerOwner().Pawn.bIncapacitated &&
			 !GetPlayerOwner().Pawn.bIncapacitatedOnTurret )
		{
			// They're dead
			Background.bHidden = 1;			
			MenuOptions[3].bHidden = 1;
			FocusOnWidget( MenuOptions[0] );			
			
			// Since we know we're over a white screen,
			// make the blurred text darker.
			for ( i = 0; i < NUM_OPTIONS; ++i )
			{
				MenuOptions[i].Blurred.DrawColor.R = 45;
				MenuOptions[i].Blurred.DrawColor.G = 100;
				MenuOptions[i].Blurred.DrawColor.B = 255;
			}
		}
	}
	else
	{
		FocusOnWidget( MenuOptions[3] );
	}

	if (GetPlayerOwner().CanEnableHints())
		MenuOptions[8].bHidden = 0;
	else
		MenuOptions[8].bHidden = 1;

	AdjustButtons();
}

simulated function AdjustButtons()
{
	// NOTE: If you change this function, please make the same changes to CTPauseXBoxMenu.uc
	local int i;
	local int NumUnhidden;
	local float NumUnhiddenFloat;
	local float DistBetweenMenus;
	local float MenuPos;

	// Count the number of hidden things
	NumUnhidden = 0;
	NumUnhiddenFloat = 0.0;
	for (i = 0; i < NUM_OPTIONS; i++)
	{
		if (MenuOptions[i].bHidden == 0)
		{
			NumUnhidden++;
			NumUnhiddenFloat += 1.0;
		}
	}
	
	DistBetweenMenus = MenuOptions[1].Blurred.PosY - MenuOptions[0].Blurred.PosY;

	// Start of menu pos is .5 - (.5 * TotalSizeOfMenus)
	MenuPos = 0.5 - (0.5 * (((NumUnhiddenFloat - 1.0) * DistBetweenMenus) + MenuOptions[0].BackgroundBlurred.ScaleY));

	for (i = 0; i < NUM_OPTIONS; i++)
	{
		if (MenuOptions[i].bHidden == 0)
		{
			MenuOptions[i].Blurred.PosY = MenuPos;
			MenuOptions[i].Focused.PosY = MenuPos;
			MenuOptions[i].BackgroundBlurred.PosY = MenuPos;
			MenuOptions[i].BackgroundFocused.PosY = MenuPos;
			MenuPos = MenuPos + DistBetweenMenus;
		}
	}
}

simulated function LoadLastSaveSelected()
{
	if ( bLoadOrSaveSelected )
		return;
		
	bLoadLastSelected = True;
    OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(LoadLastConfirm) );
}

simulated function QuickSaveSelected()
{
	GetPlayerOwner().ConsoleCommand("QuickSave");
	GetPlayerOwner().SetPause(false);
	GetPlayerOwner().MenuClose();
}

simulated function QuickLoadSelected()
{
	if ( bLoadOrSaveSelected )
		return;
		
	GetPlayerOwner().QuickLoad();
	GetPlayerOwner().SetPause(false);
	GetPlayerOwner().MenuClose();
}

simulated function ResumeGameSelected()
{
	if ( MenuOptions[3].bHidden == 0 )
	{
		GetPlayerOwner().SetPause(false);
		GetPlayerOwner().MenuClose();
	}
}

simulated function RestartMissionSelected()
{
	local bool bMarketingDemo;
	local bool bGotValue;
	local string value;
	
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "MarketingDemo", value );			
	if ( bGotValue )
		bMarketingDemo = bool(value);

	bRestartMissionSelected = True;
	
	if ( !bMarketingDemo )	
		OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(RestartMissionConfirm) );
	else
		OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(RestartMissionDemoConfirm) );
}

simulated function LoadGameSelected()
{
	bLoadOrSaveSelected = True;
	CallMenuClass("XInterfaceCTMenus.CTLoadGameMenu");
}

simulated function SaveGameSelected()
{
	bLoadOrSaveSelected = True;
	CallMenuClass("XInterfaceCTMenus.CTSaveGameMenu");
}

simulated function OptionsSelected()
{
	CallMenuClass("XInterfaceCTMenus.CTGameOptionsPCMenu");
}

simulated function EndMissionSelected()
{
	local bool bMarketingDemo;
	local bool bGotValue;
	local string value;
	
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "MarketingDemo", value );			
	if ( bGotValue )
		bMarketingDemo = bool(value);
		
	bEndMissionSelected = True;
	if ( !bMarketingDemo )
		OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(EndMissionConfirm) );
	else
		OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(EndMissionDemoConfirm) );

}

simulated function QuitSelected()
{
	bQuitGameSelected = True;
    OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(QuitGameConfirm) );
}

simulated function bool MenuClosed( Menu closingMenu )
{
    local MenuQuestionYesNo QuestionMenu;

	if ( bLoadOrSaveSelected )
	{
		if ( ( CTLoadGameMenu( closingMenu ) != None ) || 
			 ( CTSaveGameMenu( closingMenu ) != None ) )
		{
			if ( MenuOptions[0].bHidden == 0 )
			{
				// They might have deleted all their saves in the
				// load game menu...
				if ( GetPlayerOwner().CurrentProfileNumSaves() == 0 )
				{
					// There are no saves...hide the load last save option
					MenuOptions[0].bHidden = 1;
					FocusOnNothing();	
				}
			}
			
			if ( MenuOptions[2].bHidden == 0 )
			{
				if ( !GetPlayerOwner().HasQuickSave() )
				{
					// No quicksave
					MenuOptions[2].bHidden = 1;
					FocusOnNothing();					
				}
			}
			
			bLoadOrSaveSelected = False;
		}
	}
	
	if ( !bEndMissionSelected && !bQuitGameSelected && !bRestartMissionSelected && !bLoadLastSelected )
		return false;
		
    QuestionMenu = MenuQuestionYesNo( closingMenu );
    if( QuestionMenu != None )
    {
        if( QuestionMenu.bSelectedYes )
        {
			if ( bEndMissionSelected )
			{
				bEndMissionSelected = False;
				
				// Exit the level
				GetPlayerOwner().ExitLevel();				
			}
			else if ( bQuitGameSelected )
			{
				bQuitGameSelected = False;
				
				GetPlayerOwner().ConsoleCommand("exit");				
			}
			else if ( bRestartMissionSelected )
			{
				bRestartMissionSelected = False;
				GetPlayerOwner().ConsoleCommand("restartlevel");			
				//GetPlayerOwner().RestartMission();
			}
			else if ( bLoadLastSelected )
			{
				bLoadLastSelected = False;
				GetPlayerOwner().LoadMostRecent();
				GetPlayerOwner().SetPause(false);
				GetPlayerOwner().MenuClose();	
			}
        }
        else
        {
			bEndMissionSelected = False;
			bQuitGameSelected = False;
			bRestartMissionSelected = False;
			bLoadLastSelected = False;
        }
        
        return true;
    }

    return false;
}

simulated function HandleInputBack()
{
	ResumeGameSelected();
}

simulated function EnableHintsSelected()
{
	if (GetPlayerOwner().CanEnableHints())
		GetPlayerOwner().bKeepHintMenusAwfulHack = true;
	ResumeGameSelected();
}


defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.blacksquare',DrawColor=(A=120),Style="FullScreen")
     MenuOptions(0)=(Blurred=(Text="LOAD LAST SAVE",PosX=0.5,PosY=0.233332),BackgroundBlurred=(PosX=0.5,PosY=0.233332,ScaleX=0.3675,ScaleY=0.04333),OnSelect="LoadLastSaveSelected",Style="ButtonTextStyle1")
     MenuOptions(1)=(Blurred=(Text="QUICK SAVE",PosY=0.291666),BackgroundBlurred=(PosY=0.291666),OnSelect="QuickSaveSelected")
     MenuOptions(2)=(Blurred=(Text="QUICK LOAD"),OnSelect="QuickLoadSelected")
     MenuOptions(3)=(Blurred=(Text="RESUME GAME"),OnSelect="ResumeGameSelected")
     MenuOptions(4)=(Blurred=(Text="RESTART LEVEL"),OnSelect="RestartMissionSelected")
     MenuOptions(5)=(Blurred=(Text="SAVE GAME"),OnSelect="SaveGameSelected")
     MenuOptions(6)=(Blurred=(Text="LOAD GAME"),OnSelect="LoadGameSelected")
     MenuOptions(7)=(Blurred=(Text="OPTIONS"),OnSelect="OptionsSelected")
     MenuOptions(8)=(Blurred=(Text="ENABLE HINTS"),OnSelect="EnableHintsSelected")
     MenuOptions(9)=(Blurred=(Text="END MISSION"),OnSelect="EndMissionSelected")
     MenuOptions(10)=(Blurred=(Text="QUIT PROGRAM"),OnSelect="QuitSelected")
     EndMissionConfirm="ARE YOU SURE YOU WANT TO END THE CURRENT MISSION?  ANY UNSAVED PROGRESS WILL BE LOST."
     QuitGameConfirm="ARE YOU SURE YOU WANT TO QUIT TO WINDOWS?  ANY UNSAVED PROGRESS WILL BE LOST."
     RestartMissionConfirm="ARE YOU SURE YOU WANT TO RESTART THE MISSION?  ANY UNSAVED PROGRESS WILL BE LOST."
     LoadLastConfirm="ARE YOU SURE YOU WANT TO LOAD THE LAST SAVE GAME?  ANY UNSAVED PROGRESS WILL BE LOST."
     EndMissionDemoConfirm="ARE YOU SURE YOU WANT TO END THE CURRENT MISSION?  ANY PROGRESS WILL BE LOST."
     RestartMissionDemoConfirm="ARE YOU SURE YOU WANT TO RESTART THE LEVEL?  ANY PROGRESS WILL BE LOST."
     ModulateRate=1
     BackgroundMovieName=""
     BackgroundMusic=None
     bFullscreenOnly=True
}

