class CTControlsOptionsPCMenu extends MenuTemplateTitled;

var() MenuText			Label;

var() MenuSprite		OptionsBorder;
var() MenuSprite		OptionsDescBorder;

var() MenuText			OptionDesc;

const NUM_SET0_OPTIONS = 14;

var() MenuText			OptionSet0Labels[NUM_SET0_OPTIONS];
var() MenuButtonText	OptionSet0[NUM_SET0_OPTIONS];
var() string			OptionSet0Funcs[NUM_SET0_OPTIONS];

const NUM_SET1_OPTIONS = 14;

var() MenuText			OptionSet1Labels[NUM_SET1_OPTIONS];
var() MenuButtonText	OptionSet1[NUM_SET1_OPTIONS];
var() string			OptionSet1Funcs[NUM_SET1_OPTIONS];

const NUM_SET2_OPTIONS = 6;

var() MenuText			OptionSet2Labels[NUM_SET2_OPTIONS];
var() MenuButtonText	OptionSet2[NUM_SET2_OPTIONS];
var() string			OptionSet2Funcs[NUM_SET2_OPTIONS];

var() MenuText			ControlsLabel;
var() MenuSprite		ControlsLabelBackground;
var() MenuSprite		ControlsLabelConnector;

var() MenuButtonText	Game;
var() MenuButtonText	Sound;
var() MenuButtonText	Graphics;
//var() MenuButtonText	Multiplayer;

var() MenuButtonText	RestoreToDefault;
var() MenuSprite		DefaultConnector;
var() MenuSprite		DefaultLine;

var() MenuButtonText	Done;

var() MenuButtonText	PrevSet;
var() MenuButtonText	NextSet;

var() int				WhichSet;

var() bool				bRemapping;

simulated function Init( string Args )
{
	Super.Init( Args );
	
	if ( Caps(GetPlayerOwner().GetLanguage()) == "EST" ||
		 Caps(GetPlayerOwner().GetLanguage()) == "DET" )
	{
		Label.ScaleX = 1.5;
	}

	SwitchToSet(0);
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
					OptionSet0[i].Blurred.Text = RetrieveLocalizedKeyName(keys[j]);
					OptionSet0[i].Focused.Text = RetrieveLocalizedKeyName(keys[j]);
				}
				else
				{
					OptionSet0[i].Blurred.Text = OptionSet0[i].Blurred.Text$", "$RetrieveLocalizedKeyName(keys[j]);
					OptionSet0[i].Focused.Text = OptionSet0[i].Focused.Text$", "$RetrieveLocalizedKeyName(keys[j]);					
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
			OptionSet0[i].Blurred.DrawColor.G=0;
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
					OptionSet1[i].Blurred.Text = RetrieveLocalizedKeyName(keys[j]);
					OptionSet1[i].Focused.Text = RetrieveLocalizedKeyName(keys[j]);
				}
				else
				{
					OptionSet1[i].Blurred.Text = OptionSet1[i].Blurred.Text$", "$RetrieveLocalizedKeyName(keys[j]);
					OptionSet1[i].Focused.Text = OptionSet1[i].Focused.Text$", "$RetrieveLocalizedKeyName(keys[j]);					
				}
			}
			
			OptionSet1[i].Blurred.DrawColor.R=120;
			OptionSet1[i].Blurred.DrawColor.G=200;
			OptionSet1[i].Blurred.DrawColor.B=255;			
		}
		else
		{
			OptionSet1[i].Blurred.Text = "???";
			OptionSet1[i].Focused.Text = "???";
			
			OptionSet1[i].Blurred.DrawColor.R=255;
			OptionSet1[i].Blurred.DrawColor.G=0;
			OptionSet1[i].Blurred.DrawColor.B=0;			
		}
		
		OptionSet1[i].ContextID = i;				
	}
}

simulated function RefreshSet2()
{
	local int i;
	local int j;
	local array<int> keys;
	
	for ( i = 0; i < NUM_SET2_OPTIONS; ++i )
	{
		keys.Length = 0;
		
		if ( GetPlayerOwner().GetAllButtonMappings( OptionSet2Funcs[i], keys ) )
		{
			for ( j = 0; j < keys.Length; ++j )
			{
				if ( j == 0 )
				{
					OptionSet2[i].Blurred.Text = RetrieveLocalizedKeyName(keys[j]);
					OptionSet2[i].Focused.Text = RetrieveLocalizedKeyName(keys[j]);
				}
				else
				{
					OptionSet2[i].Blurred.Text = OptionSet2[i].Blurred.Text$", "$RetrieveLocalizedKeyName(keys[j]);
					OptionSet2[i].Focused.Text = OptionSet2[i].Focused.Text$", "$RetrieveLocalizedKeyName(keys[j]);					
				}
			}

			OptionSet2[i].Blurred.DrawColor.R=120;
			OptionSet2[i].Blurred.DrawColor.G=200;
			OptionSet2[i].Blurred.DrawColor.B=255;			
		}
		else
		{
			OptionSet2[i].Blurred.Text = "???";
			OptionSet2[i].Focused.Text = "???";
			
			OptionSet2[i].Blurred.DrawColor.R=255;
			OptionSet2[i].Blurred.DrawColor.G=0;
			OptionSet2[i].Blurred.DrawColor.B=0;			
		}
		
		OptionSet2[i].ContextID = i;		
	}
}

