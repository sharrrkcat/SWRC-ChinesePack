class CTPauseXBoxMenu extends MenuTemplate;

var() MenuSprite		Background;

const NUM_OPTIONS = 10;

var() MenuButtonText	MenuOptions[NUM_OPTIONS];

var() localized String	EndMissionConfirm;
var() localized String	RestartMissionConfirm;
var() localized String	LoadLastConfirm;

var() localized String EndMissionDemoConfirm;
var() localized String RestartMissionDemoConfirm;

var() bool				bEndMissionSelected;
var() bool				bRestartMissionSelected;
var() bool				bLoadLastSelected;

var() localized String StringCloakToggleOn; // live friends cloak?
var() localized String StringCloakToggleOff;

var() MenuSprite FriendsIcon;
var() Material FriendRequestIcon;
var() Material GameInviteIcon;

var() bool				bLoadOrSaveSelected;

const					NUM_GOD_MODE_BUTTONS = 8;
var() String			GodModeSequence[NUM_GOD_MODE_BUTTONS];
var() int				GodModePos;

const					NUM_FULL_AMMO_BUTTONS = 8;
var() String			FullAmmoSequence[NUM_FULL_AMMO_BUTTONS];
var() int				FullAmmoPos;

const					NUM_SKIP_LEVEL_BUTTONS = 8;
var() String			SkipLevelSequence[NUM_SKIP_LEVEL_BUTTONS];
var() int				SkipLevelPos;

const					NUM_ALL_LEVELS_BUTTONS = 8;
var() String			AllLevelsSequence[NUM_ALL_LEVELS_BUTTONS];
var() int				AllLevelsPos;

var() Sound				SoundFX;

var() localized String	DamagedSave;

simulated function Init( String Args )
{
	local bool IsLive;
	local string value;
	local bool bGotValue;
	local bool bOXMDemo;
	local bool bDVDDemo;
	local int i;
	local string LevelName;

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "OXMDemo", value );			
	if ( bGotValue )
		bOXMDemo = bool(value);

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "DVDDemo", value );			
	if ( bGotValue )
		bDVDDemo = bool(value);

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

	if ( (GetPlayerOwner().Pawn == None) ||
		 (GetPlayerOwner().Pawn.Health <= 0) || 
		  GetPlayerOwner().Pawn.bIncapacitated ||
		  GetPlayerOwner().Pawn.bIncapacitatedOnTurret )
	{
		// They're dead OR incapacitated
		FocusOnWidget( MenuOptions[1] );					
				
		if ( GetPlayerOwner().CurrentProfileNumSaves() > 0 )
		{
			// There are saves, give them the load last save option
			MenuOptions[0].bHidden = 0;			
		}
			
		if ( (GetPlayerOwner().Pawn.Health <= 0) && 
			 !GetPlayerOwner().Pawn.bIncapacitated &&
			 !GetPlayerOwner().Pawn.bIncapacitatedOnTurret )
		{
			// They're dead
			Background.bHidden = 1;			
			
			MenuOptions[1].bHidden = 1;		
			
			if ( MenuOptions[0].bHidden == 0 )
				FocusOnWidget( MenuOptions[0] );		
			else
				FocusOnNothing();
			
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
		FocusOnWidget( MenuOptions[1] );
	}

	if ( !bOXMDemo && !bDVDDemo )
		IsLive = ( ConsoleCommand("XLIVE GETAUTHSTATE") == "ONLINE" );
	else IsLive = false;

	if ( IsLive )
	{
		if (ConsoleCommand("XLIVE CLOAKCHECK") == "TRUE")
			MenuOptions[6].Blurred.Text = StringCloakToggleOff;
		else
			MenuOptions[6].Blurred.Text = StringCloakToggleOn;
	}
	else
	{
		MenuOptions[6].bHidden = 1;
		MenuOptions[5].bHidden = 1;
	}

	GetPlayerOwner().GetCurrentMapName( LevelName );
	LevelName = Caps( LevelName );
	// Strip any extension off the level name
	if ( Caps(Right(LevelName, 4)) == ".CTM" )
		LevelName = Left(LevelName, Len(LevelName) - 4);
	
	if ( (GetPlayerOwner().Pawn == None) || (GetPlayerOwner().Pawn.Health <= 0) ||
	     GetPlayerOwner().bBriefing || (LevelName == "PRO") )
	{
		MenuOptions[3].bHidden = 1;
	}
	
	if ( bOXMDemo || bDVDDemo )
	{
		MenuOptions[0].bHidden = 1;
		MenuOptions[3].bHidden = 1;
		MenuOptions[4].bHidden = 1;
		MenuOptions[5].bHidden = 1;
		MenuOptions[6].bHidden = 1;
		
		if ( MenuOptions[1].bHidden != 0 )
			FocusOnNothing();
	}

	if (GetPlayerOwner().CanEnableHints())
		MenuOptions[8].bHidden = 0;
	else
		MenuOptions[8].bHidden = 1;

	AdjustButtons();
}

