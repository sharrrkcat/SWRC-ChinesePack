class CTLoadingInfo extends CTInfoBase;

const					NUM_HINT_PICS = 6;
var() MenuSprite		HintPics[NUM_HINT_PICS];

var() MenuSprite		HintSeparator;

var() MenuText			HintTitle;
var() MenuText			HintText;

var() MenuProgressBar	LoadingBar;
var() MenuText			LoadingText;

var() float				LastHintTime;

var() bool				bNoHints;

simulated function Init( String Args )
{
	local int i;
	
	Super.Init( Args );

	if ( Caps(GetPlayerOwner().GetLanguage()) != "INT" )
	{
		AButton.BackgroundFocused.ScaleX = 0.25;
		AButton.BackgroundBlurred.ScaleX = 0.25;
	}
	
	LoadingBar.Low = 0.0;
	LoadingBar.High = 1.0;
	LoadingBar.Value = 0.0;
		
	if ( !IsOnConsole() )
		bNoHints = True;
			
	if ( InStr(Args, "LOADINGDONE") > -1)
	{
		HideAButton(0);
		LoadingBar.bHidden = 1;
		LoadingText.bHidden = 1;
		bHideMouseCursor = False;
		bNoHints = True;
		
		for ( i = 0; i < NUM_HINT_PICS; ++i )
		{
			HintPics[i].bHidden = 1;
		}
		
		HintTitle.bHidden = 1;		
		HintText.bHidden = 1;
		HintSeparator.bHidden = 1;
	}
	else
	{
		HideAButton(1);
	}	
	
	LastHintTime = GetAppTime();	
}

function SetInfoOptions(String Pic, String Title, String Text, String NewLevel, bool ShowHints)
{
	Super.SetInfoOptions( Pic, Title, Text, NewLevel, ShowHints );
	
	bNoHints = !ShowHints;
	
	if ( !IsOnConsole() )
		bNoHints = True;
}

function UpdateLoadingProgress(float LoadingRatioCompleted)
{
	local float ElapsedHintTime;
	
	LoadingBar.Value = LoadingRatioCompleted;
	bHideMouseCursor = True;
	
	if ( !bNoHints )
	{
		ElapsedHintTime = GetAppTime() - LastHintTime;
		
		if ( ElapsedHintTime >= 10.0 )
		{
			SetupNewHint();
		
			LastHintTime = GetAppTime();
		}
	}	
}

simulated function SetupNewHint()
{
	local String HTitle;
	local String HText;
	local int HPicIndex;
	local int i;
	local PlayerController PC;
	
	ForEach AllActors(class'PlayerController', PC)
		break;

	if ( PC == None )
		return;

	for ( i = 0; i < NUM_HINT_PICS; ++i )
	{
		HintPics[i].bHidden = 1;
	}
	
	InfoTitle.bHidden = 1;
	InfoText.bHidden = 1;
	//InfoPic.bHidden = 1;
	
	PC.GetNewLoadingHint( HTitle, HText, HPicIndex );
	
	HintTitle.Text = HTitle;
	HintTitle.bHidden = 0;
		
	HintText.Text = HText;
	HintText.bHidden = 0;
	
	HintPics[HPicIndex].bHidden = 0;
	
	HintSeparator.bHidden = 0;
}

function bool PauseOnLoadingFinish() 
{ 
	return True; 
}

simulated function OnAButton()
{
	GetPlayerOwner().SetPause(false);
	Super.OnAButton();
}


defaultproperties
{
     HintPics(0)=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.Load_Head_01',PosX=0.12,PosY=0.14,ScaleX=1.25,ScaleY=1.25,Pass=2,bHidden=1)
     HintPics(1)=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.Load_Head_02',bHidden=1)
     HintPics(2)=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.Load_Head_03',bHidden=1)
     HintPics(3)=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.Load_Head_04',bHidden=1)
     HintPics(4)=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.Load_Head_05',bHidden=1)
     HintPics(5)=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.Load_Head_06',bHidden=1)
     HintSeparator=(WidgetTexture=Texture'GUIContent.Menu.loading_bar',TextureCoords=(X1=5,Y1=5,X2=5,Y2=5),DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.25,PosY=0.27666,ScaleX=0.01,ScaleY=0.3,ScaleMode=MSCM_FitStretch,Pass=2,bHidden=1)
     HintTitle=(MenuFont=Font'OrbitFonts.OrbitBold15',DrawColor=(B=255,G=200,R=120,A=255),DrawPivot=DP_MiddleLeft,PosX=0.28,PosY=0.16,ScaleX=1.1,ScaleY=1.1,MaxSizeX=0.6,Pass=2,bHidden=1)
     HintText=(MenuFont=Font'OrbitFonts.OrbitBold15',DrawColor=(B=255,G=255,R=255,A=255),PosX=0.28,PosY=0.195,ScaleX=0.8,ScaleY=0.8,MaxSizeX=0.6,bWordWrap=1,Pass=2,bHidden=1)
     LoadingBar=(BarBack=(WidgetTexture=Texture'GUIContent.Menu.loading_bar_empty',DrawColor=(B=255,G=255,R=255,A=255),PosX=0.56875,PosY=0.5975),BarTop=(WidgetTexture=Texture'GUIContent.Menu.loading_bar',DrawColor=(B=255,G=255,R=255,A=255),PosX=0.56875,PosY=0.5975),BarWidth=0.275,BarHeight=0.041666)
     LoadingText=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="LOADING",DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_UpperMiddle,PosX=0.70625,PosY=0.67333,ScaleX=1,ScaleY=1)
     ALabel=(Text=": START")
     AButton=(Blurred=(Text="START"))
     bHideMousecursor=True
}

