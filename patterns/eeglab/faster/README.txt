
Notes on changes from Nolan et al.
======================

Detecting bad channels from epoched data
----------------------------------

Just using raw channels for detection of bad channels is a bad idea when e.g. between-list impedance checks cause large voltage changes. Also, signal during breaks is often very erratic, so it would increase noise in the analysis if it were included. Want to reject channels based on the actual data we're using in the analysis. So changing some code to allow calculation of stats on epoched data.

This seems to only be an issue for the Hurst exponent measure, since it is a temporal measure which will be sensitive to the breaks between different epochs. So that needs to be calculated within the epochs (preferably not too short), then take the median (the distributions can be highly skewed).

Affected files:
channel_properties.m

Correcting for EOG to improve bad channel detection
------------------------------------------

Found that, in datasets heavily contaminated with eye artifacts, that most frontal electrodes are identified as "bad." Since we're using ICA to deal with eye artifacts, we don't want to exclude channels due to eye movements; in fact, they are critical to aid in indentifying blink and eye movement components, so they must not be excluded. Added a regression step to remove most of the variance due to eye movements; it does not distinguish between blinks and eye movements, limiting its accuracy, but it seems good enough for the purpose of bad channel detection.

Also added an option to define a set of frontopolar electrodes, which are evaluated separately from other electrodes, since they tend to have higher variance (in some cases, this is still true even after EOG regression).

Affected files:
FASTER_process.m
new function: reject_channels.m 

Improved outlier detection
---------------------

Found that the z-score method performs poorly in some cases for finding outliers reflecting e.g. bad epochs. For example, if there are many highly noisy epochs, rejecting based on the z-score only removes the worst cases, while leaving many noisy epochs in the data. Added an option (now the default; can be set through rejection_options.stat) for using a non-parametric stat, inter-quartile distance, for outlier detection. The multiple of IQR to use as the threshold (below quartile 1 and above quartile 3) is an option. I've found that 3 works well as a strict threshold.

Affected files:
min_z.m

Detecting EMG
------------

For rejecting single channel epochs and components, they used the median gradient for one of their stats. This seems like a strange choice, since a lot of information was thrown away by using the median of the raw diff values rather than the median of the absolute value of change. For exemple, if for some of the time, there were large alternating positive and negative changes that were perfectly matched in amplitude, then the median change value might be near 0; this is true regardless of how extreme the changes were.

Tested on data contaminated with EMG, and found that affected channels were better identified (specificity and sensitivity) by using taking the median absolute change over time, rather than the median change.

UPDATE: I developed a new method after this. It takes the sum of the squared gradient, and divides by the total sum of squared deviations, where deviation is from the mean for each channel over time. This performs well for identifying components that have spiky activity for some epochs, and are nearly flat for others.

Affected files:
single_epoch_channel_properties.m
component_properties.m

Dealing with overlapping epochs
--------------------------

For power calculation, when ISIs are small and calculating power using wavelets down to 2 Hz, with a wavenumber of 6, need epochs that overlap with one another. This might cause an issue with the ICA; presumably, assumptions are violated when some samples appear multiple times. Before ICA, overlap between epochs with the same sample times is taken out to make a dataset that is partially continuous (i.e., some epochs are merged together). After ICA, the data are moved back to the original segments. 

Added an option (just a hack in FASTER_process.m) to indicate when epochs are overlapping. This needs to be expanded to be more flexible.

Affected files:
FASTER_process.m

Added:
eeg_remove_epoch_overlap.m
eeg_epoch_overlap.m

Bad epoch detection
----------------

Switched to using fixed thresholds for bad epoch detection. If the median maximum voltage change for an epoch over channels is above a certain value, the epoch is rejected completely. I found that an absolute threshold is better for dealing with noisy datasets; using a z-score just takes out the worst epochs, leaving a number of less-bad, but still bad, epochs. This threshold is fairly easy to set, but requires some experimentation for the study, cap type, recording, etc. Probably determining one threshold for each type of study and recording setup is sufficient.

Affected files:
none in the FASTER project; remove epochs before running FASTER, and turn off standard epoch rejection

Dealing with undefined properties
---------------------------

Rather than setting undefined properties to the mean over other channels, instead setting to the median. This way, undefined channels are set to 0 once the median is subtracted out. Also, undefined channels should not affect the median.

Affected files:
channel_properties.m
single_epoch_channel_properties.m
component_properties.m

BUG - channel correlations
---------------------

In channel_properties.m, channel correlations were being sorted in order of distance from the reference channel, rather than their input order. This made that stat be in a different order from the others, and could have caused removal of incorrect channels. Fixed this bug in the current version.

Affected files:
channel_properties.m

Possible name for new version: 
SPEED (Signal Preprocessing of ElectroEncephalography Data)

