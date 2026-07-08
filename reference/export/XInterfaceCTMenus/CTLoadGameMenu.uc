class CTLoadGameMenu extends MenuTemplateTitledBXA;

var() MenuSprite		KaminoBorder;
var() MenuSprite		Kamino;
var() MenuSprite		GeonosisBorder;
var() MenuSprite		Geonosis;
var() MenuSprite		AssaultShipBorder;
var() MenuSprite		AssaultShip;
var() MenuSprite		KashyyykBorder;
var() MenuSprite		Kashyyyk;

var() MenuSprite		LabelBackground;
var() MenuText			Label;

var() int				SelectedCampaign;

var() MenuSprite		Border;

var() MenuStringList    SaveList;

var() MenuScrollBar     ScrollBar;
var() MenuButtonSprite  ScrollBarArrowUp, ScrollBarArrowDown;

var() MenuScrollArea    ScrollArea;
var() MenuActiveWidget  PageUpArea, PageDownArea;

var() int				SelectedSave;

var() localized string  StringDeleteConfirm;
var() localized string  StringDeleteConfirmEnd;
var() localized String	LoadConfirm;

var() bool				bDeleteSelected;
var() bool				bLoadSelected;
var() bool				bLowStorage;

var() string			SelectedSaveName;

const DATETIME_LENGTH = 20;

var() localized String	DamagedSave;

var() localized String QuickSaveName;
var() localized String AutoSaveName;

simulated function Init( String Args )
{
	Super.Init( Args );

    if ( !IsOnConsole() ) 
    {
		SaveList.Template.bNoMouseOverFocus = 1;
		SaveList.Template.bStickyDrawFocus = 1;
	}

	Refresh();
}

simulated function Tick( float ElapsedTime )
{
	local int i;
	
	Super.Tick( ElapsedTime );
	
	if ( !IsOnConsole() )
	{
		// Let's check to make sure two things aren't highlighted in the save list
		for ( i = 0; i < SaveList.Items.Length; ++i )
		{
			if ( SaveList.Items[i].bHasFocus != 0 || SaveList.Items[i].bDrawFocused != 0 )
			{
				if ( SelectedSave != i )
				{
					// We've gone foobar...clear the list focus
					ClearListStickyFocus( SaveList );
					SelectedSave = -1;
					return;
				}
			}
		}
	}	
}

simulated function SortSaveGames( out array<string> SaveGames, out array<string> DateTimes )
{
	local int i;
	local int j;
	local string temp;
	local string profileName;
	local string prefix;
	local string displayName;

	profileName = GetPlayerOwner().GetCurrentProfileName();
	prefix = profileName $ "_";
	
	// Put the auto save in slot 0 and the quicksave in slot 1
	for ( i = 0; i < SaveGames.Length; ++i )
	{
		displayName = Right(SaveGames[i], Len(SaveGames[i]) - Len(profileName) - 1);
		
		if ( ( displayName == AutoSaveName ) && ( SaveGames.Length > 1 ) )
		{
			temp = SaveGames[i];
			SaveGames[i] = SaveGames[0];
			SaveGames[0] = temp;
			
			temp = DateTimes[i];
			DateTimes[i] = DateTimes[0];
			DateTimes[0] = temp;
		}
		else if ( ( displayName == QuickSaveName ) && ( SaveGames.Length > 1 ) )
		{
			temp = SaveGames[i];
			SaveGames[i] = SaveGames[1];
			SaveGames[1] = temp;
			
			temp = DateTimes[i];
			DateTimes[i] = DateTimes[1];
			DateTimes[1] = temp;			
		}
	}

	for ( i = 2; i < SaveGames.Length - 1; ++i )
	{
		for ( j = 2; j < SaveGames.Length - 1; ++j )
		{
			if ( SaveGames[j] > SaveGames[j + 1] )
			{
				temp = SaveGames[j];
				SaveGames[j] = SaveGames[j + 1];
				SaveGames[j + 1] = temp;
				
				temp = DateTimes[j];
				DateTimes[j] = DateTimes[j + 1];
				DateTimes[j + 1] = temp;								
			}
		}
	}
}

