# Installation #

## Dependencies ##

The toolbox uses code projects developed by the Kahana Computational Memory Lab at UPenn.  Since these projects are not updated regularly, we plan on setting up public read-only access to the necessary SVN projects, eeg\_toolbox (unstable branch) and beh\_toolbox. In the meantime, packages (including current versions of dependencies) are released periodically on the Downloads page.

Pattern classification requires the [Princeton MVPA toolbox](http://code.google.com/p/princeton-mvpa-toolbox/).  To generate PDF reports, you must have a distribution of LaTeX installed and have latex, pdflatex and dvipdf on your path.

For now, a version of all the dependencies (except LaTeX) are included with the download.

## Setup ##

Download the toolbox, open MATLAB, and change into the main toolbox directory.  Then enter

```
init_eeg_ana
```

to add the necessary directories to your path.