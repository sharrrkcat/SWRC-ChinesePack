class CTControllerOptionsRemapXboxMenu extends MenuTemplateTitledBXA;

var() MenuText			Label;

const NUM_SET0_OPTIONS = 9;

var() MenuText			OptionSet0Labels[NUM_SET0_OPTIONS];
var() MenuButtonText	OptionSet0[NUM_SET0_OPTIONS];
var() string			OptionSet0Funcs[NUM_SET0_OPTIONS];

const NUM_SET1_OPTIONS = 5;

var() MenuText			OptionSet1Labels[NUM_SET1_OPTIONS];
var() MenuButtonText	OptionSet1[NUM_SET1_OPTIONS];
var() string			OptionSet1Funcs[NUM_SET1_OPTIONS];

var() MenuButtonText	PrevSet;
var() MenuButtonText	NextSet;

var() int				WhichSet;

var() localized	String	ClickRightStickText;
var() localized	String	ClickLeftStickText;

var() localized String	RightStickText;
var() localized String	LeftStickText;

const GAME_LSTICK = 214;	// EInputKey.GAME_LSTICK
const GAME_RSTICK = 215;	// EInputKey.GAME_RSTICK
const GAME_JOYU = 232;
const GAME_JOYV = 233;
const GAME_JOYX = 240;
const GAME_JOYY = 241;
const GAME_DUP = 208;
const GAME_DDOWN = 209;
const GAME_DLEFT = 210;
const GAME_DRIGHT = 211;

var() String IniButtonNames[16];

var() bool bRemapping;

simulated function String GetINIButtonName( int button )
{
	return IniButtonNames[button - 200];
}

simulated function Init( string Args )
{
	Super.Init( Args );
	
	// BS manual setting of values, because I can't tell
	// why XInterface is not using the values specified
	// in the default settings.
	OptionSet0[0].bDisabled = 1;
	OptionSet0[0].BackgroundBlurred.DrawColor.A = 0;
	OptionSet0[1].bDisabled = 1;
	OptionSet0[1].BackgroundBlurred.DrawColor.A = 0;
	
	SwitchToSet(0);
}

simulated function RestoreDefaults()
{
	GetPlayerOwner().ConsoleCommand("UseControllerConfig DefaultCtrl.ini");
	GetPlayerOwner().SavePlayerInputConfig();
	GetPlayerOwner().SaveInputConfig();
	
	CallMenuClass( "XInterfaceCTMenus.CTSavingSettingsMenu", "" );
	
	RefreshSet0();
	RefreshSet1();	
}

