class CTGameOptionsXboxMenu extends MenuTemplateTitledBXA;

var() MenuText			Label;

const NUM_OPTIONS = 7;

var() MenuText			OptionLabels[NUM_OPTIONS];
var() MenuButtonEnum	Options[NUM_OPTIONS];
var() MenuButtonSprite  OptionLeftArrows[NUM_OPTIONS];
var() MenuButtonSprite	OptionRightArrows[NUM_OPTIONS];

var() int				OptionDefaults[NUM_OPTIONS];

var() int				PreviousSettings[NUM_OPTIONS];

var() localized String	ApplySettingsConfirm;

var() bool				bInMultiplayer;

simulated function Init( string Args )
{
	Super.Init( Args );

	bInMultiplayer = Level.NetMode != NM_StandAlone;
	
	Refresh();
	
	HideAButton( 1 );
}
	
simulated function DisableOption( int i )
{
	Options[i].bDisabled = 1;
	Options[i].Blurred.DrawColor.R = 128;
	Options[i].Blurred.DrawColor.G = 128;
	Options[i].Blurred.DrawColor.B = 128;
	Options[i].BackgroundBlurred.DrawColor.R = 128;
	Options[i].BackgroundBlurred.DrawColor.G = 128;
	Options[i].BackgroundBlurred.DrawColor.B = 128;
	
	OptionLabels[i].DrawColor.R = 128;
	OptionLabels[i].DrawColor.G = 128;
	OptionLabels[i].DrawColor.B = 128;

	OptionLeftArrows[i].bDisabled = 1;	
	OptionLeftArrows[i].Blurred.DrawColor.R = 128;
	OptionLeftArrows[i].Blurred.DrawColor.G = 128;
	OptionLeftArrows[i].Blurred.DrawColor.B = 128;
	
	OptionRightArrows[i].bDisabled = 1;
	OptionRightArrows[i].Blurred.DrawColor.R = 128;
	OptionRightArrows[i].Blurred.DrawColor.G = 128;
	OptionRightArrows[i].Blurred.DrawColor.B = 128;
}

simulated function int SensitivityToScale( float Sensitivity )
{
	if ( Sensitivity == 0.3 )
		return 1;
	else if ( Sensitivity == 0.6 )
		return 2;
	else if ( Sensitivity == 1.0 )
		return 3;
	else if ( Sensitivity == 1.5 )
		return 4;
	else if ( Sensitivity == 2.0 )
		return 5;
	else if ( Sensitivity == 2.5 )
		return 6;
	else if ( Sensitivity == 3.0 )
		return 7;
	else if ( Sensitivity == 3.5 )
		return 8;
	else if ( Sensitivity == 4.0 )
		return 9;
	else if ( Sensitivity == 4.5 )
		return 10;
		
	return 3;
}

simulated function float ScaleToSensitivity( int Scale )
{
	if ( Scale == 1 )
		return 0.3;
	else if ( Scale == 2 )
		return 0.6;
	else if ( Scale == 3 )
		return 1.0;
	else if ( Scale == 4 )
		return 1.5;
	else if ( Scale == 5 )
		return 2.0;
	else if ( Scale == 6 )
		return 2.5;
	else if ( Scale == 7 )
		return 3.0;
	else if ( Scale == 8 )
		return 3.5;
	else if ( Scale == 9 )
		return 4.0;
	else if ( Scale == 10 )
		return 4.5;

	return 1.0;
}
	
simulated function Refresh()
{
	local float s1;
	local float s2;
	local int i;

	if ( GetPlayerOwner().GetInvertLook() )
		Options[0].Current = 0;
	else
		Options[0].Current = 1;
		
	GetPlayerOwner().GetJoySensitivity(s1, s2);
	Options[1].Current = SensitivityToScale( s2 ) - 1;

	if ( GetPlayerOwner().myHUD.bShowSubtitles )
		Options[2].Current = 0;
	else
		Options[2].Current = 1;

	if ( GetPlayerOwner().GetRumble() )
		Options[3].Current = 0;
	else
		Options[3].Current = 1;		
			
	if ( GetPlayerOwner().AimingHelp != 0 )
		Options[4].Current = 0;
	else
		Options[4].Current = 1;		

	if(GetPlayerOwner().GetDifficultyLevel() != -1)
		Options[5].Current = GetPlayerOwner().GetDifficultyLevel();		
	else
		Options[5].Current = 1;		
	
	if ( GetPlayerOwner().bAutoPullManeuvers )
		Options[6].Current = 0;
	else
		Options[6].Current = 1;	

	if ( bInMultiplayer )
	{
		DisableOption( 2 );	
		if ( int(ConsoleCommand("NUMVIEWPORTS")) > 1 )
			DisableOption( 3 );			
		DisableOption( 4 );	
		DisableOption( 5 );	
		DisableOption( 6 );	
	}
			
	for ( i = 0; i < NUM_OPTIONS; ++i )
	{
		PreviousSettings[i] = Options[i].Current;
	}
}

