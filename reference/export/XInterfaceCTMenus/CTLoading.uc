class CTLoading extends MenuTemplate;

var() MenuSprite		Background;

const					NUM_HINT_PICS = 6;
var() MenuSprite		HintPics[NUM_HINT_PICS];

var() MenuSprite		HintBorder;
var() MenuSprite		HintSeparator;
var() MenuText			HintTitle;
var() MenuText			HintText;

var() MenuText			InfoBlurb;

var() MenuSprite		LoadingBorder;
var() MenuProgressBar	LoadingBar;
var() MenuText			LoadingText;

var() float				LastHintTime;

var() bool				bNoHints;

simulated function Init( String Args )
{
	LoadingBar.Low = 0.0;
	LoadingBar.High = 1.0;
	LoadingBar.Value = 0.0;
	
	if ( !IsOnConsole() )
	{
		bNoHints = True;
		HintBorder.bHidden = 1;
		HintTitle.bHidden = 1;
		HintText.bHidden = 1;
		HintSeparator.bHidden = 1;
	}
	else
	{
		SetupNewHint();
	}
	
	LastHintTime = GetAppTime();
}

function SetInfoOptions(String Pic, String Title, String Text, String NewLevel, bool ShowHints)
{
	local int i;
	
	InfoBlurb.Text = Title;

	bNoHints = !ShowHints;
	if ( !IsOnConsole() )
		bNoHints = True;
		
	if ( ( Title == "" ) || bNoHints )
	{
		bNoHints = True;
		HintBorder.bHidden = 1;
		HintTitle.bHidden = 1;
		HintText.bHidden = 1;
		HintSeparator.bHidden = 1;
		
		for ( i = 0; i < NUM_HINT_PICS; ++i )
		{
			HintPics[i].bHidden = 1;
		}		
	}
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
	
	PC.GetNewLoadingHint( HTitle, HText, HPicIndex );
	
	HintTitle.Text = HTitle;
	HintText.Text = HText;
	HintPics[HPicIndex].bHidden = 0;	
	HintSeparator.bHidden = 0;
}


defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.blacksquare',DrawColor=(B=255,G=255,R=255,A=255),ScaleX=1,ScaleY=1,ScaleMode=MSCM_Fit,Style="FullScreen")
     HintPics(0)=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.Load_Head_01',PosX=0.12,PosY=0.14,ScaleX=1.25,ScaleY=1.25,Pass=2,bHidden=1)
     HintPics(1)=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.Load_Head_02',bHidden=1)
     HintPics(2)=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.Load_Head_03',bHidden=1)
     HintPics(3)=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.Load_Head_04',bHidden=1)
     HintPics(4)=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.Load_Head_05',bHidden=1)
     HintPics(5)=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.Load_Head_06',bHidden=1)
     HintBorder=(PosX=0.5,PosY=0.27666,ScaleX=0.8375,ScaleY=0.34,Style="BorderStyle1")
     HintSeparator=(WidgetTexture=Texture'GUIContent.Menu.loading_bar',TextureCoords=(X1=5,Y1=5,X2=5,Y2=5),DrawColor=(B=255,G=255,R=255,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.25,PosY=0.27666,ScaleX=0.01,ScaleY=0.3,ScaleMode=MSCM_FitStretch,Pass=2)
     HintTitle=(MenuFont=Font'OrbitFonts.OrbitBold15',DrawColor=(B=255,G=200,R=120,A=255),DrawPivot=DP_MiddleLeft,PosX=0.28,PosY=0.16,ScaleX=1.1,ScaleY=1.1,MaxSizeX=0.6,Pass=2)
     HintText=(MenuFont=Font'OrbitFonts.OrbitBold15',DrawColor=(B=255,G=255,R=255,A=255),PosX=0.28,PosY=0.195,ScaleX=0.8,ScaleY=0.8,MaxSizeX=0.6,bWordWrap=1,Pass=2)
     InfoBlurb=(MenuFont=Font'OrbitFonts.OrbitBold15',DrawColor=(B=142,G=123,R=89,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.63,ScaleX=1,ScaleY=1,Pass=2)
     LoadingBorder=(PosX=0.5,PosY=0.75,ScaleX=0.55,ScaleY=0.15,Pass=1,Style="BorderStyle1")
     LoadingBar=(BarBack=(WidgetTexture=Texture'GUIContent.Menu.loading_bar_empty',DrawColor=(B=255,G=255,R=255,A=255),PosX=0.25,PosY=0.7),BarTop=(WidgetTexture=Texture'GUIContent.Menu.loading_bar',DrawColor=(B=255,G=255,R=255,A=255),PosX=0.25,PosY=0.7),BarWidth=0.5,BarHeight=0.041666,Pass=2)
     LoadingText=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="LOADING",DrawColor=(B=142,G=123,R=89,A=192),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.79,ScaleX=1,ScaleY=1,Pass=2)
     ModulateRate=1
     SoundOnFocus=None
     BackgroundMusic=None
     bFullscreenOnly=True
     bHideMousecursor=True
}

