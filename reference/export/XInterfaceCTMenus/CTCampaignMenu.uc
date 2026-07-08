class CTCampaignMenu extends MenuTemplateTitledBA;

var() MenuSprite		KaminoBorder;
var() MenuSprite		Kamino;

var() MenuButtonSprite	Geonosis;
var() MenuButtonSprite	AssaultShip;
var() MenuButtonSprite	Kashyyyk;

const					NUM_GEO_MISSIONS = 4;
var() MenuSprite		CompletedGeonosis[NUM_GEO_MISSIONS];
var() int				GEO_MissionSubEnd[NUM_GEO_MISSIONS];

const					NUM_RAS_MISSIONS = 4;
var() MenuSprite		CompletedAssaultShip[NUM_RAS_MISSIONS];
var() int				RAS_MissionSubEnd[NUM_RAS_MISSIONS];

const					NUM_YYY_MISSIONS = 5;
var() MenuSprite		CompletedKashyyyk[NUM_YYY_MISSIONS];
var() int				YYY_MissionSubEnd[NUM_YYY_MISSIONS];

var() MenuButtonSprite	GEONavigateRight;
var() MenuButtonSprite	RASNavigateLeft;
var() MenuButtonSprite	RASNavigateRight;
var() MenuButtonSprite	YYYNavigateLeft;

var() MenuSprite		LabelBackground;
var() MenuText			Label;

var() MenuSprite		CampaignBackground;
var() MenuText			Campaign;
var() localized string	Campaigns[3];

var() int				SelectedCampaign;

var() MenuSprite		Border;

const					DEV_NUM_GEO_SUB_MISSIONS = 15;
var() string			DEV_GEO_SubMissions[DEV_NUM_GEO_SUB_MISSIONS];
var() string			DEV_GEO_SubMissionDescs[DEV_NUM_GEO_SUB_MISSIONS];
var() int				DEV_GEO_SubMissionAvailable[DEV_NUM_GEO_SUB_MISSIONS];

const					DEV_NUM_RAS_SUB_MISSIONS = 16;
var() string			DEV_RAS_SubMissions[DEV_NUM_RAS_SUB_MISSIONS];
var() string			DEV_RAS_SubMissionDescs[DEV_NUM_RAS_SUB_MISSIONS];
var() int				DEV_RAS_SubMissionAvailable[DEV_NUM_RAS_SUB_MISSIONS];

const					DEV_NUM_YYY_SUB_MISSIONS = 25;
var() string			DEV_YYY_SubMissions[DEV_NUM_YYY_SUB_MISSIONS];
var() string			DEV_YYY_SubMissionDescs[DEV_NUM_YYY_SUB_MISSIONS];
var() int				DEV_YYY_SubMissionAvailable[DEV_NUM_YYY_SUB_MISSIONS];

const					NUM_GEO_SUB_MISSIONS = 6;
var() string			GEO_SubMissions[NUM_GEO_SUB_MISSIONS];
var() localized string	GEO_SubMissionDescs[NUM_GEO_SUB_MISSIONS];
var() int				GEO_SubMissionAvailable[NUM_GEO_SUB_MISSIONS];

const					NUM_RAS_SUB_MISSIONS = 4;
var() string			RAS_SubMissions[NUM_RAS_SUB_MISSIONS];
var() localized string	RAS_SubMissionDescs[NUM_RAS_SUB_MISSIONS];
var() int				RAS_SubMissionAvailable[NUM_RAS_SUB_MISSIONS];

const					NUM_YYY_SUB_MISSIONS = 7;
var() string			YYY_SubMissions[NUM_YYY_SUB_MISSIONS];
var() localized string	YYY_SubMissionDescs[NUM_YYY_SUB_MISSIONS];
var() int				YYY_SubMissionAvailable[NUM_YYY_SUB_MISSIONS];

var() MenuStringList    LevelList;

var() MenuScrollBar     ScrollBar;
var() MenuButtonSprite  ScrollBarArrowUp, ScrollBarArrowDown;

var() MenuScrollArea    ScrollArea;
var() MenuActiveWidget  PageUpArea, PageDownArea;

var() int				SelectedLevel;

var() float				BlipPulseTime;
var() float				ElapsedBlipPulseTime;

var() float				RingPulseTime;
var() float				ElapsedRingPulseTime;

var() bool				bDevMode;

simulated function Init( String Args )
{
	Super.Init( Args );

    if ( !IsOnConsole() ) 
    {
		LevelList.Template.bNoMouseOverFocus = 1;
		LevelList.Template.bStickyDrawFocus = 1;
	}
	else
	{
		GEONavigateRight.bDisabled = 1;
		RASNavigateLeft.bDisabled = 1;
		RASNavigateRight.bDisabled = 1;
		YYYNavigateLeft.bDisabled = 1;
	}

	// Determine what missions are available...
	GetAvailableMissions();	
		

	LayoutMenuStringList( LevelList );
	UpdateScrollBar();

	if ( YYYAvailable() )
		KashyyykSelected();
	else if ( RASAvailable() )
		AssaultShipSelected();
	else	
		GeonosisSelected();
}

