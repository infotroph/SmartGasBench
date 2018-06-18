SmartGasBench
=============

## Automated peak-height management for unattended Gasbench analysis of air samples

Christopher K. Black, Michael D. Masters

Contact: chris@ckblack.org

This script setup is intended to solve several problems commonly encountered in Keeling plot analysis: 
	
1. Differing reference and sample peak intensities

	Successful Keeling plots require substantial differences in [CO2] between samples, but in continuous flow IRMS analysis it is common practice to try to match reference and sample gas intensities as closely as possible. Mismatched sample and reference intensities amplify errors from nonlinearity and could systematically bias the estimated Keeling intercept, but for practical reasons large batch analyses have usually required picking one reference intensity to use for all samples.

	To maintain throughput while matching reference and sample intensities across widely varying sample concentrations, we connect the same CO2 tank to all three reference inlets on the Gasbench, and set each to a different flow rate. We can then choose up to seven different peak heights by activating one, two, or three inlets at once. Thanks to Paul Eby for suggesting this method on the Isogeochem list... If a linkable citation for it exists, please tell us.

	To best match reference peaks to each sample without wasting run time on a lot of unused reference peaks with varying heights, SmartGasBench monitors sample peak heights and chooses the reference peak most closely matched to the sample. Notably, reference heights are recalculated every time, so no calibration table is needed and changes in e.g. CO2 pressure at the inlet are automatically accounted for. As long as inlets 1-3 have relative intensities R1 < R2 < (R1+R2) < R3 < (R1+R3) < (R2+R3) < (R1+R2+R3), the script will always pick the one that is closest to the sample.
	
2. Air peaks

	CO2 is introduced in an air matrix, and even after chromatographic separation in the Gasbench, water and N ions can introduce isobaric interference and produce offsets in the measured d13C and d18O of CO2. This effect can be greatly reduced by blanking the sample stream through timed activation of the Gasbench's sample open split at times when the 'air peak' is eluting ([Levitt 2014](http://dx.doi.org/10.1002/rcm.7019)).

	SmartGasBench handles this manually and requires you to edit timings in the script, which is less convenient than specifying them in your Isodat method but is necessary to allow simultaneous autodilution of sample peaks (see below).

3. One-shot dilution

	Samples with extremely high [CO2] may require dilution to bring the peak intensity into a usable range. This is rare in atmospheric samples but not uncommon in e.g. incubated root or soil samples used as endpoints in the Keeling calculation. Thermo provides a method for automatically diluting high-intensity samples using the same open split that is used for air blanking, but this method only signals a single one-time change in open split position after the first sample peak has eluted. If you enable this autodilution in a method with timed split movements for air blanking, the timed split movements will cancel the effect of the autodilution cues and result in no dilution of sample peaks. 

	To fix this, we take a different approach. SmartGasBench stores dilution status in software (as a flag in the Windows registry) instead of hardware, allowing us to cue the split for both air blanking and as-needed sample dilution in the same method.



## Approach

The setup consists of an Isodat method coupled to two ISL scripts: 

* The method `GB smart dilute.met` triggers injection of pre-sample reference pulses and of sample peaks, but not of any open split motions or post-sample reference pulses. It uses `aquisition smart dilution 50C.isl` as its aquisition script. Depending on your system setup, you may want to treat this as an example to build your own method rather than using it directly.
* The aquisition script `aquisition smart dilution 50C.isl` triggers injection of the end-of-run reference peaks and timed dilution of the air peaks, and in turn calls `AutoDilutionByRegistry.isl` to track peak heights and determine whether to dilute the next sample peak.
* `AutoDilutionByRegistry.isl` is called once for each peak, to record the peak height in the Windows registry and decide whether autodilution is needed. If dilution is needed, it cues the aquisition script by setting a registry flag.


Note that this means you have to set timings in both the method *and* the aquisition script:

* Beginning-of-run reference peaks: Set in the method, using whatever timings and reference ports make sense for your application. Then match timings by adjusting delays in the aquisition script so that it finds and records one reference peak from each of ports 1, 2, and 3.
* Delay before sample injection: Set in the method, adjust delay in the aquisition script to match.
* Threshold for autodilution: Set in the method, no script edits needed.
* Delay between sample injections: Set in the method to obtain good separation between air peaks and sample peaks, then adjust delays before and after air peak dilution in the aquisition script to match.
* Delay after sample injections: Set FIRST in aquisition script, then set method to match.
* Number and timing of post-sample reference pulses: Set in aquisition script, then set method to match. The method should NOT cue any post-sample reference pulses, but rather simply wait long enough for the aquisition script to provide them.

## Hardware

To use the automatic reference peak selection, you need to replumb your Gasbench to run one reference gas through all three inlets, and possibly adjust lengths of reference capillaries as needed to get the best range of peak heights. On our machine used for both atmospheric and incubated samples, I try to tune for heights of 1-2-3-5-6-7-8 volts. 

If you need multiple reference gases or aren't ready/don't have permission to hot-rod your Gasbench, peak height selection won't work but you can still use the autodilution script to minimize influence from air peaks. 

To come: Details on which machines / Isodat versions this does and doesn't work with.


## Installation instructions

To come


## References

Levitt, N.P. (2014) Sample matrix effects on measured carbon and oxygen isotope ratios during continuous-flow isotope-ratio mass spectrometry. Rapid Communications In Mass Spectrometry, 28, 2259–2274. DOI: [10.1002/rcm.7019](http://dx.doi.org/10.1002/rcm.7019).
