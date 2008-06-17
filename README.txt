Note: I started this
separate CVS project for development purposes.  When it is stable,
this set of scripts may get moved into the eeg_toolbox.

NWM
3/10/08

This is an addition to the eeg_toolbox that is designed to handle the
higher-level aspects of eeg analysis.  It centers around a struct
called "exp" that holds all of the information relating to a given
experiment.  Sub-structs called "subj," "sess," and "chan" hold information
about each subject, their sessions, and the channels that EEG data were
recorded from.  As analyses are carried out, more structs (here
referred to as "objects") are added onto the exp struct to keep track
of filenames, figures, etc.

-- initial creation of the exp struct --
First, you need to create a "subj" struct that contains the identifiers for
all the subjects in your experiment, as well as the locations of
the raw data for each of their sessions.

For example, an m-file that creates subj could look like this:
   subj(1).id = 'UP001';
   subj(1).sess(1).dir = '/data/eeg/UP001/catFR/session_0';
   subj(1).sess(2).dir = '/data/eeg/UP001/catFR/session_1';
   subj(2).id = 'UP002';
and so forth.

Once you have a subj struct with all the sessions you want to analyze,
run init_scalp.m or init_iEEG.m to create the exp struct.

-- the exp struct --
Note that the exp struct contains a number of filenames.  If you
change from working on the cluster to working on a local machine (or
vice versa), the filenames will be incorrect.  To remedy this, use
loadStruct.m to load the exp struct.  It will run strrep recursively
on every string in the struct or any of its sub-structs, and so can 
be used to change filenames systematically.

Since there is only one exp struct, scripts in the toolbox take care to make sure that no two nodes try to access it at the same time.  Also, each time the exp struct is modified using update_exp.m, a backup is saved in a .mat file whose filename contains the current data and time.  If you encounter any problems with information in the exp struct being overwritten or deleted, load the latest backup, check it, and if it looks ok make it the current exp struct with a save(exp.file, 'exp') command.

-- ev objects --
In order to use events structs with this toolbox, you must import them
into the exp struct.  Since events structs can be large, the struct
itself is not stored in exp, just the filename of it.  Info about events
structs is stored in 
"ev" objects.  Run addEvents.m to incorporate existing events structs 
into the exp struct, or use post_process_exp.m if you have unprocessed 
EGI data.

-- pat objects --
Most analyses create "patterns."  Here "pattern" is a general class of
data that is arranged in matrices of these dimensions:

events X channels X time X frequency

Note that any of these dimensions can be singleton.  For example,
voltage patterns don't have a frequency dimension.  The functions that
operate on patterns are designed to work with both three- and 
four-dimensional patterns, as long as the existing dimensions are in
the correct positions.

Each pattern is saved with corresponding "masks."  A mask is a boolean
matrix that is the same size as its corresponding pattern.  Each mask
marks parts of the pattern that may have problems.  The kurtosis
mask marks events with high kurtosis, and the artifacts mask marks
periods of blink artifacts.  When running an analysis later, you can
indicate which masks to apply as filters before running an analysis on
a pattern.

Information about each pattern is stored in a "pat" object that is
attached to each subject.  The "dim" sub-struct of the pat
object keeps track of info relating to each of the four dimensions,
and the "file" field gives the filename of the pattern itself.

Once patterns are created with one of the creation scripts in the
patterns folder, a number of scripts can manipulate them.

- modify_pat.m can be used to 
average over adjacent timebins or
frequencies to create lower-resolution patterns, or average over 
adjacent channels for ROI analyses.  It can also be used to average over subsets of events.  The
events dimension of the new pattern that is created is collapsed to
be the same length as the number of conditions.  For example, you
might filter to look at only word presentation events, then average over
recalled item events and average over not recalled item events 
to get an events dimension of length 2.

-- fig objects --
These objects are sub-structs of pat objects, and are designed to keep
track of the filenames of figures created from a given pattern.  They
can hold erps, spectrograms, topoplots, and whatever other figures you
come up with.  Each fig object has a "name" field so it can be
accessed later when creating pdf reports.  pat_plots.m and
pat_topoplots.m can be used to create basic figures.

-- reports --
report_by_channel.m creates a custom pdf report using whatever fig objects
you specify, with one row for each channel.
