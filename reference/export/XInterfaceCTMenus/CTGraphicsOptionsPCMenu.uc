class CTGraphicsOptionsPCMenu extends MenuTemplateTitled;

var() MenuText			Label;

var() MenuSprite		OptionsBorder;
var() MenuSprite		OptionsDescBorder;

var() MenuText			OptionDesc;

const NUM_OPTIONS = 12;

var() MenuText			OptionLabels[NUM_OPTIONS];
var() MenuButtonEnum	Options[NUM_OPTIONS];
var() MenuButtonSprite  OptionLeftArrows[NUM_OPTIONS];
var() MenuButtonSprite	OptionRightArrows[NUM_OPTIONS];

var() int				OptionApplyRestartRequired[NUM_OPTIONS];
var() MenuText			RestartRequired;

var() int				PreviousSettings[NUM_OPTIONS];
var() int				DirtyBeforeApply[NUM_OPTIONS];

var() MenuText			GraphicsLabel;
var() MenuSprite		GraphicsLabelBackground;
var() MenuSprite		GraphicsLabelConnector;

var() MenuButtonText	Game;
var() MenuButtonText	Sound;
var() MenuButtonText	Controls;
//var() MenuButtonText	Multiplayer;

var() MenuButtonText	Apply;

var() MenuButtonText	SetRecommended;
var() MenuSprite		DefaultConnector;
var() MenuSprite		DefaultLine;

var() MenuButtonText	Done;

var() bool				bApplyNewResolution;

const NUM_PRESETS = 5;
var() string PresetKeys[NUM_PRESETS];

