function varargout = smultiplot(varargin)
% SMULTIPLOT M-file for smultiplot.fig
%      SMULTIPLOT, by itself, creates a new SMULTIPLOT or raises the existing
%      singleton*.
%
%      H = SMULTIPLOT returns the handle to a new SMULTIPLOT or the handle to
%      the existing singleton*.
%
%      SMULTIPLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SMULTIPLOT.M with the given input arguments.
%
%      SMULTIPLOT('Property','Value',...) creates a new SMULTIPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before smultiplot_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to smultiplot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help smultiplot

% Last Modified by GUIDE v2.5 14-Sep-2012 12:57:05

% Begin initialization code - DO NOT EDIT
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)
%%% MD - VISIBILITY 
% set(0,'DefaultFigureVisible',varargin{11});
%%%
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @smultiplot_OpeningFcn, ...
                   'gui_OutputFcn',  @smultiplot_OutputFcn, ...
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



% --- Executes just before smultiplot is made visible.
function smultiplot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to smultiplot (see VARARGIN)

% Choose default command line output for smultiplot
handles.output = hObject;
%%% %MD
% set(handles.figure1,'Visible',varargin{11});
% set(0,'DefaultFigureVisible',varargin{11});
% handles.figure1.HandleVisibility = 'off';
%handles.figure1.Visible = varargin{11};
% if strcmp(varargin{11},'on')
%     figure(handles.figure1)
% else
%     
% end
%%%
%figure(handles.figure1 ); %%MD!!!!!!
set(handles.figure1,'Name',varargin{4});
set(handles.text1,'String',num2str(varargin{3}));

handles.plotdata=varargin{1};
handles.plotminv=varargin{2};
handles.plotmaxv=varargin{3};
handles.plottitl=varargin{4};
handles.prnfilename=varargin{5};
handles.chanopis=varargin{6};
handles.savefigs=varargin{7};
handles.baselnv=varargin{8};
handles.bootflag=varargin{9};
handles.pautoflag=varargin{10};
% handles.visibility = varargin{11}; %MD
set(handles.checkbox1,'Value',get(handles.checkbox1,'Min'));
handles.sqflag=get(handles.checkbox1,'Value');
%handles.sqflag=1;
%set(handles.checkbox1,'Value',1);

% fig=hObject;
% %fig=handles.axes1;
% units=get(fig,'Units');
% set(fig,'Units','pixels');
% figpos=get(fig,'Position');
% v=get(0,'MonitorPosition');
% if figpos(4)>v(4)*0.9 || figpos(3)>v(3)*0.9
%     upos=[1 1 round(figpos(3)*3/4) round(figpos(4)*3/4)];
%         % left bottom sizex          sizey
%     set(fig,'Position',upos);
% end
% set(fig,'Units',units);
% set(fig,'Toolbar','figure');
%%% MD
%%%


if handles.bootflag
    a2multigraph(handles.axes1,handles.plotdata,...
                   handles.plotminv,...
                   handles.plotmaxv,...
                   handles.plottitl,...
                   handles.prnfilename,...
                   handles.chanopis,...
                   handles.savefigs,...
                   handles.sqflag,...
                   handles.pautoflag,...
                   handles.baselnv);
else
    amultigraph(handles.axes1,handles.plotdata,...
                   handles.plotminv,...
                   handles.plotmaxv,...
                   handles.plottitl,...
                   handles.prnfilename,...
                   handles.chanopis,...
                   handles.savefigs,...
                   handles.sqflag,...
                   handles.pautoflag,...
                   handles.baselnv);
end
if handles.savefigs
    printfigure(handles,handles);
end

% Update handles structure
guidata(hObject, handles);
% UIWAIT makes smultiplot wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = smultiplot_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%handles.output.Visible = 'off';
varargout{1} = handles.output;

