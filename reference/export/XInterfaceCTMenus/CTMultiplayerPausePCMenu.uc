class CTMultiplayerPausePCMenu extends MenuTemplate;

var() MenuSprite		Background;

const NUM_OPTIONS = 6;
var() MenuButtonText	MenuOptions[NUM_OPTIONS];

var() localized String StringForfeit;       // Single-player game
var() localized String StringDisconnect;    // Client in network game
var() localized String StringEndMatch;      // Host in network game (or root split-screen?)
var() localized String StringLeaveMatch;    // Non-root split-screen client
var() localized String StringTutorialDisconnect; // for tutorial

var() localized String StringReallyForfeit;
var() localized String StringReallyDisconnect;
var() localized String StringReallyEndMatch;
var() localized String StringReallyLeaveMatch;
var() localized String StringReallySwitchTeams;

var() localized String StringGuestWillGoToo;

var() localized String StringGamePaused;

var() localized String QuitGameConfirm;

var() bool bQuitGameSelected;

var() localized String StringEnterSpectatorMode;
var() localized String StringExitSpectatorMode;

simulated function Init( String Args )
{
	local GameReplicationInfo GRI;
	local PlayerController PC;
	local int i;
	    
	PC = PlayerController(Owner);
	
	Super.Init( Args );

	if ( Caps(GetPlayerOwner().GetLanguage()) != "INT" )
	{
		for ( i = 0; i < NUM_OPTIONS; ++i )
		{
			MenuOptions[i].BackgroundBlurred.ScaleX = 0.65;
			MenuOptions[i].BackgroundFocused.ScaleX = 0.65;
		}
	}
	
	FocusOnWidget( MenuOptions[0] );
	
	GRI = PC.GameReplicationInfo;
	
//    if( IsSinglePlayerGame() || !GRI.bTeamGame )
	// TODO: turn this back on for spectators later
	if( !GRI.bTeamGame || PC.IsSpectating() )
        MenuOptions[1].bHidden = 1;

	if ( PC.IsSpectating() )
		MenuOptions[2].Blurred.Text = StringExitSpectatorMode;
	else
		MenuOptions[2].Blurred.Text = StringEnterSpectatorMode;
		
	MenuOptions[4].Blurred.Text = StringDisconnect;

	// TODO: verify this is an ok place to set these.
	class'GameEngine'.default.DisconnectMenuClass = "XInterfaceCTMenus.CTMultiplayerPCMenu";
	class'GameEngine'.default.DisconnectMenuArgs = "";
	
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

simulated function ReturnToGameSelected()
{
	GetPlayerOwner().SetPause(false);
	GetPlayerOwner().MenuClose();
}

simulated function OptionsSelected()
{
	GotoMenuClass("XInterfaceCTMenus.CTGameOptionsPCMenu");
}

simulated function EndGameSelected()
{
//	if (IsOnConsole() && Level.NetMode != NM_StandAlone )
	if (Level.NetMode != NM_StandAlone )
		OnDisconnect();
	else
		GotoMenuClass("XInterfaceCTMenus.CTMenuMain");
}

simulated function QuitSelected()
{
	bQuitGameSelected = True;
    OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(QuitGameConfirm) );
}

simulated function SpectatorSelected()
{
	local PlayerController PC;
	PC = PlayerController(Owner);

	PC.ToggleSpectatorMode();
	
	CloseMenu();
}

simulated function ChangeTeamsSelected()
{
    local MenuSwitchTeam Question;
	 local PlayerController PC;
	 PC = PlayerController(Owner);

	 if (PC.IsSpectating())
	 {
		 // TODO: make this work
		 GetPlayerOwner().SetPause(false);
		 GetPlayerOwner().MenuClose();
		 PC.ClientOpenMenu( PC.GetTeamMenuClass() );
	 }
	 else
	 {
		 Question = Spawn(class'MenuSwitchTeam', Owner);
		 Question.SetText( StringReallySwitchTeams );
		 CloseMenu();
		 CallMenu( Question );
	 }
}

