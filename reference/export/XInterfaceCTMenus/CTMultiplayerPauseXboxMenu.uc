class CTMultiplayerPauseXboxMenu extends MenuTemplate;

var() MenuSprite		Background;

var() MenuSprite FriendsIcon;
var() Material FriendRequestIcon;
var() Material GameInviteIcon;

const NUM_OPTIONS = 8;
var() MenuButtonText	MenuOptions[NUM_OPTIONS];

var() localized String StringCloakToggleOn; // live friends cloak?
var() localized String StringCloakToggleOff;

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

var() localized String StringEnterSpectatorMode;
var() localized String StringExitSpectatorMode;

simulated function Init( String Args )
{
	local GameReplicationInfo GRI;
	local PlayerController PC;
	local bool IsLive;
	local int i;
    
	PC = PlayerController(Owner);
	
	IsLive = ( ConsoleCommand("XLIVE GETAUTHSTATE") == "ONLINE" );
	
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

	if( Level.NetMode == NM_StandAlone )
	{
		MenuOptions[3].bHidden = 1;
		MenuOptions[4].bHidden = 1;
	}
	else if (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer)
	{
		MenuOptions[7].Blurred.Text = StringEndMatch;

		if (Level.IsSplitScreen())
			MenuOptions[3].bHidden = 1;

		// TODO: verify this is an ok place to set these.
		if (Level.IsSystemLink())
			class'GameEngine'.default.DisconnectMenuClass = "XInterfaceCTMenus.CTMultiplayerXBoxMenu";
		else
			class'GameEngine'.default.DisconnectMenuClass = "XInterfaceLive.MenuLiveMain";
		class'GameEngine'.default.DisconnectMenuArgs = "";
	}
	else
	{
		MenuOptions[7].Blurred.Text = StringDisconnect;

		// TODO: verify this is an ok place to set these.
		if (Level.IsSystemLink())
			class'GameEngine'.default.DisconnectMenuClass = "XInterfaceCTMenus.CTMultiplayerXBoxMenu";
		else
			class'GameEngine'.default.DisconnectMenuClass = "XInterfaceLive.MenuLiveMain";
		class'GameEngine'.default.DisconnectMenuArgs = "";
	}

	// TODO: check something less totally lame.
	if ( int(ConsoleCommand( "NUMVIEWPORTS" )) > 1 )
	{
		MenuOptions[7].Blurred.Text = StringEndMatch;

		// TODO: verify this is an ok place to set these.
		class'GameEngine'.default.DisconnectMenuClass = "XInterfaceMP.MenuSplitscreenPlayers";
		class'GameEngine'.default.DisconnectMenuArgs = "";
	}



	if ( IsLive )
	{
		if (ConsoleCommand("XLIVE CLOAKCHECK") == "TRUE")
			MenuOptions[5].Blurred.Text = StringCloakToggleOff;
		else
			MenuOptions[5].Blurred.Text = StringCloakToggleOn;
	}
	else
	{
		MenuOptions[4].bHidden = 1;
		MenuOptions[3].bHidden = 1;
		MenuOptions[5].bHidden = 1;
	}
		
	if ( Level.IsSystemLink() || Level.IsSplitScreen() )
	{
		// No players list when in System Link or Splitscreen
		MenuOptions[3].bHidden = 1;		
	}
	
	if ( Level.IsDedicatedServer() )
	{
		// Make the background completely black
		Background.DrawColor.A = 255;
		
		// Hide these options for a dedicated server
		MenuOptions[1].bHidden = 1;
		MenuOptions[2].bHidden = 1;
		MenuOptions[6].bHidden = 1;
		MenuOptions[7].bHidden = 1;
		FocusOnNothing();
	}
	
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

simulated function ToggleCloakSelected()
{
	ConsoleCommand("XLIVE CLOAKTOGGLE");
	if (ConsoleCommand("XLIVE CLOAKCHECK") == "TRUE")
		MenuOptions[5].Blurred.Text = StringCloakToggleOff;
	else
		MenuOptions[5].Blurred.Text = StringCloakToggleOn;
}

simulated function ReturnToGameSelected()
{
	if ( Level.IsDedicatedServer() )
	{
		CloseMenu();
	}
	else
	{
		GetPlayerOwner().SetPause(false);
		GetPlayerOwner().MenuClose();
	}
}


simulated function OptionsSelected()
{
	CallMenuClass("XInterfaceCTMenus.CTOptionsXboxMenu");
}

simulated function QuitGameSelected()
{
	if (IsOnConsole() && Level.NetMode != NM_StandAlone )
		OnDisconnect();
	else
	{
		GotoMenuClass("XInterfaceCTMenus.CTMenuMain");
		// TODO:  don't really wanna Exit here, go back to main menu, probably.
		//GetPlayerOwner().ConsoleCommand("exit");
		//GetPlayerOwner().MenuClose();
	}
}

simulated function SpectatorSelected()
{
	local PlayerController PC;
	PC = PlayerController(Owner);

	PC.ToggleSpectatorMode();
	
	GetPlayerOwner().SetPause(false);
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

		 GotoMenu( Question );
	 }
}

simulated function PlayerListSelected()
{
    CallMenuClass( "XInterfaceLive.MenuPlayerList" );
}

simulated function FriendListSelected()
{
//    SavePosition();
//    GotoMenuClass( "XInterfaceLive.MenuFriendList", "START" );
	CallMenuClass( "XInterfaceLive.MenuFriendList", "START" );
}