simulated function AdjustButtons()
{
	// NOTE: If you change this function, please make the same changes to CTPausePCMenu.uc
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

simulated function ToggleCloakSelected()
{
	local string value;
	local bool bGotValue;
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "TokyoGameShow", value );
	if ( bGotValue && bool(value) )
	{
		return;
	}

	ConsoleCommand("XLIVE CLOAKTOGGLE");
	if (ConsoleCommand("XLIVE CLOAKCHECK") == "TRUE")
		MenuOptions[6].Blurred.Text = StringCloakToggleOff;
	else
		MenuOptions[6].Blurred.Text = StringCloakToggleOn;
}


simulated function FriendListSelected()
{
	local string value;
	local bool bGotValue;
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "TokyoGameShow", value );
	if ( bGotValue && bool(value) )
	{
		return;
	}

	CallMenuClass( "XInterfaceLive.MenuFriendList", "START" );
}

simulated function LoadLastSaveSelected()
{
	if ( bLoadOrSaveSelected )
		return;
		
	bLoadLastSelected = True;
    OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(LoadLastConfirm) );
}

simulated function ResumeGameSelected()
{
	// If you're allowed to...
	if ( MenuOptions[1].bHidden == 0 )
	{
		GetPlayerOwner().SetPause(false);
		GetPlayerOwner().MenuClose();
	}
}

simulated function RestartMissionSelected()
{
	local bool bOXMDemo;
	local bool bDVDDemo;
	local bool bGotValue;
	local string value;
	
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "OXMDemo", value );			
	if ( bGotValue )
		bOXMDemo = bool(value);

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "DVDDemo", value );			
	if ( bGotValue )
		bDVDDemo = bool(value);

	bRestartMissionSelected = True;
	
	if ( !bOXMDemo && !bDVDDemo )	
		OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(RestartMissionConfirm) );
	else
		OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(RestartMissionDemoConfirm) );
}

simulated function LoadGameSelected()
{
	local string value;
	local bool bGotValue;
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "TokyoGameShow", value );
	if ( bGotValue && bool(value) )
	{
		return;
	}

	bLoadOrSaveSelected = True;	
	CallMenuClass("XInterfaceCTMenus.CTLoadGameMenu");
}

simulated function SaveGameSelected()
{
	local string value;
	local bool bGotValue;
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "TokyoGameShow", value );
	if ( bGotValue && bool(value) )
	{
		return;
	}

	bLoadOrSaveSelected = True;	
	CallMenuClass("XInterfaceCTMenus.CTSaveGameMenu");
}

simulated function OptionsSelected()
{
	CallMenuClass("XInterfaceCTMenus.CTOptionsXBoxMenu");
}

simulated function EndMissionSelected()
{
	local bool bOXMDemo;
	local bool bDVDDemo;
	local bool bGotValue;
	local string value;
	
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "OXMDemo", value );			
	if ( bGotValue )
		bOXMDemo = bool(value);
		
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "DVDDemo", value );			
	if ( bGotValue )
		bDVDDemo = bool(value);

	bEndMissionSelected = True;
	if ( !bOXMDemo && !bDVDDemo)
		OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(EndMissionConfirm) );
	else
		OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(EndMissionDemoConfirm) );
}

