# Statistical Maps #

By running a univariate test such as a _t_-test or ANOVA on every sample in a pattern, one can create a statistical map to determine which time samples/electrodes/frequencies show a given effect.

## Creation ##

Statistical maps are created using `pattern_statmap`.  It is flexible, and can use any function that follows one of the following forms:

```
[a,b,c,...] = f_stat(x, ...)
```

or

```
[a,b,c,...] = f_stat(x, group, ...)
```

If the function uses regressors.  `group` is a cell array where each cell contains one factor, which may be represented as a numeric array or a cell array of strings.  Each unique value in each factor represents a different group.  The regressors are generated from the events structure associated with the pattern; the `reg_defs` input to `pattern_statmap` defines how the events should be divided up.  `reg_defs` is a cell array, where each cell gives the definition for one factor.  See `make_event_index` for allowed definition types.

The test will be run on each sample in the pattern, and saved to a new [stat object](Statistics.md).  By default, the variables in the new file will be named _p_, _statistic_, and _res_.  The statistics function may return either a scalar for each output, or vectors if it is testing multiple effects (e.g. an _N_-way ANOVA).

Note that in order to plot the statistical map with the toolbox plotting functions, significance values must be saved in a variable named "p."

## Plotting ##

Plotting functions in the toolbox can plot statistics generated from `pattern_statmap`.  First, you must indicate the `stat_name` you indicated when running `pattern_statmap`; this specifies which statistics object should be used.  The significance map "p" will be loaded.  There is also an optional input `stat_index` which allows you to choose which _p_-value to plot if the test includes multiple effects.  `stat_index` may be an integer, or a string indicating the name of an effect if there is a cell array of strings called "names" saved in the stat file.

Finally, there are two params which determine whether a given sample should be plotted as significant: _alpha_ and _correctm_.  _alpha_ sets the criterion for a _p_-value to be significant (default is 0.05).  _correctm_ specifies options for running correction for multiple comparisons, and can run Bonferroni or false discovery rate (FDR) correction (default is to plot uncorrected significance).