simulated function Tick( float ElapsedTime )
{
	local int i;
	local int MissionStart;
	local int MissionEnd;
	local float HalfRingPulseTime;
	local float Alpha;

	Super.Tick( ElapsedTime );

	if ( !IsOnConsole() )
	{
		// Let's check to make sure two things aren't highlighted in the level list
		for ( i = 0; i < LevelList.Items.Length; ++i )
		{
			if ( LevelList.Items[i].bHasFocus != 0 || LevelList.Items[i].bDrawFocused != 0 )
			{
				if ( SelectedLevel != i )
				{
					// We've gone foobar...clear the list focus
					ClearListStickyFocus( LevelList );
					SelectedLevel = -1;
					return;
				}
			}
		}
	}
		
	if ( SelectedCampaign == 0 )
	{
		for ( i = 0; i < NUM_GEO_MISSIONS; ++i )
		{
			if ( i == 0 )
				MissionStart = 1; // NOTE we're starting at 1 to exclude the prologue
			else
				MissionStart = GEO_MissionSubEnd[i - 1] + 1;
				
			MissionEnd = GEO_MissionSubEnd[i];				
		
			if ( ( SelectedLevel >= MissionStart ) && ( SelectedLevel <= MissionEnd ) )
			{
				ElapsedBlipPulseTime += ElapsedTime;
				if ( ElapsedBlipPulseTime > BlipPulseTime )
					ElapsedBlipPulseTime = 0;
				CompletedGeonosis[i].DrawColor.A = 255.0 * ( ElapsedBlipPulseTime / BlipPulseTime );
				break;
			}
		}
	}
	else if ( SelectedCampaign == 1 )
	{
		for ( i = 0; i < NUM_RAS_MISSIONS; ++i )
		{
			if ( i == 0 )
				MissionStart = 0;
			else
				MissionStart = RAS_MissionSubEnd[i - 1] + 1;
				
			MissionEnd = RAS_MissionSubEnd[i];				
		
			if ( ( SelectedLevel >= MissionStart ) && ( SelectedLevel <= MissionEnd ) )
			{
				ElapsedBlipPulseTime += ElapsedTime;
				if ( ElapsedBlipPulseTime > BlipPulseTime )
					ElapsedBlipPulseTime = 0;
				CompletedAssaultShip[i].DrawColor.A = 255.0 * ( ElapsedBlipPulseTime / BlipPulseTime );
				break;
			}
		}	
	}
	else if ( SelectedCampaign == 2 )
	{
		for ( i = 0; i < NUM_YYY_MISSIONS; ++i )
		{
			if ( i == 0 )
				MissionStart = 0;
			else
				MissionStart = YYY_MissionSubEnd[i - 1] + 1;
				
			MissionEnd = YYY_MissionSubEnd[i];				
		
			if ( ( SelectedLevel >= MissionStart ) && ( SelectedLevel <= MissionEnd ) )
			{
				ElapsedBlipPulseTime += ElapsedTime;
				if ( ElapsedBlipPulseTime > BlipPulseTime )
					ElapsedBlipPulseTime = 0;
				CompletedKashyyyk[i].DrawColor.A = 255.0 * ( ElapsedBlipPulseTime / BlipPulseTime );
				break;
			}
		}		
	}

	// Pulse the non-selected selectable rings
	ElapsedRingPulseTime += ElapsedTime;
	if ( ElapsedRingPulseTime > RingPulseTime )
		ElapsedRingPulseTime = 0;
	
	HalfRingPulseTime = RingPulseTime / 2;

	if ( ElapsedRingPulseTime < HalfRingPulseTime )
		Alpha = 32 + (160 * (ElapsedRingPulseTime / HalfRingPulseTime));
	else
		Alpha = 192 - (160 * ((ElapsedRingPulseTime - HalfRingPulseTime) / HalfRingPulseTime));

	if ( ( SelectedCampaign != 0 ) && GEOAvailable() )
	{
		Geonosis.BackgroundBlurred.DrawColor.A = Alpha;
		Geonosis.BackgroundFocused.DrawColor.A = Alpha;
	}
	
	if ( ( SelectedCampaign != 1 ) && RASAvailable() )
	{
		AssaultShip.BackgroundBlurred.DrawColor.A = Alpha;
		AssaultShip.BackgroundFocused.DrawColor.A = Alpha;
	}
	
	if ( ( SelectedCampaign != 2 ) && YYYAvailable() )
	{
		Kashyyyk.BackgroundBlurred.DrawColor.A = Alpha;
		Kashyyyk.BackgroundFocused.DrawColor.A = Alpha;
	}
	
	// And the arrows
	GEONavigateRight.Blurred.DrawColor.A = Alpha;
	RASNavigateLeft.Blurred.DrawColor.A = Alpha;
	RASNavigateRight.Blurred.DrawColor.A = Alpha;
	YYYNavigateLeft.Blurred.DrawColor.A = Alpha;
}

simulated function GetAvailableMissions()
{
	local int i;

	// Enable all the dev missions	
	for ( i = 0; i < DEV_NUM_GEO_SUB_MISSIONS; ++i )
		DEV_GEO_SubMissionAvailable[i] = 1;

	for ( i = 0; i < DEV_NUM_RAS_SUB_MISSIONS; ++i )
		DEV_RAS_SubMissionAvailable[i] = 1;
	
	for ( i = 0; i < DEV_NUM_YYY_SUB_MISSIONS; ++i )
		DEV_YYY_SubMissionAvailable[i] = 1;


/********************************************************
	for ( i = 0; i < NUM_GEO_SUB_MISSIONS; ++i )
		GEO_SubMissionAvailable[i] = 1;

	for ( i = 0; i < NUM_RAS_SUB_MISSIONS; ++i )
		RAS_SubMissionAvailable[i] = 1;
	
	for ( i = 0; i < NUM_YYY_SUB_MISSIONS; ++i )
		YYY_SubMissionAvailable[i] = 1;
********************************************************/

	// Figure out what levels are available
	for ( i = 0; i < NUM_GEO_SUB_MISSIONS; ++i )
	{
		if ( GetPlayerOwner().HasReachedLevel( GEO_SubMissions[i] ) )
			GEO_SubMissionAvailable[i] = 1;
		else
			GEO_SubMissionAvailable[i] = 0;
	}
	
	for ( i = 0; i < NUM_RAS_SUB_MISSIONS; ++i )
	{
		if ( GetPlayerOwner().HasReachedLevel( RAS_SubMissions[i] ) )
			RAS_SubMissionAvailable[i] = 1;
		else
			RAS_SubMissionAvailable[i] = 0;
	}
	
	for ( i = 0; i < NUM_YYY_SUB_MISSIONS; ++i )
	{
		if ( GetPlayerOwner().HasReachedLevel( YYY_SubMissions[i] ) )
			YYY_SubMissionAvailable[i] = 1;
		else
			YYY_SubMissionAvailable[i] = 0;
	}
}

simulated function bool GEOMissionAvailable( int Mission )
{
	local int i;
	local int MissionStart;
	local int MissionEnd;
	
	if ( Mission == 0 )
		MissionStart = 0;
	else
		MissionStart = GEO_MissionSubEnd[Mission - 1] + 1;
		
	MissionEnd = GEO_MissionSubEnd[Mission];
	
	for ( i = MissionStart; i <= MissionEnd; ++i )
	{
		if ( bDevMode )
		{
			if ( DEV_GEO_SubMissionAvailable[i] != 0 )
			{
				return true;
			}
		}
		else
		{
			if ( GEO_SubMissionAvailable[i] != 0 )
			{
				return true;
			}
		}
	}
	
	return false;
}

simulated function bool RASMissionAvailable( int Mission )
{
	local int i;
	local int MissionStart;
	local int MissionEnd;
	
	if ( Mission == 0 )
		MissionStart = 0;
	else
		MissionStart = RAS_MissionSubEnd[Mission - 1] + 1;
		
	MissionEnd = RAS_MissionSubEnd[Mission];
	
	for ( i = MissionStart; i <= MissionEnd; ++i )
	{
		if ( bDevMode )
		{
			if ( DEV_RAS_SubMissionAvailable[i] != 0 )
			{
				return true;
			}
		}
		else
		{
			if ( RAS_SubMissionAvailable[i] != 0 )
			{
				return true;
			}
		}
	}
	
	return false;
}

simulated function bool YYYMissionAvailable( int Mission )
{
	local int i;
	local int MissionStart;
	local int MissionEnd;
	
	if ( Mission == 0 )
		MissionStart = 0;
	else
		MissionStart = YYY_MissionSubEnd[Mission - 1] + 1;
		
	MissionEnd = YYY_MissionSubEnd[Mission];
	
	for ( i = MissionStart; i <= MissionEnd; ++i )
	{
		if ( bDevMode )
		{
			if ( DEV_YYY_SubMissionAvailable[i] != 0 )
			{
				return true;
			}
		}
		else
		{
			if ( YYY_SubMissionAvailable[i] != 0 )
			{
				return true;
			}
		}
	}
	
	return false;
}

simulated function bool GEOAvailable()
{
	if ( bDevMode )
		return (DEV_GEO_SubMissionAvailable[0] != 0);
		
	return (GEO_SubMissionAvailable[0] != 0);
}

simulated function bool RASAvailable()
{
	if ( bDevMode )
		return (DEV_RAS_SubMissionAvailable[0] != 0);
		
	return (RAS_SubMissionAvailable[0] != 0);		
}

