function varargout = groundwater_downscaling_drought(varargin)
% GROUNDWATER_DOWNSCALING_DROUGHT MATLAB code for groundwater_downscaling_drought.fig
%      GROUNDWATER_DOWNSCALING_DROUGHT, by itself, creates a new GROUNDWATER_DOWNSCALING_DROUGHT or raises the existing
%      singleton*.
%
%      H = GROUNDWATER_DOWNSCALING_DROUGHT returns the handle to a new GROUNDWATER_DOWNSCALING_DROUGHT or the handle to
%      the existing singleton*.
%
%      GROUNDWATER_DOWNSCALING_DROUGHT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GROUNDWATER_DOWNSCALING_DROUGHT.M with the given input arguments.
%
%      GROUNDWATER_DOWNSCALING_DROUGHT('Property','Value',...) creates a new GROUNDWATER_DOWNSCALING_DROUGHT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before groundwater_downscaling_drought_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to groundwater_downscaling_drought_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help groundwater_downscaling_drought

% Last Modified by GUIDE v2.5 02-Dec-2024 14:46:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @groundwater_downscaling_drought_OpeningFcn, ...
                   'gui_OutputFcn',  @groundwater_downscaling_drought_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end


shadowWarnState = warning('query','MATLAB:HandleGraphics:ObsoletedProperty');
warning('off','MATLAB:HandleGraphics:ObsoletedProperty');
shadowWarnRestore = onCleanup(@() warning(shadowWarnState.state,'MATLAB:HandleGraphics:ObsoletedProperty'));

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
clear shadowWarnRestore
% End initialization code - DO NOT EDIT

% --- Executes just before groundwater_downscaling_drought is made visible.
function groundwater_downscaling_drought_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to groundwater_downscaling_drought (see VARARGIN)

% Choose default command line output for groundwater_downscaling_drought
handles.output = hObject;
try
    set(handles.edit3,'String','0.25');
    set(handles.edit4,'String','0.01');
    set(handles.edit5,'String','2002 4 2024 12');
    handles.input_resolution = 0.25;
    handles.output_resolution = 0.01;
    handles.trange = [2002 4 2024 12];
    set(hObject,'Visible','on');
    figure(hObject);
    drawnow;
catch ME
    warning('Failed to initialize new-data controls: %s', ME.message);
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes groundwater_downscaling_drought wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = groundwater_downscaling_drought_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
set(handles.output,'Visible','on');
figure(handles.output);
drawnow;
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_readshp.
function pushbutton_readshp_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_readshp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file,location,file_index] = local_uigetfile(handles, ...
    '*.shp', ...
    'Pick shp data');
if file_index==1
   filename=strcat(location,file);
   set(handles.edit2,'String',filename);
else
   warndlg('wrong');
end

[filepath, basename, ~] = fileparts(filename);
shxfilename = fullfile(filepath, [basename '.shx']);
dbffilename = fullfile(filepath, [basename '.dbf']);

if ~exist(shxfilename, 'file') || ~exist(dbffilename, 'file')
    warning('Missing .shx/.dbf for %s. Continue with geometry-only shaperead.', basename);
end

shp =shaperead(filename,'UseGeoCoords',true);
A=msgbox('Read shp processing');
S=shaperead(filename);
xv=S.X';
yv=S.Y';
lon_min=min(xv);
lon_max=max(xv);
lat_min=min(yv);
lat_max=max(yv);
% 鍒涘缓mask&rbi
handles.input_resolution=str2double(get(handles.edit3,'string'));
if (handles.input_resolution==0.25)
        lon = 0.125:0.25:359.875;
        lat = 89.875:-0.25:-89.875;
        jj=720;
        ii=1440;
        [LonMask,LatMask]=meshgrid(lon,lat);
        mask1 = double(inpolygon(LonMask,LatMask,xv,yv));
    elseif (handles.input_resolution==1)
        lon=0.5:359.5;
        lat=89.5:-1:-89.5;
        jj=180;
        ii=360;
        mask1 = zeros(jj,ii);
        for j=1:jj
            for i=1:ii
                if lon(i)>=lon_min && lon(i)<=lon_max && ...
                    lat(j)>=lat_min && lat(j)<=lat_max
                    in =inpolygon(lon(i),lat(j),xv,yv);
                    if in==1
                        mask1(j,i) = 1;
                    end
                end
            end
        end        
    elseif (handles.input_resolution==0.5)
        lon=0.25:0.5:359.75;
        lat=89.75:-0.5:-89.75;
        jj=360;
        ii=720;
        mask1 = zeros(jj,ii);
        for j=1:jj
            for i=1:ii
                if lon(i)>=lon_min && lon(i)<=lon_max && ...
                    lat(j)>=lat_min && lat(j)<=lat_max
                    in =inpolygon(lon(i),lat(j),xv,yv);
                    if in==1
                        mask1(j,i) = 1;
                    end
                end
            end
        end
    elseif (handles.input_resolution==0.1) 
        lon=0.05:0.1:359.95;
        lat=89.95:-0.1:-89.95;
        jj=1800;
        ii=3600;
        mask1 = zeros(jj,ii);
        for j=1:jj
            for i=1:ii
                if lon(i)>=lon_min && lon(i)<=lon_max && ...
                    lat(j)>=lat_min && lat(j)<=lat_max
                    in =inpolygon(lon(i),lat(j),xv,yv);
                    if in==1
                        mask1(j,i) = 1;
                    end
                end
            end
        end
    elseif (handles.input_resolution==0.01) 
        lon=0.005:0.01:359.995;
        lat=89.995:-0.01:-89.995;
        jj=18000;
        ii=36000;
        mask1 = zeros(jj,ii);
        for j=1:jj
            for i=1:ii
                if lon(i)>=lon_min && lon(i)<=lon_max && ...
                    lat(j)>=lat_min && lat(j)<=lat_max
                    in =inpolygon(lon(i),lat(j),xv,yv);
                    if in==1
                        mask1(j,i) = 1;
                    end
                end
            end
        end

   else
        warndlg('input error');
        return
end

handles.output_resolution=str2double(get(handles.edit4,'string'));
if (handles.output_resolution==0.25)
        lon1 = 0.125:0.25:359.875;
        lat1 = 89.875:-0.25:-89.875;
        jj=720;
        ii=1440;
        mask2 = zeros(jj,ii);
        for j=1:jj
            for i=1:ii
                if lon1(i)>=lon_min && lon1(i)<=lon_max && ...
                    lat1(j)>=lat_min && lat1(j)<=lat_max
                    in =inpolygon(lon1(i),lat1(j),xv,yv);
                    if in==1
                        mask2(j,i) = 1;
                    end
                end
            end
        end
    elseif (handles.output_resolution==1)
        lon1=0.5:359.5;
        lat1=89.5:-1:-89.5;
        jj=180;
        ii=360;
        mask2 = zeros(jj,ii);
        for j=1:jj
            for i=1:ii
                if lon1(i)>=lon_min && lon1(i)<=lon_max && ...
                    lat1(j)>=lat_min && lat1(j)<=lat_max
                    in =inpolygon(lon1(i),lat1(j),xv,yv);
                    if in==1
                        mask2(j,i) = 1;
                    end
                end
            end
        end        
    elseif (handles.output_resolution==0.5)
        lon1=0.25:0.5:359.75;
        lat1=89.75:-0.5:-89.75;
        jj=360;
        ii=720;
        mask2 = zeros(jj,ii);
        for j=1:jj
            for i=1:ii
                if lon1(i)>=lon_min && lon1(i)<=lon_max && ...
                    lat1(j)>=lat_min && lat1(j)<=lat_max
                    in =inpolygon(lon1(i),lat1(j),xv,yv);
                    if in==1
                        mask2(j,i) = 1;
                    end
                end
            end
        end
    elseif (handles.output_resolution==0.1) 
        lon1=0.05:0.1:359.95;
        lat1=89.95:-0.1:-89.95;
        jj=1800;
        ii=3600;
        mask2 = zeros(jj,ii);
        for j=1:jj
            for i=1:ii
                if lon1(i)>=lon_min && lon1(i)<=lon_max && ...
                    lat1(j)>=lat_min && lat1(j)<=lat_max
                    in =inpolygon(lon1(i),lat1(j),xv,yv);
                    if in==1
                        mask2(j,i) = 1;
                    end
                end
            end
        end
    elseif (handles.output_resolution==0.01)
        % 0.01鎺?output is created over the shp bounding box only (memory-safe).
        lon1_min = max(0.005, floor(lon_min/0.01)*0.01 - 0.01);
        lon1_max = min(359.995, ceil(lon_max/0.01)*0.01 + 0.01);
        lat1_min = max(-89.995, floor(lat_min/0.01)*0.01 - 0.01);
        lat1_max = min(89.995, ceil(lat_max/0.01)*0.01 + 0.01);
        lon1 = lon1_min:0.01:lon1_max;
        lat1 = lat1_max:-0.01:lat1_min;
        [Lon2Mask,Lat2Mask] = meshgrid(lon1,lat1);
        mask2 = double(inpolygon(Lon2Mask,Lat2Mask,xv,yv));

    else
        warndlg('output error');
        return
end
msgbox('Read shp Done');
close(A)
% 鍥炶皟缁撴瀯浣?  
[handles.Lon1,handles.Lat1]=meshgrid(lon,lat);
handles.mask1=mask1;
handles.rbi1=find(mask1 == 1);      
[handles.Lon2,handles.Lat2]=meshgrid(lon1,lat1);
handles.mask2=mask2;
handles.rbi2=find(mask2 == 1);
handles.lon1=lon;
handles.lat1=lat;
handles.lon2=lon1;
handles.lat2=lat1;
handles.lon_min=lon_min;
handles.lon_max=lon_max;
handles.lat_min=lat_min;
handles.lat_max=lat_max;
handles.shp=shp;
guidata(hObject,handles);

% --- Executes on button press in pushbutton_readMacson.
function pushbutton_readMacson_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_readMacson (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file,location,file_index] = local_uigetfile(handles, ...
    '*.nc',...
    'Pick CSR-Mascon data');
if file_index==1
   filename=strcat(location,file);
   set(handles.edit1, 'String',filename);
else
   warndlg('wrong');
end
[output_file,output_location] = local_uiputfile(handles, ...
    '*.mat', ...
    'Save Mascon data');
time_1=ncread(filename,'time');
dt2 = datetime((time_1)*24*3600, 'ConvertFrom', 'epochtime', 'Epoch', '2002-01-01');

dateVector = datevec(dt2);

year = dateVector(:,1);
month = dateVector(:,2);
day = dateVector(:,3);
time=year+((month-1)*30+day)/365.;
% 灏嗘椂闂翠紶鎹㈡垚灏忔暟鐐瑰舰寮?time=year+((month-1)*30+day)/365.;
% 璇诲彇Mascon鏁版嵁
[k,~]=size(time);
h=waitbar(0,'Read CSR Mascon data>>>>>>');
% 鏋勫缓杩涘害鏉?h=waitbar(0,'Read CSR Mascon data>>>>>>');
for kk=1:k
csr=ncread(filename,'lwe_thickness',[1,1,kk],[inf,inf,1]);
csr=permute(csr,[2 1]);
csr=flipud(csr);
[a,b]=size(csr);
csr=reshape(csr,1,a*b);
zz=csr;
CSR_Mascon(kk,:)=zz(handles.rbi1);
%鏄剧ず杩涘害
waitbar(kk/k,h)
end
delete(h);
CSR_Mascon=CSR_Mascon*10;
% 鎻愬彇鎵€闇€鏃堕棿娈垫暟鎹?  % 鏁版嵁鏃堕棿璺ㄥ害鎻愬彇   
   start_date = datetime([handles.trange(:,1:2),1]);
   end_date = datetime([handles.trange(:,3:4),1]);
   time_matrix = [year,month];

  % 灏嗘椂闂寸煩闃典腑鐨勫勾鏈堜俊鎭浆鎹负datetime绫诲瀷
   time_matrix_dates = datetime(time_matrix(:, 1), time_matrix(:, 2), 1);

  % 鎵惧嚭鍦ㄧ粰瀹氭椂闂磋法搴﹀唴鐨勬椂闂村尮閰嶉」
   matching_dates_indices = find(time_matrix_dates >= start_date & time_matrix_dates <= end_date);
   matching_dates = time_matrix(matching_dates_indices, :);
  % 鎸囧畾鏃堕棿娈垫暟鎹彁鍙?   CSR_Mascon=CSR_Mascon(matching_dates_indices,:);
   year=matching_dates(:,1);
   month=matching_dates(:,2);
   time=time(matching_dates_indices);
% 璁＄畻CSR_Mascon搴忓垪
[jj,ii]=size(handles.Lon1);
lat=handles.lat1;
[nn,~]=size(CSR_Mascon);
CSR_series = zeros(nn,1);
%
% create the weight 
%

grid_weight=zeros(jj,ii);
for j=1:jj
    for i=1:ii
        grid_weight(j,i)=cos(lat(j)*pi/180);
    end
end
grid_weight=grid_weight.*handles.mask1;

%
% create the time series
%

for n=1:nn
    tmmp=zeros(1,jj*ii);
    tmmp(handles.rbi1)=CSR_Mascon(n,:);
    tmmp=reshape(tmmp,jj,ii);
    grid_weight_new=grid_weight;
    tmmppp=tmmp.*grid_weight_new;
    tmmppp(logical(isnan(tmmppp)))=0;
    grid_sum=sum(sum(tmmppp));
    
    grid_weight_new(logical(isnan(tmmp)))=0;
    weight_sum=sum(sum(grid_weight_new));
    CSR_series(n)=grid_sum/weight_sum;
