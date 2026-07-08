class CTInfoBase extends MenuTemplate;

var() MenuSprite		Background;

var() MenuText			InfoTitle;
var() MenuText			InfoText;
var() MenuSprite		InfoTextBorder;

var() MenuSprite		InfoPic;
var() MenuSprite		InfoPicBorder;

var() MenuSprite        AButtonIcon;
var() MenuText          ALabel;
var() MenuButtonText	AButton;

simulated function Init( String Args )
{
	Super.Init( Args );
}

simulated event TransferTransientElements(Menu m)
{
	local CTInfoBase ibm;

	if ( m == None )
	{
		return;
	}
	
	Super.TransferTransientElements(m);

	if ( m.IsA('CTInfoBase') )
	{
		ibm = CTInfoBase(m);
		if ( ibm != None )
		{
			InfoPic.WidgetTexture = ibm.InfoPic.WidgetTexture;
			InfoTitle.Text = ibm.InfoTitle.Text;
			InfoText.Text = ibm.InfoText.Text;
		}
	}
}

function SetInfoOptions(String Pic, String Title, String Text, String NewLevel, bool ShowHints)
{
	InfoPic.WidgetTexture = Material(DynamicLoadObject(Pic, class'Material'));
	
	//**** COMPLETE HACK -- Hard-coding the texture coordinates to try
	//						and fix the loading screen sometimes not using the
	//						whole texture.  Don't know how or even if these
	//						are getting hosed.  If this doesn't work, try
	//						setting X2 and Y2 to 255 (the known size of the texture).
	InfoPic.TextureCoords.X1 = 0;
	InfoPic.TextureCoords.Y1 = 0;
	InfoPic.TextureCoords.X2 = 0;
	InfoPic.TextureCoords.Y2 = 0;
	//****
	
	InfoTitle.Text = Title;
	InfoText.Text = Text;
}

simulated function OnAButton()
{
	GetPlayerOwner().MenuClose();
}

simulated function HideAButton(int hide)
{
	if ( !IsOnConsole() )
	{
	    AButton.bHidden = hide;
		return;
	}	
	
	AButtonIcon.bHidden = hide;
    ALabel.bHidden = hide;
}

simulated function bool HandleInputGamePad( String ButtonName )
{
    if( ButtonName ~= "A" )
    {
        OnAButton();
        return( true );
    }
    
	return( Super.HandleInputGamePad( ButtonName ) );
}

simulated function HandleInputBack();


defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.RC_LoadTransition_bg',DrawColor=(B=255,G=255,R=255,A=255),ScaleX=1,ScaleY=1,ScaleMode=MSCM_Fit)
     InfoTitle=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="DEFAULT INFO TITLE",DrawColor=(B=255,G=200,R=120,A=255),DrawPivot=DP_MiddleLeft,PosX=0.12,PosY=0.16,ScaleX=1.1,ScaleY=1.1,MaxSizeX=0.75,Pass=2)
     InfoText=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="DEFAULT INFO TEXT",DrawColor=(B=255,G=255,R=255,A=255),PosX=0.12,PosY=0.195,ScaleX=0.8,ScaleY=0.8,MaxSizeX=0.75,bWordWrap=1,Pass=2)
     InfoTextBorder=(PosX=0.5,PosY=0.27666,ScaleX=0.8375,ScaleY=0.34,Style="BorderStyle1")
     InfoPic=(WidgetTexture=Texture'GUIContent.LoadInfoScreens.DefaultImage',DrawPivot=DP_MiddleMiddle,PosX=0.2875,PosY=0.695,ScaleX=0.375,ScaleY=0.3666,ScaleMode=MSCM_Fit,Pass=2)
     InfoPicBorder=(PosX=0.2875,PosY=0.695,ScaleX=0.4225,ScaleY=0.40666,Style="BorderStyle1")
     AButtonIcon=(DrawPivot=DP_MiddleRight,PosX=0.66625,PosY=0.618333,Platform=MWP_Console,Style="XboxButtonA")
     ALabel=(DrawPivot=DP_MiddleLeft,PosX=0.65625,PosY=0.618333,Platform=MWP_Console,Style="LabelText")
     AButton=(Blurred=(PosX=0.70625,PosY=0.618333),BackgroundBlurred=(PosX=0.70625,PosY=0.618333,ScaleX=0.19,ScaleY=0.04333),OnSelect="OnAButton",Pass=2,bHidden=1,Platform=MWP_PC,Style="ButtonTextStyle1")
     ModulateRate=1
     SoundOnFocus=None
     BackgroundMovieName=""
     BackgroundMusic=None
     bFullscreenOnly=True
}