simulated function RefreshSet0()
{
	local int i;
	local int j;
	local array<int> keys;
	
	for ( i = 0; i < NUM_SET0_OPTIONS; ++i )
	{
		keys.Length = 0;
		
		if ( GetPlayerOwner().GetAllButtonMappings( OptionSet0Funcs[i], keys ) )
		{
			for ( j = 0; j < keys.Length; ++j )
			{
				if ( j == 0 )
				{
					if ( keys[j] == GAME_LSTICK )
					{
						OptionSet0[i].Blurred.Text = ClickLeftStickText;
						OptionSet0[i].Focused.Text = ClickLeftStickText;
					}
					else if ( keys[j] == GAME_RSTICK )
					{
						OptionSet0[i].Blurred.Text = ClickRightStickText;
						OptionSet0[i].Focused.Text = ClickRightStickText;
					}
					else if ( ( keys[j] == GAME_JOYX ) || 
							  ( keys[j] == GAME_JOYY ) )
					{
						OptionSet0[i].Blurred.Text = LeftStickText;
						OptionSet0[i].Focused.Text = LeftStickText;
					}
					else if ( ( keys[j] == GAME_JOYU ) || 
							  ( keys[j] == GAME_JOYV ) )
					{
						OptionSet0[i].Blurred.Text = RightStickText;
						OptionSet0[i].Focused.Text = RightStickText;
					}
					else
					{
						OptionSet0[i].Blurred.Text = RetrieveLocalizedKeyName(keys[j]);
						OptionSet0[i].Focused.Text = RetrieveLocalizedKeyName(keys[j]);
					}
				}
				else
				{
					if ( keys[j] == GAME_LSTICK )
					{
						OptionSet0[i].Blurred.Text = OptionSet0[i].Blurred.Text $ ", " $ ClickLeftStickText;
						OptionSet0[i].Focused.Text = OptionSet0[i].Focused.Text $ ", " $ ClickLeftStickText;
					}
					else if ( keys[j] == GAME_RSTICK )
					{
						OptionSet0[i].Blurred.Text = OptionSet0[i].Blurred.Text $ ", " $ ClickRightStickText;
						OptionSet0[i].Focused.Text = OptionSet0[i].Focused.Text $ ", " $ ClickRightStickText;
					}
					else if ( ( keys[j] == GAME_JOYX ) || 
							  ( keys[j] == GAME_JOYY ) )
					{
						OptionSet0[i].Blurred.Text = OptionSet0[i].Blurred.Text $ ", " $ LeftStickText;
						OptionSet0[i].Focused.Text = OptionSet0[i].Focused.Text $ ", " $ LeftStickText;
					}
					else if ( ( keys[j] == GAME_JOYU ) || 
							  ( keys[j] == GAME_JOYV ) )
					{
						OptionSet0[i].Blurred.Text = OptionSet0[i].Blurred.Text $ ", " $ RightStickText;
						OptionSet0[i].Focused.Text = OptionSet0[i].Focused.Text $ ", " $ RightStickText;
					}
					else
					{
						OptionSet0[i].Blurred.Text = OptionSet0[i].Blurred.Text$", "$RetrieveLocalizedKeyName(keys[j]);
						OptionSet0[i].Focused.Text = OptionSet0[i].Focused.Text$", "$RetrieveLocalizedKeyName(keys[j]);
					}					
				}				
			}
			
			OptionSet0[i].Blurred.DrawColor.R=120;
			OptionSet0[i].Blurred.DrawColor.G=200;
			OptionSet0[i].Blurred.DrawColor.B=255;
		}
		else
		{
			OptionSet0[i].Blurred.Text = "???";
			OptionSet0[i].Focused.Text = "???";
			
			OptionSet0[i].Blurred.DrawColor.R=255;
			OptionSet0[i].Blurred.DrawColor.G=255;
			OptionSet0[i].Blurred.DrawColor.B=0;			
		}
		
		OptionSet0[i].ContextID = i;				
	}
}


