function varargout = advancePlot(varargin)
% ADVANCEPLOT MATLAB code for advancePlot.fig
%      ADVANCEPLOT, by itself, creates a new ADVANCEPLOT or raises the existing
%      singleton*.
%
%      H = ADVANCEPLOT returns the handle to a new ADVANCEPLOT or the handle to
%      the existing singleton*.
%
%      ADVANCEPLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ADVANCEPLOT.M with the given input arguments.
%
%      ADVANCEPLOT('Property','Value',...) creates a new ADVANCEPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before advancePlot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to advancePlot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help advancePlot

% Last Modified by GUIDE v2.5 13-Apr-2011 16:44:53

% Begin initialization code - DO NOT EDIT
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @advancePlot_OpeningFcn, ...
                   'gui_OutputFcn',  @advancePlot_OutputFcn, ...
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


% --- Executes just before advancePlot is made visible.
function advancePlot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to advancePlot (see VARARGIN)

% Choose default command line output for advancePlot
handles.output = hObject;

handles.output = '';
trial=varargin{1};
ntrls=varargin{2};
set(handles.figure1,'Name','Process next record');
set(handles.text1,'String',sprintf('(%d/%d)',trial,ntrls));
% Update handles structure
set(handles.figure1,'WindowStyle','normal')
guidata(hObject, handles);
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = advancePlot_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.figure1);

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = get(hObject,'String');
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = get(hObject,'String');
guidata(hObject, handles);
uiresume(handles.figure1);
