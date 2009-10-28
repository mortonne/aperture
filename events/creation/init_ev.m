function ev = init_ev(name, varargin)
%INIT_EV   Initialize an ev object to hold events metadata.
%
%  ev = init_ev(name, ...)
%
%  Create an ev object that holds metadata about an events structure.
%
%  INPUTS:
%     name:  string identifier for the events.
%
%  OUTPUTS:
%       ev:  an ev object with the following optional fields, which can
%            be set by passing parameter, value pairs as additional
%            arguments:
%
%             source - string identifier of the source of the events,
%                      e.g. a subject ID
%             file   - path to the MAT-file where the events structure
%                      will be saved
%
%  EXAMPLES:
%   % create an events structure
%   my_events = struct('subject', repmat({'subj00'}, 1, 10));
%
%   % initialize an ev object
%   ev = init_ev('my_events', 'source', 'subj00');
%
%   % add the events to the .mat field of ev
%   ev = set_mat(ev, my_events);
%
%   % initialize an object with a "file" field
%   ev = init_ev('my_events', 'source', 'subj00', 'file', 'events.mat');
%
%   % save the events to file
%   ev = set_mat(ev, my_events);

% input checks
if ~exist('name', 'var')
  error('You must specify a name for the ev object.')
end

% set defaults
def = struct('name',   name, ...
             'source', '',   ...
             'file',   '',   ...
             'len',    NaN);

try
  in = struct(varargin{:});
catch
  error('Additional inputs must be parameter, value pairs.')
end

ev = combineStructs(in, def);
ev = orderfields(ev, def);

% sanity checks
if ~ischar(ev.name)
  error('name must be a string.')
elseif ~ischar(ev.source)
  error('source must be a string.')
elseif ~ischar(ev.file)
  error('file must be a string.')
elseif ~(isnan(ev.len) || isinteger(ev.len))
  error('len must be an integer.')
end

