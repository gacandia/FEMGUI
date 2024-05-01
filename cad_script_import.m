

db=dbstack;

if any(contains({db.name}','cad_addline'))
    return
end

if ~strcmp(db(2).name,'LockToolbar_ClickedCallback')
    [handles.sys,handles.fem,handles.loads]=cad_import(handles.fname);
end
[FILEPATH,NAME,EXT] = fileparts(handles.fname);

handles.figure1.Name     = sprintf('%s%s : FEMGUI',NAME,EXT);
handles.ObjSelect = cad_CreateObj(7);
guidata(hObject,handles)

delete(findobj(handles.figure1,...
    '-or','tag','uipanel',...
    '-or','tag','uicontrol',...
    '-or','tag','objclick'))
cad_restoreGraphics(handles.ax,handles.sys,handles.fem,handles.loads)

set(handles.Enable,'Visible','off')
set(handles.Disable,'Visible','on')

handles.status    = 0;
handles.ver       = struct('sys',[],'fem',[],'loads',[]);
handles.ver.sys   = handles.sys;
handles.ver.fem   = handles.fem;
handles.ver.loads = handles.loads;

handles.currentver = 1;
handles.LockToolbar.CData=handles.Lock.Open;
handles.figure1.Pointer='arrow';
guidata(hObject,handles)

handles.UndoTool.Visible  = 'off';
handles.RedoTool.Visible  = 'off';
handles.DefToggle.State   = 'off';
handles.ForceToggle.State = 'off';
handles.AreaStressToggle.State='off';
handles.AssignButton.Visible='off';
handles.CancelButton.Visible='off';

handles.units.Value  = handles.sys.Units;

% T=findall(handles.ax,'tag','ax_title');T.Visible='off';
handles.title1.String='Bending Moment';
handles.title2.String='sigma xx';

