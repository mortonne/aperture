function chan_numbers = perimeter_chans(cap_type)

if ~exist('cap_type','var')
  cap_type = 'HCGSN128';
end

switch cap_type
  case 'HCGSN128'
  % going clockwise from Nz
  chan_numbers = [17 14 8 126 1 125 119 113 107 99 94 88 81 ... % right side
                  73 68 63 56 49 48 128 127 25 21]; % left side
  
  otherwise
  error('Unknown cap type.')
end
