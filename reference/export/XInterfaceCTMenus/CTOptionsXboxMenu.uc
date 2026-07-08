class CTOptionsXboxMenu extends MenuTemplateTitledBA;

var() MenuText			Label;

const NUM_OPTION_SCREENS = 4;

var() MenuButtonText	Options[NUM_OPTION_SCREENS];

var() bool				bInMultiplayer;

simulated function Init( String Args )
{
	Super.Init( Args );
	
	if ( Level.NetMode != NM_StandAlone )
	{
		// All HUD options are disabled anyway
		Options[1].bDisabled = 1;
		Options[1].Blurred.DrawColor.R = 128;
		Options[1].Blurred.DrawColor.G = 128;
		Options[1].Blurred.DrawColor.B = 128;
	}
}

simulated function GameOptionsSelected()
{
	CallMenuClass("XInterfaceCTMenus.CTGameOptionsXBoxMenu");
}

simulated function HUDOptionsSelected()
{
	CallMenuClass("XInterfaceCTMenus.CTHUDOptionsXBoxMenu");
}

simulated function SoundGraphicsOptionsSelected()
{
	CallMenuClass("XInterfaceCTMenus.CTSoundGraphicsOptionsXBoxMenu");
}

simulated function ControllerOptionsSelected()
{
	CallMenuClass("XInterfaceCTMenus.CTControllerOptionsXBoxMenu");
}


defaultproperties
{
     Label=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="OPTIONS",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.108333,ScaleX=1.75,ScaleY=1.75,Style="LabelText")
     Options(0)=(Blurred=(Text="GAME OPTIONS",PosX=0.5,PosY=0.35),BackgroundBlurred=(PosX=0.5,PosY=0.35,ScaleX=0.6125,ScaleY=0.04333),OnSelect="GameOptionsSelected",Style="ButtonTextStyle1")
     Options(1)=(Blurred=(Text="HUD OPTIONS",PosY=0.45),BackgroundBlurred=(PosY=0.45),OnSelect="HUDOptionsSelected")
     Options(2)=(Blurred=(Text="SOUND / GRAPHICS OPTIONS"),OnSelect="SoundGraphicsOptionsSelected")
     Options(3)=(Blurred=(Text="CONTROLLER OPTIONS"),OnSelect="ControllerOptionsSelected")
     Background=(bHidden=1)
}