simulated function bool YYYAvailable()
{
	if ( bDevMode )
		return (DEV_YYY_SubMissionAvailable[0] != 0);
		
	return (YYY_SubMissionAvailable[0] != 0);		
}

simulated function RefreshCurrent()
{
	if ( SelectedCampaign == 0 )
		GeonosisSelected();
	else if ( SelectedCampaign == 1 )
		AssaultShipSelected();
	else if ( SelectedCampaign == 2 )
		KashyyykSelected();
}

simulated function HighlightMissionBlip()
{
	local int i;
	local int MissionStart;
	local int MissionEnd;

	if ( SelectedCampaign == 0 )
	{
		for ( i = 0; i < NUM_GEO_MISSIONS; ++i )
		{
			if ( i == 0 )
				MissionStart = 1;  // NOTE we're starting at 1 to exclude the prologue
			else
				MissionStart = GEO_MissionSubEnd[i - 1] + 1;
				
			MissionEnd = GEO_MissionSubEnd[i];				
		
			if ( ( SelectedLevel >= MissionStart ) && ( SelectedLevel <= MissionEnd ) )
			{
				CompletedGeonosis[i].DrawColor.R = 128;
				CompletedGeonosis[i].DrawColor.G = 255;
				CompletedGeonosis[i].DrawColor.B = 128;
				CompletedGeonosis[i].DrawColor.A = 255;					
			}
			else
			{
				CompletedGeonosis[i].DrawColor.R = 255;
				CompletedGeonosis[i].DrawColor.G = 255;
				CompletedGeonosis[i].DrawColor.B = 255;
				CompletedGeonosis[i].DrawColor.A = 255;								
			}
		}	
	}
	else if ( SelectedCampaign == 1 )
	{
		for ( i = 0; i < NUM_RAS_MISSIONS; ++i )
		{
			if ( i == 0 )
				MissionStart = 0;
			else
				MissionStart = RAS_MissionSubEnd[i - 1] + 1;
				
			MissionEnd = RAS_MissionSubEnd[i];				
		
			if ( ( SelectedLevel >= MissionStart ) && ( SelectedLevel <= MissionEnd ) )
			{
				CompletedAssaultShip[i].DrawColor.R = 128;
				CompletedAssaultShip[i].DrawColor.G = 255;
				CompletedAssaultShip[i].DrawColor.B = 128;
				CompletedAssaultShip[i].DrawColor.A = 255;					
			}
			else
			{
				CompletedAssaultShip[i].DrawColor.R = 255;
				CompletedAssaultShip[i].DrawColor.G = 255;
				CompletedAssaultShip[i].DrawColor.B = 255;
				CompletedAssaultShip[i].DrawColor.A = 255;								
			}
		}	
	}
	else if ( SelectedCampaign == 2 )
	{
		for ( i = 0; i < NUM_YYY_MISSIONS; ++i )
		{
			if ( i == 0 )
				MissionStart = 0;
			else
				MissionStart = YYY_MissionSubEnd[i - 1] + 1;
				
			MissionEnd = YYY_MissionSubEnd[i];				
		
			if ( ( SelectedLevel >= MissionStart ) && ( SelectedLevel <= MissionEnd ) )
			{
				CompletedKashyyyk[i].DrawColor.R = 128;
				CompletedKashyyyk[i].DrawColor.G = 255;
				CompletedKashyyyk[i].DrawColor.B = 128;
				CompletedKashyyyk[i].DrawColor.A = 255;					
			}
			else
			{
				CompletedKashyyyk[i].DrawColor.R = 255;
				CompletedKashyyyk[i].DrawColor.G = 255;
				CompletedKashyyyk[i].DrawColor.B = 255;
				CompletedKashyyyk[i].DrawColor.A = 255;								
			}
		}		
	}
}

simulated function UnSelectCampaign()
{
	local int i;
	
	Geonosis.BackgroundBlurred.DrawColor.R = 96;
	Geonosis.BackgroundBlurred.DrawColor.G = 96;
	Geonosis.BackgroundBlurred.DrawColor.B = 96;
	Geonosis.BackgroundFocused.DrawColor.R = 96;
	Geonosis.BackgroundFocused.DrawColor.G = 96;
	Geonosis.BackgroundFocused.DrawColor.B = 96;
	Geonosis.Blurred.DrawColor.R = 96;
	Geonosis.Blurred.DrawColor.G = 96;
	Geonosis.Blurred.DrawColor.B = 96;
	Geonosis.Blurred.DrawColor.A = 192;
	
	GEONavigateRight.bHidden = 1;
	
	if ( !IsOnConsole() && GEOAvailable() )
		Geonosis.bDisabled=0;
	else
		Geonosis.bDisabled=1;

	for ( i = 0; i < NUM_GEO_MISSIONS; ++i )
	{
		CompletedGeonosis[i].DrawColor.R = 96;
		CompletedGeonosis[i].DrawColor.G = 96;
		CompletedGeonosis[i].DrawColor.B = 96;
		CompletedGeonosis[i].DrawColor.A = 192;		
		
		if ( !GEOAvailable() || !GEOMissionAvailable(i) )
			CompletedGeonosis[i].bHidden = 1;		
	}
		
	AssaultShip.BackgroundBlurred.DrawColor.R = 96;
	AssaultShip.BackgroundBlurred.DrawColor.G = 96;
	AssaultShip.BackgroundBlurred.DrawColor.B = 96;
	AssaultShip.BackgroundFocused.DrawColor.R = 96;
	AssaultShip.BackgroundFocused.DrawColor.G = 96;
	AssaultShip.BackgroundFocused.DrawColor.B = 96;
	AssaultShip.Blurred.DrawColor.R = 96;
	AssaultShip.Blurred.DrawColor.G = 96;
	AssaultShip.Blurred.DrawColor.B = 96;
	AssaultShip.Blurred.DrawColor.A = 192;
	
	RASNavigateLeft.bHidden = 1;
	RASNavigateRight.bHidden = 1;
	
	if ( !IsOnConsole() && RASAvailable() )
		AssaultShip.bDisabled=0;
	else
		AssaultShip.bDisabled=1;
		
	for ( i = 0; i < NUM_RAS_MISSIONS; ++i )
	{
		CompletedAssaultShip[i].DrawColor.R = 96;
		CompletedAssaultShip[i].DrawColor.G = 96;
		CompletedAssaultShip[i].DrawColor.B = 96;
		CompletedAssaultShip[i].DrawColor.A = 192;		
		
		if ( !RASAvailable() || !RASMissionAvailable(i) )
			CompletedAssaultShip[i].bHidden = 1;		
	}

	Kashyyyk.BackgroundBlurred.DrawColor.R = 96;
	Kashyyyk.BackgroundBlurred.DrawColor.G = 96;
	Kashyyyk.BackgroundBlurred.DrawColor.B = 96;	
	Kashyyyk.BackgroundFocused.DrawColor.R = 96;
	Kashyyyk.BackgroundFocused.DrawColor.G = 96;
	Kashyyyk.BackgroundFocused.DrawColor.B = 96;	
	Kashyyyk.Blurred.DrawColor.R = 96;
	Kashyyyk.Blurred.DrawColor.G = 96;
	Kashyyyk.Blurred.DrawColor.B = 96;		
	Kashyyyk.Blurred.DrawColor.A = 192;
	
	YYYNavigateLeft.bHidden = 1;	
	
	if ( !IsOnConsole() && YYYAvailable() )
		Kashyyyk.bDisabled=0;
	else
		Kashyyyk.bDisabled=1;

	for ( i = 0; i < NUM_YYY_MISSIONS; ++i )
	{
		CompletedKashyyyk[i].DrawColor.R = 96;
		CompletedKashyyyk[i].DrawColor.G = 96;
		CompletedKashyyyk[i].DrawColor.B = 96;
		CompletedKashyyyk[i].DrawColor.A = 192;
		
		if ( !YYYAvailable() || !YYYMissionAvailable(i) )
			CompletedKashyyyk[i].bHidden = 1;
	}

	// Clear the level list
	LevelList.Items.Remove(0, LevelList.Items.Length);	
	
	SelectedLevel = -1;	
	
	FocusOnNothing();
}

