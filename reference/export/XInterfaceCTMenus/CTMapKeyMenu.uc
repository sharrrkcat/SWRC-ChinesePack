class CTMapKeyMenu extends MenuTemplateTitledBXA;

var() MenuText			Label;

var() MenuSprite		Border;

var() MenuText			ActionLabel;
var() MenuText			AssignedToLabel;
var() MenuText			ButtonLabel;

var() MenuText			Prompt;

var() string			Func;
var() string			OrigButton;

var() Interactions.EInputKey	NewKey;

var() bool				Canceled;

var() bool				DisallowXboxSpecial;
var() bool				DisallowPCSpecial;

var() MenuText			LabelNoXboxSpecial;
var() MenuText			LabelNoPCSpecial;

var() localized	String	ClickLeftStickText;
var() localized	String	ClickRightStickText;

const GAME_LSTICK = 214;	// EInputKey.GAME_LSTICK
const GAME_RSTICK = 215;	// EInputKey.GAME_RSTICK

var() byte				ConsoleKey;

simulated function Init( string Args )
{
	local bool bGotValue;
	local string value;
	local String Disallow;
	
	Super.Init( Args );
	
	if ( Caps(GetPlayerOwner().GetLanguage()) != "INT" )
	{
		Prompt.ScaleX = 0.7;
	}
	
	if ( Caps(GetPlayerOwner().GetLanguage()) == "DET" )
	{
		AssignedToLabel.ScaleX = 0.8;
	}
	
	HideAButton(1);
	HideBButton(1);
	HideXButton(1);
	
	ActionLabel.Text = ParseToken( Args );		// Action description
	OrigButton = ParseToken( Args );	// Current assignment description
	ButtonLabel.Text = OrigButton;
	Func = ParseToken( Args );			// Actual binding function
	Disallow = ParseToken( Args );
	
	if ( InStr(Disallow, "DISALLOWXBOXSPECIAL") >= 0 )
	{
		DisallowXboxSpecial = True;
		LabelNoXboxSpecial.bHidden = 0;
		LabelNoPCSpecial.bHidden = 1;
	}
	else if ( InStr(Disallow, "DISALLOWPCSPECIAL") >= 0 )
	{
		DisallowPCSpecial = True;
		LabelNoXboxSpecial.bHidden = 1;
		LabelNoPCSpecial.bHidden = 0;
	}
	else
	{
		LabelNoXboxSpecial.bHidden = 1;	
		LabelNoPCSpecial.bHidden = 1;
	}
	
	bGotValue = GetPlayerOwner().GetConfigValue("Engine.Console", "ConsoleKey", value );			
	if ( bGotValue )
		ConsoleKey = byte(value);	
}

simulated function OnAButton()
{
	if ( !IsOnConsole() )
	{
		if ( AButton.bHidden != 0 )
			return;
	}
	else
	{
		if ( ALabel.bHidden != 0 )
			return;
	}

	Canceled = False;
	CloseMenu();
}

simulated function OnBButton()
{
	if ( !IsOnConsole() )
	{
		if ( AButton.bHidden != 0 )
			return;
	}
	else
	{
		if ( ALabel.bHidden != 0 )
			return;
	}

	Canceled = True;
	CloseMenu();
}

simulated function OnXButton()
{
	if ( !IsOnConsole() )
	{
		if ( AButton.bHidden != 0 )
			return;
	}
	else
	{
		if ( ALabel.bHidden != 0 )
			return;
	}

	HideAButton(1);
	HideBButton(1);
	HideXButton(1);
	
	ButtonLabel.Text = OrigButton;
	Prompt.bHidden = 0;
}

simulated function HandleInputBack()
{
	if ( !IsOnConsole() )
	{
		if ( AButton.bHidden != 0 )
			return;
	}
	else
	{
		if ( ALabel.bHidden != 0 )
			return;
	}
	
	OnBButton();
}

