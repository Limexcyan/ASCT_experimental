function varargout = multargui(varargin)
% MULTARGUI M-file for multargui.fig
%      MULTARGUI, by itself, creates a new MULTARGUI or raises the existing
%      singleton*.
%
%      H = MULTARGUI returns the handle to a new MULTARGUI or the handle to
%      the existing singleton*.
%
%      MULTARGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MULTARGUI.M with the given input arguments.
%
%      MULTARGUI('Property','Value',...) creates a new MULTARGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before multargui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to multargui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help multargui

% Last Modified by GUIDE v2.5 05-Jun-2017 12:09:31

% Begin initialization code - DO NOT EDIT
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @multargui_OpeningFcn, ...
                   'gui_OutputFcn',  @multargui_OutputFcn, ...
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


% --- Executes just before multargui is made visible.
function multargui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to multargui (see VARARGIN)

% Choose default command line output for multargui
handles.output = hObject;



mv=varargin{1};
%possibleDataFormats = {'float32','int16','int32','ASCII','EDF/BDF'};
possibleDataFormats = {'float32','int16','int32','float64','ASCII','MAT file'};
set(handles.popupmenu1,'String',possibleDataFormats);
handles=values_update(handles,mv);
handles.multdata=mv;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes multargui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = multargui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
mv=handles.multdata;
s=str2double(get(handles.edit1,'String'));
if ~isnan(s)
    mv.chans=s;
    handles.multdata=mv;
else
    mv.chans=[];
    handles.multdata=mv;
    set(handles.edit1,'String','');
end
guidata(hObject, handles);

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



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
mv=handles.multdata;
s=str2double(get(handles.edit2,'String'));
if ~isnan(s)
    mv.recl=s;
    handles.multdata=mv;
else
    mv.recl=[];
    handles.multdata=mv;
    set(handles.edit2,'String','');
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double
mv=handles.multdata;
s=str2double(get(handles.edit3,'String'));
if ~isnan(s)
    mv.ntrls=s;
    handles.multdata=mv;
else
    mv.ntrls=[];
    handles.multdata=mv;
    set(handles.edit3,'String','');
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double
mv=handles.multdata;
s=str2double(get(handles.edit4,'String'));
if ~isnan(s)
    mv.fsamp=s;
    handles.multdata=mv;
else
    set(handles.edit4,'String','');
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double
mv=handles.multdata;
s=str2double(get(handles.edit5,'String'));
if ~isnan(s)
    mv.fstart=s;
    handles.multdata=mv;
else
    set(handles.edit5,'String','');
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double
mv=handles.multdata;
s=str2double(get(handles.edit6,'String'));
if ~isnan(s)
    mv.fend=s;
    handles.multdata=mv;
