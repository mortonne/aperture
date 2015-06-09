# Events #

Information about the experiment is stored in a vector structure called an _events structure_.  This may have any number of fields, each of which keeps track of some value as it changes throughout the experiment.

Events structures are used to define factors for running statistics; for example, you might have a field called "response" that contains 1 for correct responses and 0 for incorrect responses.  This field could then be used as a factor in a _t_-test or for pattern classification.

## Events objects ##

Since events structures can be large, they are generally not stored as part of the experiment structure.  Instead, they are stored on the hard drive; the experiment merely contains links to saved events structures.  Each events structure has a unique name that can be used to access it.  For example, to retrieve "study" events from subject "LTP015":

```
events = get_mat(getobj(exp, 'subj', 'LTP015', 'ev', 'study'));
```

`getobj` retrieves information about the events (including the path to the MAT-file where it is stored), and `get_mat` loads the events structure.

## Examining events ##

To view an events structure as a table, use `disp_events`.

## Filtering events ##

To return a subset of events, use `filterStruct`.  This function allows one to define a subset of events using a _filter string_, and is called by many toolbox functions.

## Creating factors ##

`make_event_index` is used by many functions in the toolbox to generate factors for statistical analyses, and allows for creating factors from fields or combinations of fields, filter strings, and random subsets of events. See [Regressors](Regressors.md) for details.

When an events dimension is binned, for example when averaging over events, some fields of the events structure will become ambiguous.  That is, the events in the bin might have multiple values on some field.
In this case, the field will be removed from the events structure.  On the other hand, fields that have the same value throughout the bin will be kept as part of the events structure.