simulated function Refresh()
{
	local array<string> SaveGames;
	local array<string> DateTimes;
	local int i;
	local string profileName;
	local string prefix;
	local string displayName;

	FocusOnNothing();
	
	// Clear the saved games list
	SaveList.Items.Remove(0, SaveList.Items.Length);	
	
	SelectedSave = -1;	
	
	profileName = GetPlayerOwner().GetCurrentProfileName();
	prefix = profileName $ "_";

	PlayerController(Owner).GetSaveGames( prefix, SaveGames, DateTimes );

	SortSaveGames( SaveGames, DateTimes );
		
	for ( i = 0; i < SaveGames.Length; ++i )
	{
		// Strip the profile name
		displayName = Right(SaveGames[i], Len(SaveGames[i]) - Len(profileName) - 1);
		
		// Add the date/time
		displayName = displayName $ " " $ DateTimes[i];
		
		SaveList.Items[i].Focused.Text = displayName;
		SaveList.Items[i].Blurred.Text = displayName;
	}

    LayoutMenuStringList( SaveList );    
    UpdateScrollBar();	
    
    SelectedSave = GetFocusedItem();
}

simulated function HandleInputBack()
{
	if ( bDeleteSelected || bLoadSelected || bLowStorage )
		return;

	CloseMenu();
}

simulated function UpdateScrollBar()
{
    ScrollBar.Position = SaveList.Position;
    ScrollBar.Length = SaveList.Items.Length;
    ScrollBar.DisplayCount = SaveList.DisplayCount;
    LayoutMenuScrollBarEx( ScrollBar, PageUpArea, PageDownArea );
}

simulated function OnListScroll()
{
	if ( bDeleteSelected || bLoadSelected || bLowStorage )
		return;

    SaveList.Position = ScrollBar.Position;
    LayoutMenuStringList( SaveList );
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
	if ( bDeleteSelected || bLoadSelected || bLowStorage )
		return;

	if ( !IsOnConsole() )
	{
		ClearListStickyFocus( SaveList );
		SelectedSave = -1;
	}

    ScrollListTo( ScrollBar.Position - 1 );
}

simulated function OnListScrollDown()
{
	if ( bDeleteSelected || bLoadSelected || bLowStorage )
		return;

	if ( !IsOnConsole() )
	{
		ClearListStickyFocus( SaveList );
		SelectedSave = -1;
	}

    ScrollListTo( ScrollBar.Position + 1 );
}

simulated function OnListPageUp()
{
	if ( bDeleteSelected || bLoadSelected || bLowStorage )
		return;

	if ( !IsOnConsole() )
	{
		ClearListStickyFocus( SaveList );
		SelectedSave = -1;
	}

    ScrollListTo( ScrollBar.Position - ScrollBar.DisplayCount );
}

simulated function OnListPageDown()
{
	if ( bDeleteSelected || bLoadSelected || bLowStorage )
		return;

	if ( !IsOnConsole() )
	{
		ClearListStickyFocus( SaveList );
		SelectedSave = -1;
	}
	
    ScrollListTo( ScrollBar.Position + ScrollBar.DisplayCount );
}

simulated function SaveListOnSelect()
{
	if ( bDeleteSelected || bLoadSelected || bLowStorage )
		return;

	SelectedSave = GetFocusedItem();
	
	if ( IsOnConsole() )
	{
		SelectCurrentSave();
	}
}

simulated function SaveListOnFocus()
{
    //ShowProfileDetails( GetFocusedItem() );
}

