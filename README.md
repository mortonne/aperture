# APERTURE
This is a MATLAB-based toolbox for analysis of EEG data.

The toolbox uses functions from the EEG Toolbox developed at the
University of Pennsylvania Computational Memory Lab. Pattern
classification uses the Princeton MVPA toolbox, and much of the internal
organization and user interface is based on the MVPA toolbox. 3D
plotting functions are taken from EEGLAB, and other plotting functions
are based on EEGLAB and fieldTrip functions.

# Installation
To install, add all project subdirectories to your MATLAB path. For
example:
`addpath(genpath('path_to_eeg_ana'))`

You must also install some dependencies, including the
[UPenn Behavioral Toolbox](http://memory.psych.upenn.edu/Behavioral_toolbox),
the UPenn EEG Toolbox, EEGLAB, and the
[Princeton MVPA Toolbox](http://code.google.com/p/princeton-mvpa-toolbox/). It
is recommended that you use the versions of these dependencies that
are available on the Google Code site's
[download page](https://code.google.com/p/eeg-analysis-toolbox/downloads/detail?name=eeg_ana_0.6.0.zip),
in the `external` directory.

To use reporting functions that produce PDF reports, you must have LaTeX 
installed and have latex, pdflatex and dvipdf on your path.

Distributed computing options require the MATLAB Distributed Computing
 Toolbox.

# Authors
* Neal Morton
* Sean Polyn
* Zachary Cohen
* Matthew Mollison
* Joshua McCluey
