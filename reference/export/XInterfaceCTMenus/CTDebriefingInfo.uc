class CTDebriefingInfo extends CTInfoBase;

var() String	TransitionToLevel;
var() MenuText	UnlockedText1;
var() MenuText	UnlockedText2;


simulated function Init( String Args )
{
	Super.Init( Args );
	
	if ( Caps(GetPlayerOwner().GetLanguage()) != "INT" )
	{
		UnlockedText1.bHidden = 1;
		UnlockedText2.bHidden = 1;
		
		AButtonIcon.PosY = 0.6183333;
		ALabel.PosY = 0.6183333;
		AButton.Blurred.PosY = 0.6183333;
		AButton.BackgroundBlurred.PosY = 0.6183333;
		AButton.Focused.PosY = 0.6183333;
		AButton.BackgroundFocused.PosY = 0.6183333;
		
		AButton.BackgroundFocused.ScaleX = 0.25;
		AButton.BackgroundBlurred.ScaleX = 0.25;
	}
	
	HideAButton(0);	
}

function SetInfoOptions(String Pic, String Title, String Text, String NewLevel, bool ShowHints)
{
	Super.SetInfoOptions(Pic, Title, Text, NewLevel, ShowHints);

	TransitionToLevel = NewLevel;	
}

simulated function OnAButton()
{
	if ( TransitionToLevel != "" )
	{
		GetPlayerOwner().ConsoleCommand("open " $ TransitionToLevel);
	}
	else
	{
		GetPlayerOwner().SetPause(false);
		Super.OnAButton();
	}
}


defaultproperties
{
     UnlockedText1=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="YOU HAVE UNLOCKED",DrawColor=(G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.70625,PosY=0.6,ScaleX=0.8,ScaleY=0.8,MaxSizeX=0.4)
     UnlockedText2=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="EXTRAS CONTENT",DrawColor=(G=255,R=255,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.70625,PosY=0.65,ScaleX=0.8,ScaleY=0.8,MaxSizeX=0.4)
     AButtonIcon=(PosY=0.878333)
     ALabel=(Text=": CONTINUE",PosY=0.878333)
     AButton=(Blurred=(Text="CONTINUE",PosY=0.878333),BackgroundBlurred=(PosY=0.878333))
}

