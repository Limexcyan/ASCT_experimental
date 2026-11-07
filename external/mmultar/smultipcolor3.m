function varargout = smultipcolor3(varargin)
% SMULTIPCOLOR3 M-file for smultipcolor3.fig
%      SMULTIPCOLOR3, by itself, creates a new SMULTIPCOLOR3 or raises the existing
%      singleton*.
%
%      H = SMULTIPCOLOR3 returns the handle to a new SMULTIPCOLOR3 or the handle to
%      the existing singleton*.
%
%      SMULTIPCOLOR3('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SMULTIPCOLOR3.M with the given input arguments.
%
%      SMULTIPCOLOR3('Property','Value',...) creates a new SMULTIPCOLOR3 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before smultipcolor_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to smultipcolor3_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help smultipcolor3

% Last Modified by GUIDE v2.5 14-Sep-2012 15:07:43

% Begin initialization code - DO NOT EDIT
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @smultipcolor3_OpeningFcn, ...
                   'gui_OutputFcn',  @smultipcolor3_OutputFcn, ...
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


% --- Executes just before smultipcolor3 is made visible.
function smultipcolor3_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to smultipcolor3 (see VARARGIN)

% Choose default command line output for smultipcolor3
handles.output = hObject;
handles.plotdata=varargin{1};
handles.plotminv=varargin{2};
handles.plotmaxv=varargin{3};
handles.plottitl=varargin{4};
handles.prfname=varargin{5};
handles.chanopis=varargin{6};
handles.savefigs=varargin{7};
handles.pautoflag=varargin{8};
figure(handles.figure1);
set(handles.figure1,'Name',handles.plottitl);
set(handles.text1,'String',num2str(varargin{3}));
set(handles.radiobutton1,'Value',get(handles.radiobutton1,'Min'));
set(handles.radiobutton2,'Value',get(handles.radiobutton1,'Max'));
%set(handles.radiobutton3,'Value',get(handles.radiobutton1,'Min'));

%fig=hObject;
fig1=handles.axes1;
units=get(fig1,'Units');
set(fig1,'Units','pixels');
figpos=get(fig1,'Position');
v=get(0,'MonitorPosition');
if figpos(4)>v(4)*0.9 || figpos(3)>v(3)*0.9
%     upos=[1 1 round(figpos(3)*3/4) round(figpos(4)*3/4)];
%         % left bottom sizex          sizey
%     set(fig1,'Position',upos);
end
set(fig1,'Units',units);
%set(fig,'Toolbar','figure');

fig2=handles.axes2;
units=get(fig2,'Units');
set(fig2,'Units','pixels');
figpos=get(fig2,'Position');
v=get(0,'MonitorPosition');
if figpos(4)>v(4)*0.9 || figpos(3)>v(3)*0.9
%     upos=[1 1 round(figpos(3)*3/4) round(figpos(4)*3/4)];
%         % left bottom sizex          sizey
%     set(fig2,'Position',upos);
end
set(fig2,'Units',units);
%set(fig,'Toolbar','figure');

fig3=handles.axes3;
units=get(fig3,'Units');
set(fig3,'Units','pixels');
figpos=get(fig3,'Position');
v=get(0,'MonitorPosition');
if figpos(4)>v(4)*0.9 || figpos(3)>v(3)*0.9
%     upos=[1 1 round(figpos(3)*3/4) round(figpos(4)*3/4)];
%         % left bottom sizex          sizey
%     set(fig3,'Position',upos);
end
set(fig3,'Units',units);
%set(fig,'Toolbar','figure');

set(handles.axes1,'Visible','off');
set(handles.axes2,'Visible','on');
set(handles.axes3,'Visible','off');

amultipcolor3(handles.axes1,handles.axes2,handles.axes3,...
                   handles.plotdata,...
                   handles.plotminv,...
                   handles.plotmaxv,...
                   handles.plottitl,...
                   handles.prfname,...
                   handles.chanopis,...
                   handles.pautoflag,...
                   handles.savefigs);
state_string={'off','on'};
b1v=get(handles.radiobutton1,'Value')==get(handles.radiobutton1,'Max');
b2v=get(handles.radiobutton2,'Value')==get(handles.radiobutton2,'Max');
b3v=get(handles.radiobutton3,'Value')==get(handles.radiobutton3,'Max');
set(handles.axes1,'Visible',state_string{b1v+1});
set(handles.axes2,'Visible',state_string{b2v+1});
set(handles.axes3,'Visible',state_string{b3v+1});
s=findall(handles.axes1,'Type','surface'); set(s,'Visible',state_string{b1v+1});
s=findall(handles.axes2,'Type','surface'); set(s,'Visible',state_string{b2v+1});
s=findall(handles.axes3,'Type','surface'); set(s,'Visible',state_string{b3v+1});
if handles.savefigs
    printfigure(handles);
end
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes smultipcolor3 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = smultipcolor3_OutputFcn(hObject, eventdata, handles) 
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


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
prompt = {'Enter graphs max value:'};
dlg_title = 'Change scaling';
num_lines = 1;
%def = curmax;
def = {num2str(handles.plotmaxv)};
answer = inputdlg(prompt,dlg_title,num_lines,def);
if ~isempty(answer)
    n=str2num(answer{1});
    if ~isempty(n) && n>0
        newmax=n;
        %cla(handles.axes1);
        amultipcolor3(handles.axes1,handles.axes2,handles.axes3,...
                   handles.plotdata,...
                   handles.plotminv,...
                   newmax,...
                   handles.plottitl,...
                   handles.prfname,...
                   handles.chanopis,...
                   handles.pautoflag,...
                   handles.savefigs);
        set(handles.text1,'String',num2str(newmax));
        state_string={'off','on'};
        b1v=get(handles.radiobutton1,'Value')==get(handles.radiobutton1,'Max');
        b2v=get(handles.radiobutton2,'Value')==get(handles.radiobutton2,'Max');
        b3v=get(handles.radiobutton3,'Value')==get(handles.radiobutton3,'Max');
        set(handles.axes1,'Visible',state_string{b1v+1});
        set(handles.axes2,'Visible',state_string{b2v+1});
        set(handles.axes3,'Visible',state_string{b3v+1});
        s=findall(handles.axes1,'Type','surface'); set(s,'Visible',state_string{b1v+1});
        s=findall(handles.axes2,'Type','surface'); set(s,'Visible',state_string{b2v+1});
        s=findall(handles.axes3,'Type','surface'); set(s,'Visible',state_string{b3v+1});
%         if handles.savefigs
%             printfigure(handles);
%         end
    end
end
guidata(hObject, handles);


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cla
amultipcolor3(handles.axes1,handles.axes2,handles.axes3,...
                   handles.plotdata,...
                   handles.plotminv,...
                   handles.plotmaxv,...
                   handles.plottitl,...
                   handles.prfname,...
                   handles.chanopis,...
                   handles.pautoflag,...
                   handles.savefigs);
set(handles.text1,'String',num2str(handles.plotmaxv));
state_string={'off','on'};
b1v=get(handles.radiobutton1,'Value')==get(handles.radiobutton1,'Max');
b2v=get(handles.radiobutton2,'Value')==get(handles.radiobutton2,'Max');
b3v=get(handles.radiobutton3,'Value')==get(handles.radiobutton3,'Max');
set(handles.axes1,'Visible',state_string{b1v+1});
set(handles.axes2,'Visible',state_string{b2v+1});
set(handles.axes3,'Visible',state_string{b3v+1});
s=findall(handles.axes1,'Type','surface'); set(s,'Visible',state_string{b1v+1});
s=findall(handles.axes2,'Type','surface'); set(s,'Visible',state_string{b2v+1});
s=findall(handles.axes3,'Type','surface'); set(s,'Visible',state_string{b3v+1});
% if handles.savefigs
%     printfigure(handles);
% end
guidata(hObject, handles);


% --- Executes when selected object is changed in uipanel1.
function uipanel1_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel1 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(eventdata) return; end
z =get(eventdata.NewValue,'Tag');
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'radiobutton1'
        set(handles.axes1,'Visible','on');
        set(handles.axes2,'Visible','off');
        set(handles.axes3,'Visible','off');
    case 'radiobutton2'
        set(handles.axes1,'Visible','off');
        set(handles.axes2,'Visible','on');
        set(handles.axes3,'Visible','off');
    case 'radiobutton3'
        set(handles.axes1,'Visible','off');
        set(handles.axes2,'Visible','off');
        set(handles.axes3,'Visible','on');
end
guidata(hObject, handles);


% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton1
set(handles.axes1,'Visible','on');
set(handles.axes2,'Visible','off');
set(handles.axes3,'Visible','off');
s=findall(handles.axes1,'Type','surface');
set(s,'Visible','on');
s=findall(handles.axes2,'Type','surface');
set(s,'Visible','off');
s=findall(handles.axes3,'Type','surface');
set(s,'Visible','off');
guidata(hObject, handles);

% --- Executes on button press in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton2
set(handles.axes1,'Visible','off');
set(handles.axes2,'Visible','on');
set(handles.axes3,'Visible','off');
s=findall(handles.axes1,'Type','surface');
set(s,'Visible','off');
s=findall(handles.axes2,'Type','surface');
set(s,'Visible','on');
s=findall(handles.axes3,'Type','surface');
set(s,'Visible','off');
guidata(hObject, handles);

% --- Executes on button press in radiobutton3.
function radiobutton3_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton3
set(handles.axes1,'Visible','off');
set(handles.axes2,'Visible','off');
set(handles.axes3,'Visible','on');
s=findall(handles.axes1,'Type','surface');
set(s,'Visible','off');
s=findall(handles.axes2,'Type','surface');
set(s,'Visible','off');
s=findall(handles.axes3,'Type','surface');
set(s,'Visible','on');
guidata(hObject, handles);



% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printfigure(handles);
guidata(hObject,handles);

function printfigure(handles)
set(gcf,'PaperPositionMode','auto');
%set(gcf,'PaperOrientation','landscape');
set(gcf,'PaperType','A4');
set(handles.pushbutton1,'Visible','off');
set(handles.pushbutton2,'Visible','off');
set(handles.pushbutton3,'Visible','off');
set(handles.pushbutton4,'Visible','off');
set(handles.uipanel1,'Visible','off');
ttl=get(handles.uipanel1,'Title');
set(handles.uipanel1,'Title','');
set(handles.radiobutton1,'Visible','off');
set(handles.radiobutton2,'Visible','off');
set(handles.radiobutton3,'Visible','off');
print(gcf,'-dtiff',[handles.prfname{1} handles.prfname{2} '.tif']);
set(handles.pushbutton1,'Visible','on');
set(handles.pushbutton2,'Visible','on');
set(handles.pushbutton3,'Visible','on');
set(handles.pushbutton4,'Visible','on');
set(handles.uipanel1,'Visible','on');
set(handles.uipanel1,'Title',ttl);
set(handles.radiobutton1,'Visible','on');
set(handles.radiobutton2,'Visible','on');
set(handles.radiobutton3,'Visible','on');


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cla
gmax=amultipcolor3(handles.axes1,handles.axes2,handles.axes3,...
                   handles.plotdata,...
                   handles.plotminv,...
                   handles.plotmaxv,...
                   handles.plottitl,...
                   handles.prfname,...
                   handles.chanopis,...
                   1,...
                   handles.savefigs);
set(handles.text1,'String',num2str(gmax));
state_string={'off','on'};
b1v=get(handles.radiobutton1,'Value')==get(handles.radiobutton1,'Max');
b2v=get(handles.radiobutton2,'Value')==get(handles.radiobutton2,'Max');
b3v=get(handles.radiobutton3,'Value')==get(handles.radiobutton3,'Max');
set(handles.axes1,'Visible',state_string{b1v+1});
set(handles.axes2,'Visible',state_string{b2v+1});
set(handles.axes3,'Visible',state_string{b3v+1});
s=findall(handles.axes1,'Type','surface'); set(s,'Visible',state_string{b1v+1});
s=findall(handles.axes2,'Type','surface'); set(s,'Visible',state_string{b2v+1});
s=findall(handles.axes3,'Type','surface'); set(s,'Visible',state_string{b3v+1});
% if handles.savefigs
%     printfigure(handles);
% end
guidata(hObject, handles);