simulated function OnDisconnect()
{
    local MenuDisconnect Question;
    local PlayerController PC;
    
    PC = PlayerController(Owner);

    Question = Spawn(class'MenuDisconnect', Owner);
    
    if( MenuOptions[4].Blurred.Text == StringForfeit )
    {
        Question.SetText( StringReallyForfeit );
    }
    else if( MenuOptions[4].Blurred.Text == StringDisconnect )
    {
        Question.SetText( StringReallyDisconnect );
    }
    else if( MenuOptions[4].Blurred.Text == StringEndMatch )
    {
        Question.SetText( StringReallyEndMatch );
    }
    else if( MenuOptions[4].Blurred.Text == StringLeaveMatch )
    {
        Question.SetText( StringReallyLeaveMatch );
    }

    GotoMenu( Question );
}


simulated function Tick( float DT )
{
    local PlayerController PC;
    
    Super.Tick(DT);

    PC = PlayerController(Owner);
   
}

simulated function HandleInputBack()
{
	ReturnToGameSelected();
}

simulated function bool MenuClosed( Menu closingMenu )
{
    local MenuQuestionYesNo QuestionMenu;

	if ( !bQuitGameSelected )
		return false;
		
    QuestionMenu = MenuQuestionYesNo( closingMenu );
    if( QuestionMenu != None )
    {
        if( QuestionMenu.bSelectedYes )
        {
			if ( bQuitGameSelected )
			{
				bQuitGameSelected = False;
				
				GetPlayerOwner().ConsoleCommand("exit");				
			}
        }
        else
        {
			bQuitGameSelected = False;
        }
        
        return true;
    }

    return false;
}



defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.blacksquare',DrawColor=(A=192),Style="FullScreen")
     MenuOptions(0)=(Blurred=(Text="RETURN TO GAME",PosX=0.5,PosY=0.408333),BackgroundBlurred=(PosX=0.5,PosY=0.408333,ScaleX=0.5,ScaleY=0.04333),OnSelect="ReturnToGameSelected",Style="ButtonTextStyle1")
     MenuOptions(1)=(Blurred=(Text="CHANGE TEAMS",PosY=0.466666),BackgroundBlurred=(PosY=0.466666),OnSelect="ChangeTeamsSelected")
     MenuOptions(2)=(OnSelect="SpectatorSelected")
     MenuOptions(3)=(Blurred=(Text="OPTIONS"),OnSelect="OptionsSelected")
     MenuOptions(4)=(Blurred=(Text="END GAME"),OnSelect="EndGameSelected")
     MenuOptions(5)=(Blurred=(Text="QUIT PROGRAM"),OnSelect="QuitSelected")
     StringForfeit="FORFEIT"
     StringDisconnect="DISCONNECT"
     StringEndMatch="END MATCH"
     StringLeaveMatch="LEAVE MATCH"
     StringReallyForfeit="ARE YOU SURE YOU WANT TO FORFEIT?"
     StringReallyDisconnect="ARE YOU SURE YOU WANT TO DISCONNECT?"
     StringReallyEndMatch="ARE YOU SURE YOU WANT TO END THE MATCH?"
     StringReallyLeaveMatch="ARE YOU SURE YOU WANT TO LEAVE THE MATCH?"
     StringReallySwitchTeams="ARE YOU SURE YOU WANT TO SWITCH TEAMS?"
     StringGuestWillGoToo="YOUR GUESTS WILL BE FORCED TO DISCONNECT."
     QuitGameConfirm="ARE YOU SURE YOU WANT TO QUIT TO WINDOWS?  ANY UNSAVED PROGRESS WILL BE LOST."
     StringEnterSpectatorMode="ENTER SPECTATOR MODE"
     StringExitSpectatorMode="EXIT SPECTATOR MODE"
     ModulateRate=1
     BackgroundMovieName=""
     BackgroundMusic=None
     bFullscreenOnly=True
}

