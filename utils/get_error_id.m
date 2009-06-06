function id = get_error_id(err)
%GET_ERROR_ID   Return the last segment of an error identifier.
%
%  id = get_error_id(err)

% input checks
if ~exist('err','var') || ~isa(err, 'MException')
  error('eeg_ana:get_error_id:NoError', 'You must pass an MException.')
end

% use a regular expression to get the last segment of the id
id = regexp(err.identifier, '(?<=:)\w+$', 'match');
if ~isempty(id)
  id = id{1};
else
  % if no ID, just return an empty string
  id = '';
end
