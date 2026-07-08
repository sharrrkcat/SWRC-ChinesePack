class CT_PCDemo_Splash extends MenuTemplate;

var() MenuSprite    Background;

//var() MenuText		ContinueText;

var() MenuButtonText	Continue;


simulated function Init( String Args )
{
    FocusOnWidget( Continue );
}

simulated function ContinueSelected()
{
	GetPlayerOwner().ExitLevel();
}

simulated function HandleInputBack();



defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.DemoScreen_PC',Style="FullScreen")
     Continue=(Blurred=(Text="MAIN MENU",PosX=0.5,PosY=0.896),BackgroundBlurred=(PosX=0.5,PosY=0.896,ScaleX=0.27,ScaleY=0.04333),OnSelect="ContinueSelected",Style="ButtonTextStyle1")
     ModulateRate=1
     BackgroundMovieName=""
     bFullscreenOnly=True
}

