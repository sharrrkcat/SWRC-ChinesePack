class CTControllerOptionsXboxMenu extends MenuTemplateTitledBA;

var() MenuText			Label;

const NUM_OPTIONS = 6;

var() MenuButtonText	Options[NUM_OPTIONS];

simulated function Init( String Args )
{
	Super.Init( Args );
}

simulated function DefaultSelected()
{
	GetPlayerOwner().ConsoleCommand("UseControllerConfig DefaultCtrl.ini");	
	GetPlayerOwner().SavePlayerInputConfig();
	GetPlayerOwner().SaveInputConfig();
	CallMenuClass( "XInterfaceCTMenus.CTSavingSettingsMenu", "" );
}

simulated function Config1Selected()
{
	GetPlayerOwner().ConsoleCommand("UseControllerConfig AltCtrl1.ini");	
	GetPlayerOwner().SavePlayerInputConfig();
	GetPlayerOwner().SaveInputConfig();
	CallMenuClass( "XInterfaceCTMenus.CTSavingSettingsMenu", "" );
}

simulated function Config2Selected()
{
	GetPlayerOwner().ConsoleCommand("UseControllerConfig AltCtrl2.ini");
	GetPlayerOwner().SavePlayerInputConfig();
	GetPlayerOwner().SaveInputConfig();
	CallMenuClass( "XInterfaceCTMenus.CTSavingSettingsMenu", "" );
}

simulated function Config3Selected()
{
	GetPlayerOwner().ConsoleCommand("UseControllerConfig AltCtrl3.ini");
	GetPlayerOwner().SavePlayerInputConfig();
	GetPlayerOwner().SaveInputConfig();
	CallMenuClass( "XInterfaceCTMenus.CTSavingSettingsMenu", "" );
}

simulated function Config4Selected()
{
	GetPlayerOwner().ConsoleCommand("UseControllerConfig AltCtrl4.ini");
	GetPlayerOwner().SavePlayerInputConfig();
	GetPlayerOwner().SaveInputConfig();
	CallMenuClass( "XInterfaceCTMenus.CTSavingSettingsMenu", "" );
}

simulated function RemapSelected()
{
	CallMenuClass("XInterfaceCTMenus.CTControllerOptionsRemapXBoxMenu");
}

simulated function bool MenuClosed( Menu closingMenu )
{
	local CTSavingSettingsMenu ssMenu;
	
	ssMenu = CTSavingSettingsMenu( closingMenu );
	
	if ( ssMenu != None )
	{
		CallMenuClass("XInterfaceCTMenus.CTControllerOptionsRemapXBoxMenu");
		return True;
	}
	
	return False;
}


defaultproperties
{
     Label=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="CONTROLLER OPTIONS",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.108333,ScaleX=1.75,ScaleY=1.75,Style="LabelText")
     Options(0)=(Blurred=(Text="USE DEFAULT XBOX CONTROLLER CONFIGURATION",PosX=0.5,PosY=0.2),BackgroundBlurred=(PosX=0.5,PosY=0.2,ScaleX=0.9,ScaleY=0.04333),OnSelect="DefaultSelected",Style="ButtonTextStyle1")
     Options(1)=(Blurred=(Text="USE XBOX CONTROLLER CONFIGURATION 1",PosY=0.3),BackgroundBlurred=(PosY=0.3),OnSelect="Config1Selected")
     Options(2)=(Blurred=(Text="USE XBOX CONTROLLER CONFIGURATION 2"),OnSelect="Config2Selected")
     Options(3)=(Blurred=(Text="USE XBOX CONTROLLER CONFIGURATION 3"),OnSelect="Config3Selected")
     Options(4)=(Blurred=(Text="USE XBOX CONTROLLER CONFIGURATION 4"),OnSelect="Config4Selected")
     Options(5)=(Blurred=(Text="REMAP XBOX CONTROLLER BUTTONS",PosY=0.8),BackgroundBlurred=(PosY=0.8),OnSelect="RemapSelected")
     Background=(bHidden=1)
}