simulated function SelectCurrentSave()
{
	local string saveName;
	local string currentMapName;
	
	if ( bDeleteSelected || bLoadSelected || bLowStorage )
		return;
	
	if ( SelectedSave >= 0 )
	{
		saveName = SaveList.Items[SelectedSave].Focused.Text;
		
		// Strip the date/time
		saveName = Left(saveName, Len(SaveName) - DATETIME_LENGTH); 
		
		// Add the profile name
		saveName = GetPlayerOwner().GetCurrentProfileName() $ "_" $ saveName;

		SelectedSaveName = saveName;
		
		if ( IsOnConsole() )
		{
			// Check for hard disc space
			if ( !GetPlayerOwner().HaveAdequateDiscSpace( True, True ) )
			{
				bLowStorage = True;
				OverlayMenuClass("XInterfaceCommon.MenuLowStorage", "");
				return;
			}
		}	
		
		GetPlayerOwner().GetCurrentMapName( currentMapName );
		currentMapName = Caps( currentMapName );
		// Strip any extension off the level name
		if ( Caps(Right(currentMapName, 4)) == ".CTM" )
			currentMapName = Left(currentMapName, Len(currentMapName) - 4);
		
		if ( currentMapName != "ENTRY" )
		{
			// We're in a level, so get confirmation
			bLoadSelected = True;
		    OverlayMenuClass( "XInterface.MenuQuestionYesNo", MakeQuotedString(LoadConfirm) );
		}
		else
		{
			if ( GetPlayerOwner().VerifySaveGame( saveName ) )
			{
				GetPlayerOwner().LoadGame(saveName);
			}
			else
			{
				OverlayMenuClass( "XInterfaceCommon.MenuWarning", MakeQuotedString(saveName $ DamagedSave) );
			}
		}
	}
}

simulated function int GetFocusedItem()
{
    local int i;
    for (i=0; i<SaveList.Items.Length; i++)
        if (SaveList.Items[i].bHasFocus != 0 || SaveList.Items[i].bDrawFocused != 0)
            return i;
            
    if ( SelectedSave >= 0 )
		return SelectedSave;
		
    return -1;
}

simulated function OnXButton()
{
	if ( bDeleteSelected || bLoadSelected || bLowStorage )
		return;

	SelectedSave = GetFocusedItem();
	
	if ( SelectedSave >= 0 )
	{
		bDeleteSelected = True;
		OverlayMenuClass("XInterface.MenuQuestionYesNo", 
			MakeQuotedString(StringDeleteConfirm $ SaveList.Items[SelectedSave].Focused.Text $ StringDeleteConfirmEnd));
	}
}

simulated function bool MenuClosed( Menu closingMenu )
{
    local MenuQuestionYesNo questionMenu;
    local MenuLowStorage lowStorageMenu;
    local string saveName;

	if ( !bDeleteSelected && !bLoadSelected && !bLowStorage )
		return False;

    questionMenu = MenuQuestionYesNo( closingMenu );
    lowStorageMenu = MenuLowStorage( closingMenu );
    if( questionMenu != None )
    {
        if( questionMenu.bSelectedYes )
        {
			if ( bDeleteSelected )
			{
				bDeleteSelected = False;
				saveName = GetPlayerOwner().GetCurrentProfileName() $ "_" $ SaveList.Items[SelectedSave].Focused.Text;
				saveName = Left( saveName, Len(saveName) - DATETIME_LENGTH );
				GetPlayerOwner().DeleteSaveGame( saveName );
				
				Refresh();
			}
			else if ( bLoadSelected )
			{
				if ( GetPlayerOwner().VerifySaveGame( SelectedSaveName ) )
				{
					GetPlayerOwner().LoadGame(SelectedSaveName);			
					SelectedSaveName = "";
				}
				else
				{
					OverlayMenuClass( "XInterfaceCommon.MenuWarning", MakeQuotedString(SelectedSaveName $ DamagedSave) );
				}
				
				bDeleteSelected = False;
				bLoadSelected = False;
				SelectedSaveName = "";				
			}
        }
        else
        {
			bDeleteSelected = False;
			bLoadSelected = False;
			SelectedSaveName = "";
        }
        
        return true;
    }
    else if ( lowStorageMenu != None )
    {
		if ( bLowStorage )
		{
			bLowStorage = False;
			GetPlayerOwner().LoadGame(SelectedSaveName);			
			SelectedSaveName = "";			
		}
		
		return true;
    }
    else if ( CTControllerDisconnect( closingMenu ) != None )
    {
		// In case they managed to unplug the controller
		// before the confirmation screen came up.
		bDeleteSelected = False;
		bLoadSelected = False;
		
		return true;
    }

    return false;
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
		 XButton.bHasFocus == 0 )
	{
		SelectCurrentSave();
	}
	else
	{
		Super.HandleInputSelect();
	}
}