simulated function RefreshSet1()
{
	local int i;
	local int j;
	local array<int> keys;
	
	for ( i = 0; i < NUM_SET1_OPTIONS; ++i )
	{
		keys.Length = 0;	
		
		if ( GetPlayerOwner().GetAllButtonMappings( OptionSet1Funcs[i], keys ) )
		{
			for ( j = 0; j < keys.Length; ++j )
			{
				if ( j == 0 )
				{
					if ( keys[j] == GAME_LSTICK )
					{
						OptionSet1[i].Blurred.Text = ClickLeftStickText;
						OptionSet1[i].Focused.Text = ClickLeftStickText;
					}
					else if ( keys[j] == GAME_RSTICK )
					{
						OptionSet1[i].Blurred.Text = ClickRightStickText;
						OptionSet1[i].Focused.Text = ClickRightStickText;
					}
					else if ( ( keys[j] == GAME_JOYX ) || 
							  ( keys[j] == GAME_JOYY ) )
					{
						OptionSet1[i].Blurred.Text = LeftStickText;
						OptionSet1[i].Focused.Text = LeftStickText;
					}
					else if ( ( keys[j] == GAME_JOYU ) || 
							  ( keys[j] == GAME_JOYV ) )
					{
						OptionSet1[i].Blurred.Text = RightStickText;
						OptionSet1[i].Focused.Text = RightStickText;
					}
					else
					{
						OptionSet1[i].Blurred.Text = RetrieveLocalizedKeyName(keys[j]);
						OptionSet1[i].Focused.Text = RetrieveLocalizedKeyName(keys[j]);
					}
				}
				else
				{
					if ( keys[j] == GAME_LSTICK )
					{
						OptionSet1[i].Blurred.Text = OptionSet1[i].Blurred.Text $ ", " $ ClickLeftStickText;
						OptionSet1[i].Focused.Text = OptionSet1[i].Focused.Text $ ", " $ ClickLeftStickText;
					}
					else if ( keys[j] == GAME_RSTICK )
					{
						OptionSet1[i].Blurred.Text = OptionSet1[i].Blurred.Text $ ", " $ ClickRightStickText;
						OptionSet1[i].Focused.Text = OptionSet1[i].Focused.Text $ ", " $ ClickRightStickText;
					}
					else if ( ( keys[j] == GAME_JOYX ) || 
							  ( keys[j] == GAME_JOYY ) )
					{
						OptionSet1[i].Blurred.Text = OptionSet0[i].Blurred.Text $ ", " $ LeftStickText;
						OptionSet1[i].Focused.Text = OptionSet0[i].Focused.Text $ ", " $ LeftStickText;
					}
					else if ( ( keys[j] == GAME_JOYU ) || 
							  ( keys[j] == GAME_JOYV ) )
					{
						OptionSet1[i].Blurred.Text = OptionSet0[i].Blurred.Text $ ", " $ RightStickText;
						OptionSet1[i].Focused.Text = OptionSet0[i].Focused.Text $ ", " $ RightStickText;
					}
					else
					{
						OptionSet1[i].Blurred.Text = OptionSet1[i].Blurred.Text$", "$RetrieveLocalizedKeyName(keys[j]);
						OptionSet1[i].Focused.Text = OptionSet1[i].Focused.Text$", "$RetrieveLocalizedKeyName(keys[j]);
					}					
				}				
			}

			OptionSet1[i].Blurred.DrawColor.R=120;
			OptionSet1[i].Blurred.DrawColor.G=200;
			OptionSet1[i].Blurred.DrawColor.B=255;			
			
			if ( OptionSet1[i].bDisabled == 1 )
			{
				OptionSet1[i].BackgroundBlurred.DrawColor.A=0;
			}			
		}
		else
		{
			OptionSet1[i].Blurred.Text = "???";
			OptionSet1[i].Focused.Text = "???";
			
			OptionSet1[i].Blurred.DrawColor.R=255;
			OptionSet1[i].Blurred.DrawColor.G=255;
			OptionSet1[i].Blurred.DrawColor.B=0;			
			
			if ( OptionSet1[i].bDisabled == 1 )
			{
				OptionSet1[i].BackgroundBlurred.DrawColor.A=0;
			}						
		}
		
		OptionSet1[i].ContextID = i;				
	}
}

simulated function PrevSetSelected()
{
	GetPlayerOwner().PlaySound(SoundOnSelect);
	SwitchToSet( WhichSet  - 1 );
}

simulated function NextSetSelected()
{
	GetPlayerOwner().PlaySound(SoundOnSelect);
	SwitchtoSet( WhichSet + 1 );
}

simulated function SwitchToSet( int NewSet )
{
	local int i;
	
	if ( WhichSet == NewSet || NewSet < 0 || NewSet > 1 )
		return;
	
	// Hide all sets	
	for ( i = 0; i < NUM_SET0_OPTIONS; ++i )
	{
		OptionSet0Labels[i].bHidden = 1;
		OptionSet0[i].bHidden = 1;
	}
	
	for ( i = 0; i < NUM_SET1_OPTIONS; ++i )
	{
		OptionSet1Labels[i].bHidden = 1;
		OptionSet1[i].bHidden = 1;
	}
	
	WhichSet = NewSet;
	
	// Show the new set
	if ( WhichSet == 0 )
	{
		for ( i = 0; i < NUM_SET0_OPTIONS; ++i )
		{
			OptionSet0Labels[i].bHidden = 0;
			OptionSet0[i].bHidden = 0;
		}
		
		RefreshSet0();
		
		PrevSet.bHidden = 1;
		NextSet.bHidden = 0;
		
		FocusOnWidget( NextSet );
	}
	else if ( WhichSet == 1 )
	{
		for ( i = 0; i < NUM_SET1_OPTIONS; ++i )
		{
			OptionSet1Labels[i].bHidden = 0;
			OptionSet1[i].bHidden = 0;
		}
		
		RefreshSet1();

		PrevSet.bHidden = 0;
		NextSet.bHidden = 1;
		
		FocusOnWidget( PrevSet );		
	}
}

