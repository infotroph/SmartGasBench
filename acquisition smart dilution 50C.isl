//ISODAT NT SCRIPT LANGUAGE (ISL) : Gas Bench Acqusition Script
//
//  History list
//    
//  Author      		Date        Reason      				changes
//  ----------------------------------------------------------------------
//  Chris Black			2012-10-08	Created
//	Chris Black			2012-10-09	Calibration					Updated cutpoints in openRefsByHeight()  
//	Chris Black			2012-10-09	Bug fix							Reset "Last Peak Height" 
//																										to avoid carryover between samples
//	Chris Black 		2012-10-09	Calibration					Tweak delays between peaks
//	Chris Black			2012-10-09	Bug fix							Leave 5 sec after last peak to ensure registry is updated			
//	Chris Black			2012-10-10	Bug fix							Make that 30 sec, air peaks still getting caught	
//	Chris Black			2012-10-10	calibration					Leave 20 instead of 10 sec between ref peaks
//	Chris Black			2012-10-11	calibration					Injecting sample every 90 sec instead of 75, 
//																										so add 15 sec to sample peak delay					
//	Chris Black			2012-10-11	calibration					extend first sample peak delay to 50 from 38 sec	
//	Chris Black			2012-10-16	calibration					update cutpoints in openRefsByHeight()
//																										to match changed hardware configuration--Ref 3 capillary shortened 
//																										to increase max ref peak height from 4.4V to 8V.				
//	Chris Black			2012-12-03	Bug fix							Peak 1 was always evaluating as heavier--standardize timing by
//																										putting peak 1 dilution inside same loops as peaks 2-5 	
//	Chris Black			2012-12-05	calibrugfix					Check peak height in each sample instead of relying on 
//																										hard-coded values
//	Chris Black			2014-01-16	adjust timing				Gas bench column temperature was reduced from 60C for 50C
//																										for better peak separation. Updated split timings to match.
script GasbenchAcquisitionSmartDilute
{
	switches (EXCLUSIVE-)
	switches (TERMINATE_DIALOG+)

}

include "lib\stdisl.isl"
include "lib\instrument.isl"
include "lib\Continues Flow_lib.isl"
include "lib\GasBench_lib.isl"

function CleanUp()
{
	call StopAutoDilution();
}

function InitScript()
{
  OnBreak CleanUp;

	_Set("Gas Bench/Valco",LOAD);
	_Set("Gas Bench/Split",OUT);
	_Set("Gas Bench/Reference 1",0);
	_Set("Gas Bench/Reference 2",0);
	_Set("Gas Bench/Reference 3",0);

	_Set("Gas Bench/Trap",UP);
	_Set("Gas Bench/Trap 2",UP);
	call PrepareHWo();
}

function StartBetterAutoDilution()
{
	if (bGb_AutoDilutionOn)
	{
    _SetEvent("Isodat@Eval@PeakFound","GasBench\AutoDilutionByRegistry.isl",FALSE, nGb_DilutionAmplitude,0);
	}
}

function setRefs(number r1, number r2, number r3)
{
	_Set("Gas Bench/Reference 1",r1);
	_Set("Gas Bench/Reference 2",r2);
	_Set("Gas Bench/Reference 3",r3);
}

