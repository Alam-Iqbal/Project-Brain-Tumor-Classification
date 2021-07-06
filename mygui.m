function varargout = mygui(varargin)
% MYGUI MATLAB code for mygui.fig
%      MYGUI, by itself, creates a new MYGUI or raises the existing
%      singleton*.
%
%      H = MYGUI returns the handle to a new MYGUI or the handle to
%      the existing singleton*.
%
%      MYGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MYGUI.M with the given input arguments.
%
%      MYGUI('Property','Value',...) creates a new MYGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mygui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mygui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mygui

% Last Modified by GUIDE v2.5 10-Dec-2020 02:38:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mygui_OpeningFcn, ...
                   'gui_OutputFcn',  @mygui_OutputFcn, ...
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


% --- Executes just before mygui is made visible.
function mygui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mygui (see VARARGIN)

% Choose default command line output for mygui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mygui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = mygui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in LoadMRI.
function LoadMRI_Callback(hObject, eventdata, handles)
% hObject    handle to LoadMRI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% Input
[I,path]=uigetfile('*.jpg;*.png;*.bmp;*.JPEG;','Pick an MRI Image');
str=strcat(path,I);
s=imread(str); 

axes(handles.axes1);
imshow(s);
title('Input Image','FontSize',15);





%% Filter
num_iter = 10;
delta_t = 1/7;
kappa = 15;
option = 2;
disp('Preprocessing Image');
inp = anisodiff(s,num_iter,delta_t,kappa,option);
inp = uint8(inp);
    
inp=imresize(inp,[256,256]);
if size(inp,3)>1
    inp=rgb2gray(inp);
end
axes(handles.axes2);
imshow(inp);
title('Filtered Image','FontSize',15);
%% thresholding
sout=imresize(inp,[256,256]);
t0=60;
th=t0+((max(inp(:))+min(inp(:)))./2);
for i=1:1:size(inp,1)
    for j=1:1:size(inp,2)
        if inp(i,j)>th
            sout(i,j)=1;
        else
            sout(i,j)=0;
        end
    end
end
%% Morphological Operation

label=bwlabel(sout);
stats=regionprops(logical(sout),'Solidity','Area','BoundingBox');
density=[stats.Solidity];
area=[stats.Area];
high_dense_area=density>0.6;
max_area=max(area(high_dense_area));
tumor_label=find(area==max_area);
tumor=ismember(label,tumor_label);

if max_area>100
   axes(handles.axes3);
   imshow(tumor)
   title('Tumor Found','FontSize',15);
else
    h = msgbox('No Tumor','status');
    %disp('No tumor');
    return;
end

           
%% Bounding box

box = stats(tumor_label);
wantedBox = box.BoundingBox;
axes(handles.axes4);
imshow(inp);
title('Bounding Box','FontSize',15);
hold on;
rectangle('Position',wantedBox,'EdgeColor','y');
hold off;


%% Getting Tumor Outline image filling, eroding, subtracting


dilationAmount = 5;
rad = floor(dilationAmount);
[r,c] = size(tumor);
filledImage = imfill(tumor, 'holes');

for i=1:r
   for j=1:c
       x1=i-rad;
       x2=i+rad;
       y1=j-rad;
       y2=j+rad;
       if x1<1
           x1=1;
       end
       if x2>r
           x2=r;
       end
       if y1<1
           y1=1;
       end
       if y2>c
           y2=c;
       end
       erodedImage(i,j) = min(min(filledImage(x1:x2,y1:y2)));
   end
end
figure
imshow(erodedImage);
title('Eroded Image','FontSize',15);

%% subtracting eroded image from original BW image

tumorOutline=tumor;
tumorOutline(erodedImage)=0;

axes(handles.axes5);
imshow(tumorOutline);
title('Tumor Outline','FontSize',15);


%% Inserting the outline in filtered image in red color
rgb = inp(:,:,[1 1 1]);
red = rgb(:,:,1);
red(tumorOutline)=255;
green = rgb(:,:,2);
green(tumorOutline)=0;
blue = rgb(:,:,3);
blue(tumorOutline)=0;

tumorOutlineInserted(:,:,1) = red;
tumorOutlineInserted(:,:,2) = green;
tumorOutlineInserted(:,:,3) = blue;


axes(handles.axes6);
imshow(tumorOutlineInserted);
title('Detected Tumor','FontSize',15);


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function About_Callback(hObject, eventdata, handles)
% hObject    handle to About (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function author_Callback(hObject, eventdata, handles)
% hObject    handle to author (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox(sprintf('Name: Iqbal Alam\nClass: M.Tech(CSE)\nRoll No.: 19MCS006'),'Author')


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over BTD.
function BTD_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to BTD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