simulated function PopulateListGeonosis()
{
	local int i;
	
	if ( bDevMode )
	{
		for ( i = 0; i < DEV_NUM_GEO_SUB_MISSIONS; ++i )
		{
			if ( DEV_GEO_SubMissionAvailable[i] != 0 )
			{
				LevelList.Items[i].Focused.Text = DEV_GEO_SubMissionDescs[i];
				LevelList.Items[i].Blurred.Text = DEV_GEO_SubMissionDescs[i];
			}
		}
	}
	else
	{
		for ( i = 0; i < NUM_GEO_SUB_MISSIONS; ++i )
		{
			if ( GEO_SubMissionAvailable[i] != 0 )
			{
				LevelList.Items[i].Focused.Text = GEO_SubMissionDescs[i];
				LevelList.Items[i].Blurred.Text = GEO_SubMissionDescs[i];
			}
		}
	}
}

simulated function GeonosisSelected()
{
	local int i;
	
	UnSelectCampaign();
		
	Geonosis.BackgroundBlurred.DrawColor.R = 255;
	Geonosis.BackgroundBlurred.DrawColor.G = 255;
	Geonosis.BackgroundBlurred.DrawColor.B = 255;
	Geonosis.BackgroundBlurred.DrawColor.A = 255;
	Geonosis.BackgroundFocused.DrawColor.R = 255;
	Geonosis.BackgroundFocused.DrawColor.G = 255;
	Geonosis.BackgroundFocused.DrawColor.B = 255;
	Geonosis.BackgroundFocused.DrawColor.A = 255;
	Geonosis.Blurred.DrawColor.R = 255;
	Geonosis.Blurred.DrawColor.G = 255;
	Geonosis.Blurred.DrawColor.B = 255;
	Geonosis.Blurred.DrawColor.A = 255;
	Geonosis.bDisabled=1;

	for ( i = 0; i < NUM_GEO_MISSIONS; ++i )
	{
		CompletedGeonosis[i].DrawColor.R = 255;
		CompletedGeonosis[i].DrawColor.G = 255;
		CompletedGeonosis[i].DrawColor.B = 255;
		CompletedGeonosis[i].DrawColor.A = 255;		
	}
		
	// Populate the level list with levels from this campaign
	PopulateListGeonosis();
	
	SelectedCampaign = 0;
	
	LevelList.Position = 0;
	
    LayoutMenuStringList( LevelList );    
    UpdateScrollBar();
    
    Campaign.Text = Campaigns[0];
    
    if ( RASAvailable() )
		GEONavigateRight.bHidden = 0;
}

simulated function PopulateListAssaultShip()
{
	local int i;
	
	if ( bDevMode )
	{
		for ( i = 0; i < DEV_NUM_RAS_SUB_MISSIONS; ++i )
		{
			if ( DEV_RAS_SubMissionAvailable[i] != 0 )
			{
				LevelList.Items[i].Focused.Text = DEV_RAS_SubMissionDescs[i];
				LevelList.Items[i].Blurred.Text = DEV_RAS_SubMissionDescs[i];
			}
		}
	}
	else
	{
		for ( i = 0; i < NUM_RAS_SUB_MISSIONS; ++i )
		{
			if ( RAS_SubMissionAvailable[i] != 0 )
			{
				LevelList.Items[i].Focused.Text = RAS_SubMissionDescs[i];
				LevelList.Items[i].Blurred.Text = RAS_SubMissionDescs[i];
			}
		}
	}
}

simulated function AssaultShipSelected()
{
	local int i;
	
	UnSelectCampaign();
	
	AssaultShip.BackgroundBlurred.DrawColor.R = 255;
	AssaultShip.BackgroundBlurred.DrawColor.G = 255;
	AssaultShip.BackgroundBlurred.DrawColor.B = 255;
	AssaultShip.BackgroundBlurred.DrawColor.A = 255;
	AssaultShip.BackgroundFocused.DrawColor.R = 255;
	AssaultShip.BackgroundFocused.DrawColor.G = 255;
	AssaultShip.BackgroundFocused.DrawColor.B = 255;
	AssaultShip.BackgroundFocused.DrawColor.A = 255;
	AssaultShip.Blurred.DrawColor.R = 255;
	AssaultShip.Blurred.DrawColor.G = 255;
	AssaultShip.Blurred.DrawColor.B = 255;	
	AssaultShip.Blurred.DrawColor.A = 255;
	AssaultShip.bDisabled=1;	
	
	for ( i = 0; i < NUM_RAS_MISSIONS; ++i )
	{
		CompletedAssaultShip[i].DrawColor.R = 255;
		CompletedAssaultShip[i].DrawColor.G = 255;
		CompletedAssaultShip[i].DrawColor.B = 255;
		CompletedAssaultShip[i].DrawColor.A = 255;		
	}
	
	// Populate the level list with levels from this campaign
	PopulateListAssaultShip();

	SelectedCampaign = 1;	    
	
   	LevelList.Position = 0;
    	
    LayoutMenuStringList( LevelList );
    UpdateScrollBar();
    
    Campaign.Text=Campaigns[1];    
    
    if ( GEOAvailable() )
		RASNavigateLeft.bHidden = 0;
		
    if ( YYYAvailable() )
		RASNavigateRight.bHidden = 0;
}

simulated function PopulateListKashyyyk()
{
	local int i;
	
	if ( bDevMode )
	{
		for ( i = 0; i < DEV_NUM_YYY_SUB_MISSIONS; ++i )
		{
			if ( DEV_YYY_SubMissionAvailable[i] != 0 )
			{
				LevelList.Items[i].Focused.Text = DEV_YYY_SubMissionDescs[i];
				LevelList.Items[i].Blurred.Text = DEV_YYY_SubMissionDescs[i];
			}
		}
	}
	else
	{
		for ( i = 0; i < NUM_YYY_SUB_MISSIONS; ++i )
		{
			if ( YYY_SubMissionAvailable[i] != 0 )
			{
				LevelList.Items[i].Focused.Text = YYY_SubMissionDescs[i];
				LevelList.Items[i].Blurred.Text = YYY_SubMissionDescs[i];
			}
		}	
	}
}