simulated function ActionSelected( int ContextID )
{
	local string Action;
	local string Button;
	local string Func;
	local string args;
	
	if ( bRemapping )
		return;
	
	if ( WhichSet == 0 )
	{
		Action = OptionSet0Labels[ContextID].Text;
		Button = OptionSet0[ContextID].Focused.Text;
		Func = OptionSet0Funcs[ContextID];
	}
	else if ( WhichSet == 1 )
	{
		Action = OptionSet1Labels[ContextID].Text;
		Button = OptionSet1[ContextID].Focused.Text;
		Func = OptionSet1Funcs[ContextID];
	}
	
	args = "\"" $ Action $ "\"" $ "\"" $ Button $ "\"" $ "\"" $ Func $ "\"" $ "\"DISALLOWXBOXSPECIAL\"";
	bRemapping = True;
	OverlayMenuClass("XInterfaceCTMenus.CTMapKeyMenu", args);
}

simulated function bool MenuClosed( Menu closingMenu )
{
    local CTMapKeyMenu mapKeyMenu;
    local String newKeyName;

    mapKeyMenu = CTMapKeyMenu( closingMenu );
    if( mapKeyMenu != None )
    {
        if( !mapKeyMenu.Canceled )
        {
			GetPlayerOwner().ChangeKeyBinding( mapKeyMenu.NewKey, mapKeyMenu.Func, True );
			
			if ( mapKeyMenu.Func == "Use | onrelease StopUse" )
			{
				newKeyName = GetINIButtonName( mapKeyMenu.NewKey );

				GetPlayerOwner().ChangeKeyBinding( GAME_DUP, "OnDown " $ newKeyName $ " SquadEngage | OnUp " $ newKeyName $ " SwitchWeapon 1", True );
				GetPlayerOwner().ChangeKeyBinding( GAME_DDOWN, "OnDoubleTap SwitchWeapon 4 | OnDown " $ newKeyName $ " CancelAllMarkers | OnUp " $ newKeyName $ " SwitchWeapon 5", True );
				GetPlayerOwner().ChangeKeyBinding( GAME_DLEFT, "OnDown " $ newKeyName $ " SetStanceOffensive | OnUp " $ newKeyName $ " SwitchWeapon 3", True );
				GetPlayerOwner().ChangeKeyBinding( GAME_DRIGHT, "OnDown " $ newKeyName $ " SetStanceDefensive | OnUp " $ newKeyName $ " SwitchWeapon 2", True );				
			}
			
			RefreshSet0();
			RefreshSet1();
			
			CallMenuClass( "XInterfaceCTMenus.CTSavingSettingsMenu", "" );
        }
        
        bRemapping = False;
        
        return true;
    }

    return false;
}

simulated function OnXButton()
{
	if ( bRemapping )
		return;
	
	RestoreDefaults();
}

simulated function HandleInputBack()
{
	if ( bRemapping )
		return;

	Super.HandleInputBack();
}


