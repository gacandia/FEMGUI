
handles.fem.nElements(1) = 0;
handles.fem.nElements(2) = 0;
handles.fem.nElements(3) = 0;

if isfield(handles.fem,'elasticBeamColumn')
    handles.fem.nElements(1) = height(handles.fem.elasticBeamColumn);
    if handles.fem.nElements(1)==0
        handles.fem = rmfield(handles.fem,'elasticBeamColumn');
    end
end
if isfield(handles.fem,'tri31')
    handles.fem.nElements(2)  = height(handles.fem.tri31);
    if handles.fem.nElements(2)==0
        handles.fem = rmfield(handles.fem,'tri31');
    end    
end
if isfield(handles.fem,'quad')
    handles.fem.nElements(3)  = height(handles.fem.quad);
    if handles.fem.nElements(3)==0
        handles.fem = rmfield(handles.fem,'quad');
    end    
end

dbcallback = db(1).name;

switch dbcallback
    case {'UndoTool_ClickedCallback','UndoMenu_Callback'}
        N = handles.currentver-1;
        handles.sys   = handles.ver(N).sys;
        handles.fem   = handles.ver(N).fem;
        handles.loads = handles.ver(N).loads;
        
        handles.currentver=N;
        cad_restoreGraphics(handles.ax,handles.sys,handles.fem,handles.loads)
        
        if N==1
            handles.UndoTool.Visible='off';
            handles.UndoMenu.Enable='off';
        end
        handles.RedoTool.Visible='on';
        handles.RedoMenu.Enable='on';
        
    case {'RedoTool_ClickedCallback','RedoMenu_Callback'}
        N = handles.currentver+1;
        handles.sys   = handles.ver(N).sys;
        handles.fem   = handles.ver(N).fem;
        handles.loads = handles.ver(N).loads;
        handles.currentver=N;
        cad_restoreGraphics(handles.ax,handles.sys,handles.fem,handles.loads)
        
        if N==numel(handles.ver)
            handles.RedoTool.Visible='off';
            handles.UndoMenu.Enable='off';
        end
        handles.UndoTool.Visible='on';
        handles.UndoMenu.Enable='on';
        
    otherwise
        N = handles.currentver+1;
        handles.ver(N)=struct('sys',handles.sys,'fem',handles.fem,'loads',handles.loads);
        handles.currentver=N;
        
        handles.UndoTool.Visible='on';
        handles.RedoTool.Visible='off';
        
        handles.UndoMenu.Enable='on';
        handles.RedoMenu.Enable='off';        
        handles.ver(N+1:end)=[];
        
        % add text elements
        cad_restoreGraphics(handles.ax,handles.sys,handles.fem,handles.loads)
        handles.ObjSelect.joint  = zeros(0,1);
        handles.ObjSelect.beam   = zeros(0,1);
        handles.ObjSelect.tri31  = zeros(0,1);
        handles.ObjSelect.quad   = zeros(0,1);
end

[FILEPATH,NAME,EXT]  = fileparts(handles.fname);
handles.figure1.Name = sprintf('*%s%s : FEMGUI',NAME,EXT);


delete(findall(handles.ax,'tag','ax_title'))
title(handles.ax,'Empty','visible','off','tag','ax_title');

