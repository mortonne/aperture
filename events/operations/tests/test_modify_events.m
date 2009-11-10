classdef test_modify_events < mlunit.test_case
  properties
    ev
    event
    ev_file = 'events_temp.mat';
    res_dir = 'new_events';
  end
  
  methods
    function self = test_modify_events(varargin)
      self = self@mlunit.test_case(varargin{:});
      self.ev = init_ev('test_events');
      self.event = repmat(struct('type', 'test'), 1, 10);
    end
    
    function self = test_hd_overwrite(self)
      % save events to disk
      ev = self.ev;
      ev.file = self.ev_file;
      ev = set_mat(ev, self.event);
      
      % overwrite the old events
      params = struct('overwrite', true);
      ev = modify_events(ev, params);
      
      % check location
      mlunit.assert(strcmp(get_obj_loc(ev), 'hd'), 'ev in ws.');
      
      % check file
      mlunit.assert(strcmp(ev.file, self.ev_file), 'ev in new file.');
      
      % check modified label
      mlunit.assert(~ev.modified, 'ev modified.');
    end
    
    function self = test_hd_rename(self)
      % save events to disk
      ev = self.ev;
      ev.file = self.ev_file;
      ev = set_mat(ev, self.event);
      
      % save to a new events file
      ev_name = 'test_events_mod';
      params = struct('overwrite', true);
      ev = modify_events(ev, params, ev_name, self.res_dir);
      
      % check location
      mlunit.assert(strcmp(get_obj_loc(ev), 'hd'), 'ev in ws.');
      
      % check file
      mlunit.assert(~strcmp(ev.file, self.ev_file), 'ev in old file.');
      
      % check modified label
      mlunit.assert(~ev.modified, 'ev modified.');
    end
    
    function self = test_ws_overwrite(self)
      % add events to the workspace
      ev = set_mat(self.ev, self.event);
      
      % overwrite the existing events
      ev = modify_events(ev);
      
      % check location
      mlunit.assert(strcmp(get_obj_loc(ev), 'ws'), 'ev in hd.');
      
      % check modified label
      mlunit.assert(ev.modified, 'ev not modified.');
    end
    
    function self = test_ws_rename(self)
      % add events to the workspace
      ev = set_mat(self.ev, self.event);
      
      % rename the events
      ev_name = 'test_events_mod';
      ev = modify_events(ev, struct, ev_name);
      
      % check location
      mlunit.assert(strcmp(get_obj_loc(ev), 'ws'), 'ev in hd.');
      
      % check name
      mlunit.assert(strcmp(ev.name, ev_name), 'old ev name.');
      
      % check modified label
      mlunit.assert(ev.modified, 'ev not modified.');
    end
  end
end
