class CTTitleCardMenu extends MenuTemplate;

var() MenuSprite			Background;

var(MenuDefault) MenuText	TitleCardTextTemplate;

var() int					NumTextEntries;

const MAX_TEXT_ENTRIES = 10;
var() MenuText				TextEntries[MAX_TEXT_ENTRIES];
var() float					FadeInStartTime[MAX_TEXT_ENTRIES];
var() float					FullOnStartTime[MAX_TEXT_ENTRIES];
var() float					FadeOutStartTime[MAX_TEXT_ENTRIES];
var() float					FadeOutEndTime[MAX_TEXT_ENTRIES];

var() float					ElapsedTextTime;

var() bool					bClosed;

simulated function Init( String Args )
{
	local string key;
	local string value;
	local bool bGotValue;
	local string cardFile;
	
	Super.Init( Args );
	
	NumTextEntries = 0;
	
	do
	{
		cardFile = ParseToken( Args );
		
	} until( cardFile != "RESET" );
	
	value = Localize( "TitleCard", "BackgroundMusic", cardFile, True );
	bGotValue = (value != "" );
	if ( bGotValue )
		BackgroundMusic=Sound(DynamicLoadObject(value, class'Sound'));
	
	do
	{
		key = "FadeInStartTime[" $ NumTextEntries $ "]";
		value = Localize( "TitleCard", key, cardFile, True );
		bGotValue = (value != "");
		if ( !bGotValue )
			continue;
		FadeInStartTime[NumTextEntries] = float(value);
		
		key = "FullOnStartTime[" $ NumTextEntries $ "]";
		value = Localize( "TitleCard", key, cardFile, True );
		bGotValue = (value != "");
		if ( !bGotValue )
			continue;
		FullOnStartTime[NumTextEntries] = float(value);
	
		key = "FadeOutStartTime[" $ NumTextEntries $ "]";
		value = Localize( "TitleCard", key, cardFile, True );
		bGotValue = (value != "");
		if ( !bGotValue )
			continue;
		FadeOutStartTime[NumTextEntries] = float(value);
	
		key = "FadeOutEndTime[" $ NumTextEntries $ "]";
		value = Localize( "TitleCard", key, cardFile, True );
		bGotValue = (value != "");
		if ( !bGotValue )
			continue;
		FadeOutEndTime[NumTextEntries] = float(value);

		key = "Text[" $ NumTextEntries $ "]";
		value = Localize( "TitleCard", key, cardFile, True );
		bGotValue = (value != "");		
		if ( !bGotValue )
			continue;
		TextEntries[NumTextEntries].Text = value;

		++NumTextEntries;
		
	} until( !bGotValue );
	
	UnloadInts( cardFile );
}

event Tick( float ElapsedTime )
{
	local int i;
	local bool bAllElapsed;
	
	bAllElapsed = True;
	
	if ( !bClosed && IsVisible() )
	{
		ElapsedTextTime += ElapsedTime;	
		
		for ( i = 0; i < NumTextEntries; ++i )
		{
			if ( ElapsedTextTime < FadeOutEndTime[i] )
			{
				bAllElapsed = False;
				
				if ( ElapsedTextTime < FadeInStartTime[i] )
				{
					TextEntries[i].DrawColor.A = 0;
					TextEntries[i].bHidden = 1;
				}
				else
				{
					TextEntries[i].bHidden = 0;
					
					if ( ElapsedTextTime >= FadeOutStartTime[i] )
						TextEntries[i].DrawColor.A = int(255.0 - (255.0 * ((ElapsedTextTime - FadeOutStartTime[i]) / (FadeOutEndTime[i] - FadeOutStartTime[i]))));
					else if ( ElapsedTextTime >= FullOnStartTime[i] )
						TextEntries[i].DrawColor.A = 255;
					else if ( ElapsedTextTime >= FadeInStartTime[i] )
						TextEntries[i].DrawColor.A = int(255.0 * ((ElapsedTextTime - FadeInStartTime[i]) / (FullOnStartTime[i] - FadeInStartTime[i])));
				}
			}
			else
			{
				TextEntries[i].bHidden = 1;
			}
		}
			
		if ( bAllElapsed )
		{
			bClosed = True;
			GetPlayerOwner().SetPause( False );
			GetPlayerOwner().MenuClose();
		}
	}
}

simulated function HandleInputBack();


defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.blacksquare',Style="FullScreen")
     TitleCardTextTemplate=(MenuFont=Font'OrbitFonts.OrbitBold15',DrawColor=(B=255,G=200,R=120,A=255),DrawPivot=DP_MiddleLeft,PosX=0.125,PosY=0.5,ScaleX=1,ScaleY=1,MaxSizeX=0.75,bWordWrap=1,Pass=1)
     TextEntries(0)=(bHidden=1,Style="TitleCardTextTemplate")
     ModulateRate=1
     SoundTweenIn=None
     SoundTweenOut=None
     SoundOnFocus=None
     SoundOnSelect=None
     SoundOnError=None
     BackgroundMovieName=""
     BackgroundMusic=None
     bBackgroundMusicDuringLevel=True
     bFullscreenOnly=True
     bHideMousecursor=True
}