simulated function HandleInputDown()
{
	local int i;
	
	if ( bDeleteSelected || bLoadSelected || bLowStorage )
		return;

	if ( IsOnConsole() )
	{
		Super.HandleInputDown();
		return;
	}
	
	if ( ( BButton.bHasFocus != 0 ) || 
		 ( XButton.bHasFocus != 0 ) ||
		 ( AButton.bHasFocus != 0 ) )
	{
		Super.HandleInputDown();
		return;
	}
	
	if ( SelectedSave == -1 )
	{
		ClearListStickyFocus( SaveList );			
		ScrollListTo( 0 );
		FocusOnWidget( SaveList.Items[0] );
		SelectedSave = 0;
		
		return;
	}
	
	for ( i = 0; i < SaveList.Items.Length; ++i )
	{
		if ( SaveList.Items[i].bDrawFocused != 0 )
		{
			if ( i == ( SaveList.Items.Length - 1 ) )
			{
				SelectedSave = -1;
				ClearListStickyFocus( SaveList );
				FocusOnWidget( AButton );
			}
			else
			{
				ClearListStickyFocus( SaveList );			
				ScrollListTo( i + 1 );
				FocusOnWidget( SaveList.Items[i + 1] );
				SelectedSave = i + 1;
			}
			
			break;
		}
	}
}


simulated function HandleInputUp()
{
	local int i;

	if ( bDeleteSelected || bLoadSelected || bLowStorage )
		return;
	
	if ( IsOnConsole() )
	{
		Super.HandleInputUp();
		return;
	}
	
	if ( ( BButton.bHasFocus != 0 ) ||
		 ( XButton.bHasFocus != 0 ) || 
		 ( AButton.bHasFocus != 0 ) )
	{
		ClearListStickyFocus( SaveList );			
		ScrollListTo( 0 );
		FocusOnWidget( SaveList.Items[0] );
		SelectedSave = 0;
		
		return;
	}

	for ( i = 0; i < SaveList.Items.Length; ++i )
	{
		if ( SaveList.Items[i].bDrawFocused != 0 )
		{
			if ( i != 0 )
			{
				ClearListStickyFocus( SaveList );			
				ScrollListTo( i - 1 );
				FocusOnWidget( SaveList.Items[i - 1] );
				SelectedSave = i - 1;
			}
			
			break;
		}
	}
}


