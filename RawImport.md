# Importing Raw Data #

## Subjects ##

Information about subjects is stored in an [experiment object](Experiment.md).  If you're using the toolbox to import raw data, you will need to import information about where the data are stored, probably using `get_sessdirs`:

```
data_dir = '/path/to/main/data/directory';
subj_str = 'every_subject_id_starts_with_this*';
subj = get_sessdirs(data_dir, subj_str);
```

`get_sessdirs` assumes that there is a directory with sub-directories named for the subjects in the experiment.  `subj_str` is a pattern (may contain stars to indicate a wildcard) that matches the name of every subject directory to import.

Once you have a subjects vector, you can use `init_exp` to create an experiment object.

## Events ##

Information about the [events](Events.md) in an experiment should be saved in a vector structure in each session directory.  Then `import_events` can be used to add references to the events structures to the experiment object.

## EEG Data ##

### Continuous ###

Raw continuous data may be imported from any filetype that is supported by eeg\_toolbox (see `eeg_toolbox/core/io` for data conversion scripts).  Once the data are in a standard format, they must be aligned to the events in the experiment.  See `eeg_toolbox/core/align` for functions to help with alignment.

### EGI ###

EGI data may be prepared for analysis using `prep_egi_data`, which converts the continuous data, aligns it, and average rereferences. The scripts for doing this have been developed for a specific setup used in the Polyn and Kahana labs. This setup uses pyEPL for stimulus presentation, and NetStation for EEG acquisition. The system could potentially be adapted for other setups; low-level functions that are more generally useful can be found in eeg\_toolbox.

To run this on all sessions of a subject, use `post_process_subj`; this also attempts to tell the user about common problems. To prepare EEG data for all subjects, call:

```
exp.subj = apply_to_subj(exp.subj, @post_process_subj, {});
```

There are 3 steps to preparing the data: splitting (changing the input format to the eeg\_toolbox format, which has a separate file for each channel), rereferencing (converting electrodes to an average reference), and alignment (syncing up the behavioral and EEG data.

You can just run a specific step or steps, by setting the 'steps\_to\_run' option. For example, to run only the alignment step:

```
exp.subj = apply_to_subj(exp.subj, @post_process_subj, {'steps_to_run' {'align'}});
```

By default, the prepare functions (`prep_egi_data` being the lowest-level function) make a number of assumptions about the directory structure of the data, which can be changed by setting options. In each session directory (e.g. exp.subj(1).sess(1).dir), there is expected to be an `events.mat` file containing the events for that session. The events must at least have an mstime field, giving the start time of each event in milliseconds. The EEG data are assumed by default to be in a subdirectory of the session directory called `eeg`, and have a .raw file extension (created using the export tool in NetStation to make a binary raw file). The EEG file is expected to have a channel in it corresponding to the sync pulses sent from the stimulus presentation machine, which has a code starting with "D". There is also expected to be a text file in the session directory called eeg.eeglog.up, which contains a line for each sync pulse (sent by PyEPL in our setup) with the time in milliseconds (this must correspond to the times given in the events structure).