simulated function Init( string Args )
{
	local int i;
	local int newLength;
	
	Super.Init( Args );	
	
	if ( Caps(GetPlayerOwner().GetLanguage()) == "EST" ||
		 Caps(GetPlayerOwner().GetLanguage()) == "DET" )
	{
		Label.ScaleX = 1.5;
	}

	for ( i = 1; i <= 16; ++i )
	{
		if ( GetPlayerOwner().SupportsFSAALevel( i ) )
		{
			newLength = Options[11].Items.Length + 1;
			Options[11].Items.Length = newLength;			
			Options[11].Items[newLength - 1] = i $ "X";
		}
	}

	Refresh( True, True );	
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

simulated function Tick(float ElapsedTime)
{
	local int XSize;
	local int YSize;
	local string tmp;
	
	Super.Tick( ElapsedTime );
	
	if ( bApplyNewResolution )
	{
		tmp = Options[2].Items[Options[2].Current];
		
		XSize = int(Left(tmp, InStr(tmp, "x")));
		YSize = int(Right(tmp, Len(tmp) - InStr(tmp, "x") - 1));
		
		GetPlayerOwner().SetWindowedViewport( XSize, YSize );
		GetPlayerOwner().SetFullscreenViewport( XSize, YSize );
		
		GetPlayerOwner().ConsoleCommand("setres " $ tmp);

		// Save the settings
		GetPlayerOwner().SaveClientConfig();
		GetPlayerOwner().SaveRenderDeviceConfig();
				
		bApplyNewResolution = False;		
	}
}

simulated function bool MenuClosed( Menu closingMenu )
{
    local CTAcceptSettingsTimedMenu acceptMenu;
    local int i;

    acceptMenu = CTAcceptSettingsTimedMenu( closingMenu );
    if( acceptMenu != None )
    {
        if( acceptMenu.bNo || acceptMenu.bTimedOut )
        {
			// Restore the old settings
			RestorePrevious();		
			ApplySettings( True );
        }
        else
        {
			// Accept the new settings
			for ( i = 0; i < NUM_OPTIONS; ++i )
			{
				PreviousSettings[i] = Options[i].Current;
				DirtyBeforeApply[i] = 0;
			}			
        }
        
        return true;
    }

    return false;
}

simulated function Refresh( bool bResetPrevious, bool bGraphicsSettingRefresh )
{
	local int value;
	local string tmp;
	local int i;
	local int XSize;
	local int YSize;

	if ( bGraphicsSettingRefresh )
		Options[0].Current = MatchSettingsToPreset();
	
	value = int((GetPlayerOwner().GetNormalizedGamma() * 10.0) + 0.5);
	if ( value >= Options[1].Items.Length || value < 0 )
		log("*** GOT GAMMA VALUE ("$value$") OUT OF RANGE! ***");
	else
		Options[1].Current = value;
	
	if ( GetPlayerOwner().IsFullscreen() )
		GetPlayerOwner().GetFullscreenViewport( XSize, YSize );
	else
		GetPlayerOwner().GetWindowedViewport( XSize, YSize );
	tmp = string(XSize) $ "x" $ string(YSize);
	for ( i = 0; i < Options[2].Items.Length; ++i )
	{
		if ( Options[2].Items[i] == tmp )
		{
			Options[2].Current = i;
			break;
		}
	}
	
	if ( Options[0].Current != 5 )
		Options[3].Current = Options[0].Current;
	else
		Options[3].Current = MatchTextureDetailSettingsToPreset();
	
	value = GetPlayerOwner().GetCharacterLODLevel();
	if ( value == 0 )
		Options[4].Current = 2;
	else if ( value == 1 )
		Options[4].Current = 1;
	else if ( value == 2 )
		Options[4].Current = 0;
		
	value = GetPlayerOwner().GetBumpmappingQuality();
	if ( value >= Options[5].Items.Length || value < 0 )
		log("*** GOT BUMPMAPPING QUALITY VALUE ("$value$") OUT OF RANGE! ***");
	else
		Options[5].Current = value;

	if ( GetPlayerOwner().GetBlurEnabled() )
		Options[6].Current = 0;
	else
		Options[6].Current = 1;
	
	value = GetPlayerOwner().GetBloomQuality();
	if ( value >= Options[7].Items.Length || value < 0 )
		log("*** GOT BLOOM QUALITY VALUE ("$value$") OUT OF RANGE! ***");
	else
		Options[7].Current = value;
	
	if ( GetPlayerOwner().GetProjectorsEnabled() )
	{
		Options[8].Current = 0;
		// Enable character shadows control
		EnableOption( 9 );
	}
	else
	{
		Options[8].Current = 1;
		// Disable character shadows control
		DisableOption( 9 );
	}

	if ( GetPlayerOwner().GetShadowsEnabled() )
		Options[9].Current = 0;
	else
		Options[9].Current = 1;
	
	if ( GetPlayerOwner().GetVSyncEnabled() )
	{
		Options[10].Current = 0;
		// Enable FSAA control
		EnableOption( 11 );
	}
	else
	{
		Options[10].Current = 1;
		// Disable FSAA control
		DisableOption( 11 );
	}
	
	value = GetPlayerOwner().GetFSAALevel();
	if ( value == 0 )
	{
		Options[11].Current = 0;
	}
	else
	{
		tmp = value $ "X";
		
		for ( i = 1; i < Options[11].Items.Length; ++i )
		{
			if ( tmp == Options[11].Items[i] )
			{
				Options[11].Current = i;
				break;
			}
		}
	}
	
	if ( bResetPrevious )
	{
		for ( i = 0; i < NUM_OPTIONS; ++i )
		{
			PreviousSettings[i] = Options[i].Current;
			DirtyBeforeApply[i] = 0;
		}
	}
}

simulated function ChangeOption( int i, int Delta )
{
	local string tmp;
	local int XSize;
	local int YSize;
    local int NewItem;
    local int value;

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

	if ( Delta != 0 )
	{
		if ( DirtyBeforeApply[i] != 1 )
		{
			PreviousSettings[i] = Options[i].Current;
			DirtyBeforeApply[i] = 1;
		}
		
		Options[i].Current = NewItem;
	}
		
	if ( OptionApplyRestartRequired[i] == 0 )
	{
		// Change the option right now, no apply necessary
		switch(i)
		{
			case 1:
				GetPlayerOwner().SetNormalizedGamma( float(Options[i].Current) / 10.0 );
				GetPlayerOwner().SaveClientConfig();
				break;
				
			case 6:
				if ( Options[i].Current == 0 )
					GetPlayerOwner().EnableBlur(True);
				else
					GetPlayerOwner().EnableBlur(False);
				GetPlayerOwner().SaveClientConfig();
				break;
			
			case 7:
				GetPlayerOwner().SetBloomQuality(Options[i].Current);
				GetPlayerOwner().SaveClientConfig();
				break;
			
			case 9:
				if ( Options[i].Current == 0 )
					GetPlayerOwner().EnableShadows(True);
				else
					GetPlayerOwner().EnableShadows(False);
				GetPlayerOwner().SaveClientConfig();
				break;							
		}

		if ( Delta != 0  )
		{
			if ( i != 0 )
				Options[0].Current = MatchSettingsToPreset();
				
			if ( i != 3 )
			{
				if ( Options[0].Current != 5 )
					Options[3].Current = Options[0].Current;
				else
					Options[3].Current = MatchTextureDetailSettingsToPreset();
			}
		}
		
		// Don't store previous
		PreviousSettings[i] = Options[i].Current;
		DirtyBeforeApply[i] = 0;
	}
	else if ( OptionApplyRestartRequired[i] == 1 )
	{
		switch( i )
		{
			case 0:
				if ( Delta != 0 )
				{
					if ( Options[i].Current == 5 )
						Options[i].Current = 0;
						
					UsePreset( PresetKeys[Options[i].Current], False );
				}
				break;

			case 2:
				tmp = Options[i].Items[Options[i].Current];
				XSize = int(Left(tmp, InStr(tmp, "x")));
				YSize = int(Right(tmp, Len(tmp) - InStr(tmp, "x") - 1));
				GetPlayerOwner().SetWindowedViewport( XSize, YSize );
				GetPlayerOwner().SetFullscreenViewport( XSize, YSize );
				break;
				
			case 3:
				if ( Delta != 0 )
				{
					if ( Options[i].Current == 5 )
					{
						if ( Delta < 0 )
							Options[i].Current = 4;
						else
							Options[i].Current = 0;
					}
					UseTextureDetailPreset( PresetKeys[Options[i].Current] );
				}
				break;
				
			case 5:
				GetPlayerOwner().SetBumpmappingQuality(Options[i].Current);
				break;
				
			case 10:
				if ( Options[i].Current == 0 )
				{
					GetPlayerOwner().EnableVSync( True );
					EnableOption( 11 );
				}
				else
				{
					GetPlayerOwner().EnableVSync( False );
					GetPlayerOwner().SetFSAALevel( 0 );
					Options[11].Current = 0;
					DisableOption( 11 );
				}
				break;			
				
			case 11:
				if ( Options[i].Current == 0 )
				{
					value = 0;
				}
				else
				{
					tmp = Options[i].Items[Options[i].Current];
					value = int( Left( tmp, Len( tmp ) - 1 ) );
				}
				GetPlayerOwner().SetFSAALevel( value );
				break;			
		}
		
		if ( Delta != 0 )
		{
			if ( i != 0 )
				Options[0].Current = MatchSettingsToPreset();
			
			if ( i != 3 )
			{
				if ( Options[0].Current != 5 )
					Options[3].Current = Options[0].Current;
				else
					Options[3].Current = MatchTextureDetailSettingsToPreset();
			}
		}
		
		Apply.bHidden = 0;	
	}
	else if	 ( OptionApplyRestartRequired[i] == 2 )
	{
		// Change immediately, inform of restart required.
		switch ( i )
		{
			case 4:
				if ( Options[i].Current == 2 )
					GetPlayerOwner().SetCharacterLODLevel(0);
				else if ( Options[i].Current == 1 )
					GetPlayerOwner().SetCharacterLODLevel(1);
				else if ( Options[i].Current == 0 )
					GetPlayerOwner().SetCharacterLODLevel(2);
				GetPlayerOwner().SaveClientConfig();
				break;				
				
			case 8:
				if ( Options[i].Current == 0 )
				{
					GetPlayerOwner().EnableProjectors(True);
					EnableOption( 9 );
				}
				else
				{
					GetPlayerOwner().EnableProjectors(False);
					GetPlayerOwner().EnableShadows(False);
					Options[9].Current = 1;
					DisableOption( 9 );
				}
				GetPlayerOwner().SaveClientConfig();					
				break;
		}

		if ( Delta != 0  )
		{
			if ( i != 0 )
				Options[0].Current = MatchSettingsToPreset();
				
			if ( i != 3 )
			{
				if ( Options[0].Current != 5 )
					Options[3].Current = Options[0].Current;
				else
					Options[3].Current = MatchTextureDetailSettingsToPreset();
			}
		}
		
		RestartRequired.bHidden = 0;		
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
	if ( Apply.bHidden == 0 )
		ApplySelected();
	else
		GotoMenuClass("XInterfaceCTMenus.CTGameOptionsPCMenu");
}

simulated function SoundSelected()
{
	if ( Apply.bHidden == 0 )
		ApplySelected();
	else
		GotoMenuClass("XInterfaceCTMenus.CTSoundOptionsPCMenu");
}

simulated function ControlsSelected()
{
	if ( Apply.bHidden == 0 )
		ApplySelected();
	else
		GotoMenuClass("XInterfaceCTMenus.CTControlsOptionsPCMenu");
}

/*simulated function MultiplayerSelected()
{
	if ( Apply.bHidden == 0 )
		ApplySelected();
	else
		GotoMenuClass("XInterfaceCTMenus.CTMultiplayerOptionsPCMenu");
}*/

simulated function RestorePrevious()
{
	local int i;
	
	for ( i = 0; i < NUM_OPTIONS; ++i )
	{
		Options[i].Current = PreviousSettings[i];
		DirtyBeforeApply[i] = 0;
	}
}

simulated function ApplySettings( bool bFromRestore )
{
	local string tmp;
	local int XSize;
	local int YSize;
	local int i;
	local int value;

	// Make sure Character shadows can never be set when Projectors are off.
	if( Options[8].Current == 0 )
		Options[9].Current = 0;
	
	// We simply need to change the resolution to have them 
	// take effect.
	
	for ( i = 0; i < NUM_OPTIONS; ++i )
	{	
		if ( OptionApplyRestartRequired[i] == 1 )
		{
			switch( i )
			{
				// NOTE we don't deal with graphics quality, as it's
				//		been dealt with elsewhere

				case 2:
					tmp = Options[i].Items[Options[i].Current];
					XSize = int(Left(tmp, InStr(tmp, "x")));
					YSize = int(Right(tmp, Len(tmp) - InStr(tmp, "x") - 1));
					GetPlayerOwner().SetWindowedViewport( XSize, YSize );
					GetPlayerOwner().SetFullscreenViewport( XSize, YSize );
					break;

				case 3:
					if ( bFromRestore )
					{
						if ( Options[i].Current != 5 )
							UseTextureDetailPreset( PresetKeys[Options[i].Current] );
					}
					break;
					
				case 5:
					GetPlayerOwner().SetBumpmappingQuality(Options[i].Current);
					break;
					
				case 10:
					if ( Options[i].Current == 0 )
						GetPlayerOwner().EnableVSync( True );
					else
						GetPlayerOwner().EnableVSync( False );
					break;
					
				case 11:
					if ( Options[i].Current == 0 )
					{
						value = 0;
					}
					else
					{
						tmp = Options[i].Items[Options[i].Current];
						value = int( Left( tmp, Len( tmp ) - 1 ) );
					}
					GetPlayerOwner().SetFSAALevel( value );
					break;			
			}
		}			
	}
	
	bApplyNewResolution = True;
}

simulated function ApplySelected()
{
	ApplySettings( False );
	
	OverlayMenuClass("XInterfaceCTMenus.CTAcceptSettingsTimedMenu", "");
		
	Apply.bHidden = 1;
}

simulated function UsePreset( string ConfigKey, bool bRefreshGraphicsSetting )
{
	local string Value1;
	local string Value2;
	local bool bGotValue;
	local int i;

	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "WindowedViewportX", Value1 );
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "WindowedViewportY", Value2 );
	GetPlayerOwner().SetWindowedViewport( int(Value1), int(Value2) );
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "FullscreenViewportX", Value1 );
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "FullscreenViewportY", Value2 );
	GetPlayerOwner().SetFullscreenViewport( int(Value1), int(Value2) );

	UseTextureDetailPreset( ConfigKey );

	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "DropLODBy", Value1 );		
	GetPlayerOwner().SetCharacterLODLevel( int(Value1) );	
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "Shadows", Value1 );		
	GetPlayerOwner().EnableShadows( bool(Value1) );
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "BumpmappingQuality", Value1 );		
	GetPlayerOwner().SetBumpmappingQuality( byte(Value1) );
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "BlurEnabled", Value1 );		
	GetPlayerOwner().EnableBlur( bool(Value1) );
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "BloomQuality", Value1 );		
	GetPlayerOwner().SetBloomQuality( int(Value1) );
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "Projectors", Value1 );		
	GetPlayerOwner().EnableProjectors( bool(Value1) );
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "FSAA", Value1 );
	GetPlayerOwner().SetFSAALevel( int(Value1) );

	Refresh( False, bRefreshGraphicsSetting );
	
	for ( i = 0; i < NUM_OPTIONS; ++i )
	{
		ChangeOption( i, 0 );
	}
}

