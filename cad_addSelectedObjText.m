

delete(findall(handles.figure1,'tag','objclick'))

st1 = '';
st2 = '';
st3 = '';
st4 = '';
st5 = '';

if ~isempty(handles.ObjSelect.joint)
    points = handles.ObjSelect.joint;
    labels = handles.fem.xy(points,1);
    pat1   = mat2str(labels);
    st1    = sprintf('%s\n',pat1);
end

if ~isempty(handles.ObjSelect.beam)
    tag   = handles.fem.elasticBeamColumn(handles.ObjSelect.beam,1);
    pat2  = mat2str(tag);
    st2   = sprintf('%s\n',pat2);
end

if ~isempty(handles.ObjSelect.tri31)
    tag  = handles.fem.tri31(handles.ObjSelect.tri31,1);
    pat3 = mat2str(tag);
    st3  = sprintf('%s\n',pat3);
end

if ~isempty(handles.ObjSelect.quad)
    tag  = handles.fem.quad(handles.ObjSelect.quad,1);
    pat4 = mat2str(tag);
    st4  = sprintf('%s\n',pat4);
end

if ~isempty(handles.ObjSelect.const)
    tag  = handles.ObjSelect.const;
    pat5 = mat2str(tag);
    st5  = sprintf('%s\n',pat5);
end



str ={'Selected joints',st1,'Selected beams',st2,'Selected tri31',st3,'Selected quad',st4,'Selected joint constraints',st5};

str = strrep(str,'[','');
str = strrep(str,']','');
str = strrep(str,';',' ');

uicontrol('parent',handles.figure1,...
    'Style','text',...
    'String',str,...
    'tag','objclick',...
    'fontsize',12,...
    'BackgroundColor','w',...
    'fontname','courier',...
    'Horizontalalignment','left',...
    'units','normalized',...
    'position',[0.04 0.12 0.25 0.8]);