simulated function OnDisconnect()
{
    local MenuDisconnect Question;
    local PlayerController PC;
    local bool IsLive;
    
    PC = PlayerController(Owner);
    IsLive = ( ConsoleCommand("XLIVE GETAUTHSTATE") == "ONLINE" );

    Question = Spawn(class'MenuDisconnect', Owner);
    
    if( MenuOptions[7].Blurred.Text == StringForfeit )
        Question.SetText( StringReallyForfeit );
    else if( MenuOptions[7].Blurred.Text == StringDisconnect )
    {
//          if( IsLive && (!PC.bIsGuest) ) //&& PC.IsSharingScreen() )
//              Question.SetText( StringReallyDisconnect @ StringGuestWillGoToo);
//          else
            Question.SetText( StringReallyDisconnect );
    }
    else if( MenuOptions[7].Blurred.Text == StringEndMatch )
    {
//          if( IsLive && (!PC.bIsGuest) ) // && PC.IsSharingScreen() )
//              Question.SetText( StringReallyEndMatch @ StringGuestWillGoToo);
//          else
            Question.SetText( StringReallyEndMatch );
    }
    else if( MenuOptions[7].Blurred.Text == StringLeaveMatch )
    {
        Question.SetText( StringReallyLeaveMatch );
    }



    // StringReallyEndTutorial
    
//    SavePosition();
    GotoMenu( Question );
}


simulated function Tick( float DT )
{
    local PlayerController PC;
    
    Super.Tick(DT);

    PC = PlayerController(Owner);
    
	if( PC.GetNumFriendRequests() > 0 )
    {
		MenuOptions[4].bHidden = 0;
        FriendsIcon.bHidden = 0;
        FriendsIcon.PosX = MenuOptions[4].ActiveArea.X2;
        FriendsIcon.PosX += 0.02;
        FriendsIcon.PosY = MenuOptions[4].Blurred.PosY;
        FriendsIcon.WidgetTexture = FriendRequestIcon;
    }
	else if( PC.GetNumGameInvites() > 0 )
    {
		MenuOptions[4].bHidden = 0;
        FriendsIcon.bHidden = 0;
        FriendsIcon.PosX = MenuOptions[4].ActiveArea.X2;
        FriendsIcon.PosX += 0.02;
        FriendsIcon.PosY = MenuOptions[4].Blurred.PosY;
        FriendsIcon.WidgetTexture = GameInviteIcon;
    }
    else
    {
		 if( Level.NetMode == NM_StandAlone )
			 MenuOptions[4].bHidden = 1;

        FriendsIcon.bHidden = 1;
    }
    
	//AdjustButtons();    
}

simulated function HandleInputBack()
{
	if ( Level.IsDedicatedServer() )
		CloseMenu();
	else
		ReturnToGameSelected();
}



defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.blacksquare',DrawColor=(A=192),Style="FullScreen")
     FriendsIcon=(DrawPivot=DP_MiddleLeft,ScaleX=0.5,ScaleY=0.5,Pass=3)
     FriendRequestIcon=Texture'GUIContent.Menu.XBLplayer_add'
     GameInviteIcon=Texture'GUIContent.Menu.XBLinvite_receive'
     MenuOptions(0)=(Blurred=(Text="RETURN TO GAME",PosX=0.5,PosY=0.291666),BackgroundBlurred=(PosX=0.5,PosY=0.291666,ScaleX=0.5,ScaleY=0.04333),OnSelect="ReturnToGameSelected",Style="ButtonTextStyle1")
     MenuOptions(1)=(Blurred=(Text="CHANGE TEAMS",PosY=0.35),BackgroundBlurred=(PosY=0.35),OnSelect="ChangeTeamsSelected")
     MenuOptions(2)=(OnSelect="SpectatorSelected")
     MenuOptions(3)=(Blurred=(Text="PLAYERS LIST"),OnSelect="PlayerListSelected")
     MenuOptions(4)=(Blurred=(Text="FRIENDS LIST"),OnSelect="FriendListSelected")
     MenuOptions(5)=(OnSelect="ToggleCloakSelected")
     MenuOptions(6)=(Blurred=(Text="OPTIONS"),OnSelect="OptionsSelected")
     MenuOptions(7)=(Blurred=(Text="LEAVE GAME"),OnSelect="QuitGameSelected")
     StringCloakToggleOn="APPEAR OFFLINE"
     StringCloakToggleOff="APPEAR ONLINE"
     StringForfeit="FORFEIT"
     StringDisconnect="LEAVE GAME"
     StringEndMatch="END MATCH"
     StringLeaveMatch="LEAVE MATCH"
     StringReallyForfeit="ARE YOU SURE YOU WANT TO FORFEIT?"
     StringReallyDisconnect="ARE YOU SURE YOU WANT TO LEAVE THE GAME?"
     StringReallyEndMatch="LEAVING THE GAME NOW WILL END THIS SESSION.  ARE YOU SURE YOU WANT TO LEAVE?"
     StringReallyLeaveMatch="ARE YOU SURE YOU WANT TO LEAVE THE MATCH?"
     StringReallySwitchTeams="ARE YOU SURE YOU WANT TO SWITCH TEAMS?"
     StringGuestWillGoToo="YOUR GUESTS WILL BE FORCED TO DISCONNECT."
     StringEnterSpectatorMode="ENTER SPECTATOR MODE"
     StringExitSpectatorMode="EXIT SPECTATOR MODE"
     ModulateRate=1
     BackgroundMovieName=""
     BackgroundMusic=None
     bFullscreenOnly=True
}

