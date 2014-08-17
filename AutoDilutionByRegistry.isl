//========================================================================
//ISODAT NT SCRIPT LANGUAGE (ISL) : Simple Script
//========================================================================
//
//  History list
//    
//  Author      				Date        			Reason      					changes
//  ---------------------------------------------------------------------------------------------------------------------
//  Chris Black				2014-07-07					Recreate deleted script
//
//
//-------------------------------------------------------------------------------------------------------------------------

// This script provides autodilution of CO2 peaks in methods that also dilute air peaks at fixed times.
// To do this, it takes a different approach than the default autodilute script:
// Rather than move the split directly, which would be undone by timed split cues,
// it monitors peak heights and when a peak exceeds the autodilution threshold specified in the method, 
// it sets the "Is Diluting" registry flag. The acquisition script is then responsible for 
// checking the registry values and setting the split position as appropriate for each CO2 peak.

// In addition, this script records the height of each peak in the "Last Peak Height" registry value. 
// The acquisition script can then use this value to select an appropriate reference gas intensity.

script GasBenchAutoDilution
{

}

external number wParam=0;
external number lParam=0;

external number nInput1=0;
external number nInput2=0;

main()
{
	_RegSetProfileNumber("Gas Bench", "Last Peak Height", lParam);

	if (lParam>=nInput1)
	{
		_UserInfo("Autodilution executed",0,0);
		_RegSetProfileNumber("Gas Bench", "Is Diluting", 1);
	}
}