else
    set(handles.edit6,'String','');
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit7_Callback(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit7 as text
%        str2double(get(hObject,'String')) returns contents of edit7 as a double
mv=handles.multdata;
s=str2double(get(handles.edit7,'String'));
if ~isnan(s)
    mv.pord=s;
    handles.multdata=mv;
else
    set(handles.edit7,'String','');
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit11_Callback(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit11 as text
%        str2double(get(hObject,'String')) returns contents of edit11 as a double
mv=handles.multdata;
s=str2double(get(handles.edit11,'String'));
if ~isnan(s)
    mv.winlen=s;
else
    mv.winlen=[];
    set(handles.edit11,'String','');
end
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit12_Callback(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit12 as text
%        str2double(get(hObject,'String')) returns contents of edit12 as a double
mv=handles.multdata;
s=str2double(get(handles.edit12,'String'));
if ~isnan(s)
    mv.winshf=s;
else
    mv.winshf=[];
    set(handles.edit12,'String','');
end
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit13_Callback(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit13 as text
%        str2double(get(hObject,'String')) returns contents of edit13 as a double
mv=handles.multdata;
s=str2double(get(handles.edit13,'String'));
if ~isnan(s)
    mv.winnum=s;
else
    mv.winnum=[];
    set(handles.edit13,'String','');
end
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% IT IS IN FACT TOGGLEBUTTON
if get(hObject,'Value')==get(hObject,'Max')
    handles.multdata.pord=0;
    set(handles.edit7,'Enable','off');
else
    set(handles.edit7,'Enable','on');
    s=str2double(get(handles.edit7,'String'));
    if ~isnan(s) handles.multdata.pord=s; end
end
guidata(hObject, handles);


% function uipanel2_SelectionChangeFcn(hObject,eventdata,handles)
% switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
%     case 'radiobutton1'
%         % Code for when radiobutton1 is selected.
%         a=1;
%     case 'radiobutton2'
%         % Code for when radiobutton2 is selected.
%         a=2;
%     case 'radiobutton3'
%         % Code for when togglebutton1 is selected.
%         a=3;
%     case 'radiobutton4'
%         % Code for when togglebutton2 is selected.
%         a=4;
%     % Continue with more cases as necessary.
%     otherwise
%         % Code for when there is no match.
% end


% % --- Executes on button press in radiobutton5.
% function radiobutton5_Callback(hObject, eventdata, handles)
% % hObject    handle to radiobutton5 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of radiobutton5
% a=1;


% % --- Executes on button press in radiobutton6.
% function radiobutton6_Callback(hObject, eventdata, handles)
% % hObject    handle to radiobutton6 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of radiobutton6
% a=1;
% 
% % --- Executes on button press in radiobutton7.
% function radiobutton7_Callback(hObject, eventdata, handles)
% % hObject    handle to radiobutton7 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of radiobutton7
% a=1;
% 
% 
% % --- Executes on button press in radiobutton8.
% function radiobutton8_Callback(hObject, eventdata, handles)
% % hObject    handle to radiobutton8 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of radiobutton8
% a=1;

% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1
mv=handles.multdata;
mv.baseln=get(handles.checkbox1,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox2
mv=handles.multdata;
mv.bootst=get(handles.checkbox2,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox4
mv=handles.multdata;
mv.pDTF=get(handles.checkbox4,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox5.
function checkbox5_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox5
mv=handles.multdata;
mv.pNDTF=get(handles.checkbox5,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox6.
function checkbox6_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox6
mv=handles.multdata;
mv.pSpect=get(handles.checkbox6,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox7.
function checkbox7_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox7
mv=handles.multdata;
mv.pCohs=get(handles.checkbox7,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox8.
function checkbox8_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox8
mv=handles.multdata;
mv.pdDTF=get(handles.checkbox8,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox9.
function checkbox9_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mv=handles.multdata;
mv.pPDC=get(handles.checkbox9,'Value');
handles.multdata=mv;
guidata(hObject, handles);

% Hint: get(hObject,'Value') returns toggle state of checkbox9



function edit14_Callback(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit14 as text
%        str2double(get(hObject,'String')) returns contents of edit14 as a double
mv=handles.multdata;
s=str2double(get(handles.edit14,'String'));
if ~isnan(s)
    mv.basenum=s;
    handles.multdata=mv;
else
    set(handles.edit14,'String','');
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit15_Callback(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit15 as text
%        str2double(get(hObject,'String')) returns contents of edit15 as a double
mv=handles.multdata;
s=str2double(get(handles.edit15,'String'));
if ~isnan(s)
    mv.bootpool=s;
    handles.multdata=mv;
else
    set(handles.edit15,'String','');
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit15_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit16_Callback(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit16 as text
%        str2double(get(hObject,'String')) returns contents of edit16 as a double
mv=handles.multdata;
s=str2double(get(handles.edit16,'String'));
if ~isnan(s)
    mv.bootnum=s;
    handles.multdata=mv;
else
    set(handles.edit16,'String','');
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox10.
function checkbox10_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox10
mv=handles.multdata;
mv.sDTF=get(handles.checkbox10,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox11.
function checkbox11_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox11
mv=handles.multdata;
mv.sNDTF=get(handles.checkbox11,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox12.
function checkbox12_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox12
mv=handles.multdata;
mv.sSpect=get(handles.checkbox12,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox13.
function checkbox13_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox13
mv=handles.multdata;
mv.sCohs=get(handles.checkbox13,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox14.
function checkbox14_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox14
mv=handles.multdata;
mv.sdDTF=get(handles.checkbox14,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox15.
function checkbox15_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox15
mv=handles.multdata;
mv.sPDC=get(handles.checkbox15,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox16.
function checkbox16_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox16
mv=handles.multdata;
mv.sAR=get(handles.checkbox16,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName]=...
    uigetfile({'*.txt;*.','Text files (*.txt,*.)';'*.*','All files (*.*)'},...
    'Select input data file');
mv=handles.multdata;
if ~(isnumeric(FileName) && FileName==0 && isnumeric(PathName) && PathName==0)
    mv.descfil=[PathName FileName];
    handles.multdata=mv;
end
set(handles.edit18,'String',FileName);
guidata(hObject, handles);



function edit18_Callback(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit18 as text
%        str2double(get(hObject,'String')) returns contents of edit18 as a double
mv=handles.multdata;
mv.descfil=get(handles.edit18,'String');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit18_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName]=...
    uigetfile({'*.dat','Data files (*.dat)';'*.*','All files (*.*)'},...
    'Select input data file');
if ~(isnumeric(FileName) && FileName==0 && isnumeric(PathName) && PathName==0)
    mv=handles.multdata;
    mv.fname=[PathName FileName];
    set(handles.edit17,'String',mv.fname);
    handles.multdata=mv;
    %g=handles.multdata;
end
guidata(hObject, handles);


function edit17_Callback(hObject, eventdata, handles)
% hObject    handle to edit17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit17 as text
%        str2double(get(hObject,'String')) returns contents of edit17 as a double
mv=handles.multdata;
mv.fname=get(handles.edit17,'String');
handles.multdata=mv;
%g=getappdata(handles.figure1,'multdata');
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit17_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function uipanel7_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to uipanel7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
a=1;



% --- Executes when selected object is changed in uipanel2.
%function uipanel2_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel2 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%a=1;

% --------------------------------------------------------------------
function uipanel2_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to uipanel2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
a=1;



% --- Executes during object creation, after setting all properties.
function uipanel2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
a=1;

% % --- Executes on button press in radiobutton1.
% function radiobutton1_Callback(hObject, eventdata, handles)
% % hObject    handle to radiobutton1 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of radiobutton1
% val=get(handles.radiobutton1,'Value')
% mv=getappdata(handles.figure1,'multdata');
% mv.method=1;
% setappdata(handles.figure1,'multdata',mv);
% 
% function radiobutton2_Callback(hObject, eventdata, handles)
% mv=getappdata(handles.figure1,'multdata');
% mv.method=2;
% setappdata(handles.figure1,'multdata',mv);
% 
% function radiobutton3_Callback(hObject, eventdata, handles)
% mv=getappdata(handles.figure1,'multdata');
% mv.method=3;
% setappdata(handles.figure1,'multdata',mv);
% 
% function radiobutton4_Callback(hObject, eventdata, handles)
% mv=getappdata(handles.figure1,'multdata');
% mv.method=4;
% setappdata(handles.figure1,'multdata',mv);


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

mv=handles.multdata;
multar1m(mv);


% % --- Executes on button press in radiobutton13.
% function radiobutton13_Callback(hObject, eventdata, handles)
% % hObject    handle to radiobutton13 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of radiobutton13
% a=1;
% 
% 
% % --- Executes on button press in radiobutton14.
% function radiobutton14_Callback(hObject, eventdata, handles)
% % hObject    handle to radiobutton14 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of radiobutton14
% a=1;

% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName]=...
    uigetfile({'*.mat','MATLAB files (*.mat)';'*.*','All files (*.*)'},...
    'Select parametrs file to load');
if ~(isnumeric(FileName) && FileName==0 && isnumeric(PathName) && PathName==0)
    filn=fullfile(PathName,FileName);
    c=whos('-file',filn);
    if ~isempty(find(c.name=='mv', 1))
        load(filn,'mv');
        if ~isfield(mv,'userange')
            mv.userange=0;
            mv.timerangestart=0;
            mv.timerangeend=0;
        end
        if ~isfield(mv,'pautoflag')
            mv.pautoflag=0;
        end
        handles=values_update(handles,mv);
        handles.multdata=mv;
    else
        errordlg('Invalid parameters file','Error');
    end
end
guidata(hObject, handles);


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName]=...
    uiputfile({'*.mat','MATLAB files (*.mat)';'*.*','All files (*.*)'},...
    'Select file to save parameters');
mv=handles.multdata;
if ~(isnumeric(FileName) && FileName==0 && isnumeric(PathName) && PathName==0)
    save([PathName FileName],'mv');
end


function handles=values_update(handles,mv)
methods=[handles.radiobutton19,handles.radiobutton20,handles.radiobutton21,handles.radiobutton22];
levels=[handles.radiobutton9,handles.radiobutton10,handles.radiobutton11,handles.radiobutton12];
%format=[handles.radiobutton17,handles.radiobutton18];
mode=[handles.radiobutton24,handles.radiobutton25];
set(handles.edit17,'String',mv.fname);
set(handles.edit18,'String',mv.descfil);
set(handles.edit1,'String',num2str(mv.chans));
set(handles.edit2,'String',num2str(mv.recl));
set(handles.edit3,'String',num2str(mv.ntrls));
set(handles.edit4,'String',num2str(mv.fsamp));
set(handles.edit5,'String',num2str(mv.fstart));
set(handles.edit6,'String',num2str(mv.fend));
set(handles.edit7,'String',num2str(mv.pord));
if mv.pord<=0
    set(handles.pushbutton1,'Value',get(handles.pushbutton1,'Max'));
else
    set(handles.pushbutton1,'Value',get(handles.pushbutton1,'Min'));
end
set(handles.edit11,'String',num2str(mv.winlen));
set(handles.edit12,'String',num2str(mv.winshf));
set(handles.edit13,'String',num2str(mv.winnum));
set(handles.edit14,'String',num2str(mv.basenum));
set(handles.edit15,'String',num2str(mv.bootpool));
set(handles.edit16,'String',num2str(mv.bootnum));
set(handles.edit19,'String',mv.chansel);
set(methods(mv.method),'Value',get(methods(mv.method),'Max'));
set(levels(mv.siglev),'Value',get(levels(mv.siglev),'Max'));
%set(format(mv.format),'Value',get(format(mv.format),'Max'));
%set(handles.popupmenu1,'String',handles.possibleDataFormats);
set(handles.popupmenu1,'Value',mv.format);
tmidx=(mv.trial_mode~=0)+1;
%set(mode(tmidx),'Value',get(mode(1),'Min'));
set(mode(3-tmidx),'Value',get(mode(1),'Max'));
set(handles.checkbox1,'Value',mv.baseln);
set(handles.checkbox2,'Value',mv.bootst);
set(handles.checkbox4,'Value',mv.pDTF);
set(handles.checkbox5,'Value',mv.pNDTF);
set(handles.checkbox6,'Value',mv.pSpect);
set(handles.checkbox7,'Value',mv.pCohs);
set(handles.checkbox8,'Value',mv.pdDTF);
set(handles.checkbox9,'Value',mv.pPDC);
set(handles.checkbox18,'Value',mv.pffDTF);
set(handles.checkbox10,'Value',mv.sDTF);
set(handles.checkbox11,'Value',mv.sNDTF);
set(handles.checkbox12,'Value',mv.sSpect);
set(handles.checkbox13,'Value',mv.sCohs);
set(handles.checkbox14,'Value',mv.sdDTF);
set(handles.checkbox15,'Value',mv.sPDC);
set(handles.checkbox19,'Value',mv.sffDTF);
set(handles.checkbox16,'Value',mv.sAR);
set(handles.checkbox17,'Value',mv.savefigs);
set(handles.checkbox23,'Value',mv.userange);
if mv.userange
    set(handles.text23,'String',[num2str(mv.timerangestart) '-' num2str(mv.timerangeend)]);    
else
    set(handles.text23,'String','whole record');    
end
if sum(isfield(mv,{'norm1','norm2'}))==2
    set(handles.checkbox21,'Value',mv.norm1);
    set(handles.checkbox22,'Value',mv.norm2);
else
    set(handles.checkbox21,'Value',0);
    set(handles.checkbox22,'Value',0);
end    
set(handles.checkbox24,'Value',mv.incl_instant);

% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over radiobutton1.
% function radiobutton1_ButtonDownFcn(hObject, eventdata, handles)
% % hObject    handle to radiobutton1 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% a=1;
% val=get(handles.radiobutton1,'Value')
% 
% 
% % --- If Enable == 'on', executes on mouse press in 5 pixel border.
% % --- Otherwise, executes on mouse press in 5 pixel border or over radiobutton3.
% function radiobutton3_ButtonDownFcn(hObject, eventdata, handles)
% % hObject    handle to radiobutton3 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% a=1;
% val=get(handles.radiobutton3,'Value')
% 
% % --- If Enable == 'on', executes on mouse press in 5 pixel border.
% % --- Otherwise, executes on mouse press in 5 pixel border or over radiobutton2.
% function radiobutton2_ButtonDownFcn(hObject, eventdata, handles)
% % hObject    handle to radiobutton2 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% a=1;
% val=get(handles.radiobutton2,'Value')
% 
% % --- If Enable == 'on', executes on mouse press in 5 pixel border.
% % --- Otherwise, executes on mouse press in 5 pixel border or over radiobutton4.
% function radiobutton4_ButtonDownFcn(hObject, eventdata, handles)
% % hObject    handle to radiobutton4 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% a=1;
% val=get(handles.radiobutton4,'Value')
% 

function edit19_Callback(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit19 as text
%        str2double(get(hObject,'String')) returns contents of edit19 as a double
mv=handles.multdata;
mv.chansel=get(handles.edit19,'String');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit19_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% % --- Executes on button press in radiobutton7.
% function radiobutton17_Callback(hObject, eventdata, handles)
% % hObject    handle to radiobutton17 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of radiobutton17
% a=17;
% 
% % --- Executes on button press in radiobutton18.
% function radiobutton18_Callback(hObject, eventdata, handles)
% % hObject    handle to radiobutton18 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of radiobutton18
% a=18;



% --- Executes on button press in checkbox17.
function checkbox17_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox17
mv=handles.multdata;
mv.savefigs=get(handles.checkbox17,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --------------------------------------------------------------------
function uipanel11_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to uipanel11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function uipanel12_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to uipanel12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
q=1;

% Data format radiobuttons
%
% --- Executes when selected object is changed in uipanel14.
function uipanel14_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel14 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
mv=handles.multdata;
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'radiobutton17'
        mv.format=1;
    case 'radiobutton18'
        mv.format=2;
    case 'radiobutton23'
        mv.format=3;
    otherwise
        % Code for when there is no match.
end
handles.multdata=mv;
guidata(hObject, handles);

% AR fitting method radiobuttons
%
% --- Executes when selected object is changed in uipanel15.
function uipanel15_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel15 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
mv=handles.multdata;
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'radiobutton19'
        mv.method=1;
    case 'radiobutton20'
        mv.method=2;
    case 'radiobutton21'
        mv.method=3;
    case 'radiobutton22'
        mv.method=4;
    otherwise
        % Code for when there is no match.
end
handles.multdata=mv;
guidata(hObject, handles);

% Significance level radiobuttons
%
% --- Executes when selected object is changed in uipanel11.
function uipanel11_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel11 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
mv=handles.multdata;
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'radiobutton9'
        mv.siglev=1;
    case 'radiobutton10'
        mv.siglev=2;
    case 'radiobutton11'
        mv.siglev=3;
    case 'radiobutton12'
        mv.siglev=4;
    otherwise
        % Code for when there is no match.
end
handles.multdata=mv;
guidata(hObject, handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over radiobutton19.
function radiobutton19_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to radiobutton19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')==get(hObject,'Max')
    handles.multdata.method=1;
end
guidata(hObject, handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over radiobutton20.
function radiobutton20_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to radiobutton20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')==get(hObject,'Max')
    handles.multdata.method=2;
end
guidata(hObject, handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over radiobutton21.
function radiobutton21_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to radiobutton21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')==get(hObject,'Max')
    handles.multdata.method=3;
end
guidata(hObject, handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over radiobutton22.
function radiobutton22_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to radiobutton22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')==get(hObject,'Max')
    handles.multdata.method=4;
end
guidata(hObject, handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over radiobutton17.
function radiobutton17_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to radiobutton17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')==get(hObject,'Max')
    handles.multdata.format=1;
end
guidata(hObject, handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over radiobutton18.
function radiobutton18_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to radiobutton18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')==get(hObject,'Max')
    handles.multdata.format=2;
end
guidata(hObject, handles);



% --- Executes on button press in radiobutton24.
function radiobutton24_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of radiobutton24


% --- Executes on button press in radiobutton25.
function radiobutton25_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of radiobutton25


% --- Executes when selected object is changed in uipanel17.
function uipanel17_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel17 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
mv=handles.multdata;
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'radiobutton24'
        mv.trial_mode=1;
    case 'radiobutton25'
        mv.trial_mode=0;
    otherwise
        % Code for when there is no match.
end
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
mv=handles.multdata;
mv.format=get(handles.popupmenu1,'Value');
handles.multdata=mv;
guidata(hObject, handles);


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




% --- Executes on button press in checkbox18.
function checkbox18_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox18
mv=handles.multdata;
mv.pffDTF=get(handles.checkbox18,'Value');
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox19.
function checkbox19_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox19
mv=handles.multdata;
mv.sffDTF=get(handles.checkbox19,'Value');
handles.multdata=mv;
guidata(hObject, handles);

% --- Executes on button press in checkbox20.
function checkbox20_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox20
mv=handles.multdata;
mv.norm0=(get(hObject,'Value')==get(hObject,'Max'));
handles.multdata=mv;
guidata(hObject, handles);

% --- Executes on button press in checkbox21.
function checkbox21_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox21
mv=handles.multdata;
mv.norm1=(get(hObject,'Value')==get(hObject,'Max'));
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox22.
function checkbox22_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox22
mv=handles.multdata;
mv.norm2=(get(hObject,'Value')==get(hObject,'Max'));
handles.multdata=mv;
guidata(hObject, handles);




% --- Executes on button press in checkbox23.
function checkbox23_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox23
mv=handles.multdata;
mv.userange=(get(hObject,'Value')==get(hObject,'Max'));
if mv.userange
    answer = inputdlg({'Enter first sample number','Enter last sample number'},...
                      'Time range',1);
    if isempty(answer) || isempty(answer{1}) || isempty(answer{2})
        mv.userange = 0;
        set(hObject,'Value',get(hObject,'Min'));
        set(handles.text23,'String','whole record');
    else
        mv.timerangestart = str2double(answer{1});
        mv.timerangeend = str2double(answer{2});
        if isnan(mv.timerangestart) || isnan(mv.timerangeend) || ...
           mv.timerangestart<=0 || mv.timerangeend <=0 || ...
           mv.timerangestart>=mv.timerangeend
            mv.userange = 0;
            set(hObject,'Value',get(hObject,'Min'));
            set(handles.text23,'String','whole record');
        else
            set(handles.text23,'String',[answer{1} '-' answer{2}]);
        end
    end
else
    set(handles.text23,'String','whole record');
end
handles.multdata=mv;
guidata(hObject, handles);


% --- Executes on button press in checkbox24.
function checkbox24_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox24
mv=handles.multdata;
mv.incl_instant=(get(hObject,'Value')==get(hObject,'Max'));
handles.multdata=mv;
guidata(hObject, handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbutton3.
function pushbutton3_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
