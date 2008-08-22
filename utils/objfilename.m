function filename = objfilename(objtype,objname,source)
%OBJFILENAME   Construct a standard filename for an object.
%   FILENAME = OBJFILENAME(OBJTYPE,OBJNAME,SOURCE)
%

filename = sprintf('%s_%s_%s.mat', objtype, objname, source);
