function subj = apply_to_ev(subj, ev_name, fcn_handle, fcn_inputs, dist)
%APPLY_TO_EV   Apply a function to an ev object for all subjects.
%
%  subj = apply_to_ev(subj, ev_name, fcn_handle, fcn_inputs, dist)
%  
%  INPUTS:
%        subj:  a [1 X N subjects] structure representing each subject
%               in an experiment.
%
%     ev_name:  the name of an ev object that has been created for at
%               least one of the subjects in the subj vector.
%
%  fcn_handle:  a handle for a function of the form:
%                [ev, ...] = fcn(ev, ...)
%               If the name of the output ev object is different
%               from ev_name, a new object will be added to each
%               subject; otherwise, the existing object will be
%               overwritten.
%
%  fcn_inputs:  a cell array of additional inputs (after ev) to
%               fcn_handle.  If fcn_inputs = c, then fcn_handle will be
%               called with:
%                ev = fcn_handle(ev, c{1}, c{2}, ... c{end})
%
%        dist:  distributed evaluation; see apply_to_subj for possible
%               values.
%
%  OUTPUTS:
%        subj:  a modified subjects vector.
%
%  EXAMPLES:
%   % create a subj structure with ten subjects with ev objects
%   id = num2cell('a':'j');
%   subj = struct('id', id, 'ev', init_ev('my_events'));
%
%   % add a new field to each ev object
%   f = @(ev) setfield(ev, 'newfield', 'spam');
%   subj = apply_to_ev(subj, 'my_events', f);
%
%   % create a copy of "my_events"
%   f = @(ev, new_ev_name) setfield(ev, 'name', new_ev_name);
%   subj = apply_to_ev(subj, 'my_events', f, {'new_events'});
%
%  See also modify_events, apply_to_pat, apply_to_subj_obj.

% input checks
if ~exist('subj','var')
  error('You must pass a subjects vector.')
elseif ~exist('ev_name','var')
  error('You must specify the name of an events structure.')
elseif ~exist('fcn_handle','var')
  error('You must pass a handle to a function.')
end
if ~exist('fcn_inputs','var')
  fcn_inputs = {};
end
if ~exist('dist','var')
  dist = false;
end

% run the function on each subject
subj = apply_to_subj_obj(subj, {'ev', ev_name}, fcn_handle, fcn_inputs, dist);

