function [x, levels] = load_pattern_by_factor(pat, bin_defs, varargin)
%LOAD_PATTERN_BY_FACTOR   Load pattern data organized by factors in events.
%
%  Use to load pattern data organized by different factors defined by
%  events. Each dimension of the returned pattern corresponds to one
%  factor, and the elements of the dimension to levels of the factor.
%
%  [x, levels] = load_pattern_by_factor(pat, bin_defs)
%
%  INPUTS:
%       pat:  pattern object. All dimensions execpt events must be
%             singleton.
%
%  bin_defs:  cell array with one element for each factor. bin_defs{i}
%             will be input to make_event_index to define the
%             levels of factor i.
%
%  OUTPUTS:
%        x:  matrix of pattern data. x(i,j,k,...) contains data
%            corresponding to level i of factor 1, level j of factor 2,
%            level k of factor 3, ect.
%
%   levels:  cell array with one element for each factor, containing the
%            original labels for the factors. levels{i}{j} contains the
%            label for level j of factor i.

def.data_type = 'pattern';
def.field = '';
opt = propval(varargin, def);

events = get_dim(pat.dim, 'ev');

switch opt.data_type
  case 'pattern'
    pattern = get_mat(pat);
  case 'events'
    pattern = [events.(opt.field)];
  otherwise
    error('Unknown data_type: %s', opt.data_type);
end

[x, levels] = load_mat_by_factor(pattern, events, bin_defs);

