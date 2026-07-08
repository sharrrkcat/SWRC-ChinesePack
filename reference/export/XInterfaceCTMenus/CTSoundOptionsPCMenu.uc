class CTSoundOptionsPCMenu extends MenuTemplateTitled;

var() MenuText			Label;

var() MenuSprite		OptionsBorder;
var() MenuSprite		OptionsDescBorder;

var() MenuText			OptionDesc;

const NUM_OPTIONS = 7;

var() MenuText			OptionLabels[NUM_OPTIONS];
var() MenuButtonEnum	Options[NUM_OPTIONS];
var() MenuButtonSprite  OptionLeftArrows[NUM_OPTIONS];
var() MenuButtonSprite	OptionRightArrows[NUM_OPTIONS];

var() int				OptionDefaults[NUM_OPTIONS];

var() MenuText			SoundLabel;
var() MenuSprite		SoundLabelBackground;
var() MenuSprite		SoundLabelConnector;

var() MenuButtonText	Game;
var() MenuButtonText	Graphics;
var() MenuButtonText	Controls;
//var() MenuButtonText	Multiplayer;

var() MenuButtonText	RestoreToDefault;
var() MenuSprite		DefaultConnector;
var() MenuSprite		DefaultLine;

var() MenuButtonText	Done;

var() int				OptionApplyRestartRequired[NUM_OPTIONS];
var() MenuText			RestartRequired;

var() bool				bRestoreRestart;

var() Sound				SoundVoice;
var() Sound				SoundFX;

var() bool				bInMultiplayer;

simulated function Init( string Args )
{
	local int newLength;
	
	Super.Init( Args );

	if ( Caps(GetPlayerOwner().GetLanguage()) == "EST" ||
		 Caps(GetPlayerOwner().GetLanguage()) == "DET" )
	{
		Label.ScaleX = 1.5;
	}

	// Don't know why the default properties aren't setting
	// correctly...force it.
    Options[3].bNoWrap = 0;
    Options[4].bNoWrap = 0;
    Options[5].bNoWrap = 0;
    Options[6].bNoWrap = 0;

	bInMultiplayer = Level.NetMode != NM_StandAlone;

	if ( GetPlayerOwner().GetMaxCapsSupportedEAXVersion() <= 2 )
	{
		OptionDefaults[4] = 1;	// 3D Sound Off 	
		OptionDefaults[5] = 0;	// EAX off
		OptionDefaults[6] =	0;	// 16 Channels				
	}

	if ( GetPlayerOwner().GetMaxCapsSupportedEAXVersion() >= 2 )
	{
		newLength = Options[5].Items.Length + 1;
		Options[5].Items.Length = newLength;			
		Options[5].Items[newLength - 1] = "2.0";
	}
	
	if ( GetPlayerOwner().GetMaxCapsSupportedEAXVersion() >= 3 )
	{
		newLength = Options[5].Items.Length + 1;
		Options[5].Items.Length = newLength;			
		Options[5].Items[newLength - 1] = "3.0";
		
		OptionDefaults[4] = 0;	// 3D Sound On 
		OptionDefaults[5] = 2;	// EAX on (3.0)
		OptionDefaults[6] =	1;	// 32 Channels				
	}

	Refresh();		
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
	local int value;

	value = int(GetPlayerOwner().GetVoiceVolume() * 10);
	Options[0].Current = value;

	value = int(GetPlayerOwner().GetSoundVolume() * 10);
	Options[1].Current = value;

	if ( !bInMultiplayer)
	{
		value = int(GetPlayerOwner().GetMusicVolume() * 10);
		Options[2].Current = value;
	}
	else
	{
		DisableOption( 2 );
	}
	
	if ( GetPlayerOwner().GetUseLowQualitySound() )
		Options[3].Current = 1;
	else
		Options[3].Current = 0;

	if ( GetPlayerOwner().Get3DSoundSupported() )
	{
		if ( GetPlayerOwner().GetUse3DSound() )
		{
			Options[4].Current = 0;
			EnableOption( 5 );
		}
		else
		{
			Options[4].Current = 1;
			Options[5].Current = 2;
			DisableOption( 5 );
		}
	}
	else
	{
		Options[4].Current = 1;
		DisableOption( 4 );
		
		Options[5].Current = 0;
		DisableOption( 5 );
	}

	if ( !GetPlayerOwner().Get3DSoundSupported() ||
	     ( GetPlayerOwner().GetMaxCapsSupportedEAXVersion() < 2 ) )
	{
		Options[5].Current = 0;
		DisableOption( 5 );
	}
	else
	{
		if ( GetPlayerOwner().GetUseEAX() )
		{
			if ( ( GetPlayerOwner().GetUseEAXVersion() >= 3 ) &&
			     ( GetPlayerOwner().GetMaxCapsSupportedEAXVersion() >= 3 ) )
			{
				Options[5].Current = 2;			
			}
			else if ( ( GetPlayerOwner().GetUseEAXVersion() == 2 ) &&
			          ( GetPlayerOwner().GetMaxCapsSupportedEAXVersion() >= 2 ) )			
			{
				Options[5].Current = 1;
			}
			else
			{
				Options[5].Current = 0;
			}
		}
		else
		{
			Options[5].Current = 0;		
		}
	}
	
	if ( GetPlayerOwner().GetNumAudioChannels() == 16 )
	{
		Options[6].Current = 0;
	}
	else
	{
		Options[6].Current = 1;
	}
}

