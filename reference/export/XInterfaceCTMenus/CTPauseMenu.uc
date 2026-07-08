class CTPauseMenu extends MenuTemplate;

var() MenuSprite    Background;

var() MenuSprite FriendsIcon;
var() Material FriendRequestIcon;
var() Material GameInviteIcon;

var() MenuButtonText	ReturnToGame;
var() MenuButtonText	LoadMap;
var() MenuButtonText	QuickLoad;
var() MenuButtonText	QuickSave;
//var() MenuButtonText	Options;
var() MenuButtonText	ChangeTeams;
var() MenuButtonText	PlayerList;
Var() MenuButtonText	FriendList;
Var() MenuButtonText ToggleCloak;
var() MenuButtonText	InvertLook;
var() MenuButtonText	ControllerConfig;
var() MenuButtonText	QuitGame;

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


simulated function Init( String Args )
{
	local GameReplicationInfo GRI;
	local PlayerController PC;
	local bool IsLive;
    
	PC = PlayerController(Owner);
	
	IsLive = ( ConsoleCommand("XLIVE GETAUTHSTATE") == "ONLINE" );
	
	Super.Init( Args );
	
	FocusOnWidget( ReturnToGame );
	
	GRI = PC.GameReplicationInfo;
	
//    if( IsSinglePlayerGame() || !GRI.bTeamGame )
	// TODO: turn this back on for spectators later
	if( !GRI.bTeamGame || PC.IsSpectating() )
        ChangeTeams.bHidden = 1;

	if( Level.NetMode == NM_StandAlone )
	{
		PlayerList.bHidden = 1;
		FriendList.bHidden = 1;
	}
	else
	{
		QuickLoad.bHidden = 1;
		QuickSave.bHidden = 1;
		LoadMap.bHidden = 1;

		QuitGame.Blurred.Text = StringDisconnect;

		// TODO: verify this is an ok place to set these.
		class'GameEngine'.default.DisconnectMenuClass = "XInterfaceLive.MenuLiveMain";
		class'GameEngine'.default.DisconnectMenuArgs = "";
	}

	// TODO: check something less totally lame.
	if ( int(ConsoleCommand( "NUMVIEWPORTS" )) > 1 )
	{
		QuitGame.Blurred.Text = StringEndMatch;

		// TODO: verify this is an ok place to set these.
		class'GameEngine'.default.DisconnectMenuClass = "XInterfaceMP.MenuSplitscreenPlayers";
		class'GameEngine'.default.DisconnectMenuArgs = "";
	}



	if ( IsLive )
	{
		if (ConsoleCommand("XLIVE CLOAKCHECK") == "TRUE")
			ToggleCloak.Blurred.Text = StringCloakToggleOff;
		else
			ToggleCloak.Blurred.Text = StringCloakToggleOn;
	}
	else
		ToggleCloak.bHidden = 1;
}

simulated function ToggleCloakSelected()
{
	local PlayerController PC;

	PC = PlayerController(Owner);
	ConsoleCommand("XLIVE CLOAKTOGGLE");
	if (ConsoleCommand("XLIVE CLOAKCHECK") == "TRUE")
		ToggleCloak.Blurred.Text = StringCloakToggleOff;
	else
		ToggleCloak.Blurred.Text = StringCloakToggleOn;
}

simulated function ReturnToGameSelected()
{
	GetPlayerOwner().SetPause(false);
	GetPlayerOwner().MenuClose();
}

simulated function LoadMapSelected()
{
	local string value;
	local bool bGotValue;

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "FocusGroup", value );
	if ( bGotValue && bool(value) )
		GetPlayerOwner().ClientOpenXMenu("XInterfaceCTMenus.CT_Focus_LoadGameMenu");
	else
		GetPlayerOwner().ClientOpenXMenu("XInterfaceCTMenus.CTLoadGameMenu");
}

simulated function QuickLoadSelected()
{
	local string value;
	local bool bGotValue;

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "FocusGroup", value );
	if ( bGotValue && bool(value) )
		return;
		
	GetPlayerOwner().ConsoleCommand("QuickLoad");
	GetPlayerOwner().SetPause(false);
	GetPlayerOwner().MenuClose();
}

simulated function QuickSaveSelected()
{
	local string value;
	local bool bGotValue;

	bGotValue = GetPlayerOwner().GetConfigValue("Engine.GameEngine", "FocusGroup", value );
	if ( bGotValue && bool(value) )
		return;
	GetPlayerOwner().ConsoleCommand("QuickSave");
	GetPlayerOwner().SetPause(false);
	GetPlayerOwner().MenuClose();
}

/*
simulated function OptionsSelected()
{
}
*/

simulated function InvertLookSelected()
{
	GetPlayerOwner().ConsoleCommand("InvertLook");
	GetPlayerOwner().SetPause(false);
	GetPlayerOwner().MenuClose();
}

