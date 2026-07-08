class CTPauseHintText extends CTInfoBase;

var() MenuSprite        BButtonIcon;
var() MenuText          BLabel;
var() MenuButtonText	BButton;

simulated function Init( String Args )
{
	local float buttonMove;
	
	Super.Init( Args );

	if ( !GetPlayerOwner().bVisor )
	{
		// Shift everything up a bit
		InfoTextBorder.PosY = 0.48;
		InfoText.PosY = 0.3;
		InfoPicBorder.PosY = 0.40333333;
	}

	if ( Caps(GetPlayerOwner().GetLanguage()) == "ITT" ||
		 Caps(GetPlayerOwner().GetLanguage()) == "EST" )
	{
		ALabel.ScaleX = 0.7;
		BLabel.ScaleX = 0.7;
	}
	
	if ( Caps(GetPlayerOwner().GetLanguage()) != "INT" )
	{
		if ( GetPlayerOwner().bVisor )
			buttonMove = 0.05;
		else
			buttonMove = 0.025;
			
		AButtonIcon.PosY += buttonMove;
		ALabel.PosY += buttonMove;
		AButton.Blurred.PosY += buttonMove;
		AButton.Focused.PosY += buttonMove;
		AButton.BackgroundBlurred.PosY += buttonMove;
		AButton.BackgroundFocused.PosY += buttonMove;
		BButtonIcon.PosY += buttonMove;
		BLabel.PosY += buttonMove;
		BButton.Blurred.PosY += buttonMove;
		BButton.Focused.PosY += buttonMove;
		BButton.BackgroundBlurred.PosY += buttonMove;
		BButton.BackgroundFocused.PosY += buttonMove;
		
		InfoTextBorder.PosY += 0.045;
		InfoTextBorder.ScaleY += 0.054375;
		
		//InfoText.PosY += ;

		InfoPicBorder.PosY += 0.0375;
		InfoPicBorder.ScaleY += 0.075;
	}
	
	HideAButton(0);	
	
	FocusOnWidget( AButton );
}

function SetInfoOptions(String Pic, String Title, String Text, String NewLevel, bool ShowHints)
{
	InfoText.Text=Text;
	InfoTitle.bHidden=1;
	InfoPic.bHidden=1;
	InfoPicBorder.bHidden=0;
}

simulated function OnAButton()
{
	GetPlayerOwner().SetPause(false);
	Super.OnAButton();
}

simulated function OnBButton()
{
	GetPlayerOwner().bKeepHintMenusAwfulHack=false;
	OnAButton();
}


simulated function bool HandleInputGamePad( String ButtonName )
{
    if( ButtonName ~= "B" )
    {
        OnBButton();
        return( true );
    }
    
	return( Super.HandleInputGamePad( ButtonName ) );
}



defaultproperties
{
     BButtonIcon=(DrawPivot=DP_MiddleRight,PosX=0.105,PosY=0.778333,Platform=MWP_Console,Style="XboxButtonB")
     BLabel=(Text="CONTINUE WITHOUT HINTS",DrawPivot=DP_MiddleLeft,PosX=0.1375,PosY=0.778333,ScaleX=0.85,Platform=MWP_Console,Style="LabelText")
     BButton=(Blurred=(Text="CONTINUE WITHOUT HINTS",PosX=0.25,PosY=0.778333,ScaleX=0.7),BackgroundBlurred=(PosX=0.25,PosY=0.778333,ScaleX=0.35,ScaleY=0.04333),OnSelect="OnBButton",Pass=2,Platform=MWP_PC,Style="ButtonTextStyle1")
     Background=(bHidden=1)
     InfoText=(PosX=0.3,PosY=0.32,MaxSizeX=0.38)
     InfoTextBorder=(PosY=0.5,ScaleX=0.4225,ScaleY=0.4066,Style="BorderStyle1Opaque")
     InfoPicBorder=(PosX=0.5,PosY=0.423333,ScaleX=0.45,ScaleY=0.583333,Style="BorderStyle1Clear")
     AButtonIcon=(PosX=0.60625,PosY=0.778333)
     ALabel=(Text="CONTINUE WITH HINTS",PosX=0.62,PosY=0.778333,ScaleX=0.85)
     AButton=(Blurred=(Text="CONTINUE WITH HINTS",PosY=0.778333,ScaleX=0.7),BackgroundBlurred=(PosY=0.778333,ScaleX=0.35))
}