simulated function GameSelected()
{
	if ( bRemapping )
		return;

	GotoMenuClass("XInterfaceCTMenus.CTGameOptionsPCMenu");
}

simulated function SoundSelected()
{
	if ( bRemapping )
		return;

	GotoMenuClass("XInterfaceCTMenus.CTSoundOptionsPCMenu");
}

simulated function GraphicsSelected()
{
	if ( bRemapping )
		return;

	GotoMenuClass("XInterfaceCTMenus.CTGraphicsOptionsPCMenu");
}

/*simulated function MultiplayerSelected()
{
	GotoMenuClass("XInterfaceCTMenus.CTMultiplayerOptionsPCMenu");
}*/

simulated function RestoreToDefaultSelected()
{
	if ( bRemapping )
		return;

	GetPlayerOwner().ConsoleCommand("UseControllerConfig DefaultCtrl.ini");
	GetPlayerOwner().SavePlayerInputConfig();
	GetPlayerOwner().SaveInputConfig();

	RefreshSet0();
	RefreshSet1();	
	RefreshSet2();	
}

simulated function DoneSelected()
{
	if ( bRemapping )
		return;

	CloseMenu();
}

simulated function PrevSetSelected()
{
	if ( bRemapping )
		return;

	GetPlayerOwner().PlaySound(SoundOnSelect);
	
	SwitchToSet( WhichSet  - 1 );
}

simulated function NextSetSelected()
{
	if ( bRemapping )
		return;

	GetPlayerOwner().PlaySound(SoundOnSelect);

	SwitchtoSet( WhichSet + 1 );
}