defaultproperties
{
     Label=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="CONTROLS OPTIONS",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.108333,ScaleX=1.75,ScaleY=1.75,Style="LabelText")
     OptionSet0Labels(0)=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="MOVE",DrawPivot=DP_MiddleMiddle,PosX=0.2875,PosY=0.258333,ScaleX=1,ScaleY=1,Pass=2,Style="LabelText")
     OptionSet0Labels(1)=(Text="LOOK",PosY=0.31666)
     OptionSet0Labels(2)=(Text="RELOAD")
     OptionSet0Labels(3)=(Text="JUMP")
     OptionSet0Labels(4)=(Text="USE")
     OptionSet0Labels(5)=(Text="MELEE")
     OptionSet0Labels(6)=(Text="CYCLE DETONATORS")
     OptionSet0Labels(7)=(Text="CYCLE VISOR MODE")
     OptionSet0Labels(8)=(Text="FIRE")
     OptionSet0(0)=(Blurred=(PosX=0.7125,PosY=0.258333,ScaleX=0.8),BackgroundBlurred=(PosX=0.7125,PosY=0.258333,ScaleX=0.37,ScaleY=0.04333),OnSelect="ActionSelected",Pass=2,Style="ButtonTextStyle1")
     OptionSet0(1)=(Blurred=(PosY=0.31666),BackgroundBlurred=(PosY=0.31666))
     OptionSet0Funcs(0)="Axis aForward Speed=32768"
     OptionSet0Funcs(1)="Axis aMouseY Speed=600"
     OptionSet0Funcs(2)="ForceReload"
     OptionSet0Funcs(3)="Jump"
     OptionSet0Funcs(4)="Use | onrelease StopUse"
     OptionSet0Funcs(5)="AltFire"
     OptionSet0Funcs(6)="SwitchGrenade 6"
     OptionSet0Funcs(7)="ToggleHeadlamp"
     OptionSet0Funcs(8)="Fire | onrelease StopFire"
     OptionSet1Labels(0)=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="THROW DETONATOR",DrawPivot=DP_MiddleMiddle,PosX=0.2875,PosY=0.258333,ScaleX=1,ScaleY=1,Pass=2,Style="LabelText")
     OptionSet1Labels(1)=(Text="ZOOM",PosY=0.31666)
     OptionSet1Labels(2)=(Text="CROUCH")
     OptionSet1Labels(3)=(Text="MP SCORES")
     OptionSet1Labels(4)=(Text="PAUSE")
     OptionSet1(0)=(Blurred=(PosX=0.7125,PosY=0.258333,ScaleX=0.8),BackgroundBlurred=(PosX=0.7125,PosY=0.258333,ScaleX=0.37,ScaleY=0.04333),OnSelect="ActionSelected",Pass=2,Style="ButtonTextStyle1")
     OptionSet1(1)=(Blurred=(PosY=0.31666),BackgroundBlurred=(PosY=0.31666))
     OptionSet1(3)=(bDisabled=1)
     OptionSet1(4)=(bDisabled=1)
     OptionSet1Funcs(0)="ThrowGrenade"
     OptionSet1Funcs(1)="fov 0"
     OptionSet1Funcs(2)="Duck"
     OptionSet1Funcs(3)="MPScores"
     OptionSet1Funcs(4)="onrelease ShowMenu"
     PrevSet=(Blurred=(Text="PREVIOUS SET",DrawPivot=DP_MiddleMiddle,PosX=0.333,PosY=0.8),BackgroundBlurred=(DrawPivot=DP_MiddleMiddle,PosX=0.333,PosY=0.8,ScaleX=0.245,ScaleY=0.04333),OnSelect="PrevSetSelected",Style="ButtonTextStyle1")
     NextSet=(Blurred=(Text="NEXT SET",DrawPivot=DP_MiddleMiddle,PosX=0.666,PosY=0.8),BackgroundBlurred=(DrawPivot=DP_MiddleMiddle,PosX=0.666,PosY=0.8,ScaleX=0.245,ScaleY=0.04333),OnSelect="NextSetSelected",Style="ButtonTextStyle1")
     WhichSet=-1
     ClickRightStickText="CLICK RIGHT THUMBSTICK"
     ClickLeftStickText="CLICK LEFT THUMBSTICK"
     RightStickText="RIGHT THUMBSTICK"
     LeftStickText="LEFT THUMBSTICK"
     IniButtonNames(0)="GameA"
     IniButtonNames(1)="GameB"
     IniButtonNames(2)="GameX"
     IniButtonNames(3)="GameY"
     IniButtonNames(4)="GameBlack"
     IniButtonNames(5)="GameWhite"
     IniButtonNames(6)="GameLTrig"
     IniButtonNames(7)="GameRTrig"
     IniButtonNames(8)="GameDUp"
     IniButtonNames(9)="GameDDown"
     IniButtonNames(10)="GameDLeft"
     IniButtonNames(11)="GameDRight"
     IniButtonNames(12)="GameStart"
     IniButtonNames(13)="GameBack"
     IniButtonNames(14)="GameLStick"
     IniButtonNames(15)="GameRStick"
     XLabel=(Text=": RESTORE DEFAULTS")
     XButton=(Blurred=(Text="RESTORE DEFAULTS"))
     Background=(bHidden=1)
}

