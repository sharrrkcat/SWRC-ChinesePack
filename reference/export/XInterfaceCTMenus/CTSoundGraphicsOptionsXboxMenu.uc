class CTSoundGraphicsOptionsXboxMenu extends MenuTemplateTitledBXA;

var() MenuText			SoundLabel;
var() MenuText			GraphicsLabel;

var() MenuSprite		SliderMin;
var() MenuSprite		SliderMax;

const NUM_OPTIONS = 4;

// Sound and graphics
var() MenuText			OptionLabels[NUM_OPTIONS];
var() MenuButtonEnum	Options[NUM_OPTIONS];
var() MenuButtonSprite  OptionLeftArrows[NUM_OPTIONS];
var() MenuButtonSprite	OptionRightArrows[NUM_OPTIONS];

var() int				OptionDefaults[NUM_OPTIONS];

var() int				PreviousSettings[NUM_OPTIONS];

var() localized String	ApplySettingsConfirm;

var() Sound				SoundVoice;
var() Sound				SoundFX;

var() bool				bQueuedSoundVoice;
var() bool				bStartedSoundVoice;

var() bool				bQueuedSoundFX;
var() bool				bStartedSoundFX;

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

simulated function Tick( float ElapsedTime )
{
	if ( bQueuedSoundVoice )
	{
		if ( !bStartedSoundVoice )
		{
			if ( IsSoundActive( SoundVoice ) )
			{
				bStartedSoundVoice = True;
			}
		}
		else
		{
			if ( !IsSoundActive( SoundVoice ) )
			{
				bQueuedSoundVoice = False;
				bStartedSoundVoice = False;
				ConsoleCommand("set ini:Engine.Engine.AudioDevice VoiceVolume" @ float(PreviousSettings[0]) / 10.f );			
			}
		}
	}
	
	if ( bQueuedSoundFX )
	{
		if ( !bStartedSoundFX )
		{
			if ( IsSoundActive( SoundFX ) )
			{
				bStartedSoundFX = True;
			}
		}
		else
		{
			if ( !IsSoundActive( SoundFX ) )
			{
				bQueuedSoundFX = False;
				bStartedSoundFX = False;
				ConsoleCommand("set ini:Engine.Engine.AudioDevice SoundVolume" @ float(PreviousSettings[1]) / 10.f );			
			}
		}
	}
}