simulated function RestoreDefaults()
{
	local int i;
	
	for ( i = 0; i < NUM_OPTIONS; ++i )
	{
		if ( ( Options[i].Current != OptionDefaults[i] ) &&
			 ( OptionApplyRestartRequired[i] == 2 ) )
		{
			bRestoreRestart = True;
		}
		
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
	
	if ( OptionApplyRestartRequired[i] == 0 )
	{
		switch( i )
		{
			case 0:// not profile-able
				GetPlayerOwner().SetVoiceVolume(float(Options[i].Current) / 10.f);
				GetPlayerOwner().SaveAudioConfig();
				if ( Delta != 0 )
					GetPlayerOwner().PlaySound( SoundVoice );
				break;

			case 1:// not profile-able
    			GetPlayerOwner().SetSoundVolume(float(Options[i].Current) / 10.f);
    			GetPlayerOwner().SaveAudioConfig();
				if ( Delta != 0 )
					GetPlayerOwner().PlaySound( SoundFX );
				break;

			case 2:// not profile-able
    			GetPlayerOwner().SetMusicVolume(float(Options[i].Current) / 10.f);
    			GetPlayerOwner().SaveAudioConfig();
				break;            
		}		
	}
	else if	 ( OptionApplyRestartRequired[i] == 2 )
	{
		switch( i )
		{
			case 3:
				if ( Options[i].Current == 0 )
					GetPlayerOwner().SetUseLowQualitySound( False );
				else
					GetPlayerOwner().SetUseLowQualitySound( True );

				GetPlayerOwner().SaveAudioConfig();
				break;
		
			case 4:
				if ( GetPlayerOwner().Get3DSoundSupported() && 
				     ( Options[i].Current == 0 ) )
				{
					GetPlayerOwner().SetUse3DSound( True );
					
					if ( GetPlayerOwner().GetMaxCapsSupportedEAXVersion() >= 2 )
					{
						EnableOption( 5 );
					}
					else
					{
						Options[5].Current = 0;
						GetPlayerOwner().SetUseEAX( False );
						GetPlayerOwner().SetUseEAXVersion( 0 );
						DisableOption( 5 );
					}
				}
				else
				{
					GetPlayerOwner().SetUse3DSound( False );
					Options[5].Current = 0;

					GetPlayerOwner().SetUseEAX( False );
					GetPlayerOwner().SetUseEAXVersion( 0 );
					DisableOption( 5 );
				}
				GetPlayerOwner().SaveAudioConfig();
				break;

			case 5:
				if ( ( GetPlayerOwner().GetMaxCapsSupportedEAXVersion() >= 2 ) &&
					 ( Options[4].Current == 0 ) )
				{
					if ( ( Options[i].Current == 2 ) && 
		 			     ( GetPlayerOwner().GetMaxCapsSupportedEAXVersion() >= 3 ) )
					{					
						GetPlayerOwner().SetUseEAX( True );
						GetPlayerOwner().SetUseEAXVersion( 3 );
					}
					else if ( ( Options[i].Current == 1 ) &&
			  			      ( GetPlayerOwner().GetMaxCapsSupportedEAXVersion() >= 2 ) )
					{
						GetPlayerOwner().SetUseEAX( True );
						GetPlayerOwner().SetUseEAXVersion( 2 );
					}
					else
					{
						Options[i].Current = 0;
						GetPlayerOwner().SetUseEAX( False );
						GetPlayerOwner().SetUseEAXVersion( 0 );
					}
				}
				else
				{
					GetPlayerOwner().SetUseEAX( False );
					GetPlayerOwner().SetUseEAXVersion( 0 );					
					Options[i].Current = 0;
					DisableOption( 5 );
				}
				
				GetPlayerOwner().SaveAudioConfig();			
				break;
				
			case 6:
				if ( Options[i].Current == 0 )
					GetPlayerOwner().SetNumAudioChannels( 16 );
				else
					GetPlayerOwner().SetNumAudioChannels( 32 );

				GetPlayerOwner().SaveAudioConfig();
				break;
		}		
		
		if ( ( Delta != 0 ) || bRestoreRestart )
		{
			RestartRequired.bHidden = 0;
			bRestoreRestart = False;
		}
	}
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

simulated function GameSelected()
{
	GotoMenuClass("XInterfaceCTMenus.CTGameOptionsPCMenu");
}

simulated function GraphicsSelected()
{
	GotoMenuClass("XInterfaceCTMenus.CTGraphicsOptionsPCMenu");
}

simulated function ControlsSelected()
{
	GotoMenuClass("XInterfaceCTMenus.CTControlsOptionsPCMenu");
}

/*simulated function MultiplayerSelected()
{
	GotoMenuClass("XInterfaceCTMenus.CTMultiplayerOptionsPCMenu");
}*/

simulated function RestoreToDefaultSelected()
{
	RestoreDefaults();
}

simulated function DoneSelected()
{
	CloseMenu();
}


defaultproperties
{
     Label=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="OPTIONS",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.078333,ScaleX=1.75,ScaleY=1.75,Style="LabelText")
     OptionsBorder=(PosX=0.63125,PosY=0.405,ScaleX=0.65,ScaleY=0.68666,Style="BorderStyle1")
     OptionsDescBorder=(PosX=0.63125,PosY=0.858333,ScaleX=0.65,ScaleY=0.1666,Style="BorderStyle1")
     OptionLabels(0)=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="VOICES VOLUME",DrawPivot=DP_MiddleLeft,PosX=0.34,PosY=0.12,ScaleX=0.6,ScaleY=0.6,Pass=2,Style="LabelText")
     OptionLabels(1)=(Text="SOUND FX VOLUME",PosY=0.16)
     OptionLabels(2)=(Text="MUSIC VOLUME")
     OptionLabels(3)=(Text="SOUND QUALITY",PosY=0.28)
     OptionLabels(4)=(Text="3D SOUND",PosY=0.32)
     OptionLabels(5)=(Text="   EAX",PosY=0.36)
     OptionLabels(6)=(Text="AUDIO CHANNELS",PosY=0.4)
     Options(0)=(Items=("0","1","2","3","4","5","6","7","8","9","10"),bNoWrap=1,Blurred=(PosX=0.77375,PosY=0.12,ScaleX=0.6,ScaleY=0.6),BackgroundBlurred=(PosX=0.77375,PosY=0.12,ScaleX=0.26,ScaleY=0.02666),OnLeft="OnLeft",OnRight="OnRight",Pass=2,Style="ButtonEnumStyle1")
     Options(1)=(Items=("0","1","2","3","4","5","6","7","8","9","10"),Blurred=(PosY=0.16),BackgroundBlurred=(PosY=0.16))
     Options(2)=(Items=("0","1","2","3","4","5","6","7","8","9","10"))
     Options(3)=(Items=("HIGH","LOW"),Blurred=(PosY=0.28),BackgroundBlurred=(PosY=0.28))
     Options(4)=(Items=("ON","OFF"),Blurred=(PosY=0.32),BackgroundBlurred=(PosY=0.32))
     Options(5)=(Items=("OFF"),Blurred=(PosY=0.36),BackgroundBlurred=(PosY=0.36))
     Options(6)=(Items=("16","32"),Blurred=(PosY=0.4),BackgroundBlurred=(PosY=0.4))
     OptionLeftArrows(0)=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowLeft',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.62625,PosY=0.12,ScaleX=0.5,ScaleY=0.5),Focused=(DrawColor=(B=255,G=255,R=255,A=255),ScaleX=0.65,ScaleY=0.65),bIgnoreController=1,OnSelect="OnLeft",Pass=2)
     OptionLeftArrows(1)=(Blurred=(PosX=0.62625,PosY=0.16))
     OptionLeftArrows(2)=(Blurred=(PosX=0.62625))
     OptionLeftArrows(3)=(Blurred=(PosY=0.28))
     OptionLeftArrows(4)=(Blurred=(PosY=0.32))
     OptionLeftArrows(5)=(Blurred=(PosY=0.36))
     OptionLeftArrows(6)=(Blurred=(PosY=0.4))
     OptionRightArrows(0)=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowRight',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.9225,PosY=0.12,ScaleX=0.5,ScaleY=0.5),Focused=(DrawColor=(B=255,G=255,R=255,A=255),ScaleX=0.65,ScaleY=0.65),bIgnoreController=1,OnSelect="OnRight",Pass=2)
     OptionRightArrows(1)=(Blurred=(PosX=0.9225,PosY=0.16))
     OptionRightArrows(2)=(Blurred=(PosX=0.9225))
     OptionRightArrows(3)=(Blurred=(PosY=0.28))
     OptionRightArrows(4)=(Blurred=(PosY=0.32))
     OptionRightArrows(5)=(Blurred=(PosY=0.36))
     OptionRightArrows(6)=(Blurred=(PosY=0.4))
     OptionDefaults(0)=10
     OptionDefaults(1)=5
     OptionDefaults(2)=7
     OptionDefaults(5)=2
     OptionDefaults(6)=1
     SoundLabel=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="SOUND",DrawColor=(A=255),DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.25,ScaleX=1,ScaleY=0.8,Pass=2)
     SoundLabelBackground=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.25,ScaleX=0.245,ScaleY=0.04333,ScaleMode=MSCM_FitStretch,Pass=1)
     SoundLabelConnector=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleLeft,PosX=0.295,PosY=0.25,ScaleX=0.005,ScaleY=0.04333,ScaleMode=MSCM_FitStretch)
     Game=(Blurred=(Text="GAME",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.2),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.2,ScaleX=0.245,ScaleY=0.04333),OnSelect="GameSelected",Style="ButtonTextStyle1")
     Graphics=(Blurred=(Text="GRAPHICS",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.3),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.3,ScaleX=0.245,ScaleY=0.04333),OnSelect="GraphicsSelected",Style="ButtonTextStyle1")
     Controls=(Blurred=(Text="CONTROLS",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.35),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.35,ScaleX=0.245,ScaleY=0.04333),OnSelect="ControlsSelected",Style="ButtonTextStyle1")
     RestoreToDefault=(Blurred=(Text="RESTORE DEFAULTS",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.658333,ScaleX=0.6,ScaleY=0.6),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.658333,ScaleX=0.245,ScaleY=0.04333,ScaleMode=MSCM_FitStretch),OnSelect="RestoreToDefaultSelected",Style="ButtonTextStyle1")
     DefaultConnector=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleLeft,PosX=0.295,PosY=0.688333,ScaleX=0.005,ScaleY=0.02,ScaleMode=MSCM_FitStretch)
     DefaultLine=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.688333,ScaleX=0.245,ScaleY=0.02,ScaleMode=MSCM_FitStretch)
     Done=(Blurred=(Text="DONE",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.921666),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.921666,ScaleX=0.245,ScaleY=0.04333),OnSelect="DoneSelected",Style="ButtonTextStyle1")
     OptionApplyRestartRequired(3)=2
     OptionApplyRestartRequired(4)=2
     OptionApplyRestartRequired(5)=2
     OptionApplyRestartRequired(6)=2
     RestartRequired=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="YOU HAVE CHANGED AN OPTION THAT REQUIRES THE GAME BE RESTARTED TO TAKE EFFECT.",DrawColor=(G=175,R=175,A=255),DrawPivot=DP_MiddleLeft,PosX=0.34,PosY=0.858333,ScaleX=1,ScaleY=0.8,MaxSizeX=0.5,bWordWrap=1,Pass=2,bHidden=1)
     SoundVoice=SoundMultiple'UI_Sound.UI.Voice_Volume_Set'
     SoundFX=SoundMultiple'UI_Sound.UI.SFX_Volume_Set'
     Background=(bHidden=1)
}