simulated function Tick( float DT )
{
    local PlayerController PC;
    
    Super.Tick(DT);

    PC = PlayerController(Owner);
    
	if( PC.GetNumFriendRequests() > 0 )
    {
//		MenuOptions[5].bHidden = 0;
        FriendsIcon.bHidden = 0;
        FriendsIcon.PosX = MenuOptions[5].ActiveArea.X2;
        FriendsIcon.PosX += 0.02;
        FriendsIcon.PosY = MenuOptions[5].Blurred.PosY;
        FriendsIcon.WidgetTexture = FriendRequestIcon;
    }
	else if( PC.GetNumGameInvites() > 0 )
    {
//		MenuOptions[5].bHidden = 0;
        FriendsIcon.bHidden = 0;
        FriendsIcon.PosX = MenuOptions[5].ActiveArea.X2;
        FriendsIcon.PosX += 0.02;
        FriendsIcon.PosY = MenuOptions[5].Blurred.PosY;
        FriendsIcon.WidgetTexture = GameInviteIcon;
    }
    else
    {
		// don't hide friend list option...
		 //if( Level.NetMode == NM_StandAlone )
			// MenuOptions[5].bHidden = 1;

        FriendsIcon.bHidden = 1;
    }
}


simulated function EnableHintsSelected()
{
	if (GetPlayerOwner().CanEnableHints())
		GetPlayerOwner().bKeepHintMenusAwfulHack = true;
	ResumeGameSelected();
}

