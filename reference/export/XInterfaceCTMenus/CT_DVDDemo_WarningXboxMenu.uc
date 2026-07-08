class CT_DVDDemo_WarningXboxMenu extends MenuTemplate;

var() MenuSprite    Background;
var() MenuText		Title;
var() MenuText		Header;
var() MenuText		Text1;
var() MenuText		Text2;
var() MenuText		Text3;

simulated function Init( String Args )
{
	Super.Init( Args );
	
	SetTimer(10.0, False);
}

simulated function Timer()
{
	GotoMenuClass("XInterfaceCTMenus.CTStartXboxMenu");
}

simulated function HandleInputBack();


defaultproperties
{
     Background=(WidgetTexture=Texture'GUIContent.Menu.blacksquare',DrawColor=(B=255,G=255,R=255,A=255),ScaleX=1,ScaleY=1,ScaleMode=MSCM_Fit,Style="FullScreen")
     Title=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="IMPORTANT HEALTH WARNING:",DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0.1,ScaleX=1.5,ScaleY=1.5)
     Header=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="ABOUT PHOTOSENSITIVE SEIZURES",DrawPivot=DP_UpperMiddle,PosX=0.55,PosY=0.15,MaxSizeX=0.3,bWordWrap=1)
     Text1=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="A very small percentage of people may experience a seizure when exposed to certain visual images, including flashing lights or patterns that may appear in video games.  Even people who have no history of seizures or epilepsy may have an undiagnosed condition that can cause these 'photosensitive epileptic seizures' while watching video games.",DrawPivot=DP_UpperMiddle,PosX=0.55,PosY=0.2,ScaleX=0.75,ScaleY=0.75,MaxSizeX=0.3,bWordWrap=1)
     Text2=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="These seizures may have a variety of symptoms, including lightheadedness, altered vision, eye or face twitching, jerking or shaking of arms or legs, disorientation, confusion, or momentary loss of awareness.  Seizures may also cause loss of consciousness or convulsions that can lead to injury from falling down or striking nearby objects.",DrawPivot=DP_UpperMiddle,PosX=0.55,PosY=0.475,ScaleX=0.75,ScaleY=0.75,MaxSizeX=0.3,bWordWrap=1)
     Text3=(MenuFont=Font'OrbitFonts.OrbitBold15',Text="Immediately stop playing and consult a doctor if you experience any of these symptoms.  Parents should watch for or ask their children about the above symptoms- children and teenagers are more likely than adults to experience these seizures.",DrawPivot=DP_UpperMiddle,PosX=0.55,PosY=0.75,ScaleX=0.75,ScaleY=0.75,MaxSizeX=0.3,bWordWrap=1)
     ModulateRate=1
     BackgroundMovieName=""
     BackgroundMusic=None
     bFullscreenOnly=True
}