simulated function bool HandleInputGamePad( String ButtonName )
{
	if ( !IsOnConsole() )
	{
		if ( AButton.bHidden != 0 )
			return( True );
	}
	else
	{
		if ( ALabel.bHidden != 0 )
			return ( True );
	}

    if( ButtonName ~= "A" )
    {
        OnAButton();
        return( true );
    }
    
    return( Super.HandleInputGamePad( ButtonName ) );
}

simulated function bool HandleInputKeyRaw( Interactions.EInputKey Key )
{
	log("Key="@key);
	if ( !IsOnConsole() )
	{
		if ( AButton.bHidden == 0 )
			return Super.HandleInputKeyRaw(Key);
			
		if ( DisallowPCSpecial &&
				  ( ( Key == 27 ) || ( Key == 19 ) || ( Key == 9 ) || ( Key == ConsoleKey ) ) )
		{
			// The can't use these keys (Esc, Pause, Tab, console key on the PC)
			GetPlayerOwner().PlaySound(SoundOnError);			
			
			return true;
		}	
	}
	else
	{
		if ( ALabel.bHidden == 0 )
			return Super.HandleInputKeyRaw(Key);
			
		if ( DisallowXboxSpecial && 
			( Key >= 208 ) && 
			( Key <= 213 ) )
		{
			// They can't use this key (D-Pad, Start and Back on the X-Box)
			GetPlayerOwner().PlaySound(SoundOnError);
			
			return True;
		}
	}
	
	NewKey = Key;
	
	if ( NewKey == GAME_LSTICK )
		ButtonLabel.Text = ClickLeftStickText;
	else if ( NewKey == GAME_RSTICK )
		ButtonLabel.Text = ClickRightStickText;
	else
		ButtonLabel.Text = RetrieveLocalizedKeyName(NewKey);
	
	HideAButton(0);
	HideBButton(0);
	HideXButton(0);	
	
	Prompt.bHidden = 1;
	
	return True;
}


defaultproperties
{
     Label=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="REASSIGN BUTTON",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.125,ScaleX=1.75,ScaleY=1.75,Pass=2,Style="LabelText")
     Border=(PosX=0.5,PosY=0.4666,ScaleX=0.65,ScaleY=0.44,ScaleMode=MSCM_FitStretch,Style="BorderStyle1")
     ActionLabel=(MenuFont=Font'OrbitFonts.OrbitBold15',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.341666,Style="LabelText")
     AssignedToLabel=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="IS CURRENTLY ASSIGNED TO",DrawColor=(B=255,G=200,R=120,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.385,Style="LabelText")
     ButtonLabel=(MenuFont=Font'OrbitFonts.OrbitBold15',DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.428333,Style="LabelText")
     Prompt=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="HIT ANY BUTTON TO REASSIGN",DrawColor=(B=255,G=200,R=120,A=255),DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.558333,Style="LabelText")
     LabelNoXboxSpecial=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="D-PAD, START AND BACK FUNCTIONS CANNOT BE REASSIGNED",DrawColor=(G=120,R=120,A=255),PosX=0.12,PosY=0.7333,MaxSizeX=0.75,bWordWrap=1)
     LabelNoPCSpecial=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="ESC, PAUSE AND TAB FUNCTIONS CANNOT BE REASSIGNED",DrawColor=(G=120,R=120,A=255),PosX=0.12,PosY=0.7333,MaxSizeX=0.75,bWordWrap=1)
     ClickLeftStickText="CLICK LEFT THUMBSTICK"
     ClickRightStickText="CLICK RIGHT THUMBSTICK"
     XLabel=(Text=": CLEAR")
     XButton=(Blurred=(Text="CLEAR"))
     ALabel=(Text="ACCEPT :")
     AButton=(Blurred=(Text="ACCEPT"))
     BLabel=(Text=": CANCEL")
     BButton=(Blurred=(Text="CANCEL"))
     Background=(bHidden=1)
}

