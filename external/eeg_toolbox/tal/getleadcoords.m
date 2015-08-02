% function [leads,X,Y,plotwidth,legendlead]=getleadcoords(fname)
% This function reads the files fname, properly formatted as a lead coordinates
% files, and returns the plotwidth (from the first line), the lead # at which
% to put the legend (legendlead, also from the first line),the lead # in the 
% variable, leads, (from the subsequent first column), and the corresponding
% relative X and Y values (scaled from the second and third columns,
% respectively
function [leads,X,Y,plotwidth,legendlead]=getleadcoords(fname)

fprintf(1,'\nError: I''m using getleadcoords.m. This is obselete. Please upgrade to getleads.m\n');
in=fopen(fname,'rt');
plotwidth=fscanf(in,'%f',1); legendlead=fscanf(in,'%f',1);
A=fscanf(in,'%i',[3,inf]);

if(size(A,2)>1)
 A(2,:)=0.8*( (A(2,:)-min(A(2,:)))/(max(A(2,:))-min(A(2,:))) );
 A(3,:)=0.75*( (A(3,:)-min(A(3,:)))/(max(A(3,:))-min(A(3,:))) );
 A(2,:)=A(2,:)*(1-plotwidth)+0.1;
 A(3,:)=A(3,:)*(1-plotwidth)+0.05;
end

leads=A(1,:); X(leads)=A(2,:); Y(leads)=A(3,:);
