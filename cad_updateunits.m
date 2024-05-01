
LEN = [10, 1, 1/100, 10, 1, 1/100, 10, 1, 1/100, 50/127, 25/762]';
FOR = [1, 1, 1, 196133/20000000, 196133/20000000, 196133/20000000, 50000/45359237, 50000/45359237, 50000/45359237, 100000000/45359237, 100000000/45359237]';
ARE = LEN.^2;
VOL = LEN.^3;

MOM     = FOR.*LEN;
FOR_LEN = FOR./LEN;
FOR_ARE = FOR./ARE;
FOR_VOL = FOR./VOL;
FORTARE = FOR.*ARE;

cur_un = handles.sys.Units;
new_un = hObject.Value;

if new_un==12
    new_un=cur_un;
    strFOR = '';
    strLEN = '';
else
    strs = horzcat(regexp(handles.units.String{new_un},', ','split'));
    strFOR = strs{1};
    strLEN = strs{2};
end

% CONVERSION FACTORS
a_LEN     = LEN(new_un)     / LEN(cur_un);
a_FOR     = FOR(new_un)     / FOR(cur_un);
a_MOM     = MOM(new_un)     / MOM(cur_un); % moment
a_FOR_LEN = FOR_LEN(new_un) / FOR_LEN(cur_un); % force per unit length
a_FOR_ARE = FOR_ARE(new_un) / FOR_ARE(cur_un); % force per unit length
a_FOR_VOL = FOR_VOL(new_un) / FOR_VOL(cur_un); % force per unit length
a_FORTARE = FORTARE(new_un) / FORTARE(cur_un); % force times length squared

%% SYS UPDATE
handles.sys.Units=new_un;
handles.sys. XLim=a_LEN*handles.sys. XLim;
handles.sys. YLim=a_LEN*handles.sys. YLim;
handles.sys.XTick=a_LEN*handles.sys.XTick;
handles.sys.YTick=a_LEN*handles.sys.YTick;

%% FEM UPDATE
handles.fem.xy(:,2:3) = a_LEN * handles.fem.xy(:,2:3);

% contraints (pending)
% This applies when a X or Y DOF is slave to a rotational DOF 
% (The amplification factor of the rotational DOF is in units of length)
for i=1:numel(handles.fem.constraints)
    con_i = handles.fem.constraints(i);
    if strcmp(con_i.type,'jointcons') && any(con_i.slave(2)==[1 2])
        b = find(con_i.master(:,1)==3);
        con_i.master(b,3)=con_i.master(b,3)*a_LEN;
    end
end

% materials
for i=1:numel(handles.fem.material)
    switch handles.fem.material(i).type
        case 1 % elasticIsotropic
            handles.fem.material(i).values=handles.fem.material(i).values.*[a_FOR_ARE 1 a_FOR_VOL];
    end
end

% section
for i=1:numel(handles.fem.section)
    handles.fem.section(i).values=handles.fem.section(i).values.*[a_LEN^2 a_LEN^4 a_LEN^4];
    handles.fem.section(i).height=handles.fem.section(i).height*a_LEN;
end

if exist('tempsect.mat','file')==2
    load tempsect vsect
    for i=1:numel(vsect)
        vsect(i).values=vsect(i).values.*[a_LEN^2 a_LEN^4 a_LEN^4];
        vsect(i).height=vsect(i).height*a_LEN;
    end
    save tempsect vsect
end

% area elements
if handles.fem.nElements(2)>0
    handles.fem.tri31(:,5)=handles.fem.tri31(:,5)*a_LEN;
end

if handles.fem.nElements(3)>0
    handles.fem.quad(:,6)=handles.fem.quad(:,6)*a_LEN;
end

%% LOADS
if height(handles.loads.joint)>0
    handles.loads.joint(:,2:4)= handles.loads.joint(:,2:4).*[a_FOR a_FOR a_MOM];
end

if height(handles.loads.jointdisp)>0
    handles.loads.jointdisp(:,2:3) = handles.loads.jointdisp(:,2:3)*a_LEN;
end

for i=1:numel(handles.loads.eleload)
    if  handles.loads.eleload(i).loadtype==1 % continuous load
        handles.loads.eleload(i).values=handles.loads.eleload(i).values*a_FOR_LEN;
    else % discrete load
        handles.loads.eleload(i).values=handles.loads.eleload(i).values*a_FOR_VOL;
    end
end

%% ASSIGN PANNELS
hp=findobj(handles.figure1,'tag','uipanel');
if ~isempty(hp)
    ch  = findobj(hp,'tag','uicontrol');
    switch hp.Title
        case 'Joint loads'
            val1 = str2double(ch(1).String)*a_FOR;
            val2 = str2double(ch(2).String)*a_FOR;
            val3 = str2double(ch(3).String)*a_MOM;
            ch(1).String = sprintf('%g',val1);
            ch(2).String = sprintf('%g',val2);
            ch(3).String = sprintf('%g',val3);
            
            ch(4).String = cad_getUnitSt(handles.units,'force','FX (%s)');
            ch(5).String = cad_getUnitSt(handles.units,'force','FY (%s)');
            ch(6).String = cad_getUnitSt(handles.units,'moment','M (%s)');
            
        case 'Line loads'
            val3 = str2double(ch(3).String)*a_LEN;
            val4 = str2double(ch(4).String)*a_FOR_LEN;
            val5 = str2double(ch(5).String)*a_FOR_LEN;
            ch(3).String = sprintf('%g',val3);
            ch(4).String = sprintf('%g',val4);
            ch(5).String = sprintf('%g',val5);
            
            val9  = ch(9).String; ch(9).String  = cad_getUnitSt(handles.units,'force/length',[val9(1:2),' (%s)']);
            val10 = ch(10).String;ch(10).String = cad_getUnitSt(handles.units,'force/length',[val10(1:2),' (%s)']);
            
        case 'Area loads'
            val1 = str2double(ch(1).String)*a_FOR_VOL;
            val2 = str2double(ch(2).String)*a_FOR_VOL;
            ch(1).String = sprintf('%g',val1);
            ch(2).String = sprintf('%g',val2);     
            
            ch(3).String = cad_getUnitSt(handles.units,'force/volume','qx (%s)');
            ch(4).String = cad_getUnitSt(handles.units,'force/volume','qy (%s)');
            
        case 'Area section'
            val3 = str2double(ch(3).String)*a_LEN;
            ch(3).String = sprintf('%g',val3);
            
        case 'Section parameters'
            val3 = str2double(ch(3).String)*a_LEN^2;
            val4 = str2double(ch(4).String)*a_LEN^4;
            val5 = str2double(ch(5).String)*a_LEN^4;
            ch(3).String = sprintf('%g',val3);
            ch(4).String = sprintf('%g',val4);
            ch(5).String = sprintf('%g',val5);
            
            ch(7).String = cad_getUnitSt(handles.units,'length2','Area (%s)');
            ch(8).String = cad_getUnitSt(handles.units,'length3','Ixx (%s)');
            ch(9).String = cad_getUnitSt(handles.units,'length4','Iyy (%s)');            
    end
end

