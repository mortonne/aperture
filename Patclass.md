# Pattern Classification #

## Preparing data ##

Any pattern object can be classified.  Each element of the associated events structure must contain enough information to determine which class each event belongs to.  Also, if you're using cross-validation, the events structure must have a field or fields that contain information for splitting up the data for cross-validation iterations.

## Cross-validation ##

Usually the ability of a pattern classifier to generalize to a new dataset is assessed using a cross-validation or leave-one-out method.  For example, the classifier might be trained on all but one block of an experiment, then tested on the remaining block.  This process is repeated so that each block is tested, and then performance is averaged over the cross-validation iterations.  Cross-validation is accomplished using `classify_pat`.  Iterations can be defined using the events structure through the _selector_ input.

## Testing on a different set of events ##

In some cases you might instead want to train on one set of events, and test on another.  In this case where cross-validation is not necessary, you should use `classify_pat2pat`.  It allows you to train the classifier on one pattern and test on another.

## Classifiers ##

The toolbox supports all of the classifiers available in the [Princeton MVPA toolbox](http://code.google.com/p/princeton-mvpa-toolbox/).

## Performance metrics ##

The toolbox supports all of the performance metrics available in the [Princeton MVPA toolbox](http://code.google.com/p/princeton-mvpa-toolbox/).  After classification is complete, you can convert the performance results into a new pattern using `create_perf_pattern`.  This then allows you to plot classifier performance using any plotting function in the toolbox.

## Writing extensions ##

### Classifiers ###

See mvpa/core/template/train\_template.m, test\_template.m, and perfmet\_template.m for examples of how to write new training, testing, and performance metric functions, respectively.

### Feature selection ###

Feature selection functions are applied to the training set before learning on each cross-validation iteration. They output a p-value which is thresholded at a given alpha value to determine which features will be used for training. Feature selection functions must have the form:

```
p = my_feature_select_function(train_pattern, train_targets, ...)
```

Where `train_pattern` is an (observations) X (features) matrix, `train_targets` is a (observations) X (class) matrix (see MVPA documentation for details), and `p` is a vector giving the p-value for each variable. You may also use additional constant inputs. Note that, at the point that the function is applied, all dimensions besides observations (events) have been combined. So, for example, if you have voltage values at 129 electrodes and 10 time points measured at 100 observations, you will have a 100 X 1290 `train_pattern`.