simulated function int TextureDetailSettingToValue( string setting )
{
	local string cmp;
	
	cmp = Caps(setting);
	
	if ( cmp == "ULTRAHIGH" )
		return 0;
	else if ( cmp == "VERYHIGH" )
		return 1;
	else if ( cmp == "HIGH" )
		return 2;
	else if ( cmp == "HIGHER" )
		return 3;
	else if ( cmp == "NORMAL" )
		return 4;
	else if ( cmp == "LOWER" )
		return 5;
	else if ( cmp == "LOW" )
		return 6;
	else if ( cmp == "VERYLOW" )
		return 7;
	else if ( cmp == "ULTRALOW" )
		return 8;

	return 0;
}

simulated function UseTextureDetailPreset( string ConfigKey )
{
	local string Value1;
	local bool bGotValue;
	local int Interface;
	local int Terrain;
	local int WeaponSkin;
	local int PlayerSkin;
	local int World;
	local int RenderMap;
	local int LightMap;

	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailInterface", Value1 );
	Interface = TextureDetailSettingToValue(Value1);
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailTerrain", Value1 );
	Terrain = TextureDetailSettingToValue(Value1);
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailWeaponSkin", Value1 );
	WeaponSkin = TextureDetailSettingToValue(Value1);
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailPlayerSkin", Value1 );
	PlayerSkin = TextureDetailSettingToValue(Value1);
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailWorld", Value1 );
	World = TextureDetailSettingToValue(Value1);
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailRenderMap", Value1 );
	RenderMap = TextureDetailSettingToValue(Value1);
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailLightmap", Value1 );
	LightMap = TextureDetailSettingToValue(Value1);
	
	GetPlayerOwner().SetTextureDetail( Interface, Terrain, WeaponSkin, PlayerSkin, World, RenderMap, LightMap );	
}

