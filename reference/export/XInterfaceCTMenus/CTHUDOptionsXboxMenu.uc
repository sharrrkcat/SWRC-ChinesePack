class CTHUDOptionsXboxMenu extends MenuTemplateTitledBXA;

var() MenuText			Label;

const NUM_OPTIONS = 4;

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
	
simulated function EnableOption( int i )
{
	Options[i].bDisabled = 0;
	Options[i].Blurred.DrawColor.R = ButtonEnumStyle1.Blurred.DrawColor.R;
	Options[i].Blurred.DrawColor.G = ButtonEnumStyle1.Blurred.DrawColor.G;
	Options[i].Blurred.DrawColor.B = ButtonEnumStyle1.Blurred.DrawColor.B;
	Options[i].BackgroundBlurred.DrawColor.R = ButtonEnumStyle1.BackgroundBlurred.DrawColor.R;
	Options[i].BackgroundBlurred.DrawColor.G = ButtonEnumStyle1.BackgroundBlurred.DrawColor.G;
	Options[i].BackgroundBlurred.DrawColor.B = ButtonEnumStyle1.BackgroundBlurred.DrawColor.B;
	
	OptionLabels[i].DrawColor.R = LabelText.DrawColor.R;
	OptionLabels[i].DrawColor.G = LabelText.DrawColor.G;
	OptionLabels[i].DrawColor.B = LabelText.DrawColor.B;

	OptionLeftArrows[i].bDisabled = 0;	
	OptionLeftArrows[i].Blurred.DrawColor.R = 255;
	OptionLeftArrows[i].Blurred.DrawColor.G = 255;
	OptionLeftArrows[i].Blurred.DrawColor.B = 255;
	
	OptionRightArrows[i].bDisabled = 0;
	OptionRightArrows[i].Blurred.DrawColor.R = 255;
	OptionRightArrows[i].Blurred.DrawColor.G = 255;
	OptionRightArrows[i].Blurred.DrawColor.B = 255;
}

simulated function Refresh()
{
	local int i;
	
	if ( GetPlayerOwner().bVisor )
		Options[0].Current = 0;
	else
		Options[0].Current = 1;

	if ( GetPlayerOwner().myHUD.bShowPromptText )
		Options[1].Current = 0;
	else
		Options[1].Current = 1;
		
	Options[2].Current = GetPlayerOwner().VisorModeDefault;

	if ( Options[2].Current == 1 )
		DisableOption( 3 );
	else
		EnableOption( 3 );

	Options[3].Current = int(GetPlayerOwner().TacticalModeIntensity * 10.0);
	
	if ( bInMultiplayer )
	{
		DisableOption( 0 );
		DisableOption( 1 );
		DisableOption( 2 );
		DisableOption( 3 );
		FocusOnNothing();
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

	if ( i == 2 )
	{
		if ( Options[i].Current == 1 )
			DisableOption( 3 );
		else
			EnableOption( 3 );
	}
		
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
	
	for ( i = 0; i < NUM_OPTIONS; ++i )
	{
		if ( Options[i].Current == PreviousSettings[i] )
			continue;
			
		PreviousSettings[i] = Options[i].Current;

		switch( i )
		{
			case 0:
				if ( Options[i].Current == 0 )
					GetPlayerOwner().bVisor = True;
				else
					GetPlayerOwner().bVisor = False;
					
				GetPlayerOwner().SaveConfig();				
				
				break;
				
			case 1:
				if ( Options[i].Current == 0 )
					GetPlayerOwner().myHUD.bShowPromptText = True;
				else
					GetPlayerOwner().myHUD.bShowPromptText = False;
					
				GetPlayerOwner().myHUD.SaveConfig();				
				
				break;	
				
			case 2:			
				GetPlayerOwner().SetVisorModeDefault( Options[i].Current );
				GetPlayerOwner().SaveConfig();
				break;
				
			case 3:
				GetPlayerOwner().TacticalModeIntensity = float(Options[i].Current) / 10.0;
				GetPlayerOwner().SaveConfig();
				GetPlayerOwner().PassOnTacticalIntensity();
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
     Label=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="HUD OPTIONS",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.108333,ScaleX=1.75,ScaleY=1.75,Style="LabelText")
     OptionLabels(0)=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="HELMET",DrawPivot=DP_MiddleMiddle,PosX=0.2875,PosY=0.2,ScaleX=1,ScaleY=1,Pass=2,Style="LabelText")
     OptionLabels(1)=(Text="PROMPT TEXT",PosY=0.258333)
     OptionLabels(2)=(Text="TACTICAL VISOR MODE")
     OptionLabels(3)=(Text="TACTICAL MODE INTENSITY")
     Options(0)=(Items=("ON","OFF"),Blurred=(PosX=0.7125,PosY=0.2),BackgroundBlurred=(PosX=0.7125,PosY=0.2,ScaleX=0.32,ScaleY=0.04333),OnLeft="OnLeft",OnRight="OnRight",Pass=2,Style="ButtonEnumStyle1")
     Options(1)=(Items=("ON","OFF"),Blurred=(PosY=0.258333),BackgroundBlurred=(PosY=0.258333))
     Options(2)=(Items=("ON","OFF","CYCLE"))
     Options(3)=(Items=("0","1","2","3","4","5","6","7","8","9","10"))
     OptionLeftArrows(0)=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowLeft',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.52875,PosY=0.2,ScaleX=0.75,ScaleY=0.75),Focused=(DrawColor=(B=255,G=255,R=255,A=255),ScaleX=0.9,ScaleY=0.9),bIgnoreController=1,OnSelect="OnLeft",Pass=2)
     OptionLeftArrows(1)=(Blurred=(PosX=0.52875,PosY=0.258333))
     OptionLeftArrows(2)=(Blurred=(PosX=0.52875))
     OptionRightArrows(0)=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowRight',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.8975,PosY=0.2,ScaleX=0.75,ScaleY=0.75),Focused=(DrawColor=(B=255,G=255,R=255,A=255),ScaleX=0.9,ScaleY=0.9),bIgnoreController=1,OnSelect="OnRight",Pass=2)
     OptionRightArrows(1)=(Blurred=(PosX=0.8975,PosY=0.258333))
     OptionRightArrows(2)=(Blurred=(PosX=0.8975))
     OptionDefaults(2)=2
     OptionDefaults(3)=2
     ApplySettingsConfirm="APPLY SETTINGS?"
     XLabel=(Text=": RESTORE DEFAULTS")
     XButton=(Blurred=(Text="RESTORE DEFAULTS"))
     ALabel=(Text="ACCEPT :")
     AButton=(Blurred=(Text="ACCEPT"))
     Background=(bHidden=1)
}

