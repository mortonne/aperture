function create_events(exp,eventsfcn,eventsfcninput,varargin)
%CREATE_EVENTS   Create events for each session in the exp struct.
%   CREATE_EVENTS(EXP,EVENTSFCN,EVENTSFCNINPUT,VARARGIN)
%
%   Parameters:
%     'eventsfile'
%     'files2check'
%     'agethresh'

def.eventsfcninput = {};
def.eventsfile = 'events.mat';
def.files2check = {'session.log', '*.par'};
def.agethresh = .8;

[eid,emsg,eventsfcninput,eventsfile,files2check,agethresh] = getargs(fieldnames(def),struct2cell(def),varargin{:});

for subj=exp.subj
  for sess=subj.sess
    cd(sess.dir);
    
    % check for recently modified files
    if exist(eventsfile,'file') && ~isempty(files2check) && ~filecheck(files2check,agethresh)
      % none found for this session; skip
      continue
    end
    
    % create events and save
    fprintf('Creating events for %s, session %d using %s...\n', subj.id,sess.number,func2str(eventsfcn))
    events = eventsfcn(sess.dir, subj.id, sess.number, eventsfcninput{:});
    save(eventsfile, 'events');
  end
end



function update = filecheck(files,agethresh)
  %FILECHECK   See if any files have been recently modified.
  %   UPDATE is false if none of the files in cell array
  %   FILES have been modified in the past AGETHRESH days.
  %
  
  update = 0;
  if length(files)==0
    error('files must be a cell array containing paths')
  end
  
  for i=1:length(files)
    d = dir(files{i});
    if length(d)==0
      return
    end
    for i=1:length(d)
      age = now - datenum(d(i).date);
      if age<agethresh
        update = 1;
        return
      end
    end
  end
%endfunction