simulated function bool TextureDetailSettingsMatchPreset(int Preset)
{
	local string ConfigKey;
	local string Value1;
	local bool bGotValue;
	local int Interface;
	local int Terrain;
	local int WeaponSkin;
	local int PlayerSkin;
	local int World;
	local int RenderMap;
	local int LightMap;

	GetPlayerOwner().GetTextureDetail( Interface, Terrain, WeaponSkin, PlayerSkin, World, RenderMap, LightMap );
		
	ConfigKey = PresetKeys[Preset];
		
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailInterface", Value1 );
	if ( TextureDetailSettingToValue(Value1) != Interface )
		return False;
		
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailTerrain", Value1 );		
	if ( TextureDetailSettingToValue(Value1) != Terrain )
		return False;
	
	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailWeaponSkin", Value1 );		
	if ( TextureDetailSettingToValue(Value1) != WeaponSkin )
		return False;

	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailPlayerSkin", Value1 );		
	if ( TextureDetailSettingToValue(Value1) != PlayerSkin )
		return False;

	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailWorld", Value1 );		
	if ( TextureDetailSettingToValue(Value1) != World )
		return False;

	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailRenderMap", Value1 );		
	if ( TextureDetailSettingToValue(Value1) != RenderMap )
		return False;

	bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "TextureDetailLightmap", Value1 );		
	if ( TextureDetailSettingToValue(Value1) != LightMap )
		return False;

	// They've all matched, this is our guy!
	return True;
}