simulated function KashyyykSelected()
{
	local int i;
	
	UnSelectCampaign();
	
	Kashyyyk.BackgroundBlurred.DrawColor.R = 255;
	Kashyyyk.BackgroundBlurred.DrawColor.G = 255;
	Kashyyyk.BackgroundBlurred.DrawColor.B = 255;	
	Kashyyyk.BackgroundBlurred.DrawColor.A = 255;	
	Kashyyyk.BackgroundFocused.DrawColor.R = 255;
	Kashyyyk.BackgroundFocused.DrawColor.G = 255;
	Kashyyyk.BackgroundFocused.DrawColor.B = 255;	
	Kashyyyk.BackgroundFocused.DrawColor.A = 255;	
	Kashyyyk.Blurred.DrawColor.R = 255;
	Kashyyyk.Blurred.DrawColor.G = 255;
	Kashyyyk.Blurred.DrawColor.B = 255;	
	Kashyyyk.Blurred.DrawColor.A = 255;
	Kashyyyk.bDisabled=1;
	
	for ( i = 0; i < NUM_YYY_MISSIONS; ++i )
	{
		CompletedKashyyyk[i].DrawColor.R = 255;
		CompletedKashyyyk[i].DrawColor.G = 255;
		CompletedKashyyyk[i].DrawColor.B = 255;
		CompletedKashyyyk[i].DrawColor.A = 255;		
	}
	
	// Populate the level list with levels from this campaign
	PopulateListKashyyyk();

	SelectedCampaign = 2;
	
	LevelList.Position = 0;
		 
    LayoutMenuStringList( LevelList );
    UpdateScrollBar();
    
    Campaign.Text=Campaigns[2];  
    
    if ( RASAvailable() )
		YYYNavigateLeft.bHidden = 0;  
}

simulated function ToggleDevMode()
{
	GetPlayerOwner().SetLevelProgress( "EPILOGUE" );
	GetPlayerOwner().SaveConfig();
	GetPlayerOwner().PropagateSettings();
	
	if ( !bDevMode )
	{
		bDevMode = True;
		
		GEO_MissionSubEnd[0]=4;
		GEO_MissionSubEnd[1]=7;
		GEO_MissionSubEnd[2]=11;	
		GEO_MissionSubEnd[3]=14;	
		RAS_MissionSubEnd[0]=3;
		RAS_MissionSubEnd[1]=8;
		RAS_MissionSubEnd[2]=11;
		RAS_MissionSubEnd[3]=15;
		YYY_MissionSubEnd[0]=4;	
		YYY_MissionSubEnd[1]=7;	
		YYY_MissionSubEnd[2]=12;	
		YYY_MissionSubEnd[3]=18;	
		YYY_MissionSubEnd[4]=21;
		YYY_MissionSubEnd[5]=24;
	}
	else
	{
		bDevMode = False;

		GEO_MissionSubEnd[0]=1;
		GEO_MissionSubEnd[1]=3;
		GEO_MissionSubEnd[2]=4;	
		GEO_MissionSubEnd[3]=5;	
		RAS_MissionSubEnd[0]=0;
		RAS_MissionSubEnd[1]=1;
		RAS_MissionSubEnd[2]=2;
		RAS_MissionSubEnd[3]=3;
		YYY_MissionSubEnd[0]=0;	
		YYY_MissionSubEnd[1]=1;	
		YYY_MissionSubEnd[2]=2;	
		YYY_MissionSubEnd[3]=3;	
		YYY_MissionSubEnd[4]=4;
		YYY_MissionSubEnd[5]=6;		
	}
		
	RefreshCurrent();
}

simulated function HandleInputBack()
{
	CloseMenu();
}

simulated function UpdateScrollBar()
{
    ScrollBar.Position = LevelList.Position;
    ScrollBar.Length = LevelList.Items.Length;
    ScrollBar.DisplayCount = LevelList.DisplayCount;
    LayoutMenuScrollBarEx( ScrollBar, PageUpArea, PageDownArea );
}

simulated function OnListScroll()
{
    LevelList.Position = ScrollBar.Position;
    LayoutMenuStringList( LevelList );
}

simulated function ScrollListTo( int NewPosition )
{
    if( ScrollBar.Length == 0 )
        return;

    NewPosition = Clamp( NewPosition, 0, Max( 0, ScrollBar.Length - ScrollBar.DisplayCount ) );

    if( ScrollBar.Position == NewPosition )
        return;
    
    ScrollBar.Position = NewPosition;
    
    LayoutMenuScrollBar( ScrollBar );    
}

simulated function OnListScrollUp()
{
	if ( !IsOnConsole() )
	{
		ClearListStickyFocus( LevelList );
		SelectedLevel = -1;
	}
		
    ScrollListTo( ScrollBar.Position - 1 );
}

simulated function OnListScrollDown()
{
	if ( !IsOnConsole() )
	{
		ClearListStickyFocus( LevelList );
		SelectedLevel = -1;
	}

    ScrollListTo( ScrollBar.Position + 1 );
}

simulated function OnListPageUp()
{
	if ( !IsOnConsole() )
	{
		ClearListStickyFocus( LevelList );
		SelectedLevel = -1;
	}

    ScrollListTo( ScrollBar.Position - ScrollBar.DisplayCount );
}

simulated function OnListPageDown()
{
	if ( !IsOnConsole() )
	{
		ClearListStickyFocus( LevelList );
		SelectedLevel = -1;
	}

    ScrollListTo( ScrollBar.Position + ScrollBar.DisplayCount );
}

simulated function LevelListOnSelect()
{
	SelectedLevel = GetFocusedItem();
	
	HighlightMissionBlip();
	
	if ( IsOnConsole() )
	{
		SelectCurrentLevel();
	}
}

simulated function LevelListOnFocus()
{
	SelectedLevel = GetFocusedItem();
	
	HighlightMissionBlip();
}

simulated function SelectCurrentLevel()
{
	local string level;
	if ( SelectedLevel >= 0 )
	{
		if ( SelectedCampaign == 0 )
		{
			if ( bDevMode )
				level = DEV_GEO_SubMissions[SelectedLevel];
			else
				level = GEO_SubMissions[SelectedLevel];
		}
		else if ( SelectedCampaign == 1 )
		{
			if ( bDevMode )
				level = DEV_RAS_SubMissions[SelectedLevel];
			else
				level = RAS_SubMissions[SelectedLevel];
		}
		else if ( SelectedCampaign == 2 )
		{
			if ( bDevMode )
				level = DEV_YYY_SubMissions[SelectedLevel];
			else
				level = YYY_SubMissions[SelectedLevel];
		}
		else
			return;
			
		GetPlayerOwner().ConsoleCommand("open " $ level);
	}
/**********************************	
	else
	{
		ToggleDevMode();
		CallMenuClass("XInterfaceCTMenus.CT_dev_LoadGameMenu");
	}
**********************************/
}

simulated function int GetFocusedItem()
{
    local int i;
    for (i=0; i<LevelList.Items.Length; i++)
        if (LevelList.Items[i].bHasFocus != 0 || LevelList.Items[i].bDrawFocused != 0)
            return i;
            
    if ( SelectedLevel >= 0 )
		return SelectedLevel;
		
    return -1;
}


simulated function bool HandleInputGamePad( String ButtonName )
{
	if ( !IsOnConsole() )
		return Super.HandleInputGamePad( ButtonName );

/**********************************
	if ( ButtonName ~= "Y" )
	{
		ToggleDevMode();
		CallMenuClass("XInterfaceCTMenus.CT_dev_LoadGameMenu");

	}
**********************************/

    return( Super.HandleInputGamePad( ButtonName ) );
}