simulated function RestoreDefaults()
{
	local int i;
	
	for ( i = 0; i < NUM_OPTIONS; ++i )
	{
		Options[i].Current = OptionDefaults[i];
		ChangeOption(i, 0);
	}
}

simulated function ChangeOption( int i, int Delta )
{
    local int NewItem;

	NewItem = Options[i].Current + Delta;

	if( NewItem >= Options[i].Items.Length )
	{
		if( Options[i].bNoWrap == 0 )
			NewItem = 0;
		else
			NewItem = Options[i].Items.Length - 1;
	}
	else if( NewItem < 0 )
	{
		if( Options[i].bNoWrap == 0 )
			NewItem = Options[i].Items.Length - 1;
		else
			NewItem = 0;
	}

	Options[i].Current = NewItem;
	
	if ( ChangedOptions() )
		HideAButton( 0 );
	else
		HideAButton( 1 );
}

simulated function OnLeft()
{
    local int i;

    for( i = 0; i < NUM_OPTIONS; i++)
    {
        if( ( Options[i].bHasFocus != 0 ) || 
			( OptionLeftArrows[i].bHasFocus != 0 ) || 
			( OptionRightArrows[i].bHasFocus != 0 ) )
        {
			ChangeOption( i, -1 );
			return;
        }
    }
    log( "Got spurious OnLeft()", 'Error' );
}

simulated function OnRight()
{
    local int i;

    for( i = 0; i < NUM_OPTIONS; i++)
    {
        if( ( Options[i].bHasFocus != 0 ) || 
			( OptionLeftArrows[i].bHasFocus != 0 ) || 
			( OptionRightArrows[i].bHasFocus != 0 ) )
        {
			ChangeOption( i, 1 );
			return;
        }
    }
    log( "Got spurious OnRight()", 'Error' );
}

simulated function bool ChangedOptions()
{
	local int i;
	
	for ( i = 0; i < NUM_OPTIONS; ++i )
	{
		if ( PreviousSettings[i] != Options[i].Current )
			return True;
	}
	
	return False;
}

simulated function Apply()
{
	local int i;
	local float newSensitivity;
	
	for ( i = 0; i < NUM_OPTIONS; ++i )
	{
		if ( Options[i].Current == PreviousSettings[i] )
			continue;
			
		PreviousSettings[i] = Options[i].Current;
		
		switch( i )
		{
			case 0:
				if ( Options[i].Current == 0 )
					GetPlayerOwner().SetInvertLook(True);
				else
					GetPlayerOwner().SetInvertLook(False);
					
				GetPlayerOwner().SavePlayerInputConfig();				
				
				break;
				
			case 1:
				newSensitivity = ScaleToSensitivity(Options[i].Current + 1);
				GetPlayerOwner().SetJoySensitivity( newSensitivity, newSensitivity );
				GetPlayerOwner().SavePlayerInputConfig();
				
				break;
				
			case 2:
				if ( Options[i].Current == 0 )
					GetPlayerOwner().myHUD.bShowSubtitles = True;
				else
					GetPlayerOwner().myHUD.bShowSubtitles = False;
					
				GetPlayerOwner().myHUD.SaveConfig();
					
				break;
	            
			case 3:
				if ( Options[i].Current == 0 )
					GetPlayerOwner().SetRumble( True );
				else
					GetPlayerOwner().SetRumble( False );
					
				GetPlayerOwner().SaveConfig();
				
				break;
				
			case 4:
				if ( Options[i].Current == 0 )
					GetPlayerOwner().AimingHelp = 5;
				else
					GetPlayerOwner().AimingHelp = 0;
					
				GetPlayerOwner().SaveConfig();
				
				break;
				
			case 5:
				GetPlayerOwner().SetDifficultyLevel( Options[i].Current );
				GetPlayerOwner().SaveConfig();
				
				break;
				
			case 6:
				if ( Options[i].Current == 0 )
					GetPlayerOwner().bAutoPullManeuvers = True;
				else
					GetPlayerOwner().bAutoPullManeuvers = False;
				GetPlayerOwner().SaveConfig();

				break;		
		}
	}
	
	GetPlayerOwner().PropagateSettings();
	
	HideAButton( 1 );
}

simulated function OnAButton()
{
	if ( AButtonIcon.bHidden != 1 )
	{
		Apply();
		CallMenuClass( "XInterfaceCTMenus.CTSavingSettingsMenu", "" );
	}
}