end
% 璁＄畻CSR trend
t=time;
omega = 2*pi;
[epochs,i]=size(CSR_Mascon);
A = [];
A(:,1) = (ones(epochs,1));
A(:,2) = t';
A(:,3) = cos(omega*t'); 
A(:,4) = sin(omega*t');
A(:,5) = cos(omega*2*t'); 
A(:,6) = sin(omega*2*t');
NM = (A'*A)\A';
for ii=1:i
        time_series=CSR_Mascon(:,ii)';
        if sum(isnan(time_series))==0 
           x      = NM*time_series';
           Trend(1,ii)  = x(2);
        end
end
% trend 1D to 2D
[aa,bb]=size(handles.Lon1);
trend=zeros(1,aa*bb);
trend(handles.rbi1)=Trend;
trend_CSR=reshape(trend,aa,bb);
trend_CSR(trend_CSR==0)=nan;
% 缁樺浘
% 涓夌淮鍥?axes(handles.axes3)
cla reset;
surf(handles.lon1,handles.lat1,trend_CSR,'LineStyle','none');
% 浜岀淮鍥?axes(handles.axes6)
cla reset;
lon_mx=fix(handles.lon_max)+1;
lon_mi=fix(handles.lon_min);
lat_mx=fix(handles.lat_max)+1;
lat_mi=fix(handles.lat_min);
axesm('Mercator','frame','on','flinewidth',0.9,'MapParallels',10, ...
    'mlinelocation',10,'grid','on','maplatlim',[lat_mi,lat_mx], ...
    'maplonlim',[lon_mi,lon_mx],'MLineLocation',2, 'MLabelRound', 0, ...
    'MeridianLabel','on', 'PLineLocation',2,'PLabelRound', 0, ...
    'ParallelLabel','on','MLabelParallel','south')
axis off;
hold on;
geoimg = geoshow(handles.Lat1,handles.Lon1,trend_CSR, ...
         'DisplayType','texturemap') ;
geoimg.AlphaDataMapping = 'none'; 
geoimg.FaceAlpha = 'texturemap'; 
alpha(geoimg,double(~isnan(trend_CSR))) 
geoshow(handles.shp,'facecolor','none')
c = colorbar;
set(c, 'Position', [0.85 0.1 0.05 0.36]);
% 淇濆瓨Mascon鏁版嵁
save(fullfile(output_location,output_file),'CSR_Mascon');
save(fullfile(output_location,output_file),'-append','year');
save(fullfile(output_location,output_file),'-append','month');
save(fullfile(output_location,output_file),'-append','time');
save(fullfile(output_location,output_file),'-append','CSR_series');
save(fullfile(output_location,output_file),'-append','trend_CSR');
msgbox('Read Mascon data Done');
handles.CSR_Mascon=CSR_Mascon;
handles.CSR_series=CSR_series;
handles.CSR_time=time;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1


% --- Executes during object creation, after setting all properties.
function axes2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes2



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




function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


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
editBoxHandle=findobj('Tag','edit3');
handles.input_resolution=str2double(get(editBoxHandle,'string'));
guidata(hObject,handles);
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
editBoxHandle=findobj('Tag','edit4');
handles.output_resolution=str2double(get(editBoxHandle,'string'));
guidata(hObject,handles);
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
editBoxHandle=findobj('Tag','edit5');
handles.trange=sscanf(get(editBoxHandle,'string'),'%f').';
guidata(hObject,handles);

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


% --- Executes on button press in GP_fill.
function GP_fill_Callback(hObject, eventdata, handles)
% hObject    handle to GP_fill (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file,location,file_index] = local_uigetfile(handles, ...
    '*.mat', ...
    'Pick Mascon data');
if file_index==1
   filename=strcat(location,file);
else
   warndlg('wrong');
end
load(filename);
if exist('CSR_Mascon','var')
            grid=CSR_Mascon;
        else    
            warndlg('wrong');
end
[output_file,output_location] = local_uiputfile(handles, ...
    '*.mat', ...
    'Save grid-fill data');
handles.CSR_time=time;
PAR = struct('average',1,'interp',0,'gap',1/12);
% 鏃堕棿璺ㄥ害
trange = handles.trange;
t1=trange;
% 鏃堕棿濉厖
o_t2 = t1(3:4);
idatenum = 0;
iyear1 = t1(1);
iyear2 = o_t2(1);
imonth1 = t1(2);
imonth2 = o_t2(2);
NN = (iyear2-iyear1+1)*12;
rtmp(1:NN,1) = 0;

ik = 0;
for iyear = iyear1:iyear2
    for imonth = 1:12
        ik = ik+1;
        rtmp(ik) = (imonth-0.5)/12 + iyear;
    end
end
tt1 = rtmp(imonth1:end-12+imonth2);
% grid 濉厖
tt0=time;
[~,k]=size(grid);
[j,~]=size(tt1);
grid_fill=zeros(j,k);
for kk=1:k
y1=nan(size(tt1));
y0=grid(:,kk);
  for ii = 1:numel(y1)
    dd = tt0 - tt1(ii);
      if PAR.average == 0
        [mindd,loc] = min(abs(dd));
          if mindd <= PAR.gap/2
            y1(ii) = y0(loc);
          end
      else
        ind = dd<PAR.gap/2 & dd>=-PAR.gap/2;
        y1(ii) = mean(y0(ind));
      end
  end

  if PAR.interp == 1 
    ind = ~isnan(y1);
    y1 = interp1(tt1(ind),y1(ind),tt1);
  elseif PAR.interp == 2
    [~, RC, htest] = ssa_missing_GO(y1, 48, 10);
    y1 = sum(RC(:,htest==1),2);
  end

  a=find(isnan(y1));
  b=find(~isnan(y1));
  time0=tt1(a);
  time_1=tt1(b);
% 鏍肩綉鎻掕ˉ
  y=y1(b);
  gprMdl= fitrgp(time_1-time_1(1),y,'Basis',@(X) [ones(size(X,1),1),(X)./1, ...
      sin(2.*pi.*(X)/1),cos(2.*pi.*(X)/1)],'Beta',[1;1;1;1],...
      'FitMethod','exact','PredictMethod','exact', ...
      'KernelFunction','matern32','KernelParameters',[1;1], ...
      'Sigma',1,'OptimizeHyperparameters','auto', ...
      'Optimizer','quasinewton','ComputationMethod','qr', ...
      'OptimizeHyperparameters','auto','ActiveSetMethod', ...
      'likelihood','ActiveSetSize',150);
% Get the predicted data and confidence intervals corresponding to the time
  [ypred,~,~] = predict(gprMdl,time_1-time_1(1));
  [ypred0,~,~] = predict(gprMdl,time0-time_1(1));
  beta_parameter=gprMdl.Beta;
  sigmaL=gprMdl.KernelInformation.KernelParameters(1);
  sigmaF=gprMdl.KernelInformation.KernelParameters(2);
  sigma=gprMdl.Sigma;
  set(handles.edit6,'string',num2str(roundn(beta_parameter(1),-3)));
  set(handles.edit7,'string',num2str(roundn(beta_parameter(2),-3)));
  set(handles.edit8,'string',num2str(roundn(beta_parameter(3),-3)));
  set(handles.edit9,'string',num2str(roundn(beta_parameter(4),-3)));
  set(handles.edit10,'string',num2str(roundn(sigmaL,-3)));
  set(handles.edit11,'string',num2str(roundn(sigmaF,-3)));
  set(handles.edit12,'string',num2str(roundn(sigma,-3)));
  %Obtain hyperparameter covariance matrix of the mean function through the law of error propagation
    X=time_1-time_1(1);
    H=[ones(size(X,1),1),(X),sin(2.*pi.*(X)/1),cos(2.*pi.*(X)/1)];
    x1=X;
    x2=X;
    sig_n=sigmaL;
    theta0=sigmaF;
    theta1=sigma;
  %鏍稿嚱鏁?    m=size(x1,1);n=size(x2,1);
    dist_matix=zeros(m,n);%璺濈鐭╅樀
    for i=1:m
        for j=1:n
            dist_matix(i,j)=sqrt(sum((x1(i)-x2(j))^2));    
            if (i==j)
            R(i,j)=theta0^2.*(1+sqrt(3).*dist_matix(i,j)/theta1).*exp(-sqrt(3).*dist_matix(i,j)/theta1)+sig_n^2;
            else
            R(i,j)=theta0^2.*(1+sqrt(3).*dist_matix(i,j)/theta1).*exp(-sqrt(3).*dist_matix(i,j)/theta1);    
            end
        end
    end

      A=inv(H'*inv(R)*H)*H'*inv(R);
      cov=A*R*A';
  %Obtain the velocity error
      accuracy=sqrt(cov(2,2));
      set(handles.edit13,'string',num2str(roundn(accuracy,-3)));
  y1(a)=ypred0;
  grid_fill(:,kk)=y1;
  close(gcf);  
  close(gcf);
end
time=tt1;
save(fullfile(output_location,output_file),'grid_fill');
save(fullfile(output_location,output_file),'-append','time');

PAR = struct('average',1,'interp',0,'gap',1/12);
% 鏃堕棿璺ㄥ害
trange = handles.trange;
t1=trange;
% 鏃堕棿濉厖
o_t2 = t1(3:4);
idatenum = 0;
iyear1 = t1(1);
iyear2 = o_t2(1);
imonth1 = t1(2);
imonth2 = o_t2(2);
NN = (iyear2-iyear1+1)*12;
rtmp(1:NN,1) = 0;

ik = 0;
for iyear = iyear1:iyear2
    for imonth = 1:12
        ik = ik+1;
        rtmp(ik) = (imonth-0.5)/12 + iyear;
    end
end
tt1 = rtmp(imonth1:end-12+imonth2);
tt0=handles.CSR_time;
y1=nan(size(tt1));
y0=handles.CSR_series;
  for ii = 1:numel(y1)
    dd = tt0 - tt1(ii);
      if PAR.average == 0
        [mindd,loc] = min(abs(dd));
          if mindd <= PAR.gap/2
            y1(ii) = y0(loc);
          end
      else
        ind = dd<PAR.gap/2 & dd>=-PAR.gap/2;
        y1(ii) = mean(y0(ind));
      end
  end

  if PAR.interp == 1 
    ind = ~isnan(y1);
    y1 = interp1(tt1(ind),y1(ind),tt1);
  elseif PAR.interp == 2
    [~, RC, htest] = ssa_missing_GO(y1, 48, 10);
    y1 = sum(RC(:,htest==1),2);
  end
  a=find(isnan(y1));
  b=find(~isnan(y1));
  time0=tt1(a);
  time_1=tt1(b);
y=y1(b); 
gprMdl= fitrgp(time_1-time_1(1),y,'Basis',@(X) [ones(size(X,1),1),(X)./1, ...
      sin(2.*pi.*(X)/1),cos(2.*pi.*(X)/1)],'Beta',[1;1;1;1],...
      'FitMethod','exact','PredictMethod','exact', ...
      'KernelFunction','matern32','KernelParameters',[1;1], ...
      'Sigma',1,'OptimizeHyperparameters','auto', ...
      'Optimizer','quasinewton','ComputationMethod','qr', ...
      'OptimizeHyperparameters','auto','ActiveSetMethod', ...
      'likelihood','ActiveSetSize',150);
  [ypred,~,yint] = predict(gprMdl,time_1-time_1(1));
  [ypred0,~,yint0] = predict(gprMdl,time0-time_1(1));
  y1(a)=ypred0;
  y1(b)=ypred;
  model_series=y1;
  close(gcf);  
  close(gcf);
save(fullfile(output_location,output_file),'-append','model_series');
save(fullfile(output_location,output_file),'-append','yint');
save(fullfile(output_location,output_file),'-append','yint0');
save(fullfile(output_location,output_file),'-append','time0');
save(fullfile(output_location,output_file),'-append','time_1');
save(fullfile(output_location,output_file),'-append','ypred');
save(fullfile(output_location,output_file),'-append','ypred0');
msgbox('Filling data Done');
% 缁樺浘
% 璁＄畻grid_fill搴忓垪
[jj,ii]=size(handles.Lon1);
lat=handles.lat1;
lg_msk=handles.mask1;rbi=handles.rbi1;
[kk,~]=size(grid_fill);
plot_region = zeros(kk,1);
%
% create the weight 
%

grid_weight=zeros(jj,ii);
for j=1:jj
    for i=1:ii
        grid_weight(j,i)=cos(lat(j)*pi/180);
    end
end
grid_weight=grid_weight.*lg_msk;

%
% create the time series
%

for k=1:kk
    tmmp=zeros(1,jj*ii);
    tmmp(rbi)=grid_fill(k,:);
    tmmp=reshape(tmmp,jj,ii);
    grid_weight_new=grid_weight;
    tmmppp=tmmp.*grid_weight_new;
    tmmppp(logical(isnan(tmmppp)))=0;
    grid_sum=sum(sum(tmmppp));
    
    grid_weight_new(logical(isnan(tmmp)))=0;
    weight_sum=sum(sum(grid_weight_new));
    plot_region(k)=grid_sum/weight_sum;
end
handles.model_series=model_series;
handles.grid_fill=grid_fill;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function uipanel4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function uipanel5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on button press in read_gldas.
function read_gldas_Callback(hObject, eventdata, handles)
% hObject    handle to read_gldas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, location, file_index] = local_uigetfile(handles, ...
    '*.nc4', ...
    'Pick gldas-nc data', ...
    'MultiSelect', 'on');
if file_index==1
   if ischar(file)
       file = {file};
   end
   filename = fullfile(location,file);
else
   warndlg('wrong');
end
num_file = numel(filename);
lon_num=1440;
lat_num=600;
time=zeros(num_file,1);
[output_file,output_location] = local_uiputfile(handles, ...
    '*.mat', ...
    'Save gldas data');
% 鏋勫缓杩涘害鏉?h=waitbar(0,'Read GLDAS data>>>>>>');
    a=zeros(lat_num/5,lon_num);
    a(:)=nan;
for ii=1:num_file
    file_name = char(filename{ii});
    Swe=rot90(ncread(file_name,'SWE_inst'));
    Swe=circshift(Swe,lon_num/2,2);
    Swe=[Swe;a];
    [aa,bb]=size(Swe);
    Swe=reshape(Swe,1,aa*bb);
    SWE(ii,:)=Swe(handles.rbi1);
    
    SoilMoi0_10cm_inst=rot90(ncread(file_name,'SoilMoi0_10cm_inst'));
    SoilMoi100_200cm_inst=rot90(ncread(file_name,'SoilMoi100_200cm_inst'));
    SoilMoi10_40cm_inst=rot90(ncread(file_name,'SoilMoi10_40cm_inst'));
    SoilMoi40_100cm_inst=rot90(ncread(file_name,'SoilMoi40_100cm_inst'));
    Sm=SoilMoi0_10cm_inst+SoilMoi100_200cm_inst+SoilMoi10_40cm_inst+SoilMoi40_100cm_inst;
    Sm=circshift(Sm,lon_num/2,2);
    Sm=[Sm;a];
    [aaa,bbb]=size(Sm);
    Sm=reshape(Sm,1,aaa*bbb);
    SM(ii,:)=Sm(handles.rbi1);

    Can=rot90(ncread(file_name,'CanopInt_inst'));
    Can=circshift(Can,lon_num/2,2);
    Can=[Can;a];
    [aaaa,bbbb]=size(Can);
    Can=reshape(Can,1,aaaa*bbbb);
    CAN(ii,:)=Can(handles.rbi1);
    
    waitbar(ii/num_file,h)
end
    gldas=SWE+CAN+SM;
   % year month time
     year = zeros(num_file,1);
     month = zeros(num_file,1);
     for i=1:num_file
       tk = regexp(file{1,i},'A(\d{4})(\d{2})','tokens','once');
       if isempty(tk)
           error('Cannot parse GLDAS date from filename: %s', file{1,i});
       end
       year(i,:) = str2double(tk{1});
       month(i,:) = str2double(tk{2});
     end
    time=year+(month-1)*(1/12)+1/24;
   % 灏嗘椂闂翠紶鎹㈡垚灏忔暟鐐瑰舰寮?    time=year+(month-1)*(1/12)+1/24;
   % remove 鏃堕棿鍩虹嚎(2004.1-2009.12)
    t_start=datetime(2004,1,1);
    t_end= datetime(2009,12,1);
    time_matrix = [year,month];
    time_matrix_dates = datetime(time_matrix(:, 1), time_matrix(:, 2), 1);
    matching_dates_indices = find(time_matrix_dates >= t_start & time_matrix_dates <= t_end);
    data_remove=gldas(matching_dates_indices,:);
    data_remove_avg=mean(data_remove);
    for k=1:num_file
           gldas(k,:)=gldas(k,:)-data_remove_avg;
    end
   % 鏁版嵁鏃堕棿璺ㄥ害鎻愬彇   
    start_date = datetime([handles.trange(:,1:2),1]);
    end_date = datetime([handles.trange(:,3:4),1]);
    time_matrix_1 = [year,month];
   % 灏嗘椂闂寸煩闃典腑鐨勫勾鏈堜俊鎭浆鎹负datetime绫诲瀷
    time_matrix_dates_1 = datetime(time_matrix_1(:, 1), time_matrix_1(:, 2), 1);

   % 鎵惧嚭鍦ㄧ粰瀹氭椂闂磋法搴﹀唴鐨勬椂闂村尮閰嶉」
    matching_dates_indices_1 = find(time_matrix_dates_1 >= start_date & time_matrix_dates_1 <= end_date);
    matching_dates = time_matrix_1(matching_dates_indices_1, :);
    gldas=gldas(matching_dates_indices_1,:);
    year=matching_dates(:,1);
    month=matching_dates(:,2);
    time=time(matching_dates_indices_1);

    save(fullfile(output_location,output_file),'gldas');
    save(fullfile(output_location,output_file),'-append','year');
    save(fullfile(output_location,output_file),'-append','month');
    save(fullfile(output_location,output_file),'-append','time');
    delete(h);
    msgbox('Read GLDAS data Done');

    handles.gldas=gldas;
    handles.gldas_time=time;
    handles.month=month;
    guidata(hObject, handles);


% --- Executes on button press in read_LST.
function read_LST_Callback(hObject, eventdata, handles)
% hObject    handle to read_LST (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Keep the legacy LST button consistent with the split predictor workflow.
read_predictor_factor_Callback(hObject,eventdata,handles,'lst');
return;
[file, location, file_index] = local_uigetfile(handles, ...
    '*.hdf', ...
    'Pick LST data', ...
    'MultiSelect', 'on');
if file_index==1
   if ischar(file)
       file = {file};
   end
   filename = fullfile(location,file);
else
   warndlg('wrong');
end
num_file = numel(filename);

% Robust LST reader for source products with non-0.01 raw resolution.
[output_file,output_location] = local_uiputfile(handles, ...
    '*.mat', ...
    'Save LST data');
h=waitbar(0,'Read LST data>>>>>>');
year = zeros(num_file,1);
month = zeros(num_file,1);
for ii=1:num_file
    file_name = char(filename{ii});
    lst_day = double(hdfread(file_name,'LST_Day_CMG'));
    [lat_num,lon_num] = size(lst_day);
    lst_day = circshift(lst_day,round(lon_num/2),2);
    lon_step = 360/lon_num;
    lat_step = 180/lat_num;
    lon_src = (lon_step/2):lon_step:(360-lon_step/2);
    lat_src = (90-lat_step/2):-lat_step:(-90+lat_step/2);
    [LonSrc,LatSrc] = meshgrid(lon_src,lat_src);

    day_025 = interp2(LonSrc,LatSrc,lst_day,handles.Lon1,handles.Lat1,'linear');
    day_025 = reshape(day_025,1,[]);
    lst_day_025(ii,:) = day_025(handles.rbi1);
    day_001 = interp2(LonSrc,LatSrc,lst_day,handles.Lon2,handles.Lat2,'linear');
    day_001 = reshape(day_001,1,[]);
    lst_day_001(ii,:) = day_001(handles.rbi2);

    lst_night = double(hdfread(file_name,'LST_Night_CMG'));
    lst_night = circshift(lst_night,round(lon_num/2),2);
    night_025 = interp2(LonSrc,LatSrc,lst_night,handles.Lon1,handles.Lat1,'linear');
    night_025 = reshape(night_025,1,[]);
    lst_night_025(ii,:) = night_025(handles.rbi1);
    night_001 = interp2(LonSrc,LatSrc,lst_night,handles.Lon2,handles.Lat2,'linear');
    night_001 = reshape(night_001,1,[]);
    lst_night_001(ii,:) = night_001(handles.rbi2);

    tk = regexp(file{1,ii},'A(\d{4})(\d{3})','tokens','once');
    if isempty(tk)
        error('Cannot parse LST date from filename: %s', file{1,ii});
    end
    dt = datetime(str2double(tk{1}),1,1) + days(str2double(tk{2})-1);
    dv = datevec(dt);
    year(ii,:) = dv(1);
    month(ii,:) = dv(2);
    waitbar(ii/num_file,h)
end

time=year+(month-1)*(1/12)+1/24;
start_date = datetime([handles.trange(:,1:2),1]);
end_date = datetime([handles.trange(:,3:4),1]);
time_matrix_1 = [year,month];
time_matrix_dates_1 = datetime(time_matrix_1(:, 1), time_matrix_1(:, 2), 1);
matching_dates_indices_1 = find(time_matrix_dates_1 >= start_date & time_matrix_dates_1 <= end_date);
matching_dates = time_matrix_1(matching_dates_indices_1, :);
lst_day_025=lst_day_025(matching_dates_indices_1,:);
lst_day_001=lst_day_001(matching_dates_indices_1,:);
lst_night_025=lst_night_025(matching_dates_indices_1,:);
lst_night_001=lst_night_001(matching_dates_indices_1,:);
year=matching_dates(:,1);
month=matching_dates(:,2);
time=time(matching_dates_indices_1);

save(fullfile(output_location,output_file),'lst_day_001');
save(fullfile(output_location,output_file),'-append','lst_night_001');
save(fullfile(output_location,output_file),'-append','lst_day_025');
save(fullfile(output_location,output_file),'-append','lst_night_025');
save(fullfile(output_location,output_file),'-append','year');
save(fullfile(output_location,output_file),'-append','month');
save(fullfile(output_location,output_file),'-append','time');
delete(h);
msgbox('Read LST data Done');

handles.lst_day_025=lst_day_025;
handles.lst_day_001=lst_day_001;
handles.lst_night_025=lst_night_025;
handles.lst_night_001=lst_night_001;
handles.lst_time=time;
guidata(hObject, handles);
return;

[output_file,output_location] = local_uiputfile(handles, ...
    '*.mat', ...
    'Save LST data');
% 鏋勫缓杩涘害鏉?h=waitbar(0,'Read LST data>>>>>>');
[aa,bb]=size(handles.Lon1);
for ii=1:num_file
    scale=handles.input_resolution/handles.output_resolution;
    file_name=char(strcat(filename(1,ii)));
    lst_day=hdfread(file_name,'LST_Day_CMG');
    [lat_num,lon_num]=size(lst_day);
    lst_day=circshift(lst_day,lon_num/2,2);
    % 鍍忓厓骞冲潎涓?.25掳
    up_grid_day=zeros(lat_num/scale,lon_num/scale);

    for jj=1:lat_num/scale
       for kk=1:lon_num/scale
          up_grid_day(jj,kk)=nanmean(lst_day((scale*jj-(scale-1)):scale*jj,(scale*kk-(scale-1)):scale*kk),'all');
       end
    end
    up_grid_day=reshape(up_grid_day,1,aa*bb);
    lst_day_025(ii,:)=up_grid_day(handles.rbi1);
    % 鎻愬彇0.01 lst_day
    lst_day=reshape(lst_day,1,lat_num*lon_num);
    lst_day_001(ii,:)=lst_day(handles.rbi2);


    lst_night=hdfread(file_name,'LST_Night_CMG');
    lst_night=circshift(lst_night,lon_num/2,2);
    % 鍍忓厓骞冲潎涓?.25掳
    up_grid_night=zeros(lat_num/scale,lon_num/scale);

    for jj=1:lat_num/scale
       for kk=1:lon_num/scale
          up_grid_night(jj,kk)=nanmean(lst_night((scale*jj-(scale-1)):scale*jj,(scale*kk-(scale-1)):scale*kk),'all');
       end
    end
    up_grid_night=reshape(up_grid_night,1,aa*bb);
    lst_night_025(ii,:)=up_grid_night(handles.rbi1);
    % 鎻愬彇0.01 lst_night
    lst_night=reshape(lst_night,1,lat_num*lon_num);
    lst_night_001(ii,:)=lst_night(handles.rbi2);
    waitbar(ii/num_file,h)
end
    lst_day_001=double(lst_day_001);
    lst_night_001=double(lst_night_001);
   % year month time
     for i=1:num_file
       year(i,:)=str2double(file{1,i}(10:13));
     end
     for i=1:num_file
       bbb=str2double(file{1,i}(14:16));
       month(i,:)=round(bbb/30)+1;
     end
   % 灏嗘椂闂翠紶鎹㈡垚灏忔暟鐐瑰舰寮?    time=year+(month-1)*(1/12)+1/24;

   % 鏁版嵁鏃堕棿璺ㄥ害鎻愬彇   
    start_date = datetime([handles.trange(:,1:2),1]);
    end_date = datetime([handles.trange(:,3:4),1]);
    time_matrix_1 = [year,month];
   % 灏嗘椂闂寸煩闃典腑鐨勫勾鏈堜俊鎭浆鎹负datetime绫诲瀷
    time_matrix_dates_1 = datetime(time_matrix_1(:, 1), time_matrix_1(:, 2), 1);

   % 鎵惧嚭鍦ㄧ粰瀹氭椂闂磋法搴﹀唴鐨勬椂闂村尮閰嶉」
    matching_dates_indices_1 = find(time_matrix_dates_1 >= start_date & time_matrix_dates_1 <= end_date);
    matching_dates = time_matrix_1(matching_dates_indices_1, :);
    lst_day_025=lst_day_025(matching_dates_indices_1,:);
    lst_day_001=lst_day_001(matching_dates_indices_1,:);
    lst_night_025=lst_night_025(matching_dates_indices_1,:);
    lst_night_001=lst_night_001(matching_dates_indices_1,:);
    year=matching_dates(:,1);
    month=matching_dates(:,2);
    time=time(matching_dates_indices_1);


    save(fullfile(output_location,output_file),'lst_day_001');
    save(fullfile(output_location,output_file),'-append','lst_night_001');
    save(fullfile(output_location,output_file),'-append','lst_day_025');
    save(fullfile(output_location,output_file),'-append','lst_night_025');
    save(fullfile(output_location,output_file),'-append','year');
    save(fullfile(output_location,output_file),'-append','month');
    save(fullfile(output_location,output_file),'-append','time');
    delete(h);
    msgbox('Read LST data Done');

    handles.lst_day_025=lst_day_025;
    handles.lst_day_001=lst_day_001;
    handles.lst_night_025=lst_night_025;
    handles.lst_night_001=lst_night_001;
    handles.lst_time=time;
    guidata(hObject, handles);

function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


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



function edit8_Callback(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit8 as text
%        str2double(get(hObject,'String')) returns contents of edit8 as a double


% --- Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit9_Callback(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit9 as text
%        str2double(get(hObject,'String')) returns contents of edit9 as a double


% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function uipanel2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% --- Executes during object creation, after setting all properties.

function uipanel3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function edit10_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double


% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
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
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit8 as text
%        str2double(get(hObject,'String')) returns contents of edit8 as a double


% --- Executes during object creation, after setting all properties.
function edit12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
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


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, location, file_index] = uigetfile( ...
    '*.mat', ...
    'Pick grid_fill data');
if file_index==1
   filename=strcat(location,file);
else
   warndlg('wrong');
end
load(strcat(location,file));
% 缁樺浘
% 璁＄畻grid_fill搴忓垪
[jj,ii]=size(handles.Lon1);
lat=handles.lat1;
lg_msk=handles.mask1;rbi=handles.rbi1;
[kk,~]=size(grid_fill);
plot_region = zeros(kk,1);
% create the weight 
grid_weight=zeros(jj,ii);
for j=1:jj
    for i=1:ii
        grid_weight(j,i)=cos(lat(j)*pi/180);
    end
end
grid_weight=grid_weight.*lg_msk;
% create the time series
for k=1:kk
    tmmp=zeros(1,jj*ii);
    tmmp(rbi)=grid_fill(k,:);
    tmmp=reshape(tmmp,jj,ii);
    grid_weight_new=grid_weight;
    tmmppp=tmmp.*grid_weight_new;
    tmmppp(logical(isnan(tmmppp)))=0;% in case, there are NaNs
    grid_sum=sum(sum(tmmppp));
    
    grid_weight_new(logical(isnan(tmmp)))=0;
    weight_sum=sum(sum(grid_weight_new));
    plot_region(k)=grid_sum/weight_sum;
end
axes(handles.axes1)
cla reset;
errorbar(time_1,ypred,yint(:,2)-ypred,ypred-yint(:,1),'DisplayName','95% confidence interval',...
    'LineStyle','none',...
    'LineWidth',0.7,...
    'Color',[0.831372559070587 0.815686285495758 0.7843137383461]);
hold on;
plot(handles.CSR_time,handles.CSR_series,'DisplayName','CSR_Mascon','MarkerSize',8,'Marker','.',...
    'LineStyle','none',...
    'Color',[0.650980392156863 0.650980392156863 0.650980392156863]);
hold on;
plot(time,model_series,'DisplayName','GP model','LineWidth',1,...
    'Color',[0.850980392156863 0.325490196078431 0.0980392156862745]);
hold on;
plot(time(183:194),model_series(183:194),'DisplayName','GP recovery','LineWidth',1.2,...
    'Color',[0.392156862745098 0.831372549019608 0.0745098039215686]);
h=legend('95% confidence interval','CSR Mascon','GP model','GP recovery');
set(h, 'FontName', 'Times New Roman', 'FontSize', 6, 'FontWeight', 'normal');
ylabel({'Equivalent water Height(mm)'},'FontSize',10,...
    'FontName','Times New Roman');
xlabel({'Year'},'FontSize',9,'FontName','Times New Roman');
% --- Executes during object creation, after setting all properties.
function axes5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: place code in OpeningFcn to populate axes5

% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, location, file_index] = local_uigetfile(handles, ...
    '*.nc', ...
    'Pick ERA5-Land data');
if file_index==1
   filename=strcat(location,file);
else
   warndlg('wrong');
end
Valid_time = double(ncread(filename,'valid_time'));
[num_file,~]=size(Valid_time);

% Robust ERA5 reader for 0.1鎺?source products.
[output_file,output_location] = local_uiputfile(handles, ...
    '*.mat', ...
    'Save ERA5-Land data');
h=waitbar(0,'Read ERA5-Land data>>>>>>');
for ii=1:num_file
    e = double(ncread(filename,'e',[1,1,ii],[inf,inf,1]));
    e = permute(e,[2,1]);
    if size(e,1) > 1
        e(end,:) = [];
    end
    [lat_num,lon_num] = size(e);
    lon_step = 360/lon_num;
    lat_step = 180/lat_num;
    lon_raw = (lon_step/2):lon_step:(360-lon_step/2);
    lat_raw = (90-lat_step/2):-lat_step:(-90+lat_step/2);
    [LonRaw,LatRaw] = meshgrid(lon_raw,lat_raw);
    e025 = interp2(LonRaw,LatRaw,e,handles.Lon1,handles.Lat1,'linear');
    e025 = reshape(e025,1,[]);
    e_025(ii,:) = e025(handles.rbi1);
    e001 = interp2(LonRaw,LatRaw,e,handles.Lon2,handles.Lat2,'linear');
    e001 = reshape(e001,1,[]);
    e_001(ii,:) = e001(handles.rbi2);

    tp = double(ncread(filename,'tp',[1,1,ii],[inf,inf,1]));
    tp = permute(tp,[2,1]);
    if size(tp,1) > 1
        tp(end,:) = [];
    end
    tp025 = interp2(LonRaw,LatRaw,tp,handles.Lon1,handles.Lat1,'linear');
    tp025 = reshape(tp025,1,[]);
    pre_025(ii,:) = tp025(handles.rbi1);
    tp001 = interp2(LonRaw,LatRaw,tp,handles.Lon2,handles.Lat2,'linear');
    tp001 = reshape(tp001,1,[]);
    pre_001(ii,:) = tp001(handles.rbi2);

    t2m = double(ncread(filename,'t2m',[1,1,ii],[inf,inf,1]));
    t2m = permute(t2m,[2,1]);
    if size(t2m,1) > 1
        t2m(end,:) = [];
    end
    t025 = interp2(LonRaw,LatRaw,t2m,handles.Lon1,handles.Lat1,'linear');
    t025 = reshape(t025,1,[]);
    temp_025(ii,:) = t025(handles.rbi1);
    t001 = interp2(LonRaw,LatRaw,t2m,handles.Lon2,handles.Lat2,'linear');
    t001 = reshape(t001,1,[]);
    temp_001(ii,:) = t001(handles.rbi2);
    waitbar(ii/num_file,h)
end

initial_time = datetime(1970, 1, 1, 0, 0, 0);
Valid_time = Valid_time/3600;
result_time = initial_time + hours(Valid_time);
y_m_d = datevec(result_time);
year = y_m_d(:,1);
month = y_m_d(:,2);
time = year+(month-1)*(1/12)+1/24;
start_date = datetime([handles.trange(:,1:2),1]);
end_date = datetime([handles.trange(:,3:4),1]);
time_matrix_1 = [year,month];
time_matrix_dates_1 = datetime(time_matrix_1(:, 1), time_matrix_1(:, 2), 1);
matching_dates_indices_1 = find(time_matrix_dates_1 >= start_date & time_matrix_dates_1 <= end_date);
matching_dates = time_matrix_1(matching_dates_indices_1, :);
e_001=e_001(matching_dates_indices_1,:);
e_025=e_025(matching_dates_indices_1,:);
pre_001=pre_001(matching_dates_indices_1,:);
pre_025=pre_025(matching_dates_indices_1,:);
temp_001=temp_001(matching_dates_indices_1,:);
temp_025=temp_025(matching_dates_indices_1,:);
year=matching_dates(:,1);
month=matching_dates(:,2);
time=time(matching_dates_indices_1);

save(fullfile(output_location,output_file),'e_001');
save(fullfile(output_location,output_file),'-append','e_025');
save(fullfile(output_location,output_file),'-append','pre_025');
save(fullfile(output_location,output_file),'-append','pre_001');
save(fullfile(output_location,output_file),'-append','temp_025');
save(fullfile(output_location,output_file),'-append','temp_001');
save(fullfile(output_location,output_file),'-append','year');
save(fullfile(output_location,output_file),'-append','month');
save(fullfile(output_location,output_file),'-append','time');
delete(h);
msgbox('Read ERA5-Land data Done');
handles.e_025=e_025;
handles.e_001=e_001;
handles.pre_025=pre_025;
handles.pre_001=pre_001;
handles.temp_025=temp_025;
handles.temp_001=temp_001;
handles.era5_time=time;
guidata(hObject, handles);
return;

[output_file,output_location] = local_uiputfile(handles, ...
    '*.mat', ...
    'Save ERA5-Land data');
% 鏋勫缓杩涘害鏉?h=waitbar(0,'Read ERA5-Land data>>>>>>');
[aa,bb]=size(handles.Lon1);
for ii=1:num_file
e=ncread(filename,'e',[1,1,ii],[inf,inf,1]);
e=permute(e,[2,1]);
e(1801,:)=[];
lon=0.005:0.01:359.995;
lat=89.995:-0.01:-89.995;
[Lon,Lat]=meshgrid(lon,lat);
% 閲嶉噰鏍蜂负0.01
e001=interp2(Lon,Lat,e,handles.Lon2,handles.Lat2,'linear');
% 鍍忓厓骞冲潎涓?.25
scale=handles.input_resolution/handles.output_resolution;
[lat_num,lon_num]=size(e001);
up_grid_e=zeros(lat_num/scale,lon_num/scale);

    for jj=1:lat_num/scale
       for kk=1:lon_num/scale
          up_grid_e(jj,kk)=nanmean(e001((scale*jj-(scale-1)):scale*jj,(scale*kk-(scale-1)):scale*kk),'all');
       end
    end
    up_grid_e=reshape(up_grid_e,1,aa*bb);
    e_025(ii,:)=up_grid_e(handles.rbi1);
    % 鎻愬彇0.01 lst_day
    e001=reshape(e001,1,lat_num*lon_num);
    e_001(ii,:)=e001(handles.rbi2);
    clear e001
    
tp=ncread(filename,'tp',[1,1,ii],[inf,inf,1]);
tp=permute(tp,[2,1]);
tp(1801,:)=[];
lon=0.005:0.01:359.995;
lat=89.995:-0.01:-89.995;
[Lon,Lat]=meshgrid(lon,lat);
% 閲嶉噰鏍蜂负0.01
tp001=interp2(Lon,Lat,tp,handles.Lon2,handles.Lat2,'linear');
% 鍍忓厓骞冲潎涓?.25
scale=handles.input_resolution/handles.output_resolution;
[lat_num,lon_num]=size(tp001);
up_grid_tp=zeros(lat_num/scale,lon_num/scale);

    for jj=1:lat_num/scale
       for kk=1:lon_num/scale
          up_grid_tp(jj,kk)=nanmean(tp001((scale*jj-(scale-1)):scale*jj,(scale*kk-(scale-1)):scale*kk),'all');
       end
    end
    up_grid_tp=reshape(up_grid_tp,1,aa*bb);
    pre_025(ii,:)=up_grid_tp(handles.rbi1);
    % 鎻愬彇0.01 lst_day
    tp001=reshape(tp001,1,lat_num*lon_num);
    pre_001(ii,:)=tp001(handles.rbi2);
    clear tp001

t2m=ncread(filename,'t2m',[1,1,ii],[inf,inf,1]);
t2m=permute(t2m,[2,1]);
t2m(1801,:)=[];
lon=0.005:0.01:359.995;
lat=89.995:-0.01:-89.995;
[Lon,Lat]=meshgrid(lon,lat);
% 閲嶉噰鏍蜂负0.01
t2m001=interp2(Lon,Lat,t2m,handles.Lon2,handles.Lat2,'linear');
% 鍍忓厓骞冲潎涓?.25
scale=handles.input_resolution/handles.output_resolution;
[lat_num,lon_num]=size(t2m001);
up_grid_t2m=zeros(lat_num/scale,lon_num/scale);

    for jj=1:lat_num/scale
       for kk=1:lon_num/scale
          up_grid_t2m(jj,kk)=nanmean(t2m001((scale*jj-(scale-1)):scale*jj,(scale*kk-(scale-1)):scale*kk),'all');
       end
    end
    up_grid_t2m=reshape(up_grid_t2m,1,aa*bb);
    temp_025(ii,:)=up_grid_t2m(handles.rbi1);
    % 鎻愬彇0.01 lst_day
    t2m001=reshape(t2m001,1,lat_num*lon_num);
    temp_001(ii,:)=t2m001(handles.rbi2);
    clear t2m001
%鏄剧ず杩涘害
waitbar(ii/num_file,h)
end
% Etime璇诲彇
  
  initial_time = datetime(1970, 1, 1, 0, 0, 0); %璧峰鏃堕棿涓?970-01-01
  Valid_time = Valid_time/3600;
  % 璁＄畻缁撴灉鏃堕棿
  result_time = initial_time + hours(Valid_time);
  y_m_d=datevec(result_time); 
  year=y_m_d(:,1);
  month=y_m_d(:,2);
  time=year+(month-1)*(1/12)+1/24;
  % 鏁版嵁鏃堕棿璺ㄥ害鎻愬彇   
    start_date = datetime([handles.trange(:,1:2),1]);
    end_date = datetime([handles.trange(:,3:4),1]);
    time_matrix_1 = [year,month];
  % 灏嗘椂闂寸煩闃典腑鐨勫勾鏈堜俊鎭浆鎹负datetime绫诲瀷
    time_matrix_dates_1 = datetime(time_matrix_1(:, 1), time_matrix_1(:, 2), 1);
  % 鎵惧嚭鍦ㄧ粰瀹氭椂闂磋法搴﹀唴鐨勬椂闂村尮閰嶉」
    matching_dates_indices_1 = find(time_matrix_dates_1 >= start_date & time_matrix_dates_1 <= end_date);
    matching_dates = time_matrix_1(matching_dates_indices_1, :);
    e_001=e_001(matching_dates_indices_1,:);
    e_025=e_025(matching_dates_indices_1,:);
    pre_001=pre_001(matching_dates_indices_1,:);
    pre_025=pre_025(matching_dates_indices_1,:);
    temp_001=temp_001(matching_dates_indices_1,:);
    temp_025=temp_025(matching_dates_indices_1,:);
    year=matching_dates(:,1);
    month=matching_dates(:,2);
    time=time(matching_dates_indices_1);

% save data
    save(fullfile(output_location,output_file),'e_001');
    save(fullfile(output_location,output_file),'-append','e_025');
    save(fullfile(output_location,output_file),'-append','pre_025');
    save(fullfile(output_location,output_file),'-append','pre_001');
    save(fullfile(output_location,output_file),'-append','temp_025');
    save(fullfile(output_location,output_file),'-append','temp_001');
    save(fullfile(output_location,output_file),'-append','year');
    save(fullfile(output_location,output_file),'-append','month');
    save(fullfile(output_location,output_file),'-append','time');
    delete(h);
    msgbox('Read ERA5-Land data Done');
    handles.e_025=e_025;
    handles.e_001=e_001;
    handles.pre_025=pre_025;
    handles.pre_001=pre_001;
    handles.temp_025=temp_025;
    handles.temp_001=temp_001;
    handles.era5_time=time;
    guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function axes3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes3


% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% 鎵撳紑grid_fill
[file, location, file_index] = local_uigetfile(handles, ...
    '*.mat', ...
    'Pick grid_fill data');
if file_index==1
    filename=strcat(location,file);
    load(filename);
        if exist('grid_fill','var') 
            handles.twsa=grid_fill;
            handles.t=time;
        end
else
   warndlg('wrong');               
end

% 鎵撳紑gldas
[file, location, file_index] = local_uigetfile(handles, ...
    '*.mat', ...
    'Pick gldas data');
if file_index==1
    filename=strcat(location,file);
    load(filename);
        if exist('gldas','var') 
            handles.gldas_1=gldas;
        end
else
   warndlg('wrong');               
end

% 鎵撳紑lst
% Pick the split predictor MAT files and merge them for XGBoost.
[handles, predictor_ok] = hngw_pick_split_predictors(hObject, handles);
if ~predictor_ok
    return;
end

if false
[file, location, file_index] = local_uigetfile(handles, ...
    '*.mat', ...
    'Pick LST data');
if file_index==1
    filename=strcat(location,file);
    load(filename);
        if exist('lst_day_025','var') 
            handles.lst_day025=lst_day_025*0.02-273.15;
        end
if exist('lst_day_001','var') 
            handles.lst_day001=lst_day_001*0.02-273.15;
        end
        if exist('lst_night_025','var')
            handles.lst_night025=lst_night_025*0.02-273.15;
        end
        if exist('lst_night_001','var') 
            handles.lst_night001=lst_night_001*0.02-273.15;
        end
else
   warndlg('wrong');               
end

% 鎵撳紑ERA5-Land
[file, location, file_index] = local_uigetfile(handles, ...
    '*.mat', ...
    'Pick ERA5-Land data');
if file_index==1
    filename=strcat(location,file);
    load(filename);
        if exist('e_025','var')
            handles.e025=e_025*1000*30;
        elseif exist('e025','var')
            handles.e025=e025*1000*30;
        end
        if exist('e_001','var')
            handles.e001=e_001*1000*30;
        elseif exist('e001','var')
            handles.e001=e001*1000*30;
        end
        if exist('pre_025','var')
            handles.pre025=pre_025*1000*30;
        elseif exist('pre025','var')
            handles.pre025=pre025*1000*30;
        end
        if exist('pre_001','var')
            handles.pre001=pre_001*1000*30;
        elseif exist('pre001','var')
            handles.pre001=pre001*1000*30;
        end
        if exist('temp_025','var')
            handles.temp025=temp_025-273.15;
        elseif exist('temp025','var')
            handles.temp025=temp025-273.15;
        end
        if exist('temp_001','var')
            handles.temp001=temp_001-273.15;
        elseif exist('temp001','var')
            handles.temp001=temp001-273.15;
        end
else
   warndlg('wrong');
end
end
[output_file,output_location] = local_uiputfile(handles, ...
    '*.mat', ...
    'Save CSR-Downscale data');
        handles.gwsa=handles.twsa-handles.gldas_1;
        if ~isfield(handles,'predictor025') || ~isfield(handles,'predictor001')
            errordlg('Missing predictor data. Please read or pick all split predictor MAT files first.');
            return;
        end
        handles.predictorNames = hngw_predictor_names(handles);
        k = hngw_prepare_predictors_for_rf(handles);
        handles = hngw_trim_predictors(handles,k);
        if isfield(handles,'t') && numel(handles.t) >= k
            handles.t = handles.t(1:k);
        end
        n025 = size(handles.gwsa,2);
        if ~hngw_check_predictor_width(handles.predictor025,handles.predictorStatic025,n025)
            errordlg('0.25 predictor spatial sizes are inconsistent with GWSA.');
            return;
        end
        n001 = numel(handles.rbi2);
        if ~hngw_check_predictor_width(handles.predictor001,handles.predictorStatic001,n001)
            errordlg('0.01 predictor spatial sizes are inconsistent with output grid.');
            return;
        end
        if false
        if ~isfield(handles,'e025') || ~isfield(handles,'lst_day025') || ~isfield(handles,'lst_night025') || ~isfield(handles,'pre025') || ~isfield(handles,'temp025')
            errordlg('Missing 0.25掳 predictor variables. Please load ERA5-Land and LST data correctly.');
            return;
        end
        if ~isfield(handles,'e001') || ~isfield(handles,'lst_day001') || ~isfield(handles,'lst_night001') || ~isfield(handles,'pre001') || ~isfield(handles,'temp001')
            errordlg('Missing 0.01掳 predictor variables. Please load ERA5-Land and LST data correctly.');
            return;
        end
        k_all = [size(handles.gwsa,1), size(handles.e025,1), size(handles.lst_day025,1), size(handles.lst_night025,1), size(handles.pre025,1), size(handles.temp025,1), ...
                 size(handles.e001,1), size(handles.lst_day001,1), size(handles.lst_night001,1), size(handles.pre001,1), size(handles.temp001,1)];
        k = min(k_all);
        if k < 1
            errordlg('Input data is empty after alignment.');
            return;
        end
        if size(handles.gwsa,1) ~= k, handles.gwsa = handles.gwsa(1:k,:); end
        if size(handles.e025,1) ~= k, handles.e025 = handles.e025(1:k,:); end
        if size(handles.lst_day025,1) ~= k, handles.lst_day025 = handles.lst_day025(1:k,:); end
        if size(handles.lst_night025,1) ~= k, handles.lst_night025 = handles.lst_night025(1:k,:); end
        if size(handles.pre025,1) ~= k, handles.pre025 = handles.pre025(1:k,:); end
        if size(handles.temp025,1) ~= k, handles.temp025 = handles.temp025(1:k,:); end
        if size(handles.e001,1) ~= k, handles.e001 = handles.e001(1:k,:); end
        if size(handles.lst_day001,1) ~= k, handles.lst_day001 = handles.lst_day001(1:k,:); end
        if size(handles.lst_night001,1) ~= k, handles.lst_night001 = handles.lst_night001(1:k,:); end
        if size(handles.pre001,1) ~= k, handles.pre001 = handles.pre001(1:k,:); end
        if size(handles.temp001,1) ~= k, handles.temp001 = handles.temp001(1:k,:); end
        if isfield(handles,'t') && numel(handles.t) >= k
            handles.t = handles.t(1:k);
        end

        n025 = size(handles.gwsa,2);
        if size(handles.e025,2) ~= n025 || size(handles.lst_day025,2) ~= n025 || size(handles.lst_night025,2) ~= n025 || size(handles.pre025,2) ~= n025 || size(handles.temp025,2) ~= n025
            errordlg('0.25掳 data spatial sizes are inconsistent. Please ensure grid_fill, GLDAS, LST_025, and ERA5_025 use the same mask/order.');
            return;
        end
        n001 = size(handles.e001,2);
        if size(handles.lst_day001,2) ~= n001 || size(handles.lst_night001,2) ~= n001 || size(handles.pre001,2) ~= n001 || size(handles.temp001,2) ~= n001
            errordlg('0.01掳 data spatial sizes are inconsistent. Please ensure LST_001 and ERA5_001 use the same mask/order.');
            return;
        end
% RF妯″瀷璁粌
        end
ntrees=200;
leaf=5;
[k,~]=size(handles.gwsa);
n025 = size(handles.gwsa,2);
n001 = numel(handles.rbi2);
ypred = nan(k,n025);
Residual_region = nan(k,n025);
Y_pred = nan(k,n001);
model_type = 'xgboost';
residual_interp_method = 'spline';
xgb_temp_dir = fullfile(output_location,'xgb_tmp');
xgb_model_dir = fullfile(output_location,'xgb_models');
if ~exist(xgb_model_dir,'dir')
    mkdir(xgb_model_dir);
end
xgb_model_files = cell(k,1);
xgb_lag_months = 6;
xgb_corr_threshold = 0.85;
xgb_feature_selection = cell(k,1);
if ~exist(xgb_temp_dir,'dir')
    mkdir(xgb_temp_dir);
end
h=waitbar(0,'XGBoost monthly training/downscaling>>>>>>');
for kk=1:k
    [X025_all,xgb_feature_names,xgb_feature_lags]=hngw_lagged_rf_matrix(handles.predictor025,handles.predictorStatic025,handles.predictorNames,kk,xgb_lag_months);
    Y025=handles.gwsa(kk,:)';
    X001_all=hngw_lagged_rf_matrix(handles.predictor001,handles.predictorStatic001,handles.predictorNames,kk,xgb_lag_months);
    [X025,X001,selected_feature_names,removed_feature_names,selected_feature_index]=hngw_remove_collinear_lag_features( ...
        X025_all,X001_all,xgb_feature_names,xgb_feature_lags,xgb_corr_threshold);
    modelFile = hngw_xgb_model_file(xgb_model_dir,kk,time);
    [y025,y001]=hngw_xgb_predict_month(X025,Y025,X001,kk,xgb_temp_dir,modelFile);
    xgb_model_files{kk} = modelFile;
    xgb_feature_selection{kk}=struct( ...
        'month_index',kk, ...
        'lag_months',xgb_lag_months, ...
        'corr_threshold',xgb_corr_threshold, ...
        'all_feature_names',{xgb_feature_names}, ...
        'selected_feature_names',{selected_feature_names}, ...
        'removed_feature_names',{removed_feature_names}, ...
        'selected_feature_index',selected_feature_index);
    ypred(kk,:)=y025(:)';
    Residual_region(kk,:)=(Y025(:)-y025(:))';
    Y_pred(kk,:)=y001(:)';
    waitbar(kk/k,h,sprintf('XGBoost %d/%d',kk,k))
end
delete(h);
A=msgbox('XGBoost Model train/downscale Done');
pause(2)
close(A)
if false
RFModel=cell(k,1);
useTreeBagger = (exist('TreeBagger','class')==8) && license('test','Statistics_Toolbox');
if ~useTreeBagger
    warndlg('Statistics and Machine Learning Toolbox not found. Switched to linear regression fallback.');
end
h=waitbar(0,'RF Model training>>>>>>');
    for kk=1:k
        X=hngw_rf_matrix(handles.predictor025,handles.predictorStatic025,handles.predictorNames,kk);
        Y=handles.gwsa(kk,:)';
        good = isfinite(Y) & all(isfinite(X),2);
        if nnz(good) < 10
            error('Not enough valid 0.25 training pixels for month index %d.', kk);
        end
        Xtrain = X(good,:);
        Ytrain = Y(good);
        if useTreeBagger
            RFmodel=TreeBagger(ntrees, Xtrain,Ytrain, 'Method','regression', ...
                'oobvarimp','on', 'surrogate', 'on', 'minleaf',leaf);
            y=predict(RFmodel,X);
            RFModel{kk,1}=RFmodel;
        else
            Xa=[ones(size(Xtrain,1),1),Xtrain];
            beta = Xa\Ytrain;
            y = Xa*beta;
            y = [ones(size(X,1),1),X]*beta;
            RFModel{kk,1}=beta;
        end
        ypred(kk,:)=y';
        Residual_region(kk,:)=(Y-y)';
        waitbar(kk/k,h)
    end
delete(h);
A=msgbox('RF Model train Done');
pause(2)
close(A)
% 妯″瀷闄嶅昂搴?h=waitbar(0,'RF Model downscaling>>>>>>');
for kk=1:k
    X=hngw_rf_matrix(handles.predictor001,handles.predictorStatic001,handles.predictorNames,kk);
    if useTreeBagger
        Y_pred(kk,:)=(predict(RFModel{kk,1},X))';
    else
        Xa=[ones(size(X,1),1),X];
        Y_pred(kk,:)=(Xa*RFModel{kk,1})';
    end
    waitbar(kk/k,h)
end
clear RFModel
end
%娈嬪樊鎻掑€间负0.01掳
for kk=1:k
    grid=zeros(1,numel(handles.Lon1));
    a=Residual_region(kk,:);
    grid(handles.rbi1)=a; 
    grid=reshape(grid,size(handles.Lon1));
    c=interp2(handles.Lon1,handles.Lat1,grid,handles.Lon2,handles.Lat2,'spline');
    c=reshape(c,1,numel(handles.Lon2));
    c=c(handles.rbi2);     
    Residual_region_001(kk,:)=c;
end
    CSR_Down=Y_pred+Residual_region_001;

% 缁樺浘   
% 璁＄畻GWSA搴忓垪
[jj,ii]=size(handles.Lon1);
lat=handles.lat1;
lg_msk=handles.mask1;
rbi=handles.rbi1;
[kk,~]=size(handles.gwsa);
gwsa_series = zeros(kk,1);
% create the weight 
grid_weight=zeros(jj,ii);
for j=1:jj
    for i=1:ii
        grid_weight(j,i)=cos(lat(j)*pi/180);
    end
end
grid_weight=grid_weight.*lg_msk;
% create the time series
for k=1:kk
    tmmp=zeros(1,jj*ii);
    tmmp(rbi)=handles.gwsa(k,:);
    tmmp=reshape(tmmp,jj,ii);
    grid_weight_new=grid_weight;
    tmmppp=tmmp.*grid_weight_new;
    tmmppp(logical(isnan(tmmppp)))=0;
    grid_sum=sum(sum(tmmppp));
    grid_weight_new(logical(isnan(tmmp)))=0;
    weight_sum=sum(sum(grid_weight_new));
    gwsa_series(k)=grid_sum/weight_sum;
end
% 璁＄畻CSR_down搴忓垪
[jj,ii]=size(handles.Lon2);
lat=handles.lat2;
lg_msk=handles.mask2;
rbi=handles.rbi2;
[kk,~]=size(CSR_Down);
down_series = zeros(kk,1);
% create the weight 
grid_weight=zeros(jj,ii);
for j=1:jj
    for i=1:ii
        grid_weight(j,i)=cos(lat(j)*pi/180);
    end
end
grid_weight=grid_weight.*lg_msk;
% create the time series
for k=1:kk
    tmmp=zeros(1,jj*ii);
    tmmp(rbi)=CSR_Down(k,:);
    tmmp=reshape(tmmp,jj,ii);
    grid_weight_new=grid_weight;
    tmmppp=tmmp.*grid_weight_new;
    tmmppp(logical(isnan(tmmppp)))=0;
    grid_sum=sum(sum(tmmppp));
    grid_weight_new(logical(isnan(tmmp)))=0;
    weight_sum=sum(sum(grid_weight_new));
    down_series(k)=grid_sum/weight_sum;
end
% 璁＄畻闄嶅昂搴rend
t=handles.t;
omega = 2*pi;
[epochs,i]=size(CSR_Down);
A = [];
A(:,1) = (ones(epochs,1));
A(:,2) = t';
A(:,3) = cos(omega*t'); 
A(:,4) = sin(omega*t');
A(:,5) = cos(omega*2*t'); 
A(:,6) = sin(omega*2*t');
NM = (A'*A)\A';
for ii=1:i
        time_series=CSR_Down(:,ii)';
        if sum(isnan(time_series))==0 
           x      = NM*time_series';
           Trend(1,ii)  = x(2);
        end
end
% trend 1D to 2D
[aa,bb]=size(handles.Lon2);
trend=zeros(1,aa*bb);
trend(handles.rbi2)=Trend;
trend_down=reshape(trend,aa,bb);
trend_down(trend_down==0)=nan;
% 淇濆瓨闄嶅昂搴︾粨鏋?    time_series=down_series;
    time=t;
    save(fullfile(output_location,output_file),'CSR_Down','-v7.3');
    save(fullfile(output_location,output_file),'-append','ypred');
    save(fullfile(output_location,output_file),'-append','Residual_region');
    save(fullfile(output_location,output_file),'-append','Residual_region_001');
    save(fullfile(output_location,output_file),'-append','Y_pred');
    save(fullfile(output_location,output_file),'-append','trend_down');
    save(fullfile(output_location,output_file),'-append','time_series');
    save(fullfile(output_location,output_file),'-append','time');
    save(fullfile(output_location,output_file),'-append','model_type');
    save(fullfile(output_location,output_file),'-append','residual_interp_method');
    save(fullfile(output_location,output_file),'-append','xgb_model_dir');
    save(fullfile(output_location,output_file),'-append','xgb_model_files');
    save(fullfile(output_location,output_file),'-append','xgb_lag_months');
    save(fullfile(output_location,output_file),'-append','xgb_corr_threshold');
    save(fullfile(output_location,output_file),'-append','xgb_feature_selection');
% 闄嶅昂搴︾粨鏋滅粯鍥?% 鏃堕棿搴忓垪鍥?axes(handles.axes1)
cla reset;
plot(t,gwsa_series,'DisplayName','GRACE-GWSA','LineWidth',1.5);
hold on
plot(t,down_series,'DisplayName','Downscaled-GWSA','LineWidth',2,'LineStyle','--');
h=legend('GRACE_GWSA','Downscaled-GWSA');
set(h, 'FontName', 'Times New Roman', 'FontSize', 10, 'FontWeight', 'normal');
ylabel({'Equivalent water Height(mm)'},'FontSize',10,...
    'FontName','Times New Roman');
xlabel({'Year'},'FontSize',9,'FontName','Times New Roman');
% 涓夌淮鍥?axes(handles.axes5)
cla reset;
surf(handles.lon2,handles.lat2,trend_down,'LineStyle','none');
% 浜岀淮鍥?axes(handles.axes7)
cla reset;
lon_mx=fix(handles.lon_max)+1;
lon_mi=fix(handles.lon_min);
lat_mx=fix(handles.lat_max)+1;
lat_mi=fix(handles.lat_min);
axesm('Mercator','frame','on','flinewidth',0.9,'MapParallels',10, ...
    'mlinelocation',10,'grid','on','maplatlim',[lat_mi,lat_mx], ...
    'maplonlim',[lon_mi,lon_mx],'MLineLocation',2, 'MLabelRound', 0, ...
    'MeridianLabel','on', 'PLineLocation',2,'PLabelRound', 0, ...
    'ParallelLabel','on','MLabelParallel','south')
axis off;
hold on;
geoimg = geoshow(handles.Lat2,handles.Lon2,trend_down, ...
         'DisplayType','texturemap') ;
geoimg.AlphaDataMapping = 'none'; 
geoimg.FaceAlpha = 'texturemap'; 
alpha(geoimg,double(~isnan(trend_down))) 
geoshow(handles.shp,'facecolor','none')
hh = colorbar;
set(hh, 'Position', [0.85 0.1 0.05 0.36]);
delete(h);
msgbox('XGBoost Model downscaled Done');
handles.CSR_Down=CSR_Down;
handles.down_t=time;
handles.down_series=time_series;
guidata(hObject, handles);
% --- Executes during object creation, after setting all properties.
function axes6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes6


% --- Executes during object creation, after setting all properties.
function axes7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes7

% --- Executes during object creation, after setting all properties.
function pushbutton9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Keep the legacy LST plot button consistent with the split predictor workflow.
plot_predictor_factor_Callback(hObject,eventdata,handles,'lst');
return;
% 缁樺浘
% 璁＄畻LST搴忓垪
[jj,ii]=size(handles.Lon1);
lat=handles.lat1;
lg_msk=handles.mask1;
rbi=handles.rbi1;
[kk,~]=size(handles.lst_day_025);
lst_day_series = zeros(kk,1);
lst_night_series = zeros(kk,1);
% create the weight 
grid_weight=zeros(jj,ii);
for j=1:jj
    for i=1:ii
        grid_weight(j,i)=cos(lat(j)*pi/180);
    end
end
grid_weight=grid_weight.*lg_msk;
% create the time series
for k=1:kk
    tmmp=zeros(1,jj*ii);
    tmmp(rbi)=handles.lst_day_025(k,:);
    tmmp=reshape(tmmp,jj,ii);
    grid_weight_new=grid_weight;
    tmmppp=tmmp.*grid_weight_new;
    tmmppp(logical(isnan(tmmppp)))=0;
    grid_sum=sum(sum(tmmppp));
    grid_weight_new(logical(isnan(tmmp)))=0;
    weight_sum=sum(sum(grid_weight_new));
    lst_day_series(k)=grid_sum/weight_sum;
end
for k=1:kk
    tmmp=zeros(1,jj*ii);
    tmmp(rbi)=handles.lst_night_025(k,:);
    tmmp=reshape(tmmp,jj,ii);
    grid_weight_new=grid_weight;
    tmmppp=tmmp.*grid_weight_new;
    tmmppp(logical(isnan(tmmppp)))=0;
    grid_sum=sum(sum(tmmppp));
    grid_weight_new(logical(isnan(tmmp)))=0;
    weight_sum=sum(sum(grid_weight_new));
    lst_night_series(k)=grid_sum/weight_sum;
end
axes(handles.axes1)
cla reset;
plot(handles.lst_time,lst_day_series*0.02-273.15,'DisplayName','lst day','LineWidth',1,...
    'Color',[0.850980392156863 0.325490196078431 0.0980392156862745]);
hold on;
plot(handles.lst_time,lst_night_series*0.02-273.15,'DisplayName','lst night','LineWidth',1,...
    'Color',[0.392156862745098 0.831372549019608 0.0745098039215686]);
h=legend('LST day','LST night');
set(h, 'FontName', 'Times New Roman', 'FontSize', 10, 'FontWeight', 'normal');
ylabel({'Lst (鈩?'},'FontSize',10,'FontName','Times New Roman');
xlabel({'Year'},'FontSize',9,'FontName','Times New Roman');

% --- Executes during object creation, after setting all properties.
function pushbutton10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% 缁樺浘
% 璁＄畻GLDAS搴忓垪
[jj,ii]=size(handles.Lon1);
lat=handles.lat1;
lg_msk=handles.mask1;
rbi=handles.rbi1;
[kk,~]=size(handles.gldas);
gldas_series = zeros(kk,1);
% create the weight 
grid_weight=zeros(jj,ii);
for j=1:jj
    for i=1:ii
        grid_weight(j,i)=cos(lat(j)*pi/180);
    end
end
grid_weight=grid_weight.*lg_msk;
% create the time series
for k=1:kk
    tmmp=zeros(1,jj*ii);
    tmmp(rbi)=handles.gldas(k,:);
    tmmp=reshape(tmmp,jj,ii);
    grid_weight_new=grid_weight;
    tmmppp=tmmp.*grid_weight_new;
    tmmppp(logical(isnan(tmmppp)))=0;
    grid_sum=sum(sum(tmmppp));
    grid_weight_new(logical(isnan(tmmp)))=0;
    weight_sum=sum(sum(grid_weight_new));
    gldas_series(k)=grid_sum/weight_sum;
end
axes(handles.axes1)
cla reset;
plot(handles.gldas_time,gldas_series,'DisplayName','gldas','LineWidth',1,...
    'Color',[0.850980392156863 0.325490196078431 0.0980392156862745]);
h=legend('GLDAS');
set(h, 'FontName', 'Times New Roman', 'FontSize', 10, 'FontWeight', 'normal');
ylabel({'GLDAS (mm)'},'FontSize',10,'FontName','Times New Roman');
xlabel({'Year'},'FontSize',9,'FontName','Times New Roman');
% --- Executes during object creation, after setting all properties.
function axes8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: place code in OpeningFcn to populate axes8
% --- Executes during object creation, after setting all properties.
function pushbutton11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% 缁樺浘
% 璁＄畻ERA5_land搴忓垪
[jj,ii]=size(handles.Lon1);
lat=handles.lat1;
lg_msk=handles.mask1;
rbi=handles.rbi1;
[kk,~]=size(handles.gldas);
e_series = zeros(kk,1);
pre_series = zeros(kk,1);
temp_series = zeros(kk,1);
% create the weight 
grid_weight=zeros(jj,ii);
for j=1:jj
    for i=1:ii
        grid_weight(j,i)=cos(lat(j)*pi/180);
    end
end
grid_weight=grid_weight.*lg_msk;
% create the time series
for k=1:kk
    tmmp=zeros(1,jj*ii);
    tmmp(rbi)=handles.e_025(k,:);
    tmmp=reshape(tmmp,jj,ii);
    grid_weight_new=grid_weight;
    tmmppp=tmmp.*grid_weight_new;
    tmmppp(logical(isnan(tmmppp)))=0;
    grid_sum=sum(sum(tmmppp));
    grid_weight_new(logical(isnan(tmmp)))=0;
    weight_sum=sum(sum(grid_weight_new));
    e_series(k)=grid_sum/weight_sum;
end
for k=1:kk
    tmmp=zeros(1,jj*ii);
    tmmp(rbi)=handles.pre_025(k,:);
    tmmp=reshape(tmmp,jj,ii);
    grid_weight_new=grid_weight;
    tmmppp=tmmp.*grid_weight_new;
    tmmppp(logical(isnan(tmmppp)))=0;
    grid_sum=sum(sum(tmmppp));
    grid_weight_new(logical(isnan(tmmp)))=0;
    weight_sum=sum(sum(grid_weight_new));
    pre_series(k)=grid_sum/weight_sum;
end
for k=1:kk
    tmmp=zeros(1,jj*ii);
    tmmp(rbi)=handles.temp_025(k,:);
    tmmp=reshape(tmmp,jj,ii);
    grid_weight_new=grid_weight;
    tmmppp=tmmp.*grid_weight_new;
    tmmppp(logical(isnan(tmmppp)))=0;
    grid_sum=sum(sum(tmmppp));
    grid_weight_new(logical(isnan(tmmp)))=0;
    weight_sum=sum(sum(grid_weight_new));
    temp_series(k)=grid_sum/weight_sum;
end
axes(handles.axes1)
cla reset;
yyaxis left
plot(handles.era5_time,-e_series*1000*30,'DisplayName','e','LineWidth',1,...
    'Color',[0.850980392156863 0.325490196078431 0.0980392156862745]);
hold on;
plot(handles.era5_time,pre_series*1000*30,'DisplayName','pre','LineWidth',1,...
    'Color',[0.392156862745098 0.831372549019608 0.0745098039215686]);
ylabel({'ET&Pre(mm)'},'FontSize',10,'FontName','Times New Roman');
hold on;
yyaxis right
plot(handles.era5_time,temp_series-273.15,'DisplayName','temp','LineWidth',1,...
    'Color',[0.00,0.45,0.74]);
ylabel({'Temp (鈩?'},'FontSize',10,'FontName','Times New Roman');
h=legend('ET','Pre','Temp');
set(h, 'FontName', 'Times New Roman', 'FontSize', 10, 'FontWeight', 'normal');
xlabel({'Year'},'FontSize',9,'FontName','Times New Roman');
% --- Executes during object creation, after setting all properties.
function axes9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes9
% --- Executes during object creation, after setting all properties.
function pushbutton12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% --- Executes on button press in pushbutton12.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% 骞叉棻鍒嗘瀽
[output_file,output_location] = uiputfile( ...
    '*.mat', ...
    'Save GDI data');
Down_grid=handles.CSR_Down;
down_t=handles.down_t;
down_series=handles.down_series;
a=handles.month;
[GDI_series] =DSI_series(down_series,a);
[GDI_grid] =DSI_grid(Down_grid,a);
% 璁＄畻GDI-trend
t=down_t;
omega = 2*pi;
[epochs,i]=size(GDI_grid);
A = [];
A(:,1) = (ones(epochs,1));
A(:,2) = t';
A(:,3) = cos(omega*t'); 
A(:,4) = sin(omega*t');
A(:,5) = cos(omega*2*t'); 
A(:,6) = sin(omega*2*t');
NM = (A'*A)\A';
for ii=1:i
        time_series=GDI_grid(:,ii)';
        if sum(isnan(time_series))==0 
           x      = NM*time_series';
           Trend(1,ii)  = x(2);
        end
end
% trend 1D to 2D
[aa,bb]=size(handles.Lon2);
trend=zeros(1,aa*bb);
trend(handles.rbi2)=Trend;
trend_GDI=reshape(trend,aa,bb);
trend_GDI(trend_GDI==0)=nan;
% 骞叉棻鍒嗘瀽缁樺浘
% 鏃堕棿搴忓垪鍥?axes(handles.axes1)
cla reset;
y1 = GDI_series; y1(y1<0)=0; 
y2 = GDI_series; y2(y2>0)=0; 
area(down_t,y1,'FaceColor','b','EdgeColor','r','FaceAlpha',0.6); 
hold on
area(down_t,y2,'FaceColor','r','EdgeColor','b','FaceAlpha',0.6);
h=legend('Wet','Drought');
set(h, 'FontName', 'Times New Roman', 'FontSize', 10, 'FontWeight', 'normal');
ylabel('GDI','FontSize',10,'FontName','Times New Roman');
xlabel('Year','FontSize',9,'FontName','Times New Roman');
% 浜岀淮銆佷笁缁村浘
% 涓夌淮鍥?axes(handles.axes8)
cla reset;
surf(handles.lon2,handles.lat2,trend_GDI,'LineStyle','none');
% 浜岀淮鍥?axes(handles.axes9)
cla reset;
lon_mx=fix(handles.lon_max)+1;
lon_mi=fix(handles.lon_min);
lat_mx=fix(handles.lat_max)+1;
lat_mi=fix(handles.lat_min);
axesm('Mercator','frame','on','flinewidth',0.9,'MapParallels',10, ...
    'mlinelocation',10,'grid','on','maplatlim',[lat_mi,lat_mx], ...
    'maplonlim',[lon_mi,lon_mx],'MLineLocation',2, 'MLabelRound', 0, ...
    'MeridianLabel','on', 'PLineLocation',2,'PLabelRound', 0, ...
    'ParallelLabel','on','MLabelParallel','south')
axis off;
hold on;
geoimg = geoshow(handles.Lat2,handles.Lon2,trend_GDI, ...
         'DisplayType','texturemap') ;
geoimg.AlphaDataMapping = 'none'; 
geoimg.FaceAlpha = 'texturemap'; 
alpha(geoimg,double(~isnan(trend_GDI))) 
geoshow(handles.shp,'facecolor','none')
hh = colorbar;
set(hh, 'Position', [0.85 0.1 0.05 0.36]);
save(fullfile(output_location,output_file),'GDI_series');
save(fullfile(output_location,output_file),'-append','GDI_grid');
save(fullfile(output_location,output_file),'-append','trend_GDI');
% --- Executes on button press in pushbutton14.
function pushbutton14_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close

function handles = add_new_predictor_controls(handles)
parent = handles.figure1;
set(parent,'Units','characters');
pos = get(parent,'Position');
pos(3) = 270;
pos(4) = 62;
set(parent,'Position',pos);
movegui(parent,'center');

oldBtn = findobj(parent,'Tag','pushbutton_readPredictors');
if ~isempty(oldBtn), delete(oldBtn); end
oldTxt = findobj(parent,'Tag','text_newPredictors');
if ~isempty(oldTxt), delete(oldTxt); end

if isfield(handles,'uipanel9') && ishghandle(handles.uipanel9)
    set(handles.uipanel9,'Title','棰勬祴鍥犲瓙鏁版嵁');
end
if isfield(handles,'pushbutton7') && ishghandle(handles.pushbutton7)
    set(handles.pushbutton7,'String','璇诲彇棰勬祴鍥犲瓙', ...
        'Units','characters', ...
        'Position',[2.2 2.45 15.7 2.4], ...
        'Callback',@(src,event) groundwater_downscaling_drought('read_predictors_Callback',src,event,guidata(src)));
end
if isfield(handles,'pushbutton11') && ishghandle(handles.pushbutton11)
    set(handles.pushbutton11,'Visible','off','Enable','off');
end

hngw_apply_modern_layout(handles);
if isfield(handles,'pushbutton8') && ishghandle(handles.pushbutton8)
    set(handles.pushbutton8,'String','XGBoost Downscaling', ...
        'FontWeight','bold','BackgroundColor',[0.70 0.84 1.00]);
end

parentPanel = handles.figure1;
if isfield(handles,'uipanel12') && ishghandle(handles.uipanel12)
    parentPanel = handles.uipanel12;
    set(parentPanel,'Title','Predictor data');
end

legacyTags = {'read_LST','pushbutton9','pushbutton7','pushbutton11','uipanel7','uipanel9'};
for iTag = 1:numel(legacyTags)
    hLegacy = findobj(handles.figure1,'Tag',legacyTags{iTag});
    if ~isempty(hLegacy)
        set(hLegacy,'Visible','off','Enable','off');
    end
end
oldControls = findobj(handles.figure1,'-regexp','Tag','^pushbutton_(read|plot)_factor_');
if ~isempty(oldControls)
    delete(oldControls);
end

specs = hngw_factor_specs();
for iSpec = 1:numel(specs)
    row = ceil(iSpec/2);
    col = mod(iSpec-1,2);
    y = 0.86 - (row-1)*0.16;
    x = 0.04 + col*0.48;
    readTag = ['pushbutton_read_factor_', specs(iSpec).factor];
    plotTag = ['pushbutton_plot_factor_', specs(iSpec).factor];
    handles.(readTag) = uicontrol('Parent',parentPanel, ...
        'Style','pushbutton','Units','normalized', ...
        'Position',[x y 0.27 0.105], ...
        'String',['Read ', specs(iSpec).label], ...
        'Tag',readTag,'FontSize',9, ...
        'BackgroundColor',[0.88 0.94 1.00], ...
        'Callback',specs(iSpec).readCallback);
    handles.(plotTag) = uicontrol('Parent',parentPanel, ...
        'Style','pushbutton','Units','normalized', ...
        'Position',[x+0.29 y 0.15 0.105], ...
        'String','Plot', ...
        'Tag',plotTag,'FontSize',9, ...
        'BackgroundColor',[0.93 0.96 0.90], ...
        'Callback',specs(iSpec).plotCallback);
end
guidata(handles.figure1,handles);

function read_predictors_Callback(hObject, eventdata, handles)
% The old all-in-one predictor reader has been removed. The current workflow
% reads temp/rhu/pres/pre/LST/ET/NDVI/DEM separately from the predictor panel.
warndlg('请在“预测因子数据”面板中分别点击各因子的读取按钮。','预测因子读取');

function hngw_apply_modern_layout(handles)
try
    if isfield(handles,'figure1') && ishghandle(handles.figure1)
        set(handles.figure1,'Units','characters','Color',[0.94 0.95 0.96]);
        pos = get(handles.figure1,'Position');
        pos(3) = 270;
        pos(4) = 62;
        set(handles.figure1,'Position',pos);
        movegui(handles.figure1,'center');
    end
    if isfield(handles,'text17') && ishghandle(handles.text17)
        set(handles.text17,'String','Henan Groundwater Downscaling Tool', ...
            'FontSize',16,'FontWeight','bold','ForegroundColor',[0.10 0.18 0.28], ...
            'Position',[78 58.5 112 2.2]);
    end
    if isfield(handles,'uipanel11') && ishghandle(handles.uipanel11)
        set(handles.uipanel11,'Position',[2 50.5 70 10],'Title','Time and resolution');
    end
    if isfield(handles,'uipanel2') && ishghandle(handles.uipanel2)
        set(handles.uipanel2,'Position',[2 32 70 17],'Title','GRACE gap filling');
    end
    if isfield(handles,'uipanel12') && ishghandle(handles.uipanel12)
        set(handles.uipanel12,'Position',[2 9.5 70 21],'Title','Predictor data');
    end
    if isfield(handles,'uipanel14') && ishghandle(handles.uipanel14)
        set(handles.uipanel14,'Position',[2 1 70 7.5],'Title','Model and drought');
    end
    if isfield(handles,'uipanel4') && ishghandle(handles.uipanel4)
        set(handles.uipanel4,'Position',[75 32 58 22],'Title','Original data');
    end
    if isfield(handles,'uipanel5') && ishghandle(handles.uipanel5)
        set(handles.uipanel5,'Position',[137 32 58 22],'Title','Downscaled result');
    end
    if isfield(handles,'uipanel10') && ishghandle(handles.uipanel10)
        set(handles.uipanel10,'Position',[199 32 62 22],'Title','Drought result');
    end
    if isfield(handles,'uipanel6') && ishghandle(handles.uipanel6)
        set(handles.uipanel6,'Position',[75 1 186 29],'Title','Series plot');
    end
    if isfield(handles,'axes1') && ishghandle(handles.axes1)
        set(handles.axes1,'Units','characters','Position',[9 3 168 22]);
    end
    if isfield(handles,'read_gldas') && ishghandle(handles.read_gldas)
        set(handles.read_gldas,'String','Read GLDAS','Units','normalized', ...
            'Position',[0.04 0.03 0.20 0.10],'BackgroundColor',[0.88 0.94 1.00]);
    end
    if isfield(handles,'pushbutton10') && ishghandle(handles.pushbutton10)
        set(handles.pushbutton10,'String','Plot GLDAS','Units','normalized', ...
            'Position',[0.25 0.03 0.18 0.10],'BackgroundColor',[0.93 0.96 0.90]);
    end
    if isfield(handles,'edit3') && ishghandle(handles.edit3), set(handles.edit3,'String','0.25'); end
    if isfield(handles,'edit4') && ishghandle(handles.edit4), set(handles.edit4,'String','0.01'); end
    if isfield(handles,'edit5') && ishghandle(handles.edit5), set(handles.edit5,'String','2002 4 2024 12'); end
catch
end

function specs = hngw_factor_specs()
factors = {'temp','rhu','pres','pre','lst','et','ndvi','dem'};
labels = {'Temp','RHU','Pres','Pre','LST','ET','NDVI','DEM'};
sourceDialogs = {'Pick temp0.01 folder','Pick rhu0.01 folder','Pick pres0.01 folder','Pick pre0.01 folder','Pick LST 1km folder','Pick ET 500m folder','Pick NDVI 1km folder','Pick DEM MAT data'};
saveDialogs = {'Save temp predictor data','Save rhu predictor data','Save pres predictor data','Save pre predictor data','Save LST predictor data','Save ET predictor data','Save NDVI predictor data','Save DEM predictor data'};
pickDialogs = {'Pick temp predictor data','Pick rhu predictor data','Pick pres predictor data','Pick pre predictor data','Pick LST predictor data','Pick ET predictor data','Pick NDVI predictor data','Pick DEM predictor data'};
for i = 1:numel(factors)
    specs(i).factor = factors{i}; %#ok<AGROW>
    specs(i).label = labels{i};
    specs(i).sourceDialog = sourceDialogs{i};
    specs(i).saveDialog = saveDialogs{i};
    specs(i).pickDialog = pickDialogs{i};
    factor = factors{i};
    specs(i).readCallback = @(src,event) groundwater_downscaling_drought(['read_',factor,'_Callback'],src,event,guidata(src));
    specs(i).plotCallback = @(src,event) groundwater_downscaling_drought(['plot_',factor,'_Callback'],src,event,guidata(src));
end

function read_temp_Callback(hObject, eventdata, handles)
read_predictor_factor_Callback(hObject,eventdata,handles,'temp');
function read_rhu_Callback(hObject, eventdata, handles)
read_predictor_factor_Callback(hObject,eventdata,handles,'rhu');
function read_pres_Callback(hObject, eventdata, handles)
read_predictor_factor_Callback(hObject,eventdata,handles,'pres');
function read_pre_Callback(hObject, eventdata, handles)
read_predictor_factor_Callback(hObject,eventdata,handles,'pre');
function read_lst_Callback(hObject, eventdata, handles)
read_predictor_factor_Callback(hObject,eventdata,handles,'lst');
function read_et_Callback(hObject, eventdata, handles)
read_predictor_factor_Callback(hObject,eventdata,handles,'et');
function read_ndvi_Callback(hObject, eventdata, handles)
read_predictor_factor_Callback(hObject,eventdata,handles,'ndvi');
function read_dem_Callback(hObject, eventdata, handles)
read_predictor_factor_Callback(hObject,eventdata,handles,'dem');

function plot_temp_Callback(hObject, eventdata, handles)
plot_predictor_factor_Callback(hObject,eventdata,handles,'temp');
function plot_rhu_Callback(hObject, eventdata, handles)
plot_predictor_factor_Callback(hObject,eventdata,handles,'rhu');
function plot_pres_Callback(hObject, eventdata, handles)
plot_predictor_factor_Callback(hObject,eventdata,handles,'pres');
function plot_pre_Callback(hObject, eventdata, handles)
plot_predictor_factor_Callback(hObject,eventdata,handles,'pre');
function plot_lst_Callback(hObject, eventdata, handles)
plot_predictor_factor_Callback(hObject,eventdata,handles,'lst');
function plot_et_Callback(hObject, eventdata, handles)
plot_predictor_factor_Callback(hObject,eventdata,handles,'et');
function plot_ndvi_Callback(hObject, eventdata, handles)
plot_predictor_factor_Callback(hObject,eventdata,handles,'ndvi');
function plot_dem_Callback(hObject, eventdata, handles)
plot_predictor_factor_Callback(hObject,eventdata,handles,'dem');

function read_predictor_factor_Callback(hObject, eventdata, handles, factor) %#ok<INUSD>
try
    spec = hngw_factor_spec(factor);
    if strcmp(factor,'dem')
        [file,location,file_index] = local_uigetfile(handles,'*.mat',spec.sourceDialog);
        if file_index ~= 1
            warndlg('DEM file was not selected.');
            return;
        end
        sourcePath = fullfile(location,file);
    else
        sourcePath = local_uigetdir(handles,spec.sourceDialog);
    end
    defaultFile = hngw_default_factor_output(handles,factor);
    [output_file,output_location] = local_uiputfile(handles,'*.mat',spec.saveDialog,defaultFile);
    if isequal(output_file,0)
        warndlg('Predictor output was not selected.');
        return;
    end
    outputPath = fullfile(output_location,output_file);
    predictor = hngw_read_predictor_factor(handles, factor, sourcePath, outputPath);
    if ~isfield(handles,'predictorFactors') || ~isstruct(handles.predictorFactors)
        handles.predictorFactors = struct();
    end
    handles.predictorFactors.(factor) = predictor;
    handles.(['predictor_file_',factor]) = outputPath;
    hngw_plot_factor_predictor(handles,predictor);
    guidata(hObject, handles);
    msgbox(sprintf('Read %s predictor Done\n%s', upper(factor), outputPath));
catch ME
    errordlg(getReport(ME,'basic','hyperlinks','off'),['Read ',upper(factor),' predictor failed']);
end

function plot_predictor_factor_Callback(hObject, eventdata, handles, factor) %#ok<INUSD>
try
    if isfield(handles,'predictorFactors') && isfield(handles.predictorFactors,factor)
        predictor = handles.predictorFactors.(factor);
    else
        spec = hngw_factor_spec(factor);
        [file,location,file_index] = local_uigetfile(handles,'*.mat',spec.pickDialog);
        if file_index ~= 1
            warndlg('Predictor file was not selected.');
            return;
        end
        predictor = hngw_load_factor_file(fullfile(location,file),factor);
        if ~isfield(handles,'predictorFactors') || ~isstruct(handles.predictorFactors)
            handles.predictorFactors = struct();
        end
        handles.predictorFactors.(factor) = predictor;
        guidata(hObject, handles);
    end
    hngw_plot_factor_predictor(handles,predictor);
catch ME
    errordlg(getReport(ME,'basic','hyperlinks','off'),['Plot ',upper(factor),' predictor failed']);
end

function spec = hngw_factor_spec(factor)
specs = hngw_factor_specs();
idx = find(strcmp({specs.factor},lower(factor)),1);
if isempty(idx)
    error('Unsupported predictor factor: %s', factor);
end
spec = specs(idx);

function defaultFile = hngw_default_factor_output(handles,factor)
trange = hngw_current_trange(handles);
name = sprintf('%s_%04d%02d_%04d%02d.mat',factor,trange(1),trange(2),trange(3),trange(4));
baseDir = fullfile('D:\claude matlab\xinshiyan','shuju','auto_output',hngw_factor_folder_name(factor));
if isfield(handles,'auto') && isstruct(handles.auto) && isfield(handles.auto,[factor,'_mat'])
    defaultFile = handles.auto.([factor,'_mat']);
else
    defaultFile = fullfile(baseDir,name);
end
folder = fileparts(defaultFile);
if ~exist(folder,'dir')
    mkdir(folder);
end

function folderName = hngw_factor_folder_name(factor)
switch lower(factor)
    case 'lst'
        folderName = 'CLST';
    case 'ndvi'
        folderName = 'CNDVI';
    case 'dem'
        folderName = 'CDEM';
    otherwise
        folderName = ['C',lower(factor)];
end

function trange = hngw_current_trange(handles)
if isfield(handles,'edit5') && ishghandle(handles.edit5)
    vals = sscanf(get(handles.edit5,'String'),'%f').';
else
    vals = [];
end
if numel(vals) == 4
    trange = vals;
elseif isfield(handles,'trange') && numel(handles.trange) == 4
    trange = handles.trange;
else
    trange = [2002 4 2024 12];
end

function [handles, ok] = hngw_pick_split_predictors(hObject, handles)
ok = false;
specs = hngw_factor_specs();
factors = struct();
for i = 1:numel(specs)
    [file, location, file_index] = local_uigetfile(handles,'*.mat',specs(i).pickDialog);
    if file_index ~= 1
        warndlg(['Missing ', specs(i).label, ' predictor file.']);
        return;
    end
    predictor = hngw_load_factor_file(fullfile(location,file),specs(i).factor);
    factors.(specs(i).factor) = predictor;
end

handles.predictor025 = struct();
handles.predictor001 = struct();
handles.predictorStatic025 = struct();
handles.predictorStatic001 = struct();
handles.predictorNames = {};
handles.predictorFactors = factors;
for i = 1:numel(specs)
    predictor = factors.(specs(i).factor);
    [handles, okOne] = hngw_merge_factor_predictor(handles,predictor);
    if ~okOne
        return;
    end
end
guidata(hObject,handles);
ok = true;

function [handles, ok] = hngw_merge_factor_predictor(handles,predictor)
ok = true;
for i = 1:numel(predictor.names)
    name = predictor.names{i};
    if isfield(predictor.data025,name) && isfield(predictor.data001,name)
        handles.predictor025.(name) = predictor.data025.(name);
        handles.predictor001.(name) = predictor.data001.(name);
        if isfield(predictor,'time') && ~isempty(predictor.time)
            handles.predictor_time = predictor.time;
        end
    elseif isfield(predictor.static025,name) && isfield(predictor.static001,name)
        handles.predictorStatic025.(name) = predictor.static025.(name);
        handles.predictorStatic001.(name) = predictor.static001.(name);
    else
        errordlg(['Predictor file is missing variable ', name, '.']);
        ok = false;
        return;
    end
    handles.predictorNames{end+1} = name; %#ok<AGROW>
end

function predictor = hngw_load_factor_file(fileName, expectedFactor)
S = load(fileName);
if isfield(S,'predictor')
    predictor = S.predictor;
else
    predictor = struct();
    predictor.factor = expectedFactor;
    if isfield(S,'predictorNames'), predictor.names = S.predictorNames; else, predictor.names = {}; end
    if isfield(S,'predictor025'), predictor.data025 = S.predictor025; else, predictor.data025 = struct(); end
    if isfield(S,'predictor001'), predictor.data001 = S.predictor001; else, predictor.data001 = struct(); end
    if isfield(S,'predictorStatic025'), predictor.static025 = S.predictorStatic025; else, predictor.static025 = struct(); end
    if isfield(S,'predictorStatic001'), predictor.static001 = S.predictorStatic001; else, predictor.static001 = struct(); end
    if isfield(S,'time'), predictor.time = S.time; else, predictor.time = []; end
    if isfield(S,'year'), predictor.year = S.year; end
    if isfield(S,'month'), predictor.month = S.month; end
end
if ~isfield(predictor,'data025'), predictor.data025 = struct(); end
if ~isfield(predictor,'data001'), predictor.data001 = struct(); end
if ~isfield(predictor,'static025'), predictor.static025 = struct(); end
if ~isfield(predictor,'static001'), predictor.static001 = struct(); end
if ~isfield(predictor,'names') || isempty(predictor.names)
    predictor.names = [fieldnames(predictor.data025); fieldnames(predictor.static025)]';
end
if nargin > 1 && ~isempty(expectedFactor) && isfield(predictor,'factor') && ...
        ~strcmpi(predictor.factor,expectedFactor)
    warning('Predictor factor label differs from selected file: expected %s, got %s.', expectedFactor, predictor.factor);
end

function hngw_plot_factor_predictor(handles,predictor)
axes(handles.axes1);
cla reset;
if ~isempty(fieldnames(predictor.data025))
    names = fieldnames(predictor.data025);
    hold on;
    for i = 1:numel(names)
        y = hngw_weighted_series(handles,predictor.data025.(names{i}));
        plot(predictor.time,y,'LineWidth',1.2,'DisplayName',names{i});
    end
    hold off;
    legend('show','Location','best');
    xlabel('Year','FontName','Times New Roman');
    ylabel('Regional mean','FontName','Times New Roman');
    title([upper(predictor.factor),' predictor'],'FontWeight','bold');
else
    name = predictor.names{1};
    grid = nan(size(handles.Lon1));
    grid(handles.rbi1) = double(predictor.static025.(name));
    imagesc(handles.lon1,handles.lat1,grid);
    set(gca,'YDir','normal');
    axis tight;
    colorbar;
    xlabel('Longitude','FontName','Times New Roman');
    ylabel('Latitude','FontName','Times New Roman');
    title([upper(predictor.factor),' predictor'],'FontWeight','bold');
end

function series = hngw_weighted_series(handles,data025)
[jj,ii]=size(handles.Lon1);
lat=handles.lat1;
lg_msk=handles.mask1;
rbi=handles.rbi1;
[kk,~]=size(data025);
series = zeros(kk,1);
grid_weight=zeros(jj,ii);
for j=1:jj
    grid_weight(j,:)=cos(lat(j)*pi/180);
end
grid_weight=grid_weight.*lg_msk;
for k=1:kk
    tmmp=zeros(1,jj*ii);
    tmmp(rbi)=double(data025(k,:));
    tmmp=reshape(tmmp,jj,ii);
    grid_weight_new=grid_weight;
    tmmppp=tmmp.*grid_weight_new;
    tmmppp(isnan(tmmppp))=0;
    grid_sum=sum(sum(tmmppp));
    grid_weight_new(isnan(tmmp))=0;
    weight_sum=sum(sum(grid_weight_new));
    series(k)=grid_sum/weight_sum;
end

function names = hngw_predictor_names(handles)
if isfield(handles,'predictorNames') && ~isempty(handles.predictorNames)
    names = handles.predictorNames;
else
    names = fieldnames(handles.predictor025)';
    if isfield(handles,'predictorStatic025')
        names = [names, fieldnames(handles.predictorStatic025)'];
    end
end

function k = hngw_prepare_predictors_for_rf(handles)
k_all = size(handles.gwsa,1);
dyn = fieldnames(handles.predictor025);
for i = 1:numel(dyn)
    k_all(end+1) = size(handles.predictor025.(dyn{i}),1); %#ok<AGROW>
end
dyn = fieldnames(handles.predictor001);
for i = 1:numel(dyn)
    k_all(end+1) = size(handles.predictor001.(dyn{i}),1); %#ok<AGROW>
end
k = min(k_all);
if k < 1
    error('Input data is empty after time alignment.');
end

function handles = hngw_trim_predictors(handles,k)
if size(handles.gwsa,1) ~= k
    handles.gwsa = handles.gwsa(1:k,:);
end
dyn = fieldnames(handles.predictor025);
for i = 1:numel(dyn)
    if size(handles.predictor025.(dyn{i}),1) ~= k
        handles.predictor025.(dyn{i}) = handles.predictor025.(dyn{i})(1:k,:);
    end
end
dyn = fieldnames(handles.predictor001);
for i = 1:numel(dyn)
    if size(handles.predictor001.(dyn{i}),1) ~= k
        handles.predictor001.(dyn{i}) = handles.predictor001.(dyn{i})(1:k,:);
    end
end

function ok = hngw_check_predictor_width(dynamicData, staticData, n)
ok = true;
dyn = fieldnames(dynamicData);
for i = 1:numel(dyn)
    ok = ok && size(dynamicData.(dyn{i}),2) == n;
end
if nargin > 1 && ~isempty(staticData)
    stat = fieldnames(staticData);
    for i = 1:numel(stat)
        ok = ok && numel(staticData.(stat{i})) == n;
    end
end

function X = hngw_rf_matrix(dynamicData, staticData, names, kk)
cols = cell(1,numel(names));
for i = 1:numel(names)
    name = names{i};
    if isfield(dynamicData,name)
        cols{i} = double(dynamicData.(name)(kk,:)');
    elseif isfield(staticData,name)
        cols{i} = double(staticData.(name)(:) );
    else
        error('Missing predictor variable: %s', name);
    end
end
X = [cols{:}];
for j = 1:size(X,2)
    col = X(:,j);
    med = median(col(isfinite(col)));
    if isempty(med) || isnan(med)
        med = 0;
    end
    col(~isfinite(col)) = med;
    X(:,j) = col;
end

function [X,featureNames,featureLags] = hngw_lagged_rf_matrix(dynamicData, staticData, names, kk, lagMonths)
cols = {};
featureNames = {};
featureLags = [];
for i = 1:numel(names)
    name = names{i};
    if isfield(dynamicData,name)
        for lag = 0:lagMonths
            t = max(1,kk-lag);
            cols{end+1} = double(dynamicData.(name)(t,:)'); %#ok<AGROW>
            featureNames{end+1} = sprintf('%s_lag%d',name,lag); %#ok<AGROW>
            featureLags(end+1) = lag; %#ok<AGROW>
        end
    elseif isfield(staticData,name)
        cols{end+1} = double(staticData.(name)(:) ); %#ok<AGROW>
        featureNames{end+1} = name; %#ok<AGROW>
        featureLags(end+1) = -1; %#ok<AGROW>
    else
        error('Missing predictor variable: %s', name);
    end
end
X = [cols{:}];
for j = 1:size(X,2)
    col = X(:,j);
    med = median(col(isfinite(col)));
    if isempty(med) || isnan(med)
        med = 0;
    end
    col(~isfinite(col)) = med;
    X(:,j) = col;
end

function [X025,X001,selectedNames,removedNames,selectedIndex] = hngw_remove_collinear_lag_features(X025All,X001All,featureNames,featureLags,threshold)
keep = true(1,size(X025All,2));
R = corrcoef(X025All,'Rows','pairwise');
R(~isfinite(R)) = 0;
for i = 1:size(R,1)-1
    if ~keep(i)
        continue;
    end
    for j = i+1:size(R,2)
        if ~keep(j)
            continue;
        end
        if abs(R(i,j)) > threshold
            drop = hngw_choose_collinear_feature_to_drop(i,j,featureLags);
            keep(drop) = false;
        end
    end
end
selectedIndex = find(keep);
removedIndex = find(~keep);
X025 = X025All(:,selectedIndex);
X001 = X001All(:,selectedIndex);
selectedNames = featureNames(selectedIndex);
removedNames = featureNames(removedIndex);

function drop = hngw_choose_collinear_feature_to_drop(i,j,featureLags)
lagI = featureLags(i);
lagJ = featureLags(j);
if lagI > 0 || lagJ > 0
    if lagI > lagJ
        drop = i;
    elseif lagJ > lagI
        drop = j;
    else
        drop = j;
    end
else
    drop = j;
end

function modelFile = hngw_xgb_model_file(modelDir,monthIndex,timeVector)
if nargin >= 3 && numel(timeVector) >= monthIndex && isfinite(timeVector(monthIndex))
    yy = floor(timeVector(monthIndex));
    mm = round((timeVector(monthIndex)-yy)*12 + 0.5);
    mm = max(1,min(12,mm));
    label = sprintf('%04d%02d',yy,mm);
else
    label = sprintf('month_%03d',monthIndex);
end
modelFile = fullfile(modelDir,['xgb_model_',label,'.json']);

function [y025,y001] = hngw_xgb_predict_month(X025,Y025,X001,monthIndex,tempDir,modelFile)
if ~exist(tempDir,'dir')
    mkdir(tempDir);
end
inputFile = [tempname(tempDir),'.mat'];
outputFile = [tempname(tempDir),'.mat'];
X025 = single(X025);
Y025 = single(Y025(:));
X001 = single(X001);
save(inputFile,'X025','Y025','X001','-v7');

scriptFile = fullfile(fileparts(mfilename('fullpath')),'hngw_xgboost_predict_month.py');
pythonExe = hngw_python_executable();
cmd = sprintf('"%s" "%s" --input "%s" --output "%s" --month-index %d', ...
    pythonExe, scriptFile, inputFile, outputFile, monthIndex);
if nargin >= 6 && ~isempty(modelFile)
    cmd = sprintf('%s --model-output "%s"',cmd,modelFile);
end
[status,cmdout] = system(cmd);
if status ~= 0
    hngw_delete_file(inputFile);
    hngw_delete_file(outputFile);
    error('XGBoost failed for month index %d:\n%s', monthIndex, cmdout);
end
result = load(outputFile,'ypred025','ypred001');
y025 = double(result.ypred025(:));
y001 = double(result.ypred001(:));
hngw_delete_file(inputFile);
hngw_delete_file(outputFile);

function pythonExe = hngw_python_executable()
candidates = {'D:\python\python.exe','python'};
for i = 1:numel(candidates)
    if exist(candidates{i},'file') || strcmp(candidates{i},'python')
        [status,~] = system(sprintf('"%s" --version', candidates{i}));
        if status == 0
            pythonExe = candidates{i};
            return;
        end
    end
end
error('Cannot find a usable Python executable for XGBoost.');

function hngw_delete_file(fileName)
if exist(fileName,'file')
    try
        delete(fileName);
    catch
    end
end

function [file,location,file_index] = local_uigetfile(handles,filterSpec,dialogTitle,varargin)
if isstruct(handles) && isfield(handles,'auto') && isstruct(handles.auto) && ...
        isfield(handles.auto,'enabled') && handles.auto.enabled
    [file,location,file_index] = auto_uigetfile(handles.auto,filterSpec,dialogTitle,varargin{:});
else
    [file,location,file_index] = uigetfile(filterSpec,dialogTitle,varargin{:});
end

function [output_file,output_location] = local_uiputfile(handles,filterSpec,dialogTitle,varargin)
if isstruct(handles) && isfield(handles,'auto') && isstruct(handles.auto) && ...
        isfield(handles.auto,'enabled') && handles.auto.enabled
    [output_file,output_location] = auto_uiputfile(handles.auto,filterSpec,dialogTitle);
else
    [output_file,output_location] = uiputfile(filterSpec,dialogTitle,varargin{:});
end

function folder = local_uigetdir(handles,dialogTitle)
if isstruct(handles) && isfield(handles,'auto') && isstruct(handles.auto) && ...
        isfield(handles.auto,'enabled') && handles.auto.enabled
    folder = auto_uigetdir(handles.auto,dialogTitle);
else
    folder = uigetdir(pwd,dialogTitle);
end
if isequal(folder,0)
    error('Folder selection cancelled: %s', dialogTitle);
end

function [file,location,file_index] = auto_uigetfile(cfg,~,dialogTitle,varargin)
multi = false;
if ~isempty(varargin)
    for i = 1:2:numel(varargin)
        if strcmpi(varargin{i},'MultiSelect') && strcmpi(varargin{i+1},'on')
            multi = true;
        end
    end
end

switch lower(strtrim(dialogTitle))
    case lower('Pick shp data')
        target = cfg.shp_file;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick CSR-Mascon data')
        target = cfg.mascon_nc;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick Mascon data')
        target = cfg.mascon_mat;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick gldas-nc data')
        d = dir(fullfile(cfg.gldas_dir,'*.nc4'));
        [~,idx] = sort({d.name});
        d = d(idx);
        file = {d.name};
        location = [cfg.gldas_dir,filesep];
        file_index = ~isempty(file);
    case lower('Pick LST data')
        if multi
            d = dir(fullfile(cfg.lst_dir,'*.hdf'));
            [~,idx] = sort({d.name});
            d = d(idx);
            file = {d.name};
            location = [cfg.lst_dir,filesep];
            file_index = ~isempty(file);
        else
            target = cfg.lst_mat;
            [folder,name,ext] = fileparts(target);
            file = [name,ext];
            location = [folder,filesep];
            file_index = 1;
        end
    case lower('Pick ERA5-Land data')
        if isfield(cfg,'pick_era5_mat') && cfg.pick_era5_mat
            target = cfg.era5_mat;
        else
            target = cfg.era5_nc;
        end
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick grid_fill data')
        target = cfg.fill_mat;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick gldas data')
        target = cfg.gldas_mat;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick predictor data')
        target = cfg.predictor_mat;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick temp predictor data')
        target = cfg.temp_mat;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick rhu predictor data')
        target = cfg.rhu_mat;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick pres predictor data')
        target = cfg.pres_mat;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick pre predictor data')
        target = cfg.pre_mat;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick LST predictor data')
        target = cfg.lst_mat;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick ET predictor data')
        target = cfg.et_mat;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick NDVI predictor data')
        target = cfg.ndvi_mat;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick DEM predictor data')
        target = cfg.dem_mat;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    case lower('Pick DEM MAT data')
        target = cfg.dem_file;
        [folder,name,ext] = fileparts(target);
        file = [name,ext];
        location = [folder,filesep];
        file_index = 1;
    otherwise
        file = 0;
        location = 0;
        file_index = 0;
end

if isempty(file_index) || file_index==0
    error('Auto file selection failed for dialog: %s', dialogTitle);
end

function folder = auto_uigetdir(cfg,dialogTitle)
switch lower(strtrim(dialogTitle))
    case lower('Pick temp0.01 folder')
        folder = cfg.temp_dir;
    case lower('Pick rhu0.01 folder')
        folder = cfg.rhu_dir;
    case lower('Pick pres0.01 folder')
        folder = cfg.pres_dir;
    case lower('Pick pre0.01 folder')
        folder = cfg.pre_dir;
    case lower('Pick LST 1km folder')
        folder = cfg.lst_dir;
    case lower('Pick ET 500m folder')
        folder = cfg.et_dir;
    case lower('Pick NDVI 1km folder')
        folder = cfg.ndvi_dir;
    otherwise
        error('Auto folder path is not configured for dialog: %s', dialogTitle);
end
if ~exist(folder,'dir')
    error('Auto folder does not exist: %s', folder);
end

function [output_file,output_location] = auto_uiputfile(cfg,~,dialogTitle)
switch lower(strtrim(dialogTitle))
    case lower('Save Mascon data')
        target = cfg.mascon_mat;
    case lower('Save grid-fill data')
        target = cfg.fill_mat;
    case lower('Save gldas data')
        target = cfg.gldas_mat;
    case lower('Save LST data')
        target = cfg.lst_mat;
    case lower('Save ERA5-Land data')
        target = cfg.era5_mat;
    case lower('Save predictor data')
        target = cfg.predictor_mat;
    case lower('Save temp predictor data')
        target = cfg.temp_mat;
    case lower('Save rhu predictor data')
        target = cfg.rhu_mat;
    case lower('Save pres predictor data')
        target = cfg.pres_mat;
    case lower('Save pre predictor data')
        target = cfg.pre_mat;
    case lower('Save LST predictor data')
        target = cfg.lst_mat;
    case lower('Save ET predictor data')
        target = cfg.et_mat;
    case lower('Save NDVI predictor data')
        target = cfg.ndvi_mat;
    case lower('Save DEM predictor data')
        target = cfg.dem_mat;
    case lower('Save CSR-Downscale data')
        target = cfg.rf_mat;
    case lower('Save GDI data')
        target = cfg.gdi_mat;
    otherwise
        error('Auto save path is not configured for dialog: %s', dialogTitle);
end
[folder,name,ext] = fileparts(target);
if isempty(ext)
    ext = '.mat';
end
if ~exist(folder,'dir')
    mkdir(folder);
end
output_file = [name,ext];
output_location = [folder,filesep];
