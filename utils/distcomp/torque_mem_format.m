function mem_str = torque_mem_format(str_in)
%MEM_REQ_TORQUE   Reformat memory requirements from SGE to TORQUE
%
%  mem_str = torque_mem_format(str_in)
%
%  INPUTS:
%    str_in:  A string indicating node memory requirements in SGE
%             format (e.g. '1.7M').
%
%  OUTPUTS:
%   mem_str:  A string indicating node memory requirements in
%             TORQUE format (e.g. '1700kb)
%

% sanity checks
if ~ischar(str_in)
  error('Input must be a string.')
end

if isempty(str_in)
  mem_str = str_in;
  warning('No memory requirement set.')
  return
end

% parse out memory components into value and size
req = regexp(str_in, ...
             '^(?<num>(\d+\.?\d+|\d+))(?<size>([MmGgKk][Bb]?|[Bb]))$', ...
             'names');

if isempty(req)
  % if no match, error
  error('Invalid memory requirement.')
end

% size check
mem_size = check_size_req(req.size);

% value check
mem_num = str2num(req.num);
if rem(mem_num,1) ~= 0
  if strcmp(mem_size,'b')
    error('Invalid memory requirement.')
  end
  
  % multiply by 1000, round to int
  mem_num = mem_num*1000;
  mem_num = round(mem_num);
  
  % adjust size accordingly
  mem_size = strrep(mem_size,'k','');
  mem_size = strrep(mem_size,'m','k');
  mem_size = strrep(mem_size,'g','m');
else
  % ensure that mem_num ~= X.0
  mem_num = round(mem_num);
end


mem_num = num2str(mem_num);
% concatenate num and size
mem_str = strcat(mem_num,mem_size);


function size_str = check_size_req(size_str_in)
% convert block size requirements to torque format
% Steps:
% 1) ensure lowercase (e.g. M->m)
% 2) format check (e.g. m->mb)

% ensure lowercase
size_str = lower(size_str_in);

% format check
if length(size_str)<2 & ~strcmp(size_str,'b')
  size_str = strcat(size_str,'b');
end
