function varargout = selOptmalOrder(varargin)
% SELOPTMALORDER MATLAB code for selOptmalOrder.fig
%      SELOPTMALORDER, by itself, creates a new SELOPTMALORDER or raises the existing
%      singleton*.
%
%      H = SELOPTMALORDER returns the handle to a new SELOPTMALORDER or the handle to
%      the existing singleton*.
%
%      SELOPTMALORDER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SELOPTMALORDER.M with the given input arguments.
%
%      SELOPTMALORDER('Property','Value',...) creates a new SELOPTMALORDER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before selOptmalOrder_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to selOptmalOrder_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help selOptmalOrder

% Last Modified by GUIDE v2.5 14-Apr-2011 09:33:54

% Begin initialization code - DO NOT EDIT
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @selOptmalOrder_OpeningFcn, ...
                   'gui_OutputFcn',  @selOptmalOrder_OutputFcn, ...
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


% --- Executes just before selOptmalOrder is made visible.
function selOptmalOrder_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to selOptmalOrder (see VARARGIN)

% Choose default command line output for selOptmalOrder
handles.output = hObject;

% Update handles structure
TITLE=varargin{2};
handles.crit=varargin{3};
handles.MAXORDER=varargin{4};

set(handles.slider1,'Min',1);
set(handles.slider1,'Max',handles.MAXORDER);
c=handles.crit(1,:);
minpos=find(c==min(c));
set(handles.edit1,'String',num2str(minpos));
set(handles.slider1,'Value',minpos);
set(handles.slider1,'SliderStep',[1 10]./(handles.MAXORDER-1));
%xlabel(handles.axes1,'order');
set(handles.text4,'String',TITLE);
plot(handles.axes1,handles.crit(1,:));
set(handles.axes1,'XLim',[1 length(handles.crit(1,:))]);
set(handles.radiobutton1,'Value',get(handles.radiobutton1,'Max'));
set(handles.figure1,'Name','Select optimal model order');
guidata(hObject, handles);
set(handles.figure1,'WindowStyle','modal')
% UIWAIT makes selOptmalOrder wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = selOptmalOrder_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output(1);
varargout{2} = handles.output(2);
delete(handles.figure1);

function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
ed1=get(hObject,'String');
vl=round(str2double(ed1));
if vl<1 vl=1; end
if vl>handles.MAXORDER vl=handles.MAXORDER; end
set(handles.slider1,'Value',vl);


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sv2=get(hObject,'Value');
set(handles.edit1,'String',num2str(round(sv2)));


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output={handles.figure1,...
    str2double(get(handles.edit1,'String'))};
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Executes when selected object is changed in uipanel2.
function uipanel2_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel2 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'radiobutton1'
        crit_no=1;
    case 'radiobutton2'
        crit_no=2;
    otherwise
        % Code for when there is no match.
end
c=handles.crit(crit_no,:);
minpos=find(c==min(c));
set(handles.edit1,'String',num2str(minpos));
set(handles.slider1,'Value',minpos);
set(handles.text4,'String',get(eventdata.NewValue,'String'));
plot(handles.axes1,handles.crit(crit_no,:));
set(handles.axes1,'XLim',[1 length(handles.crit(crit_no,:))]);
guidata(hObject, handles);