simulated function OnXButton()
{
	RestoreDefaults();
}

simulated function OnBButton()
{
	if ( ChangedOptions() )
	{
		OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(ApplySettingsConfirm) );		
	}
	else
	{
		CloseMenu();
	}
}

simulated function bool MenuClosed( Menu closingMenu )
{
    local MenuQuestionYesNo QuestionMenu;

    QuestionMenu = MenuQuestionYesNo( closingMenu );
    if( QuestionMenu != None )
    {
        if( QuestionMenu.bSelectedYes )
        {
			Apply();
			GotoMenuClass( "XInterfaceCTMenus.CTSavingSettingsMenu", "" );
        }
        else
        {
			Refresh();
			OnBButton();
        }
        
        return true;
    }

    return false;
}

simulated function bool HandleInputGamePad( String ButtonName )
{
    if( ButtonName ~= "A" )
    {
        OnAButton();
        return( true );
    }
    
	return( Super.HandleInputGamePad( ButtonName ) );
}

simulated function HandleInputBack()
{
	OnBButton();
}


defaultproperties
{
     Label=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="GAME OPTIONS",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.108333,ScaleX=1.75,ScaleY=1.75,Style="LabelText")
     OptionLabels(0)=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="INVERT Y AXIS",DrawPivot=DP_MiddleMiddle,PosX=0.2875,PosY=0.2,ScaleX=1,ScaleY=1,Pass=2,Style="LabelText")
     OptionLabels(1)=(Text="LOOK SENSITIVITY",PosY=0.258333)
     OptionLabels(2)=(Text="SUBTITLES")
     OptionLabels(3)=(Text="VIBRATION")
     OptionLabels(4)=(Text="AUTO AIM")
     OptionLabels(5)=(Text="DIFFICULTY")
     OptionLabels(6)=(Text="AUTO PULL MANEUVERS")
     Options(0)=(Items=("YES","NO"),Blurred=(PosX=0.7125,PosY=0.2),BackgroundBlurred=(PosX=0.7125,PosY=0.2,ScaleX=0.32,ScaleY=0.04333),OnLeft="OnLeft",OnRight="OnRight",Pass=2,Style="ButtonEnumStyle1")
     Options(1)=(Items=("1","2","3","4","5","6","7","8","9","10"),Blurred=(PosY=0.258333),BackgroundBlurred=(PosY=0.258333))
     Options(2)=(Items=("ON","OFF"))
     Options(3)=(Items=("ON","OFF"))
     Options(4)=(Items=("ON","OFF"))
     Options(5)=(Items=("EASY","MEDIUM","HARD"))
     Options(6)=(Items=("YES","NO"))
     OptionLeftArrows(0)=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowLeft',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.52875,PosY=0.2,ScaleX=0.75,ScaleY=0.75),Focused=(DrawColor=(B=255,G=255,R=255,A=255),ScaleX=0.9,ScaleY=0.9),bIgnoreController=1,OnSelect="OnLeft",Pass=2)
     OptionLeftArrows(1)=(Blurred=(PosX=0.52875,PosY=0.258333))
     OptionLeftArrows(2)=(Blurred=(PosX=0.52875))
     OptionLeftArrows(3)=(Blurred=(PosX=0.52875))
     OptionLeftArrows(4)=(Blurred=(PosX=0.52875))
     OptionLeftArrows(5)=(Blurred=(PosX=0.52875))
     OptionLeftArrows(6)=(Blurred=(PosX=0.52875))
     OptionRightArrows(0)=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowRight',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.8975,PosY=0.2,ScaleX=0.75,ScaleY=0.75),Focused=(DrawColor=(B=255,G=255,R=255,A=255),ScaleX=0.9,ScaleY=0.9),bIgnoreController=1,OnSelect="OnRight",Pass=2)
     OptionRightArrows(1)=(Blurred=(PosX=0.8975,PosY=0.258333))
     OptionRightArrows(2)=(Blurred=(PosX=0.8975))
     OptionRightArrows(3)=(Blurred=(PosX=0.8975))
     OptionRightArrows(4)=(Blurred=(PosX=0.8975))
     OptionRightArrows(5)=(Blurred=(PosX=0.8975))
     OptionRightArrows(6)=(Blurred=(PosX=0.8975))
     OptionDefaults(0)=1
     OptionDefaults(1)=2
     OptionDefaults(2)=1
     OptionDefaults(5)=1
     ApplySettingsConfirm="APPLY SETTINGS?"
     XLabel=(Text=": RESTORE DEFAULTS")
     XButton=(Blurred=(Text="RESTORE DEFAULTS"))
     ALabel=(Text="ACCEPT :")
     AButton=(Blurred=(Text="ACCEPT"))
     Background=(bHidden=1)
}