simulated function ControllerConfigSelected()
{
	GetPlayerOwner().ClientOpenXMenu("XInterfaceCTMenus.CTControlConfigMenu");
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
    
    if( QuitGame.Blurred.Text == StringForfeit )
        Question.SetText( StringReallyForfeit );
    else if( QuitGame.Blurred.Text == StringDisconnect )
    {
//          if( IsLive && (!PC.bIsGuest) ) //&& PC.IsSharingScreen() )
//              Question.SetText( StringReallyDisconnect @ StringGuestWillGoToo);
//          else
            Question.SetText( StringReallyDisconnect );
    }
    else if( QuitGame.Blurred.Text == StringEndMatch )
    {
//          if( IsLive && (!PC.bIsGuest) ) // && PC.IsSharingScreen() )
//              Question.SetText( StringReallyEndMatch @ StringGuestWillGoToo);
//          else
            Question.SetText( StringReallyEndMatch );
    }
    else if( QuitGame.Blurred.Text == StringLeaveMatch )
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
		FriendList.bHidden = 0;
        FriendsIcon.bHidden = 0;
        FriendsIcon.PosX = FriendList.ActiveArea.X2;
        FriendsIcon.PosX += 0.02;
        FriendsIcon.PosY = FriendList.Blurred.PosY;
        FriendsIcon.WidgetTexture = FriendRequestIcon;
    }
	else if( PC.GetNumGameInvites() > 0 )
    {
		FriendList.bHidden = 0;
        FriendsIcon.bHidden = 0;
        FriendsIcon.PosX = FriendList.ActiveArea.X2;
        FriendsIcon.PosX += 0.02;
        FriendsIcon.PosY = FriendList.Blurred.PosY;
        FriendsIcon.WidgetTexture = GameInviteIcon;
    }
    else
    {
		 if( Level.NetMode == NM_StandAlone )
			 FriendList.bHidden = 1;

        FriendsIcon.bHidden = 1;
    }
}

simulated function HandleInputBack();



defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.RCTitlePage',DrawColor=(B=255,G=255,R=255,A=255),ScaleX=1,ScaleY=1,ScaleMode=MSCM_Fit,Style="FullScreen")
     FriendsIcon=(DrawPivot=DP_MiddleLeft,ScaleX=0.5,ScaleY=0.5,Pass=3)
     FriendRequestIcon=Texture'GUIContent.Menu.XBLplayer_add'
     GameInviteIcon=Texture'GUIContent.Menu.XBLinvite_receive'
     ReturnToGame=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="RETURN TO GAME",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.44),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.44,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="RETURN TO GAME",OnSelect="ReturnToGameSelected")
     LoadMap=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="LOAD MAP",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.48),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.48,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="LOAD MAP",OnSelect="LoadMapSelected")
     QuickLoad=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="QUICK LOAD",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.52),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.52,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="QUICK LOAD",OnSelect="QuickLoadSelected")
     QuickSave=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="QUICK SAVE",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.56),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.56,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="QUICK SAVE",OnSelect="QuickSaveSelected")
     ChangeTeams=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="CHANGE TEAMS",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.6),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.6,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="CHANGE TEAMS",OnSelect="ChangeTeamsSelected")
     PlayerList=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="PLAYERS LIST",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.64),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.64,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="PLAYERS LIST",OnSelect="PlayerListSelected")
     FriendList=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="FRIENDS LIST",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.68),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.68,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="FRIENDS LIST",OnSelect="FriendListSelected")
     ToggleCloak=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.72),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.72,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="TOGGLE CLOAK",OnSelect="ToggleCloakSelected")
     InvertLook=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="INVERT LOOK",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.76),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.76,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="INVERT LOOK",OnSelect="InvertLookSelected")
     ControllerConfig=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="CONTROLLER CONFIG",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.8),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.8,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="CONTROLLER CONFIG",OnSelect="ControllerConfigSelected")
     QuitGame=(Blurred=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="QUIT GAME",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.84),BackgroundFocused=(WidgetTexture=Texture'GUIContent.Menu.SelectionButton',DrawPivot=DP_MiddleMiddle,PosX=0.692383,PosY=0.84,ScaleX=1.5,ScaleMode=MSCM_Stretch),HelpText="QUIT GAME",OnSelect="QuitGameSelected")
     StringCloakToggleOn="APPEAR OFFLINE"
     StringCloakToggleOff="APPEAR ONLINE"
     StringForfeit="FORFEIT"
     StringDisconnect="DISCONNECT"
     StringEndMatch="END MATCH"
     StringLeaveMatch="LEAVE MATCH"
     StringReallyForfeit="REALLY FORFEIT?"
     StringReallyDisconnect="REALLY DISCONNECT?"
     StringReallyEndMatch="REALLY END THE MATCH?"
     StringReallyLeaveMatch="REALLY LEAVE THE MATCH?"
     StringReallySwitchTeams="REALLY SWITCH TEAMS?"
     StringGuestWillGoToo="YOUR GUESTS WILL BE FORCED TO DISCONNECT."
     ModulateRate=1
     SoundOnFocus=None
     BackgroundMusic=None
     bFullscreenOnly=True
}

