# Introduction #

In the toolbox, event-related averages are calculated using `bin_pattern`, which averages subsets of events according to [regressor definitions](Regressors.md).

# Averaging over subsets of events #

`bin_pattern` can average over elements of any dimension of a pattern.  Usually, it is used for averaging over the events dimension, but it can also average within time bins, frequency bins, or over multiple channels in a region of interest (ROI).

To average over events, you must specify which subsets of events you want to average over.  There are various ways of specifying subsets of events, many of which are described in the [regressors](Regressors.md) section.  The simplest example is averaging over all events in a pattern; this is accomplished by setting `eventbins` to 'overall'; this puts all events into one "bin".  All events in a given bin will be averaged together.  By placing all events into the one "overall" bin, you will be averaging over all events.

# Labeling event bins #

In order to help keep track of event subsets, the toolbox will update the events structure of a binned pattern to reflect the binning.  For a given bin, any field that had multiple values over the events in the bin will be removed.  If a field had the same value for every event in a bin, it will remain and will be set to that value.