simulated function int MatchTextureDetailSettingsToPreset()
{
	local int i;
		
	for ( i = 0; i < NUM_PRESETS; ++i )
	{
		if ( TextureDetailSettingsMatchPreset(i) )
			return i;
	}	
	
	// Nothing matched up, so it's custom
	return 5;
}

simulated function int MatchSettingsToPreset()
{
	local string ConfigKey;
	local string Value1;
	local string Value2;
	local bool bGotValue;
	local int i;
	local int V1;
	local int V2;

	for ( i = 0; i < NUM_PRESETS; ++i )
	{
		ConfigKey = PresetKeys[i];
		
		bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "WindowedViewportX", Value1 );
		bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "WindowedViewportY", Value2 );
		GetPlayerOwner().GetWindowedViewport( V1, V2 );
		if ( int(Value1) != V1 || int(Value2) != V2 )
			continue;
		
		bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "FullscreenViewportX", Value1 );
		bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "FullscreenViewportY", Value2 );
		GetPlayerOwner().GetFullscreenViewport( V1, V2 );
		if ( int(Value1) != V1 || int(Value2) != V2 )
			continue;

		bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "DropLODBy", Value1 );		
		if ( int(Value1) != GetPlayerOwner().GetCharacterLODLevel() )
			continue;
		
		bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "Shadows", Value1 );		
		if ( bool(Value1) != GetPlayerOwner().GetShadowsEnabled() )
			continue;
		
		bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "BumpmappingQuality", Value1 );		
		if ( byte(Value1) != GetPlayerOwner().GetBumpmappingQuality() )
			continue;
				
		bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "BlurEnabled", Value1 );		
		if ( bool(Value1) != GetPlayerOwner().GetBlurEnabled() )
			continue;
		
		bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "BloomQuality", Value1 );		
		if ( int(Value1) != GetPlayerOwner().GetBloomQuality() )
			continue;
		
		bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "Projectors", Value1 );		
		if ( bool(Value1) != GetPlayerOwner().GetProjectorsEnabled() )
			continue;
		
		bGotValue = GetPlayerOwner().GetConfigValue( ConfigKey, "FSAA", Value1 );
		if ( int(Value1) != GetPlayerOwner().GetFSAALevel() )
			continue;

		if ( !TextureDetailSettingsMatchPreset(i) )
			continue;
			
		// They've all matched, this is our guy!
		return i;
	}	
	
	// No preset matched up, so it's custom
	return 5;
}

