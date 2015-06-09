# Experiments #

The experiment, or _exp_ structure holds basic information about your experiment in a standard format. Once you have created an exp structure that points to your data, you can begin creating [events](Events.md) and [patterns](Patterns.md).

A vector structure, _subj_, holds information about each subject that has run in the experiment so far. A sub-structure of each subj called _sess_ contains information about each session.  If the subject ran in an EEG experiment, there will also be a _chan_ structure to keep track of information about each electrode.  See below for an explanation of each field.

| Field | Type | Description |
|:------|:-----|:------------|
| experiment | string | name of the experiment |
| recordingType | string | type of recording, if applicable (e.g. EEG, fMRI, ECoG) |
| resDir | string | path to the directory where results of analyses will be saved |
| file  | string | path to the MAT-file where this object is saved |
| lastUpdate | string | last time this object was saved |
| subj  | struct | vector structure containing information about subjects (see below) |

## Display ##

Use `exp_disp` or `subj_disp` to display a summary of an experiment object.

## Moving and copying ##

Note that the exp object contains a number of filenames. If you
change from working on a remote machine to working on a local machine (or vice versa), the
filenames will be incorrect. To remedy this, use `struct_strrep`.
It will run strrep recursively on every string in the struct or any of its
sub-structs, and so can be used to change filenames systematically.

Let's say you want to take an experiment structure created by someone else, and work with it in your own directory.  `copy_exp` is useful to create a copy that you can work from.  However, you must be careful not to save new files to their directory.  Most functions have an optional `res_dir` input you can use to override the default output directory.

`move_exp` can be used to move an entire set of results; it will move not only the exp object, but also all the results.  This will only work if all of your results are saved under `exp.resDir` (the default).

## Backups ##

Each time an exp object is saved using `update_exp`, a time-stamped backup is created; you may also specify a log message to help recover a specific backup later.  Use `exp_log` to see a list of backups, and `load_exp` to load a specific backup.

## Subjects ##

Information about the subjects who have run in the experiment is stored in a vector structure called _subj_:

| Field | Type | Description |
|:------|:-----|:------------|
| id    | string | identifier of the subject |
| dir   | string | (optional) path to the directory where raw data is saved |
| sess  | struct | (optional) vector structure with "number" and "dir" fields for each session |
| chan  | struct | (optional) vector structure containing electrode information |

Generally, subj structs can be made automatically using `get_sessdirs`, and electrode information can be imported using `import_channels`.  The _dir_, _sess_, and _chan_ fields are necessary only for importing raw data; if you're importing segmented data from another toolbox like EEGLAB, these fields aren't necessary.