simulated function Refresh()
{
	local int value;
	local int i;
	
	value = int(float(ConsoleCommand("get ini:Engine.Engine.AudioDevice VoiceVolume")) * 10);    	    
	Options[0].Current = value;

	value = int(float(ConsoleCommand("get ini:Engine.Engine.AudioDevice SoundVolume")) * 10);    	    
	Options[1].Current = value;

	if ( !bInMultiplayer )
	{
		value = int(float(ConsoleCommand("get ini:Engine.Engine.AudioDevice MusicVolume")) * 10);    	    
		Options[2].Current = value;
	}
	else
	{
		DisableOption( 2 );
	}
	
	value = int(GetPlayerOwner().GetNormalizedGamma() * 10.0 + 0.5);
	Options[3].Current = value;

	
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
	
	if ( Delta != 0 )
	{
		if ( i == 0 )
		{
			// Set the new (changed) value
			ConsoleCommand("set ini:Engine.Engine.AudioDevice VoiceVolume" @ float(Options[i].Current) / 10.f );
			
			// Play the sound at the new volume
			GetPlayerOwner().PlaySound( SoundVoice );
			
			bStartedSoundVoice = True;
		}
		else if ( i == 1 )
		{
			// Set the new (changed) value
			ConsoleCommand("set ini:Engine.Engine.AudioDevice SoundVolume" @ float(Options[i].Current) / 10.f );
			
			// Play the sound at the new volume
			GetPlayerOwner().PlaySound( SoundFX );
			
			bStartedSoundFX = True;
		}
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
			case 0:// not profile-able
				ConsoleCommand("set ini:Engine.Engine.AudioDevice VoiceVolume" @ float(Options[i].Current) / 10.f );    	    
				break;

			case 1:// not profile-able
    			ConsoleCommand("set ini:Engine.Engine.AudioDevice SoundVolume" @ float(Options[i].Current) / 10.f );
				break;

			case 2:// not profile-able
    			ConsoleCommand("set ini:Engine.Engine.AudioDevice MusicVolume" @ float(Options[i].Current) / 10.f );
				break;
	            
			case 3:
				GetPlayerOwner().SetNormalizedGamma( float(Options[i].Current) / 10.0 );
				GetPlayerOwner().SaveClientConfig();
				break;
		}	
	}
	
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
			if ( bQueuedSoundVoice || bStartedSoundVoice )
			{
				ConsoleCommand("set ini:Engine.Engine.AudioDevice VoiceVolume" @ float(PreviousSettings[0]) / 10.f );
				bQueuedSoundVoice = False;
				bStartedSoundVoice = False;
			}
			
			if ( bQueuedSoundFX || bStartedSoundFX )
			{
				ConsoleCommand("set ini:Engine.Engine.AudioDevice SoundVolume" @ float(PreviousSettings[1]) / 10.f );
				bQueuedSoundFX = False;
				bStartedSoundFX = False;
			}
			
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
     SoundLabel=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="SOUND OPTIONS",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.108333,ScaleX=1.75,ScaleY=1.75,Style="LabelText")
     GraphicsLabel=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="GRAPHICS OPTIONS",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.54,ScaleX=1.75,ScaleY=1.75,Style="LabelText")
     SliderMin=(WidgetTexture=Texture'GUIContent.Menu.CT_VolumeLow',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.575,PosY=0.2)
     SliderMax=(WidgetTexture=Texture'GUIContent.Menu.CT_VolumeHigh',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.8525,PosY=0.2)
     OptionLabels(0)=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="VOICES VOLUME",DrawPivot=DP_MiddleMiddle,PosX=0.2875,PosY=0.258333,ScaleX=1,ScaleY=1,Pass=2,Style="LabelText")
     OptionLabels(1)=(Text="SOUND FX VOLUME",PosY=0.31666)
     OptionLabels(2)=(Text="MUSIC VOLUME")
     OptionLabels(3)=(Text="BRIGHTNESS",PosY=0.65)
     Options(0)=(Items=("0","1","2","3","4","5","6","7","8","9","10"),bNoWrap=1,Blurred=(PosX=0.7125,PosY=0.258333),BackgroundBlurred=(PosX=0.7125,PosY=0.258333,ScaleX=0.32,ScaleY=0.04333),OnLeft="OnLeft",OnRight="OnRight",Pass=2,Style="ButtonEnumStyle1")
     Options(1)=(Items=("0","1","2","3","4","5","6","7","8","9","10"),Blurred=(PosY=0.31666),BackgroundBlurred=(PosY=0.31666))
     Options(2)=(Items=("0","1","2","3","4","5","6","7","8","9","10"))
     Options(3)=(Items=("0","1","2","3","4","5","6","7","8","9","10"),Blurred=(PosY=0.65),BackgroundBlurred=(PosY=0.65))
     OptionLeftArrows(0)=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowLeft',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.52875,PosY=0.258333,ScaleX=0.75,ScaleY=0.75),Focused=(DrawColor=(B=255,G=255,R=255,A=255),ScaleX=0.9,ScaleY=0.9),bIgnoreController=1,OnSelect="OnLeft",Pass=2)
     OptionLeftArrows(1)=(Blurred=(PosX=0.52875,PosY=0.31666))
     OptionLeftArrows(2)=(Blurred=(PosX=0.52875))
     OptionLeftArrows(3)=(Blurred=(PosX=0.52875,PosY=0.65))
     OptionRightArrows(0)=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowRight',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.8975,PosY=0.258333,ScaleX=0.75,ScaleY=0.75),Focused=(DrawColor=(B=255,G=255,R=255,A=255),ScaleX=0.9,ScaleY=0.9),bIgnoreController=1,OnSelect="OnRight",Pass=2)
     OptionRightArrows(1)=(Blurred=(PosX=0.8975,PosY=0.31666))
     OptionRightArrows(2)=(Blurred=(PosX=0.8975))
     OptionRightArrows(3)=(Blurred=(PosX=0.8975,PosY=0.65))
     OptionDefaults(0)=8
     OptionDefaults(1)=5
     OptionDefaults(2)=6
     OptionDefaults(3)=3
     ApplySettingsConfirm="APPLY SETTINGS?"
     SoundVoice=SoundMultiple'UI_Sound.UI.Voice_Volume_Set'
     SoundFX=SoundMultiple'UI_Sound.UI.SFX_Volume_Set'
     XLabel=(Text=": RESTORE DEFAULTS")
     XButton=(Blurred=(Text="RESTORE DEFAULTS"))
     ALabel=(Text="ACCEPT :")
     AButton=(Blurred=(Text="ACCEPT"))
     Background=(bHidden=1)
}

