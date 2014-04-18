function elo = init_elo(EEG, varargin)

def.name = EEG.setname;
def.type = 'elo';
def.file = fullfile(EEG.filepath, EEG.filename);
def.filename = EEG.filename;
def.filepath = EEG.filepath;
def.source = EEG.subject;
elo = propval(varargin, def);

