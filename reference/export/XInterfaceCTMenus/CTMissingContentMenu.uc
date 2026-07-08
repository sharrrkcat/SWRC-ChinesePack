class CTMissingContentMenu extends MenuTemplateTitledA;

var() MenuText Message;

var() localized String MissingContentStr;

simulated function Init( String Args )
{
	Super.Init( Args );
	
	UpdateTextField( MissingContentStr, "%s", Args );
		
	Message.Text = MissingContentStr;
}


simulated function OnAButton()
{
	GetPlayerOwner().ClientSetMissingContent( False, "" );
	
	HandleInputBack();
}

simulated function bool HandleInputGamePad( String ButtonName )
{
    if( ButtonName == "A" )
    {
        OnAButton();
        return( true );
    }
    
	return( Super.HandleInputGamePad( ButtonName ) );
}


defaultproperties
{
     Message=(DrawPivot=DP_MiddleLeft,PosX=0.075,PosY=0.5,MaxSizeX=0.85,bWordWrap=1,Pass=2,Style="LabelText")
     MissingContentStr="SERVER CONTENT '%s' IS NOT PRESENT ON THE LOCAL MACHINE."
     ALabel=(Text="CONTINUE :")
     AButton=(Blurred=(Text="CONTINUE"),bHidden=0)
     Background=(bHidden=1)
     MenuTitle=(Text="ERROR",bHidden=0)
     CrossFadeRate=20
}