simulated function HandleInputSelect()
{
	if ( IsOnConsole() )
	{
		Super.HandleInputSelect();
		return;
	}
	
	if ( AButton.bHasFocus == 0 && 
		 BButton.bHasFocus == 0 && 
		 Geonosis.bHasFocus == 0 &&
		 AssaultShip.bHasFocus == 0 &&
		 Kashyyyk.bHasFocus == 0 &&
		 GEONavigateRight.bHasFocus == 0 &&
		 RASNavigateLeft.bHasFocus == 0 &&
		 RASNavigateRight.bHasFocus == 0 &&
		 YYYNavigateLeft.bHasFocus == 0  )
	{
		SelectCurrentLevel();
	}
	else
	{
		Super.HandleInputSelect();
	}
}

simulated function HandleInputRight()
{
	local int NewCampaign;

	NewCampaign = SelectedCampaign + 1;	
	
	while ( NewCampaign <= 2 )
	{
		if ( NewCampaign == 1 && RASAvailable() )
		{
			FocusOnNothing();
			AssaultShipSelected();
			return;
		}
		else if ( NewCampaign == 2 && YYYAvailable() )
		{
			FocusOnNothing();
			KashyyykSelected();
			return;
		}
		// NOTE we can't get to GEO going right
		
		++NewCampaign;
	}

	// No dice		
	GetPlayerOwner().PlaySound(SoundOnError);
}


simulated function HandleInputLeft()
{
	local int NewCampaign;
	
	NewCampaign = SelectedCampaign - 1;	
	
	while ( NewCampaign >= 0 )
	{
		if ( NewCampaign == 0 && GEOAvailable() )
		{
			FocusOnNothing();
			GeonosisSelected();
			return;
		}
		else if ( NewCampaign == 1 && RASAvailable() )
		{
			FocusOnNothing();
			AssaultShipSelected();
			return;
		}
		// NOTE we can't get to YYY going left
		
		--NewCampaign;
	}

	// No dice		
	GetPlayerOwner().PlaySound(SoundOnError);
}


simulated function HandleInputDown()
{
	local int i;
	
	if ( IsOnConsole() )
	{
		Super.HandleInputDown();
		return;
	}
	
	if ( ( BButton.bHasFocus != 0 ) || 
		 ( AButton.bHasFocus != 0 ) )
	{
		Super.HandleInputDown();
		return;
	}
	
	if ( SelectedLevel == -1 )
	{
		ClearListStickyFocus( LevelList );			
		ScrollListTo( 0 );
		FocusOnWidget( LevelList.Items[0] );
		SelectedLevel = 0;
		
		return;
	}
	
	for ( i = 0; i < LevelList.Items.Length; ++i )
	{
		if ( LevelList.Items[i].bDrawFocused != 0 )
		{
			if ( i == ( LevelList.Items.Length - 1 ) )
			{
				SelectedLevel = -1;
				ClearListStickyFocus( LevelList );
				FocusOnWidget( AButton );
			}
			else
			{
				ClearListStickyFocus( LevelList );			
				ScrollListTo( i + 1 );
				FocusOnWidget( LevelList.Items[i + 1] );
				SelectedLevel = i + 1;
			}
			
			break;
		}
	}
}


simulated function HandleInputUp()
{
	local int i;
	
	if ( IsOnConsole() )
	{
		Super.HandleInputUp();
		return;
	}
	
	if ( ( BButton.bHasFocus != 0 ) || 
		 ( AButton.bHasFocus != 0 ) )
	{
		ClearListStickyFocus( LevelList );			
		ScrollListTo( 0 );
		FocusOnWidget( LevelList.Items[0] );
		SelectedLevel = 0;
		
		return;
	}
	
	for ( i = 0; i < LevelList.Items.Length; ++i )
	{
		if ( LevelList.Items[i].bDrawFocused != 0 )
		{
			if ( i != 0 )
			{
				ClearListStickyFocus( LevelList );			
				ScrollListTo( i - 1 );
				FocusOnWidget( LevelList.Items[i - 1] );
				SelectedLevel = i - 1;
			}
			
			break;
		}
	}
}


