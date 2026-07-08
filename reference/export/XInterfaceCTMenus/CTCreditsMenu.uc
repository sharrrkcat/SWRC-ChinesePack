class CTCreditsMenu extends MenuTemplateTitledB;

// NOTE this is expressed in normalized vertical screen space per second
var() float					ScrollSpeed;

var() float					YLineOffset;

var(MenuDefault) MenuText	CreditsLineTemplate;

var() int					NumCreditsLines;

const MENU_CREDIT_LINE_BUFFER_SIZE = 25;
var() MenuText				MenuCreditLineBuffer[MENU_CREDIT_LINE_BUFFER_SIZE];

var() bool					bClosed;

var() bool					bExitAndReturnToMain;

struct CreditLineEntry
{
	var String Text;
	var float PosY;
	var float Scale;
};

var Array<CreditLineEntry> CreditLines;

simulated function Init( String Args )
{
	local string line;
	local string value;
	local float yOffset;
	local bool bGotValue;
	local bool bPCOnlyLine;
	local bool bXboxOnlyLine;
	local float currentScale;
	local int i;
	
	Super.Init( Args );
	
	if ( InStr( Args, "FROMEXTRAS" ) >= 0 )
		bExitAndReturnToMain = False;
	else
		bExitAndReturnToMain = True;
	
	NumCreditsLines = 0;
	yOffset = 0;
	currentScale = 1.0;
	i = 0;
	
	
	do
	{
		bPCOnlyLine = False;
		bXboxOnlyLine = False;
		
		line = "CreditsLine[" $ i $ "]";
			
		//bGotValue = GetPlayerOwner().GetConfigValue( "Credits", line, value, "Credits.ini" );
		
		value = Localize( "Credits", line, "Credits", True );
		bGotValue = (value != "");
		if ( !bGotValue )
		{
			// Try a PC-only one
			line = "CreditsLine_PC[" $ i $ "]";
			value = Localize( "Credits", line, "Credits", True );
			
			bGotValue = (value != "");
			if ( !bGotValue )
			{
				// Try an Xbox-only one
				line = "CreditsLine_Xbox[" $ i $ "]";
				value = Localize( "Credits", line, "Credits", True );			
				bGotValue = (value != "");
				if ( bGotValue )
					bXboxOnlyLine = True;
			}
			else
			{
				bPCOnlyLine = True;
			}
		}
	
		if ( bGotValue )
		{
			if ( ( !bPCOnlyLine && !bXboxOnlyLine ) ||
				 ( bPCOnlyLine && !IsOnConsole() ) ||
				 ( bXboxOnlyLine && IsOnConsole() ) )
			{
				if ( Left(value, 6) == "Scale=" )
				{
					currentScale = float(Right(value, Len(value) - 6));
				}
				else
				{
					CreditLines.Length = NumCreditsLines + 1;
					
					CreditLines[NumCreditsLines].Text = value;
					CreditLines[NumCreditsLines].PosY = 1.01 + yOffset;
					CreditLines[NumCreditsLines].Scale = currentScale;

					yOffset += YLineOffset;
					
					++NumCreditsLines;
				}
			}
			++i;
		}
		
	} until( !bGotValue );
	
	UnloadInts( "Credits" );
}

simulated function OnBButton()
{
	if ( bExitAndReturnToMain )
	{
		GetPlayerOwner().ExitLevel();
		//GetPlayerOwner().ClientOpenXMenu("XInterfaceCTMenus.CTMenuMain");
	}
	else
	{
		CloseMenu();
	}
}

event Tick( float ElapsedTime )
{
	local int i;
	local float lastYValue;
	local int curBufferPos;
	
	if ( !bClosed && IsVisible() && ( GetPlayerOwner().Player.Console.CurMenu == self ) )
	{
		curBufferPos = 0;
		
		for ( i = 0; i < CreditLines.Length; ++i )
		{
			CreditLines[i].PosY -= ScrollSpeed * ElapsedTime;
			lastYValue = CreditLines[i].PosY;
			
			if ( ( CreditLines[i].PosY > -0.05 ) && ( CreditLines[i].PosY < 1.05 ) )
			{
				MenuCreditLineBuffer[curBufferPos].Text = CreditLines[i].Text;
				MenuCreditLineBuffer[curBufferPos].PosY = CreditLines[i].PosY;
				MenuCreditLineBuffer[curBufferPos].ScaleX = CreditLines[i].Scale;
				MenuCreditLineBuffer[curBufferPos].ScaleY = CreditLines[i].Scale;
				MenuCreditLineBuffer[curBufferPos].bHidden = 0;
				++curBufferPos;
			}
		}

		// Hide the rest of the menu text buffer
		for ( i = curBufferPos; i < MENU_CREDIT_LINE_BUFFER_SIZE; ++ i )
		{
			MenuCreditLineBuffer[i].bHidden = 1;
		}
		
		if ( lastYValue < -0.05 )
		{
			bClosed = True;
			OnBButton();
		}
	}
}

simulated function HandleInputBack()
{
	OnBButton();
}


defaultproperties
{
     ScrollSpeed=0.175
     YLineOffset=0.05
     CreditsLineTemplate=(MenuFont=Font'OrbitFonts.OrbitBold15',DrawColor=(B=255,G=200,R=120,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,ScaleX=1,ScaleY=1,Style="LabelText")
     MenuCreditLineBuffer(0)=(bHidden=1,Style="CreditsLineTemplate")
     bExitAndReturnToMain=True
     Background=(WidgetTexture=Texture'GUIContent.Menu.blacksquare',Style="FullScreen")
     ModulateRate=1
     BackgroundMusic=SoundStreamed'UI_Music.Menu_Music.ASH_Track4_Clones'
     bBackgroundMusicDuringLevel=True
}