guidata(hObject, handles);

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
data=guidata(hObject);
def = {num2str(data.plotmaxv)};
answer = inputdlg(prompt,dlg_title,num_lines,def);
if ~isempty(answer)
    n=str2num(answer{1});
    if ~isempty(n) && n>0
        newmax=n;
        cla;
        if handles.bootflag
            a2multigraph(handles.axes1,data.plotdata,...
                   data.plotminv,...
                   newmax,...
                   data.plottitl,...
                   data.prnfilename,...
                   data.chanopis,...
                   data.savefigs',...
                   handles.sqflag,...
                   handles.pautoflag,...
                   handles.baselnv);
        else
            amultigraph(handles.axes1,data.plotdata,...
                   data.plotminv,...
                   newmax,...
                   data.plottitl,...
                   data.prnfilename,...
                   data.chanopis,...
                   data.savefigs',...
                   handles.sqflag,...
                   handles.pautoflag,...
                   handles.baselnv);
        end
        set(handles.text1,'String',num2str(newmax));
        data.plotmaxv=newmax;
%         if data.savefigs
%             printfigure(data,handles);
%         end
    end
end
guidata(hObject,data);


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%cla(handles.axes1);
data=guidata(hObject);
if handles.bootflag
    a2multigraph(handles.axes1,data.plotdata,...
                   data.plotminv,...
                   data.plotmaxv,...
                   data.plottitl,...
                   data.prnfilename,...
                   data.chanopis,...
                   data.savefigs,...
                   handles.sqflag,...
                   handles.pautoflag,...
                   handles.baselnv);
else
    amultigraph(handles.axes1,data.plotdata,...
                   data.plotminv,...
                   data.plotmaxv,...
                   data.plottitl,...
                   data.prnfilename,...
                   data.chanopis,...
                   data.savefigs,...
                   handles.sqflag,...
                   handles.pautoflag,...
                   handles.baselnv);
end
set(handles.text1,'String',num2str(data.plotmaxv));
% if data.savefigs
%     printfigure(data,handles);
% end
guidata(hObject,data);


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox1
%data=guidata(hObject);
handles.sqflag=get(handles.checkbox1,'Value');
data=guidata(hObject);
if handles.bootflag
    a2multigraph(handles.axes1,data.plotdata,...
                   data.plotminv,...
                   data.plotmaxv,...
                   data.plottitl,...
                   data.prnfilename,...
                   data.chanopis,...
                   data.savefigs,...
                   handles.sqflag,...
                   handles.pautoflag,...
                   handles.baselnv);
else
    amultigraph(handles.axes1,data.plotdata,...
                   data.plotminv,...
                   data.plotmaxv,...
                   data.plottitl,...
                   data.prnfilename,...
                   data.chanopis,...
                   data.savefigs,...
                   handles.sqflag,...
                   handles.pautoflag,...
                   handles.baselnv);
end
set(handles.text1,'String',num2str(data.plotmaxv));
% if data.savefigs
%     printfigure(data,handles);
% end
guidata(hObject,handles);

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data=guidata(hObject);
printfigure(data,handles);
guidata(hObject,handles);

function printfigure(data,handles)
set(gcf,'PaperPositionMode','auto');
%set(gcf,'PaperOrientation','landscape');
set(gcf,'PaperType','A4');
set(handles.pushbutton1,'Visible','off');
set(handles.pushbutton2,'Visible','off');
set(handles.pushbutton3,'Visible','off');
set(handles.pushbutton4,'Visible','off');
print(gcf,'-dtiff',[data.prnfilename{1} data.prnfilename{2} '.tif']);
set(handles.pushbutton1,'Visible','on');
set(handles.pushbutton2,'Visible','on');
set(handles.pushbutton3,'Visible','on');
set(handles.pushbutton4,'Visible','on');

% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data=guidata(hObject);
if handles.bootflag
    gmax=a2multigraph(handles.axes1,data.plotdata,...
                   data.plotminv,...
                   data.plotmaxv,...
                   data.plottitl,...
                   data.prnfilename,...
                   data.chanopis,...
                   data.savefigs,...
                   handles.sqflag,...
                   1,...
                   handles.baselnv);
else
    gmax=amultigraph(handles.axes1,data.plotdata,...
                   data.plotminv,...
                   data.plotmaxv,...
                   data.plottitl,...
                   data.prnfilename,...
                   data.chanopis,...
                   data.savefigs,...
                   handles.sqflag,...
                   1,...
                   handles.baselnv);
end
%data.plotmaxv=gmax;
set(handles.text1,'String',num2str(gmax));
% if data.savefigs
%     printfigure(data,handles);
% end
guidata(hObject,data);