defaultproperties
{
     KaminoBorder=(DrawColor=(B=96,G=96,R=96,A=255),PosX=0.1375,PosY=0.16,ScaleX=0.125,ScaleY=0.1666,Style="PlanetBorderStyle")
     Kamino=(WidgetTexture=Texture'GUIContent.Menu.CT_Kamino',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.1375,PosY=0.16)
     Geonosis=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_Geonosis',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.32625,PosY=0.238333),Focused=(DrawColor=(B=255,G=255,R=255,A=255)),BackgroundBlurred=(WidgetTexture=Texture'GUIContent.Menu.CT_SelectionRing',DrawColor=(B=96,G=96,R=96,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.32625,PosY=0.238333,ScaleX=0.22125,ScaleY=0.295,ScaleMode=MSCM_Fit),OnSelect="GeonosisSelected")
     AssaultShip=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_RAS',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.565,PosY=0.23,Pass=1),Focused=(DrawColor=(B=255,G=255,R=255,A=255)),BackgroundBlurred=(WidgetTexture=Texture'GUIContent.Menu.CT_SelectionRing',DrawColor=(B=96,G=96,R=96,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.565,PosY=0.23,ScaleX=0.2325,ScaleY=0.31,ScaleMode=MSCM_Fit,Pass=2),OnSelect="AssaultShipSelected")
     Kashyyyk=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_Kashyyyk',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.82875,PosY=0.215),Focused=(DrawColor=(B=255,G=255,R=255,A=255)),BackgroundBlurred=(WidgetTexture=Texture'GUIContent.Menu.CT_SelectionRing',DrawColor=(B=96,G=96,R=96,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.82875,PosY=0.215,ScaleX=0.26375,ScaleY=0.351666,ScaleMode=MSCM_Fit),OnSelect="KashyyykSelected")
     CompletedGeonosis(0)=(WidgetTexture=Texture'GUIContent.Menu.CT_MissionBlip',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.2825,PosY=0.22666)
     CompletedGeonosis(1)=(PosX=0.315,PosY=0.19333)
     CompletedGeonosis(2)=(PosX=0.33625,PosY=0.24333)
     CompletedGeonosis(3)=(PosX=0.3525,PosY=0.29)
     GEO_MissionSubEnd(0)=1
     GEO_MissionSubEnd(1)=3
     GEO_MissionSubEnd(2)=4
     GEO_MissionSubEnd(3)=5
     CompletedAssaultShip(0)=(WidgetTexture=Texture'GUIContent.Menu.CT_MissionBlip',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.53375,PosY=0.23666)
     CompletedAssaultShip(1)=(PosX=0.51,PosY=0.195)
     CompletedAssaultShip(2)=(PosX=0.5675,PosY=0.19)
     CompletedAssaultShip(3)=(PosX=0.61375,PosY=0.261666)
     RAS_MissionSubEnd(1)=1
     RAS_MissionSubEnd(2)=2
     RAS_MissionSubEnd(3)=3
     CompletedKashyyyk(0)=(WidgetTexture=Texture'GUIContent.Menu.CT_MissionBlip',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.86375,PosY=0.141666)
     CompletedKashyyyk(1)=(WidgetTexture=Texture'GUIContent.Menu.CT_MissionBlip',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.7875,PosY=0.18666)
     CompletedKashyyyk(2)=(PosX=0.775,PosY=0.255)
     CompletedKashyyyk(3)=(PosX=0.81875,PosY=0.291666)
     CompletedKashyyyk(4)=(PosX=0.8675,PosY=0.281666)
     YYY_MissionSubEnd(1)=1
     YYY_MissionSubEnd(2)=2
     YYY_MissionSubEnd(3)=3
     YYY_MissionSubEnd(4)=6
     GEONavigateRight=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowRight',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.446875,PosY=0.3666,ScaleX=0.75,ScaleY=0.75),Focused=(ScaleX=0.9,ScaleY=0.9),OnSelect="AssaultShipSelected")
     RASNavigateLeft=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowLeft',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.446875,PosY=0.3666,ScaleX=0.75,ScaleY=0.75),Focused=(ScaleX=0.9,ScaleY=0.9),OnSelect="GeonosisSelected")
     RASNavigateRight=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowRight',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.690625,PosY=0.3666,ScaleX=0.75,ScaleY=0.75),Focused=(ScaleX=0.9,ScaleY=0.9),OnSelect="KashyyykSelected")
     YYYNavigateLeft=(Blurred=(WidgetTexture=Texture'GUIContent.Menu.CT_ArrowLeft',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.690625,PosY=0.3666,ScaleX=0.75,ScaleY=0.75),Focused=(ScaleX=0.9,ScaleY=0.9),OnSelect="AssaultShipSelected")
     LabelBackground=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=192,G=192,R=192,A=32),DrawPivot=DP_MiddleMiddle,PosX=0.3,PosY=0.45625,ScaleX=0.49275,ScaleY=0.0617854,ScaleMode=MSCM_FitStretch)
     Label=(Text="CAMPAIGN MISSIONS",DrawPivot=DP_MiddleMiddle,PosX=0.3,PosY=0.45625,ScaleX=1.1,ScaleY=1.1,Style="LabelText")
     CampaignBackground=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=192,G=192,R=192,A=32),DrawPivot=DP_MiddleMiddle,PosX=0.748438,PosY=0.45625,ScaleX=0.365,ScaleY=0.0617854,ScaleMode=MSCM_FitStretch)
     Campaign=(DrawPivot=DP_MiddleMiddle,PosX=0.748438,PosY=0.45625,ScaleX=1.1,ScaleY=1.1,Style="LabelText")
     Campaigns(0)="GEONOSIS"
     Campaigns(1)="ASSAULT SHIP"
     Campaigns(2)="KASHYYYK"
     Border=(PosX=0.5,PosY=0.658333,ScaleX=0.807813,ScaleY=0.31875,ScaleMode=MSCM_FitStretch,Style="BorderStyle1")
     DEV_GEO_SubMissions(0)="PRO"
     DEV_GEO_SubMissions(1)="GEO_01Briefing"
     DEV_GEO_SubMissions(2)="GEO_01A"
     DEV_GEO_SubMissions(3)="GEO_01B"
     DEV_GEO_SubMissions(4)="GEO_01C"
     DEV_GEO_SubMissions(5)="GEO_03A"
     DEV_GEO_SubMissions(6)="GEO_03C"
     DEV_GEO_SubMissions(7)="GEO_03D"
     DEV_GEO_SubMissions(8)="GEO_04A"
     DEV_GEO_SubMissions(9)="GEO_04B"
     DEV_GEO_SubMissions(10)="GEO_04C"
     DEV_GEO_SubMissions(11)="GEO_04D"
     DEV_GEO_SubMissions(12)="GEO_05A"
     DEV_GEO_SubMissions(13)="GEO_05B"
     DEV_GEO_SubMissions(14)="GEO_05C"
     DEV_GEO_SubMissionDescs(0)="PROLOGUE"
     DEV_GEO_SubMissionDescs(1)="GEO_01Briefing"
     DEV_GEO_SubMissionDescs(2)="GEO_01A"
     DEV_GEO_SubMissionDescs(3)="GEO_01B"
     DEV_GEO_SubMissionDescs(4)="GEO_01C"
     DEV_GEO_SubMissionDescs(5)="GEO_03A"
     DEV_GEO_SubMissionDescs(6)="GEO_03C"
     DEV_GEO_SubMissionDescs(7)="GEO_03D"
     DEV_GEO_SubMissionDescs(8)="GEO_04A"
     DEV_GEO_SubMissionDescs(9)="GEO_04B"
     DEV_GEO_SubMissionDescs(10)="GEO_04C"
     DEV_GEO_SubMissionDescs(11)="GEO_04D"
     DEV_GEO_SubMissionDescs(12)="GEO_05A"
     DEV_GEO_SubMissionDescs(13)="GEO_05B"
     DEV_GEO_SubMissionDescs(14)="GEO_05C"
     DEV_RAS_SubMissions(0)="RAS_01Briefing"
     DEV_RAS_SubMissions(1)="RAS_01A"
     DEV_RAS_SubMissions(2)="RAS_01B"
     DEV_RAS_SubMissions(3)="RAS_01C"
     DEV_RAS_SubMissions(4)="RAS_02A"
     DEV_RAS_SubMissions(5)="RAS_02B"
     DEV_RAS_SubMissions(6)="RAS_02C"
     DEV_RAS_SubMissions(7)="RAS_02D"
     DEV_RAS_SubMissions(8)="RAS_02E"
     DEV_RAS_SubMissions(9)="RAS_03A"
     DEV_RAS_SubMissions(10)="RAS_03B"
     DEV_RAS_SubMissions(11)="RAS_03C"
     DEV_RAS_SubMissions(12)="RAS_04A"
     DEV_RAS_SubMissions(13)="RAS_04B"
     DEV_RAS_SubMissions(14)="RAS_04C"
     DEV_RAS_SubMissions(15)="RAS_04D"
     DEV_RAS_SubMissionDescs(0)="RAS_01Briefing"
     DEV_RAS_SubMissionDescs(1)="RAS_01A"
     DEV_RAS_SubMissionDescs(2)="RAS_01B"
     DEV_RAS_SubMissionDescs(3)="RAS_01C"
     DEV_RAS_SubMissionDescs(4)="RAS_02A"
     DEV_RAS_SubMissionDescs(5)="RAS_02B"
     DEV_RAS_SubMissionDescs(6)="RAS_02C"
     DEV_RAS_SubMissionDescs(7)="RAS_02D"
     DEV_RAS_SubMissionDescs(8)="RAS_02E"
     DEV_RAS_SubMissionDescs(9)="RAS_03A"
     DEV_RAS_SubMissionDescs(10)="RAS_03B"
     DEV_RAS_SubMissionDescs(11)="RAS_03C"
     DEV_RAS_SubMissionDescs(12)="RAS_04A"
     DEV_RAS_SubMissionDescs(13)="RAS_04B"
     DEV_RAS_SubMissionDescs(14)="RAS_04C"
     DEV_RAS_SubMissionDescs(15)="RAS_04D"
     DEV_YYY_SubMissions(0)="YYY_01Briefing"
     DEV_YYY_SubMissions(1)="YYY_01B"
     DEV_YYY_SubMissions(2)="YYY_01C"
     DEV_YYY_SubMissions(3)="YYY_01D"
     DEV_YYY_SubMissions(4)="YYY_01E"
     DEV_YYY_SubMissions(5)="YYY_35A"
     DEV_YYY_SubMissions(6)="YYY_35B"
     DEV_YYY_SubMissions(7)="YYY_35C"
     DEV_YYY_SubMissions(8)="YYY_04A"
     DEV_YYY_SubMissions(9)="YYY_04B"
     DEV_YYY_SubMissions(10)="YYY_04C"
     DEV_YYY_SubMissions(11)="YYY_04E"
     DEV_YYY_SubMissions(12)="YYY_04F"
     DEV_YYY_SubMissions(13)="YYY_05A"
     DEV_YYY_SubMissions(14)="YYY_05B"
     DEV_YYY_SubMissions(15)="YYY_05C"
     DEV_YYY_SubMissions(16)="YYY_05D"
     DEV_YYY_SubMissions(17)="YYY_05E"
     DEV_YYY_SubMissions(18)="YYY_05F"
     DEV_YYY_SubMissions(19)="YYY_06A"
     DEV_YYY_SubMissions(20)="YYY_06B"
     DEV_YYY_SubMissions(21)="YYY_06C"
     DEV_YYY_SubMissions(22)="YYY07Briefing"
     DEV_YYY_SubMissions(23)="YYY_06D"
     DEV_YYY_SubMissions(24)="EPILOGUE"
     DEV_YYY_SubMissionDescs(0)="YYY_01Briefing"
     DEV_YYY_SubMissionDescs(1)="YYY_01B"
     DEV_YYY_SubMissionDescs(2)="YYY_01C"
     DEV_YYY_SubMissionDescs(3)="YYY_01D"
     DEV_YYY_SubMissionDescs(4)="YYY_01E"
     DEV_YYY_SubMissionDescs(5)="YYY_35A"
     DEV_YYY_SubMissionDescs(6)="YYY_35B"
     DEV_YYY_SubMissionDescs(7)="YYY_35C"
     DEV_YYY_SubMissionDescs(8)="YYY_04A"
     DEV_YYY_SubMissionDescs(9)="YYY_04B"
     DEV_YYY_SubMissionDescs(10)="YYY_04C"
     DEV_YYY_SubMissionDescs(11)="YYY_04E"
     DEV_YYY_SubMissionDescs(12)="YYY_04F"
     DEV_YYY_SubMissionDescs(13)="YYY_05A"
     DEV_YYY_SubMissionDescs(14)="YYY_05B"
     DEV_YYY_SubMissionDescs(15)="YYY_05C"
     DEV_YYY_SubMissionDescs(16)="YYY_05D"
     DEV_YYY_SubMissionDescs(17)="YYY_05E"
     DEV_YYY_SubMissionDescs(18)="YYY_05F"
     DEV_YYY_SubMissionDescs(19)="YYY_06A"
     DEV_YYY_SubMissionDescs(20)="YYY_06B"
     DEV_YYY_SubMissionDescs(21)="YYY_06C"
     DEV_YYY_SubMissionDescs(22)="YYY07Briefing"
     DEV_YYY_SubMissionDescs(23)="YYY_06D"
     DEV_YYY_SubMissionDescs(24)="EPILOGUE"
     GEO_SubMissions(0)="PRO"
     GEO_SubMissions(1)="GEO_01Briefing"
     GEO_SubMissions(2)="GEO_03A"
     GEO_SubMissions(3)="GEO_03D"
     GEO_SubMissions(4)="GEO_04A"
     GEO_SubMissions(5)="GEO_05A"
     GEO_SubMissionDescs(0)="PROLOGUE"
     GEO_SubMissionDescs(1)="EXTREME PREJUDICE"
     GEO_SubMissionDescs(2)="INFILTRATE THE DROID FOUNDRY"
     GEO_SubMissionDescs(3)="DESTROY THE FACTORY"
     GEO_SubMissionDescs(4)="ADVANCE TO THE CORE SHIP"
     GEO_SubMissionDescs(5)="INFILTRATION OF THE CORE SHIP"
     RAS_SubMissions(0)="RAS_01Briefing"
     RAS_SubMissions(1)="RAS_02A"
     RAS_SubMissions(2)="RAS_03A"
     RAS_SubMissions(3)="RAS_04A"
     RAS_SubMissionDescs(0)="GHOST SHIP RECON"
     RAS_SubMissionDescs(1)="RESCUE THE SQUAD"
     RAS_SubMissionDescs(2)="ATTACK OF THE CLONES"
     RAS_SubMissionDescs(3)="SAVING THE SHIP"
     YYY_SubMissions(0)="YYY_01Briefing"
     YYY_SubMissions(1)="YYY_35A"
     YYY_SubMissions(2)="YYY_04A"
     YYY_SubMissions(3)="YYY_05A"
     YYY_SubMissions(4)="YYY_06A"
     YYY_SubMissions(5)="YYY07Briefing"
     YYY_SubMissions(6)="EPILOGUE"
     YYY_SubMissionDescs(0)="THE RESCUE OF TARFFUL"
     YYY_SubMissionDescs(1)="OBLITERATE THE OUTPOST"
     YYY_SubMissionDescs(2)="THE BRIDGE AT KACHIRHO"
     YYY_SubMissionDescs(3)="THE WOOKIEE RESISTANCE"
     YYY_SubMissionDescs(4)="SEARCH AND DESTROY"
     YYY_SubMissionDescs(5)="THE FINAL STRIKE"
     YYY_SubMissionDescs(6)="EPILOGUE"
     LevelList=(Template=(Blurred=(MaxSizeX=0.65),BackgroundBlurred=(ScaleX=0.7),BackgroundFocused=(ScaleX=0.7),OnFocus="LevelListOnFocus",OnSelect="LevelListOnSelect",OnDoubleClick="SelectCurrentLevel"),PosX1=0.5,PosY1=0.545833,PosX2=0.5,PosY2=0.770833,DisplayCount=6,OnScroll="UpdateScrollBar",Pass=3,Style="ButtonList")
     ScrollBar=(PosX1=0.86875,PosY1=0.564583,PosX2=0.86875,PosY2=0.747917,OnScroll="OnListScroll",Pass=2,Style="VerticalScrollBar")
     ScrollBarArrowUp=(Blurred=(DrawPivot=DP_MiddleMiddle,PosX=0.86875,PosY=0.547917),OnSelect="OnListScrollUp",Pass=2,Style="VerticalScrollBarArrowUp")
     ScrollBarArrowDown=(Blurred=(DrawPivot=DP_MiddleMiddle,PosX=0.86875,PosY=0.770833),OnSelect="OnListScrollDown",Pass=2,Style="VerticalScrollBarArrowDown")
     ScrollArea=(OnScrollPageUp="OnListPageUp",OnScrollLineUp="OnListScrollUp",OnScrollLineDown="OnListScrollDown",OnScrollPageDown="OnListPageDown",X1=0.117188,Y1=0.5125,X2=0.889063,Y2=0.810417)
     PageUpArea=(bIgnoreController=1,OnSelect="OnListPageUp",Pass=2)
     PageDownArea=(bIgnoreController=1,OnSelect="OnListPageDown",Pass=2)
     SelectedLevel=-1
     BlipPulseTime=0.5
     RingPulseTime=1
     AButton=(OnSelect="SelectCurrentLevel",bHidden=0)
     Background=(WidgetTexture=Texture'GUIContent.Menu.CT_MainMenuGraphics',Style="FullScreen")
     ModulateRate=1
}