defaultproperties
{
     KaminoBorder=(DrawColor=(B=96,G=96,R=96,A=255),PosX=0.1375,PosY=0.16,ScaleX=0.125,ScaleY=0.1666,Style="PlanetBorderStyle")
     Kamino=(WidgetTexture=Texture'GUIContent.Menu.CT_Kamino',DrawColor=(B=128,G=128,R=128,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.1375,PosY=0.16)
     GeonosisBorder=(DrawColor=(B=255,G=255,R=255,A=255),PosX=0.32625,PosY=0.238333,ScaleX=0.22125,ScaleY=0.295,Style="PlanetBorderStyle")
     Geonosis=(WidgetTexture=Texture'GUIContent.Menu.CT_Geonosis',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.32625,PosY=0.238333)
     AssaultShipBorder=(DrawColor=(B=255,G=255,R=255,A=255),PosX=0.565,PosY=0.23,ScaleX=0.2325,ScaleY=0.31,Pass=2,Style="PlanetBorderStyle")
     AssaultShip=(WidgetTexture=Texture'GUIContent.Menu.CT_RAS',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.565,PosY=0.23,Pass=1)
     KashyyykBorder=(DrawColor=(B=255,G=255,R=255,A=255),PosX=0.82875,PosY=0.215,ScaleX=0.26375,ScaleY=0.351666,Style="PlanetBorderStyle")
     Kashyyyk=(WidgetTexture=Texture'GUIContent.Menu.CT_Kashyyyk',DrawColor=(B=255,G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.82875,PosY=0.215)
     LabelBackground=(WidgetTexture=Texture'GUIContent.Menu.CT_ButtonFocus',DrawColor=(B=192,G=192,R=192,A=32),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.45625,ScaleX=0.365,ScaleY=0.0617854,ScaleMode=MSCM_FitStretch)
     Label=(Text="LOAD GAME",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.45625,ScaleX=1.1,ScaleY=1.1,Style="LabelText")
     Border=(PosX=0.5,PosY=0.658333,ScaleX=0.807813,ScaleY=0.31875,ScaleMode=MSCM_FitStretch,Style="BorderStyle1")
     SaveList=(Template=(Blurred=(MaxSizeX=0.65),BackgroundBlurred=(ScaleX=0.7),BackgroundFocused=(ScaleX=0.7),OnFocus="SaveListOnFocus",OnSelect="SaveListOnSelect",OnDoubleClick="SelectCurrentSave"),PosX1=0.5,PosY1=0.545833,PosX2=0.5,PosY2=0.770833,DisplayCount=6,OnScroll="UpdateScrollBar",Pass=3,Style="ButtonList")
     ScrollBar=(PosX1=0.86875,PosY1=0.564583,PosX2=0.86875,PosY2=0.747917,OnScroll="OnListScroll",Pass=2,Style="VerticalScrollBar")
     ScrollBarArrowUp=(Blurred=(DrawPivot=DP_MiddleMiddle,PosX=0.86875,PosY=0.547917),OnSelect="OnListScrollUp",Pass=2,Style="VerticalScrollBarArrowUp")
     ScrollBarArrowDown=(Blurred=(DrawPivot=DP_MiddleMiddle,PosX=0.86875,PosY=0.770833),OnSelect="OnListScrollDown",Pass=2,Style="VerticalScrollBarArrowDown")
     ScrollArea=(OnScrollPageUp="OnListPageUp",OnScrollLineUp="OnListScrollUp",OnScrollLineDown="OnListScrollDown",OnScrollPageDown="OnListPageDown",X1=0.117188,Y1=0.5125,X2=0.889063,Y2=0.810417)
     PageUpArea=(bIgnoreController=1,OnSelect="OnListPageUp",Pass=2)
     PageDownArea=(bIgnoreController=1,OnSelect="OnListPageDown",Pass=2)
     SelectedSave=-1
     StringDeleteConfirm="Delete "
     StringDeleteConfirmEnd=" ?"
     LoadConfirm="ARE YOU SURE YOU WANT TO LOAD THIS SAVE GAME?  ANY UNSAVED PROGRESS WILL BE LOST."
     DamagedSave=" APPEARS TO BE DAMAGED AND CANNOT BE USED."
     QuickSaveName="QuickSave"
     AutoSaveName="AutoSave"
     XLabel=(Text=": DELETE")
     XButton=(Blurred=(Text="DELETE"))
     AButton=(OnSelect="SelectCurrentSave",bHidden=0)
     Background=(WidgetTexture=Texture'GUIContent.Menu.CT_MainMenuGraphics',Style="FullScreen")
     ModulateRate=1
}

