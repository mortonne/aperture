# APERTURE

APERTURE is a MATLAB-based toolbox for exploratory analysis of EEG data. It supports both univariate analysis and multivariate pattern analysis, and can process large amounts of data in parallel. It interfaces with R to provide advanced statistics, and includes advanced plotting functions and can generate PDF reports to help with exploratory analysis.

APERTURE is built on a collection of functions for analyzing scalp EEG and ECoG data developed in the Computational Memory Lab at University of Pennsylvania. The project is currently maintained by the Polyn lab at Vanderbilt University. The toolbox was formerly known as eeg_ana or EEG Analysis Toolbox.

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

# Publications using APERTURE

Morton, N. W, Kahana, M. J., Rosenberg, E. A., Baltuch, G. H., Litt, B., Sharan, A. D., Sperling, M. R., and Polyn, S. M. (2013) Category-specific neural oscillations predict recall organization during memory search. Cerebral Cortex, 23(10), 2407-2422.

LaRocque, J. J., Lewis-Peacock, J. A., Drysdale, A. T., Oberauer, K., and Postle, B. R. (2012) Decoding attended information in short-term memory: An EEG study. Journal of Cognitive Neuroscience 25(1), 127-142.

# Authors
* Neal Morton
* Sean Polyn
* Zachary Cohen
* Matthew Mollison
* Joshua McCluey
