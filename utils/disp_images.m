function varargout = disp_images(varargin)
% DISP_IMAGES MATLAB code for disp_images.fig
%      DISP_IMAGES, by itself, creates a new DISP_IMAGES or raises the existing
%      singleton*.
%
%      H = DISP_IMAGES returns the handle to a new DISP_IMAGES or the handle to
%      the existing singleton*.
%
%      DISP_IMAGES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DISP_IMAGES.M with the given input arguments.
%
%      DISP_IMAGES('Property','Value',...) creates a new DISP_IMAGES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before disp_images_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to disp_images_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help disp_images

% Last Modified by GUIDE v2.5 28-May-2014 16:01:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @disp_images_OpeningFcn, ...
                   'gui_OutputFcn',  @disp_images_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before disp_images is made visible.
function disp_images_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to disp_images (see VARARGIN)

% Choose default command line output for disp_images
handles.output = hObject;

% Update handles structure
handles.cur_image = NaN;
handles.images = {};
handles.labels = {};
guidata(hObject, handles);


% UIWAIT makes disp_images wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = disp_images_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in prev_button.
function prev_button_Callback(hObject, eventdata, handles)
% hObject    handle to prev_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[success, handles] = update_cur_image(handles, handles.cur_image - 1);
uicontrol(handles.output)

% --- Executes on button press in next_button.
function next_button_Callback(hObject, eventdata, handles)
% hObject    handle to next_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[success, handles] = update_cur_image(handles, handles.cur_image + 1);
uicontrol(handles.output)

% --- Executes during object creation, after setting all properties.
function display_CreateFcn(hObject, eventdata, handles)
% hObject    handle to display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate display

function [exist_images, exist_labels] = get_state(handles)

exist_images = ~isempty(handles.images);
exist_labels = ~isempty(handles.labels);

% --- Executes on button press in load_button.
function load_button_Callback(hObject, eventdata, handles)
% hObject    handle to load_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dir_name = uigetdir('', 'Select directory with images');

if isequal(dir_name, 0)
    % user canceled selection
    return
end

% read in images
d = dir(fullfile(dir_name, '*.png'));

[exist_images, exist_labels] = get_state(handles);

% sort them by component number
number = NaN(1, length(d));
file = cell(1, length(d));
for i = 1:length(d)
    number(i) = str2num(d(i).name(isstrprop(d(i).name, 'digit')));
    file{i} = fullfile(dir_name, d(i).name);
end
[~, ind] = sort(number);
file = file(ind);

handles.images = cell(1, length(file));
for i = 1:length(file)
    handles.images{i} = imread(file{i});
end

if exist_images
    % assume loading a new dataset to replace old images; forget the
    % previous position in the images, and reset labels
    handles.labels = repmat({''}, 1, length(d));
    handles.cur_image = 1;
elseif ~exist_images && ~exist_labels
    % haven't loaded anything yet; initialize variables as necessary
    handles.labels = repmat({''}, 1, length(d));
    handles.cur_image = 1;
elseif exist_labels
    % check if the input images have the same length as existing labels
    if length(handles.images) ~= length(handles.labels)
        error('Input images do not match length of existing labels')
    end
end

handles = update_display(handles);

guidata(hObject, handles);
uicontrol(handles.output)

function s = current_label(handles)
%CURRENT_LABEL   Get a string for the label of the current electrode.

if isempty(handles.labels) || isnan(handles.cur_image)
    s = '';
else
    s = handles.labels{handles.cur_image};
end

function handles = update_display(handles)

if isnan(handles.cur_image) || isempty(handles.cur_image)
    return
end

if ~isempty(handles.images)
    image(handles.images{handles.cur_image})
    axis off
end

handles = update_label(handles);
set(handles.image_number, 'String', num2str(handles.cur_image));

function handles = update_label(handles)

if isnan(handles.cur_image) || isempty(handles.cur_image)
    return
end
s = current_label(handles);
set(handles.label_display, 'String', s);
guidata(handles.output, handles);

function n_image = get_n_images(handles)

if ~isempty(handles.images)
    n_image = length(handles.images);
elseif ~isempty(handles.labels)
    n_image = length(handles.labels);
else
    n_image = 0;
end

function [success, handles] = update_cur_image(handles, new_image)

if length(new_image) > 1
    error('Must specify a single image to update to.')
end

% check if the requested new image is in bounds
n_image = get_n_images(handles);
if new_image > n_image
    new_image = n_image;
elseif new_image < 1
    new_image = 1;
end
if handles.cur_image == new_image
   % either no change, or an invalid change; ignore
   success = false;
   return
end

if ~isnan(handles.cur_image)
    % store the previous electrode before changing it
    handles.prev_image = handles.cur_image;
end

% update the current electrode number
handles.cur_image = new_image;

% update the display
handles = update_display(handles);

success = true;
guidata(handles.output, handles);


% --- Executes on button press in save_labels.
function save_labels_Callback(hObject, eventdata, handles)
% hObject    handle to save_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename, pathname, filterindex] = uiputfile('*.txt', 'Select Output File');

fid = fopen(fullfile(pathname, filename), 'w');

for i = 1:length(handles.labels)
    fprintf(fid, '%s\n', handles.labels{i});
end

fclose(fid);
uicontrol(handles.output)

% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

key = eventdata.Key;

if isnan(handles.cur_image)
    return
end

key = eventdata.Key;
if length(key) == 1 && isstrprop(key, 'alpha')
    handles.labels{handles.cur_image} = upper(key);
    handles = update_label(handles);
    [success, handles] = update_cur_image(handles, handles.cur_image + 1);
end
guidata(handles.output, handles);



function jump_Callback(hObject, eventdata, handles)
% hObject    handle to jump (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of jump as text
%        str2double(get(hObject,'String')) returns contents of jump as a double


% --- Executes during object creation, after setting all properties.
function jump_CreateFcn(hObject, eventdata, handles)
% hObject    handle to jump (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in jump_button.
function jump_button_Callback(hObject, eventdata, handles)
% hObject    handle to jump_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

s = get(handles.jump, 'String');
if isempty(s)
    return
end

n = str2num(s);
[success, handles] = update_cur_image(handles, n);
set(handles.jump, 'String', '')
guidata(handles.output, handles);


% --- Executes on button press in load_labels.
function load_labels_Callback(hObject, eventdata, handles)
% hObject    handle to load_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename, pathname, filterindex] = uigetfile('*.txt', 'Select Labels File');

fid = fopen(fullfile(pathname, filename), 'r');

c = textscan(fid, '%s');

fclose(fid);
handles.labels = c{1};

if ~isempty(handles.images)
    % we have already loaded images
    handles = update_label(handles);
else
    % no images yet; define the current image
    handles.cur_image = 1;
    handles = update_label(handles);
    set(handles.image_number, 'String', num2str(handles.cur_image));
end

guidata(handles.output, handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over load_button.
function load_button_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to load_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