simulated function SwitchToSet( int NewSet )
{
	local int i;
	
	if ( WhichSet == NewSet || NewSet < 0 || NewSet > 2 )
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
	
	for ( i = 0; i < NUM_SET2_OPTIONS; ++i )
	{
		OptionSet2Labels[i].bHidden = 1;
		OptionSet2[i].bHidden = 1;
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
		NextSet.bHidden = 0;
	}
	else if ( WhichSet == 2 )
	{
		for ( i = 0; i < NUM_SET2_OPTIONS; ++i )
		{
			OptionSet2Labels[i].bHidden = 0;
			OptionSet2[i].bHidden = 0;
		}

		RefreshSet2();
		
		PrevSet.bHidden = 0;
		NextSet.bHidden = 1;		
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
	else if ( WhichSet == 2 )
	{
		Action = OptionSet2Labels[ContextID].Text;
		Button = OptionSet2[ContextID].Focused.Text;
		Func = OptionSet2Funcs[ContextID];
	}
	
	args = "\"" $ Action $ "\"" $ "\"" $ Button $ "\"" $ "\"" $ Func $ "\"" $ "\"DISALLOWPCSPECIAL\"";
	log(args);
	bRemapping = True;
	OverlayMenuClass("XInterfaceCTMenus.CTMapKeyMenu", args);
}

simulated function bool MenuClosed( Menu closingMenu )
{
	local array<int> keys;
    local CTMapKeyMenu mapKeyMenu;
    local bool bErasePreviousMappings;

    mapKeyMenu = CTMapKeyMenu( closingMenu );
    if( mapKeyMenu != None )
    {
        if( !mapKeyMenu.Canceled )
        {
			GetPlayerOwner().GetAllButtonMappings( mapKeyMenu.Func, keys );
			if ( keys.Length > 1 )
				bErasePreviousMappings = True;
			else
				bErasePreviousMappings = False;
			
			GetPlayerOwner().ChangeKeyBinding( mapKeyMenu.NewKey, mapKeyMenu.Func, bErasePreviousMappings );
			
			RefreshSet0();
			RefreshSet1();
			RefreshSet2();
        }
        
        bRemapping = False;
        
        return true;
    }

    return false;
}

simulated function HandleInputBack()
{
	if ( bRemapping )
		return;

	Super.HandleInputBack();
}


defaultproperties
{
     Label=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="OPTIONS",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.078333,ScaleX=1.75,ScaleY=1.75,Style="LabelText")
     OptionsBorder=(PosX=0.63125,PosY=0.405,ScaleX=0.65,ScaleY=0.68666,Style="BorderStyle1")
     OptionsDescBorder=(PosX=0.63125,PosY=0.858333,ScaleX=0.65,ScaleY=0.1666,Style="BorderStyle1")
     OptionSet0Labels(0)=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="MOVE FORWARD",DrawPivot=DP_MiddleLeft,PosX=0.34,PosY=0.12,ScaleX=0.6,ScaleY=0.6,Pass=2,Style="LabelText")
     OptionSet0Labels(1)=(Text="MOVE BACKWARD",PosY=0.16)
     OptionSet0Labels(2)=(Text="TURN LEFT")
     OptionSet0Labels(3)=(Text="Turn RIGHT")
     OptionSet0Labels(4)=(Text="STRAFE LEFT")
     OptionSet0Labels(5)=(Text="STRAFE RIGHT")
     OptionSet0Labels(6)=(Text="WALK")
     OptionSet0Labels(7)=(Text="JUMP")
     OptionSet0Labels(8)=(Text="CROUCH")
     OptionSet0Labels(9)=(Text="USE/ACTIVATE/PICKUP")
     OptionSet0Labels(10)=(Text="FIRE")
     OptionSet0Labels(11)=(Text="THROW DETONATOR")
     OptionSet0Labels(12)=(Text="ZOOM")
     OptionSet0Labels(13)=(Text="CYCLE VISOR MODE")
     OptionSet0(0)=(Blurred=(PosX=0.77375,PosY=0.12,ScaleX=0.6,ScaleY=0.6),BackgroundBlurred=(PosX=0.77375,PosY=0.12,ScaleX=0.26,ScaleY=0.02666),OnSelect="ActionSelected",Pass=2,Style="ButtonTextStyle1")
     OptionSet0(1)=(Blurred=(PosY=0.16),BackgroundBlurred=(PosY=0.16))
     OptionSet0Funcs(0)="MoveForward"
     OptionSet0Funcs(1)="MoveBackward"
     OptionSet0Funcs(2)="TurnLeft"
     OptionSet0Funcs(3)="TurnRight"
     OptionSet0Funcs(4)="StrafeLeft"
     OptionSet0Funcs(5)="StrafeRight"
     OptionSet0Funcs(6)="Walking"
     OptionSet0Funcs(7)="Jump"
     OptionSet0Funcs(8)="Duck"
     OptionSet0Funcs(9)="Use | onrelease StopUse"
     OptionSet0Funcs(10)="Fire | onrelease StopFire"
     OptionSet0Funcs(11)="ThrowGrenade"
     OptionSet0Funcs(12)="fov 0"
     OptionSet0Funcs(13)="ToggleHeadlamp"
     OptionSet1Labels(0)=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="SCREEN SHOT",DrawPivot=DP_MiddleLeft,PosX=0.34,PosY=0.12,ScaleX=0.6,ScaleY=0.6,Pass=2,Style="LabelText")
     OptionSet1Labels(1)=(Text="MELEE ATTACK",PosY=0.16)
     OptionSet1Labels(2)=(Text="RELOAD")
     OptionSet1Labels(3)=(Text="DC15s PISTOL")
     OptionSet1Labels(4)=(Text="DC17m BLASTER")
     OptionSet1Labels(5)=(Text="DC17m SNIPER")
     OptionSet1Labels(6)=(Text="DC17m ANTI-ARMOR")
     OptionSet1Labels(7)=(Text="SECONDARY WEAPONS")
     OptionSet1Labels(8)=(Text="CYCLE DETONATOR")
     OptionSet1Labels(9)=(Text="SEARCH AND DESTROY")
     OptionSet1Labels(10)=(Text="FORM UP")
     OptionSet1Labels(11)=(Text="SECURE POSITION")
     OptionSet1Labels(12)=(Text="RECALL")
     OptionSet1Labels(13)=(Text="SHOW SCORES")
     OptionSet1(0)=(Blurred=(PosX=0.77375,PosY=0.12,ScaleX=0.6,ScaleY=0.6),BackgroundBlurred=(PosX=0.77375,PosY=0.12,ScaleX=0.26,ScaleY=0.02666),OnSelect="ActionSelected",Pass=2,Style="ButtonTextStyle1")
     OptionSet1(1)=(Blurred=(PosY=0.16),BackgroundBlurred=(PosY=0.16))
     OptionSet1Funcs(0)="shot"
     OptionSet1Funcs(1)="AltFire"
     OptionSet1Funcs(2)="ForceReload"
     OptionSet1Funcs(3)="SwitchWeapon 4"
     OptionSet1Funcs(4)="SwitchWeapon 1"
     OptionSet1Funcs(5)="SwitchWeapon 2"
     OptionSet1Funcs(6)="SwitchWeapon 3"
     OptionSet1Funcs(7)="SwitchWeapon 5"
     OptionSet1Funcs(8)="SwitchGrenade 6"
     OptionSet1Funcs(9)="SetStanceOffensive	;Search & Destroy"
     OptionSet1Funcs(10)="SetStanceDefensive	;Form Up"
     OptionSet1Funcs(11)="SquadEngage		;Secure Position"
     OptionSet1Funcs(12)="CancelAllMarkers	;Recall"
     OptionSet1Funcs(13)="ShowGameStats"
     OptionSet2Labels(0)=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="SWITCH TEAM",DrawPivot=DP_MiddleLeft,PosX=0.34,PosY=0.12,ScaleX=0.6,ScaleY=0.6,Pass=2,Style="LabelText")
     OptionSet2Labels(1)=(Text="QUICK LOAD",PosY=0.16)
     OptionSet2Labels(2)=(Text="QUICK SAVE")
     OptionSet2Labels(3)=(Text="CHAT")
     OptionSet2Labels(4)=(Text="TEAM CHAT")
     OptionSet2Labels(5)=(Text="SPEECH MENU")
     OptionSet2(0)=(Blurred=(PosX=0.77375,PosY=0.12,ScaleX=0.6,ScaleY=0.6),BackgroundBlurred=(PosX=0.77375,PosY=0.12,ScaleX=0.26,ScaleY=0.02666),OnSelect="ActionSelected",Pass=2,Style="ButtonTextStyle1")
     OptionSet2(1)=(Blurred=(PosY=0.16),BackgroundBlurred=(PosY=0.16))
     OptionSet2Funcs(0)="SwitchTeam"
     OptionSet2Funcs(1)="QuickLoad"
     OptionSet2Funcs(2)="QuickSave"
     OptionSet2Funcs(3)="Talk"
     OptionSet2Funcs(4)="TeamTalk"
     OptionSet2Funcs(5)="SpeechMenuToggle"
     ControlsLabel=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="CONTROLS",DrawColor=(A=255),DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.35,ScaleX=1,ScaleY=0.8,Pass=2)
     ControlsLabelBackground=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.35,ScaleX=0.245,ScaleY=0.04333,ScaleMode=MSCM_FitStretch,Pass=1)
     ControlsLabelConnector=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleLeft,PosX=0.295,PosY=0.35,ScaleX=0.005,ScaleY=0.04333,ScaleMode=MSCM_FitStretch)
     Game=(Blurred=(Text="GAME",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.2),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.2,ScaleX=0.245,ScaleY=0.04333),OnSelect="GameSelected",Style="ButtonTextStyle1")
     Sound=(Blurred=(Text="SOUND",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.25),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.25,ScaleX=0.245,ScaleY=0.04333),OnSelect="SoundSelected",Style="ButtonTextStyle1")
     Graphics=(Blurred=(Text="GRAPHICS",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.3),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.3,ScaleX=0.245,ScaleY=0.04333),OnSelect="GraphicsSelected",Style="ButtonTextStyle1")
     RestoreToDefault=(Blurred=(Text="RESTORE DEFAULTS",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.658333,ScaleX=0.6,ScaleY=0.6),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.658333,ScaleX=0.245,ScaleY=0.04333,ScaleMode=MSCM_FitStretch),OnSelect="RestoreToDefaultSelected",Style="ButtonTextStyle1")
     DefaultConnector=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleLeft,PosX=0.295,PosY=0.688333,ScaleX=0.005,ScaleY=0.02,ScaleMode=MSCM_FitStretch)
     DefaultLine=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.688333,ScaleX=0.245,ScaleY=0.02,ScaleMode=MSCM_FitStretch)
     Done=(Blurred=(Text="DONE",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.921666),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.921666,ScaleX=0.245,ScaleY=0.04333),OnSelect="DoneSelected",Style="ButtonTextStyle1")
     PrevSet=(Blurred=(Text="PREVIOUS SET",DrawPivot=DP_MiddleMiddle,PosX=0.4775,PosY=0.70333),BackgroundBlurred=(DrawPivot=DP_MiddleMiddle,PosX=0.4775,PosY=0.70333,ScaleX=0.245,ScaleY=0.04333),OnSelect="PrevSetSelected",Style="ButtonTextStyle1")
     NextSet=(Blurred=(Text="NEXT SET",DrawPivot=DP_MiddleMiddle,PosX=0.77375,PosY=0.70333),BackgroundBlurred=(DrawPivot=DP_MiddleMiddle,PosX=0.77375,PosY=0.70333,ScaleX=0.245,ScaleY=0.04333),OnSelect="NextSetSelected",Style="ButtonTextStyle1")
     WhichSet=-1
     Background=(bHidden=1)
}