function openRefsByHeight(number peakHeight, number R1, number R2, number R3)
{
// Assumes only that all three Ref lines are CO2 and pressure is set 
// such that ref1 < ref2 < (ref1+ref2) < ref3.
// This means peak height goes R1 < R2 < (R1+R2) < R3 < (R1+R3) < (R2+R3) < (R1+R2+R3).
// Ref pressures set to 1.35, 2, 2.5 bar, give, as of oct 2012, peaks of roughly 1-2-3-5-6-7-8 volts.

array RefCutPoints of number [6];
RefCutPoints[0] = (R1 + R2)/2; 
RefCutPoints[1] = (R2 + R1+R2)/2;
RefCutPoints[2] = (R1+R2 + R3)/2; 
RefCutPoints[3] = (R3 + R1+R3)/2; 
RefCutPoints[4] = (R1+R3 + R2+R3)/2; 
RefCutPoints[5] = (R2+R3 + R1+R2+R3)/2;

number cut = 0; 

while(RefCutPoints[cut] <= peakHeight){
	cut++;
	if (cut > 5) { break;}
}

	if(cut == 0) { 
		call setRefs(1, 0, 0);
	}
	if(cut == 1) { 
		call setRefs(0, 1, 0);
	}
	if(cut == 2) { 
		call setRefs(1, 1, 0);
	}
	if(cut == 3) { 
		call setRefs(0, 0, 1);
	}
	if(cut == 4) { 
		call setRefs(1, 0, 1);
	}
	if(cut == 5) { 
		call setRefs(0, 1, 1);	
	} 
	if (cut > 5){
		call setRefs(1, 1, 1);	
	}
}



main()
{
	number peakFromReg = -1;
	number isDiluting = -1;
	
	_RegSetProfileNumber("Gas Bench", "Is Diluting", 0);
	_RegSetProfileNumber("Gas Bench", "Last Peak Height", 0);
	
	call UploadSamplerMethod();
	call InitScript();
	call PeakCenter();
	
	call GasBenchNextSample();
	
	call ExecuteExtraScript();
	
	//call StartAutoDilution();
	call StartBetterAutoDilution();
	
	call WaitForStartSignal();
	
	call StartChromatogram();
	

	// Record heights of reference pulses
	// EDIT DELAYS HERE to match the reference pulses in your method.
	_Delay(50000, 1);
	number Ref1Height = _RegGetProfileNumber("Gas Bench", "Last Peak Height", -1);
	_Delay(30000, 1);
	number Ref2Height = _RegGetProfileNumber("Gas Bench", "Last Peak Height", -1);
	_Delay(30000, 1);
	number Ref3Height = _RegGetProfileNumber("Gas Bench", "Last Peak Height", -1);
	
	_UserInfo("ref peaks %f, %f, %f", 0, 0, Ref1Height, Ref2Height, Ref3Height);

	
	// wait for first sample peak
	// EDIT DELAY HERE to align with your method
	_Delay(95000,1);


	// dilute all air peaks, but respect autodilute for CO2 peaks
	// EDIT DELAYS HERE to match method timing
	number i;
	for(i=1;i<=5;i++;){
		_Set("Gas Bench/Split", OUT);
		_Delay(35000,1);
		isDiluting = _RegGetProfileNumber("Gas Bench", "Is Diluting", -1);
		if(isDiluting == 0){
			_Set("Gas Bench/Split", IN);
		}
		_Delay(55000,1);
	}
	

	// wait after last peak to make sure it gets recorded,
	// else we might match height against an air peak.
	// EDIT DELAY HERE if needed, then extend your method to match
	_Delay(30000,1);
	peakFromReg = _RegGetProfileNumber("Gas Bench", "Last Peak Height", -1);
	_UserInfo("Last peak height: %f", 0, 0, peakFromReg);
	
	if(_RegGetProfileNumber("Gas Bench", "Is Diluting", -1) == 1){
		_UserInfo("Autodiluted", 0,0);
	}
	

	// Look up reference pulse heights,
	// use them to decide which ports to open for post-sample reference pulses
	// EDIT DELAYS HERE if needed to optimize pulse duration/separation,
	// then extend your method to match
	number iPeak;
	for(iPeak=1; iPeak <=3; iPeak++;){
		call openRefsByHeight(peakFromReg, Ref1Height, Ref2Height, Ref3Height);
		_Delay(25000);
		call setRefs(0,0,0);
		_Delay(20000);
	}

	_Set("Gas Bench/Split", OUT);
	call setRefs(0,0,0);
	
	call WaitForScanEnd();
	
}
//--------------------------------------------------------------------------------------------------------------------------