simulated function bool MenuClosed( Menu closingMenu )
{
    local MenuQuestionYesNo QuestionMenu;
    local String Prefix;
    local String MostRecentSaveName;

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
			
			bLoadOrSaveSelected = False;
		}
	}
	
	if ( !bEndMissionSelected && !bRestartMissionSelected && !bLoadLastSelected )
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
			else if ( bRestartMissionSelected )
			{
				bRestartMissionSelected = False;
				GetPlayerOwner().ConsoleCommand("restartlevel");			
				//GetPlayerOwner().RestartMission();
			}
			else if ( bLoadLastSelected )
			{
				bLoadLastSelected = False;
				Prefix = GetPlayerOwner().GetCurrentProfileName() $ "_";
				GetPlayerOwner().GetMostRecentSaveGame( Prefix, MostRecentSaveName );				
				if ( !GetPlayerOwner().VerifySaveGame( MostRecentSaveName ) )
				{
					OverlayMenuClass( "XInterfaceCommon.MenuWarning", MakeQuotedString(MostRecentSaveName $ DamagedSave) );
				}
				else
				{
					GetPlayerOwner().LoadMostRecent();
					GetPlayerOwner().SetPause(false);
					GetPlayerOwner().MenuClose();	
				}
			}			
        }
        else
        {
			bEndMissionSelected = False;
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


simulated function bool HandleInputGamePad( String ButtonName )
{
	if ( !IsOnConsole() )
		return Super.HandleInputGamePad( ButtonName );

	if ( ButtonName ~= GodModeSequence[GodModePos] )
	{
		++GodModePos;
		
		if ( GodModePos >= NUM_GOD_MODE_BUTTONS )
		{
			GetPlayerOwner().ConsoleCommand("TheMatulaakLives");			
			GetPlayerOwner().PlaySound( SoundFX );
			GodModePos = 0;
		}
	}
	else
	{
		GodModePos = 0;
	}
	
	if ( ButtonName ~= FullAmmoSequence[FullAmmoPos] )
	{
		++FullAmmoPos;
		
		if ( FullAmmoPos >= NUM_FULL_AMMO_BUTTONS )
		{
			GetPlayerOwner().ConsoleCommand("Fierfek");			
			GetPlayerOwner().PlaySound( SoundFX );
			FullAmmoPos = 0;
		}
	}
	else
	{
		FullAmmoPos = 0;
	}
	
	if ( ButtonName ~= SkipLevelSequence[SkipLevelPos] )
	{
		++SkipLevelPos;
		
		if ( SkipLevelPos >= NUM_SKIP_LEVEL_BUTTONS )
		{
			GetPlayerOwner().ConsoleCommand("Darman");
			GetPlayerOwner().PlaySound( SoundFX );			
			SkipLevelPos = 0;
		}
	}
	else
	{
		SkipLevelPos = 0;
	}

	if ( ButtonName ~= AllLevelsSequence[AllLevelsPos] )
	{
		++AllLevelsPos;
		
		if ( AllLevelsPos >= NUM_ALL_LEVELS_BUTTONS )
		{
			GetPlayerOwner().ConsoleCommand("Lamasu");
			GetPlayerOwner().PlaySound( SoundFX );			
			AllLevelsPos = 0;
		}
	}
	else
	{
		AllLevelsPos = 0;
	}

    return( Super.HandleInputGamePad( ButtonName ) );
}



defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.blacksquare',DrawColor=(A=120),Style="FullScreen")
     MenuOptions(0)=(Blurred=(Text="LOAD LAST SAVE",PosX=0.5,PosY=0.291666),BackgroundBlurred=(PosX=0.5,PosY=0.291666,ScaleX=0.3675,ScaleY=0.04333),OnSelect="LoadLastSaveSelected",Style="ButtonTextStyle1")
     MenuOptions(1)=(Blurred=(Text="RESUME GAME",PosY=0.35),BackgroundBlurred=(PosY=0.35),OnSelect="ResumeGameSelected")
     MenuOptions(2)=(Blurred=(Text="RESTART LEVEL"),OnSelect="RestartMissionSelected")
     MenuOptions(3)=(Blurred=(Text="SAVE GAME"),OnSelect="SaveGameSelected")
     MenuOptions(4)=(Blurred=(Text="LOAD GAME"),OnSelect="LoadGameSelected")
     MenuOptions(5)=(Blurred=(Text="FRIENDS LIST"),OnSelect="FriendListSelected")
     MenuOptions(6)=(OnSelect="ToggleCloakSelected")
     MenuOptions(7)=(Blurred=(Text="OPTIONS"),OnSelect="OptionsSelected")
     MenuOptions(8)=(Blurred=(Text="ENABLE HINTS"),OnSelect="EnableHintsSelected")
     MenuOptions(9)=(Blurred=(Text="END MISSION"),OnSelect="EndMissionSelected")
     EndMissionConfirm="ARE YOU SURE YOU WANT TO END THE CURRENT MISSION?  ANY UNSAVED PROGRESS WILL BE LOST."
     RestartMissionConfirm="ARE YOU SURE YOU WANT TO RESTART THE LEVEL?  ANY UNSAVED PROGRESS WILL BE LOST."
     LoadLastConfirm="ARE YOU SURE YOU WANT TO LOAD THE LAST SAVE GAME?  ANY UNSAVED PROGRESS WILL BE LOST."
     EndMissionDemoConfirm="ARE YOU SURE YOU WANT TO END THE CURRENT MISSION?  ANY PROGRESS WILL BE LOST."
     RestartMissionDemoConfirm="ARE YOU SURE YOU WANT TO RESTART THE LEVEL?  ANY PROGRESS WILL BE LOST."
     StringCloakToggleOn="APPEAR OFFLINE"
     StringCloakToggleOff="APPEAR ONLINE"
     FriendsIcon=(DrawPivot=DP_MiddleLeft,ScaleX=0.5,ScaleY=0.5,Pass=3)
     FriendRequestIcon=Texture'GUIContent.Menu.XBLplayer_add'
     GameInviteIcon=Texture'GUIContent.Menu.XBLinvite_receive'
     GodModeSequence(0)="Y"
     GodModeSequence(1)="Y"
     GodModeSequence(2)="LT"
     GodModeSequence(3)="U"
     GodModeSequence(4)="X"
     GodModeSequence(5)="K"
     GodModeSequence(6)="X"
     GodModeSequence(7)="Y"
     FullAmmoSequence(0)="Y"
     FullAmmoSequence(1)="Y"
     FullAmmoSequence(2)="X"
     FullAmmoSequence(3)="D"
     FullAmmoSequence(4)="RT"
     FullAmmoSequence(5)="LT"
     FullAmmoSequence(6)="RT"
     FullAmmoSequence(7)="U"
     SkipLevelSequence(0)="Y"
     SkipLevelSequence(1)="Y"
     SkipLevelSequence(2)="R"
     SkipLevelSequence(3)="W"
     SkipLevelSequence(4)="X"
     SkipLevelSequence(5)="X"
     SkipLevelSequence(6)="K"
     SkipLevelSequence(7)="RT"
     AllLevelsSequence(0)="Y"
     AllLevelsSequence(1)="Y"
     AllLevelsSequence(2)="K"
     AllLevelsSequence(3)="RT"
     AllLevelsSequence(4)="K"
     AllLevelsSequence(5)="W"
     AllLevelsSequence(6)="LT"
     AllLevelsSequence(7)="X"
     SoundFX=SoundMultiple'UI_Sound.UI.SFX_Volume_Set'
     DamagedSave=" APPEARS TO BE DAMAGED AND CANNOT BE USED."
     ModulateRate=1
     BackgroundMovieName=""
     BackgroundMusic=None
     bFullscreenOnly=True
}

