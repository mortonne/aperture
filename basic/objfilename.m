function filename = objfilename(obj_type, obj_name, source, varargin)
%OBJFILENAME   Construct a standard filename for an object.
%  
%  Use this function to generate a filename that will be unique for a
%  given object.
%
%  filename = objfilename(obj_type, obj_name, source, ...)
%
%  INPUTS:
%  obj_type:  type of object, e.g. 'pat', 'ev'
%
%  obj_name:  string identifier of the object. Should be the same as
%             obj.name.
%
%    source:  source of the object. Generally this will be
%             parent_obj.name.
%
%  Additional inputs should be strings; they will be added to the end of
%             the filename. Spaces will be removed; periods will be
%             replaced by underscores.
%
%  EXAMPLES:
%   % generate a filename for an events object
%   objfilename('ev', 'study', 'subj02');
%
%   % generate a filename for a figure
%   fig_file = objfilename('fig', 'erp', 'subj01', 'Cz', '100ms');

filename = sprintf('%s_%s_%s', obj_type, obj_name, source);

if ~isempty(varargin)
  fix_str = @(x) strrep(strrep(x, ' ', ''), '.', '_');
  
  added = '';
  for i = 1:length(varargin) - 1
    added = [added fix_str(varargin{i}) '-'];
  end
  added = [added fix_str(varargin{end})];
  filename = [filename '_' added];
end

