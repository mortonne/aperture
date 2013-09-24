
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

Notes on manual component identification
===========================

Initial notes
---------

Working on new workflow that is only partially automated, relying on raters to determine whether a component should be excluded. But, rather than just using standard EEGLAB tools, will use a different interface to speed component inspection.

We begin with unprocessed data. No channels have been interpolated, no rereferencing has been done. The data are exported from NetStation with a highpass filter above 0.1 Hz. I've found that filtering higher (even just 0.5 Hz) causes noticeable distortions near blink artifacts. It's possible that a different type of filter might perform better, but leaving this be for now.

Channels with poor contact are identified by outlier statistics. These channels are excluded from the ICA, and interpolated after ICA is complete. Based on my initial explorations, this part of the process (implemented in faster_pattern) seems reliable for a variety of datasets.

I've explored two ways of identifying epochs that will interfere with ICA. One is currently implemented in faster_pattern. It looks for epochs with many electrodes showing large voltage deflections (median change 100 uV?). This seems to do well at finding epochs with large changes that are not due to just blinks or eye movements, but to bigger problems like large movements causing electrode shifts. I'm currently investigating an alternate method, which may have fewer assumptions. In this method, ICA is run on all epochs. Then epochs with high variance in many components are identified (I look for outliers, based on IQR), and excluded from a second pass of the ICA. I'm hoping this will allow inclusion of more epochs, if some high-amplitude artifacts can be absorbed by components. It relies on a relative measure (IQR), so this might fail for particularly contaminated or pure datasets. I'll have to compare the methods on a range of datasets to be sure what the best method is. I think both are preferable to the FASTER method, which isn't very sensitive, especially for highly contaminated data.

Next, we run the final ICA, with bad channels and bad epochs excluded. Any overlap between epochs is temporarily removed for this process, and then the data are placed back into the original segments. At this point, a PDF report with statistics about each component is generated, and the PDF is sent to a rater. The rater labels each channel according to the rating scheme of McMenamin et al. Figures for each component include topography, power spectrum, ERP image, and the 10 epochs with highest variance. The last part isn't included in the standard EEGLAB protocol, but seems to be part of how every ICA lab does component identification.  Hopefully these figures will be sufficient; as we test the procedure with different raters and datasets, additional required measures may become clear. The goal is to make it possible to identify components with only the PDF, making the process much faster and more convenient. Once the ratings are complete, clearly artifactual components are rejected, and the remaining components are projected back to sensor space to obtain cleaned voltage data.

Next, bad channel-epochs are identified using the FASTER statistics (and others?). If less then 10% of electrodes are bad for a given epoch, they are interpolated. Otherwise, the epoch is excluded.

After channel-epoch interpolation, the data are converted to an average reference. By having the interpolation step before referencing, we avoid propogating noise on individual channels to all other channels.

Bad channel-epochs are identified again, and interpolation/exclusion is done as before.

Finally, bad channels are interpolated from the other channels.

Procedure
--------

Load voltage epochs, with a notch filter around 60 Hz and a 0.1 highpass filter. Epochs should be long enough and have high enough sample rate to allow power calculation.

Identify bad electrodes, based on FASTER statistics. To keep eye movements from influencing bad electrode identification, first regress out EOG (HEOG and both VEOG pairs). Also do selection separately for frontopolar and non-frontopolar electrodes, and use special rules for the important VEOG channels. This may be complex enough to warrant going back to manual identification of bad electrodes.

Run ICA on all epochs, with bad electrodes excluded. Look for epochs where the relative variance (compared to other epochs) is high on average over components. This should find epochs that were poorly separated into components, suggesting that the assumptions of ICA were violated (probably due to electrodes moving or skin potentials). Run ICA again with those epochs removed. Repeat until no more bad epochs, or 10 iterations. If reaches 10 iterations, consider excluding that session.

Create PDF report with component properties. 

Send PDF to rater for manual identification of component type.

Read in identified component types. Including only components rated as neurogenic. Project back to sensor space.

Interpolate bad channels.

Identify bad channel-epochs based on statistics. Interpolate when 12 or fewer in an epoch; reject epoch if greater than 12.

Convert to an average reference.

Identify and interpolate bad channel-epochs.

