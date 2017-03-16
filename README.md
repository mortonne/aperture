# Aperture

Aperture is a MATLAB-based toolbox for exploratory analysis of EEG data. It supports both univariate analysis and multivariate pattern analysis, and can process large amounts of data in parallel. It interfaces with R to provide advanced statistics, and includes advanced plotting functions and can generate PDF reports to help with exploratory analysis. See the [Wiki](https://github.com/mortonne/aperture/wiki) for an introduction to using the various capabilities of the toolbox.

Aperture is built on a collection of functions for analyzing scalp EEG and ECoG data developed in the Computational Memory Lab at University of Pennsylvania. The project is currently maintained by the Polyn lab at Vanderbilt University. The toolbox was formerly known as eeg_ana or EEG Analysis Toolbox.

# Installation

For a full installation, you must obtain some dependencies:

* [Princeton MVPA Toolbox](http://code.google.com/p/princeton-mvpa-toolbox/)
  * Place in aperture/externals/mvpa
* [EEGLAB](http://sccn.ucsd.edu/eeglab/)
  * Place in aperture/externals/eeglab

You may also edit `init_aperture.m` to change the expected paths if
you have these dependencies installed somewhere else. Compatibility
with the latest versions of these external packages has not been
tested. If you run into issues, try using the versions of these
dependencies that are available on the project's old Google Code site
[download page](https://code.google.com/p/eeg-analysis-toolbox/downloads/detail?name=eeg_ana_0.6.0.zip),
in the `external` directory.

To install the package, simply download the package, add the main
project directory to your path (e.g. `addpath('my/path/to/aperture')`)
and type `init_aperture` to add the necessary directories to your
path.

To use reporting functions that produce PDF reports, you must have LaTeX 
installed and have latex, pdflatex and dvipdf on your path.

Distributed computing options require the MATLAB Distributed Computing
 Toolbox.

# Publications using Aperture

Rose, N. S., LaRocque, J. J., Riggall, A. C., Gosseries, O., Starrett, M. J., Meyering, E. E., & Postle, B. R. (2016). Reactivation of latent working memories with transcranial magnetic stimulation. Science, 354(6316), 1136–1139. http://doi.org/10.1126/science.aah7011

Morton, N. W, Kahana, M. J., Rosenberg, E. A., Baltuch, G. H., Litt, B., Sharan, A. D., Sperling, M. R., and Polyn, S. M. (2013) Category-specific neural oscillations predict recall organization during memory search. Cerebral Cortex, 23(10), 2407-2422.

LaRocque, J. J., Lewis-Peacock, J. A., Drysdale, A. T., Oberauer, K., and Postle, B. R. (2012) Decoding attended information in short-term memory: An EEG study. Journal of Cognitive Neuroscience, 25(1), 127-142.

Morton, N. W, and Polyn, S. M. (2017) Beta-band activity represents the recent past during episodic encoding. NeuroImage, 147, 692-702.

# Authors
* Neal Morton
* Sean Polyn
* Zachary Cohen
* Matthew Mollison
* Joshua McCluey
