# Data Structures #

The EEG Analysis Toolbox uses a number of standard data structures, including "objects" that represent [experiments](Experiments.md),  and [events](Events.md) in the experiment.  EEG data is represented in [patterns](Patterns.md); running analyses adds [statistics](Statistics.md) objects to patterns.  Each of these objects has a unique name, allowing different analyses to easily be saved and recovered later.

Plots are automatically stored in [Figure](Figure.md) objects, which contain references to the saved figures.  These figure objects can then be used to generate PDF [Reports](Reports.md) which are organized by subject and / or dimensions like electrode or time bin.