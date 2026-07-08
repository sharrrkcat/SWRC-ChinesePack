class CTIncapLoadConfirmMenu extends MenuTemplateTitledBA;

var() MenuText Question;

simulated function Init( String Args )
{
	if ( !IsOnConsole() )
		FocusOnWidget( BButton );
		
	GetPlayerOwner().SetPause( True );
}

simulated function OnAButton()
{
	GetPlayerOwner().LoadMostRecent();
	CloseMenu();
}

simulated function HandleInputBack()
{
    OnBButton();
}

simulated function OnBButton()
{
	GetPlayerOwner().SetPause( False );
	CloseMenu();
}

simulated function bool HandleInputGamePad( String ButtonName )
{
    if( ButtonName == "A" )
    {
        OnAButton();
        return( true );
    }

    if( ButtonName == "B" )
    {
        OnBButton();
        return( true );
    }
    
	return( Super.HandleInputGamePad( ButtonName ) );
}


defaultproperties
{
     Question=(Text="ARE YOU SURE YOU WANT TO LOAD THE LAST SAVE GAME?  ALL UNSAVED PROGRESS WILL BE LOST.",DrawPivot=DP_MiddleLeft,PosX=0.2,PosY=0.5,MaxSizeX=0.6,bWordWrap=1,Pass=2,Style="LabelText")
     ALabel=(Text="YES :")
     AButton=(Blurred=(Text="YES"),bHidden=0)
     BLabel=(Text=": NO")
     BButton=(Blurred=(Text="NO"))
     Background=(WidgetTexture=Texture'GUIContent.Menu.blacksquare',DrawColor=(A=192),Style="FullScreen")
     MenuTitle=(Text="PLEASE CONFIRM",bHidden=0)
     BackgroundMovieName=""
     BackgroundMusic=None
}