simulated function SetRecommendedSelected()
{
	local string ConfigKey;
	local bool bShowRestart;
	local bool bShowApply;
	local int i;
	
	if ( !GetPlayerOwner().GetConfigValue( "VideoSettings", "DefaultConfig", ConfigKey ) )
		return;
		
	bShowRestart = RestartRequired.bHidden == 0;		
	bShowApply = Apply.bHidden == 0;
	
	UsePreset( ConfigKey, True );
	
	for ( i = 0; i < NUM_OPTIONS; ++i )
	{
		// If no restart options have changed, hide the message
		if ( ( OptionApplyRestartRequired[i] == 2 ) &&
			 ( PreviousSettings[i] != Options[i].Current ) )
		{
			bShowRestart = True;
		}
		else if ( ( OptionApplyRestartRequired[i] == 1 ) &&
				  ( PreviousSettings[i] != Options[i].Current ) )
		{
			bShowApply = True;			
		}
	}
	
	if ( !bShowRestart )
		RestartRequired.bHidden = 1;		
		
	if ( !bShowApply )
		Apply.bHidden = 1;
}

simulated function DoneSelected()
{
	if ( Apply.bHidden == 0 )
		ApplySelected();
	else
		CloseMenu();
}


defaultproperties
{
     Label=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="OPTIONS",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.078333,ScaleX=1.75,ScaleY=1.75,Style="LabelText")
     OptionsBorder=(PosX=0.63125,PosY=0.405,ScaleX=0.65,ScaleY=0.68666,Style="BorderStyle1")
     OptionsDescBorder=(PosX=0.63125,PosY=0.858333,ScaleX=0.65,ScaleY=0.1666,Style="BorderStyle1")
     OptionLabels(0)=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="GRAPHICS QUALITY",DrawPivot=DP_MiddleLeft,PosX=0.34,PosY=0.12,ScaleX=0.6,ScaleY=0.6,Pass=2,Style="LabelText")
     OptionLabels(1)=(Text="BRIGHTNESS",PosY=0.16)
     OptionLabels(2)=(Text="VIDEO RESOLUTION",PosY=0.24)
     OptionLabels(3)=(Text="TEXTURE QUALITY",PosY=0.28)
     OptionLabels(4)=(Text="CHARACTER DETAIL",PosY=0.32)
     OptionLabels(5)=(Text="BUMPMAPPING QUALITY",PosY=0.36)
     OptionLabels(6)=(Text="BLUR EFFECTS",PosY=0.4)
     OptionLabels(7)=(Text="BLOOM EFFECTS",PosY=0.44)
     OptionLabels(8)=(Text="PROJECTORS",PosY=0.48)
     OptionLabels(9)=(Text="   SQUAD SHADOWS",PosY=0.52)
     OptionLabels(10)=(Text="VSYNC",PosY=0.56)
     OptionLabels(11)=(Text="   FSAA",PosY=0.6)
     Options(0)=(Items=("LOWEST","LOW","MEDIUM","HIGH","HIGHEST","CUSTOM"),Blurred=(PosX=0.77375,PosY=0.12,ScaleX=0.6,ScaleY=0.6),BackgroundBlurred=(PosX=0.77375,PosY=0.12,ScaleX=0.26,ScaleY=0.02666),OnLeft="OnLeft",OnRight="OnRight",Pass=2,Style="ButtonEnumStyle1")
     Options(1)=(Items=("0","1","2","3","4","5","6","7","8","9","10"),bNoWrap=1,Blurred=(PosY=0.16),BackgroundBlurred=(PosY=0.16))
     Options(2)=(Items=("640x480","800x600","1024x768","1152x864","1280x960","1280x1024","1600x1200"),Blurred=(PosY=0.24),BackgroundBlurred=(PosY=0.24))
     Options(3)=(Items=("LOWEST","LOW","MEDIUM","HIGH","HIGHEST","CUSTOM"),Blurred=(PosY=0.28),BackgroundBlurred=(PosY=0.28))
     Options(4)=(Items=("LOW","MEDIUM","HIGH"),Blurred=(PosY=0.32),BackgroundBlurred=(PosY=0.32))
     Options(5)=(Items=("LOW","MEDIUM","HIGH"),Blurred=(PosY=0.36),BackgroundBlurred=(PosY=0.36))
     Options(6)=(Items=("ON","OFF"),Blurred=(PosY=0.4),BackgroundBlurred=(PosY=0.4))
     Options(7)=(Items=("NONE","LOW","HIGH"),Blurred=(PosY=0.44),BackgroundBlurred=(PosY=0.44))
     Options(8)=(Items=("ON","OFF"),Blurred=(PosY=0.48),BackgroundBlurred=(PosY=0.48))
     Options(9)=(Items=("ON","OFF"),Blurred=(PosY=0.52),BackgroundBlurred=(PosY=0.52))
     Options(10)=(Items=("ON","OFF"),Blurred=(PosY=0.56),BackgroundBlurred=(PosY=0.56))
     Options(11)=(Items=("NONE"),Blurred=(PosY=0.6),BackgroundBlurred=(PosY=0.6))
     OptionLeftArrows(0)=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowLeft',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.62625,PosY=0.12,ScaleX=0.5,ScaleY=0.5),Focused=(DrawColor=(B=255,G=255,R=255,A=255),ScaleX=0.65,ScaleY=0.65),bIgnoreController=1,OnSelect="OnLeft",Pass=2)
     OptionLeftArrows(1)=(Blurred=(PosX=0.62625,PosY=0.16))
     OptionLeftArrows(2)=(Blurred=(PosX=0.62625,PosY=0.24))
     OptionLeftArrows(3)=(Blurred=(PosX=0.62625,PosY=0.28))
     OptionLeftArrows(4)=(Blurred=(PosX=0.62625,PosY=0.32))
     OptionLeftArrows(5)=(Blurred=(PosX=0.62625,PosY=0.36))
     OptionLeftArrows(6)=(Blurred=(PosX=0.62625,PosY=0.4))
     OptionLeftArrows(7)=(Blurred=(PosX=0.62625,PosY=0.44))
     OptionLeftArrows(8)=(Blurred=(PosX=0.62625,PosY=0.48))
     OptionLeftArrows(9)=(Blurred=(PosX=0.62625,PosY=0.52))
     OptionLeftArrows(10)=(Blurred=(PosX=0.62625,PosY=0.56))
     OptionLeftArrows(11)=(Blurred=(PosX=0.62625,PosY=0.6))
     OptionRightArrows(0)=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowRight',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.9225,PosY=0.12,ScaleX=0.5,ScaleY=0.5),Focused=(DrawColor=(B=255,G=255,R=255,A=255),ScaleX=0.65,ScaleY=0.65),bIgnoreController=1,OnSelect="OnRight",Pass=2)
     OptionRightArrows(1)=(Blurred=(PosX=0.9225,PosY=0.16))
     OptionRightArrows(2)=(Blurred=(PosX=0.9225,PosY=0.24))
     OptionRightArrows(3)=(Blurred=(PosX=0.9225,PosY=0.28))
     OptionRightArrows(4)=(Blurred=(PosX=0.9225,PosY=0.32))
     OptionRightArrows(5)=(Blurred=(PosX=0.9225,PosY=0.36))
     OptionRightArrows(6)=(Blurred=(PosX=0.9225,PosY=0.4))
     OptionRightArrows(7)=(Blurred=(PosX=0.9225,PosY=0.44))
     OptionRightArrows(8)=(Blurred=(PosX=0.9225,PosY=0.48))
     OptionRightArrows(9)=(Blurred=(PosX=0.9225,PosY=0.52))
     OptionRightArrows(10)=(Blurred=(PosX=0.9225,PosY=0.56))
     OptionRightArrows(11)=(Blurred=(PosX=0.9225,PosY=0.6))
     OptionApplyRestartRequired(0)=1
     OptionApplyRestartRequired(2)=1
     OptionApplyRestartRequired(3)=1
     OptionApplyRestartRequired(4)=2
     OptionApplyRestartRequired(5)=1
     OptionApplyRestartRequired(8)=2
     OptionApplyRestartRequired(10)=1
     OptionApplyRestartRequired(11)=1
     RestartRequired=(MenuFont=Font'OrbitFonts.OrbitBold8',Text="YOU HAVE CHANGED AN OPTION THAT REQUIRES THE GAME BE RESTARTED TO TAKE EFFECT.",DrawColor=(G=175,R=175,A=255),DrawPivot=DP_MiddleLeft,PosX=0.34,PosY=0.858333,ScaleX=1,ScaleY=0.8,MaxSizeX=0.5,bWordWrap=1,Pass=2,bHidden=1)
     GraphicsLabel=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="GRAPHICS",DrawColor=(A=255),DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.3,ScaleX=1,ScaleY=0.8,Pass=2)
     GraphicsLabelBackground=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.3,ScaleX=0.245,ScaleY=0.04333,ScaleMode=MSCM_FitStretch,Pass=1)
     GraphicsLabelConnector=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleLeft,PosX=0.295,PosY=0.3,ScaleX=0.005,ScaleY=0.04333,ScaleMode=MSCM_FitStretch)
     Game=(Blurred=(Text="GAME",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.2),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.2,ScaleX=0.245,ScaleY=0.04333),OnSelect="GameSelected",Style="ButtonTextStyle1")
     Sound=(Blurred=(Text="SOUND",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.25),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.25,ScaleX=0.245,ScaleY=0.04333),OnSelect="SoundSelected",Style="ButtonTextStyle1")
     Controls=(Blurred=(Text="CONTROLS",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.35),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.35,ScaleX=0.245,ScaleY=0.04333),OnSelect="ControlsSelected",Style="ButtonTextStyle1")
     Apply=(Blurred=(Text="APPLY",DrawColor=(G=175,R=175,A=255),DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.5),Focused=(DrawColor=(A=255)),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.5,ScaleX=0.245,ScaleY=0.04333),OnSelect="ApplySelected",bHidden=1,Style="ButtonTextStyle1")
     SetRecommended=(Blurred=(Text="SET RECOMMENDED",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.658333,ScaleX=0.6,ScaleY=0.6),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.658333,ScaleX=0.245,ScaleY=0.04333,ScaleMode=MSCM_FitStretch),OnSelect="SetRecommendedSelected",Style="ButtonTextStyle1")
     DefaultConnector=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleLeft,PosX=0.295,PosY=0.688333,ScaleX=0.005,ScaleY=0.02,ScaleMode=MSCM_FitStretch)
     DefaultLine=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.688333,ScaleX=0.245,ScaleY=0.02,ScaleMode=MSCM_FitStretch)
     Done=(Blurred=(Text="DONE",DrawPivot=DP_MiddleLeft,PosX=0.05375,PosY=0.921666),BackgroundBlurred=(DrawPivot=DP_MiddleLeft,PosX=0.04375,PosY=0.921666,ScaleX=0.245,ScaleY=0.04333),OnSelect="DoneSelected",Style="ButtonTextStyle1")
     PresetKeys(0)="GraphicsQualityLowest"
     PresetKeys(1)="GraphicsQualityLow"
     PresetKeys(2)="GraphicsQualityMedium"
     PresetKeys(3)="GraphicsQualityHigh"
     PresetKeys(4)="GraphicsQualityHighest"
     Background=(bHidden=1)
}

