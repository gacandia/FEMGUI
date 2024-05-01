
%% JOINT DISPLACEMENTS AND REACTIONS
handles.status = 1;
handles.def    = solve2D(handles.fem,handles.loads);
handles.frame  = solveFrames(handles.ax,handles.fem,handles.loads,handles.def);
handles.tri31  = solveTri31(handles.fem,handles.def);
handles.quad   = solveQuad(handles.fem,handles.def);
handles.def    = solveampD(handles.ax,handles.fem,handles.loads,handles.def,handles.frame);


%% update graphic objects
ax_title = findall(handles.ax,'tag','ax_title');
ax_title.ButtonDownFcn={@update_force,handles.frame,handles.tri31,handles.quad};

delete(findall(handles.ax,'tag','line_forces'))
if handles.fem.nElements(1)
    vert     = vertcat(handles.frame.p_moment);
    nvert    = numel(vert(:,1));
    nbeam    = handles.fem.nElements(1);
    nstation = nvert/nbeam;
    faces    = reshape(1:nvert,nstation,nbeam)';
    
    obj = patch('parent',handles.ax,...
        'vertices',vert,...
        'faces',faces,...
        'facecolor','r',...
        'facealpha',0.2,...
        'tag','line_forces',...
        'visible','on',...
        'edgecolor','none');
    cad_send2back(handles.ax,'line_forces')
end
function[]=update_force(hObject,~,frame,tri31,quad)

ax = hObject.Parent;
fig     = ax.Parent;
Toggle1 = findall(fig,'tag','ForceToggle');
if strcmp(Toggle1.State,'on')
    ch     = findall(ax,'tag','line_forces');
    title1 = findall(fig,'tag','gsv');
    switch title1.String{2}
        case 'Axial Force',    hObject.String = 'Shear Force';    ch.Vertices  = vertcat(frame.p_shear);   ch.FaceColor=[255 191 0]/255;
        case 'Shear Force',    hObject.String = 'Bending Moment'; ch.Vertices  = vertcat(frame.p_moment);  ch.FaceColor=[1 0 0];
        case 'Bending Moment', hObject.String = 'Axial Force';    ch.Vertices  = vertcat(frame.p_axial);   ch.FaceColor=[0 153 102]/255;
        otherwise
            hObject.String = 'Bending Moment'; ch.Vertices  = vertcat(frame.p_moment);  ch.FaceColor=[1 0 0];
    end
    title1.String{2} = hObject.String;
end

Toggle2 = findall(fig,'tag','AreaStressToggle');
if strcmp(Toggle2.State,'on')
    if ~isempty(tri31)
        ch  = findall(ax,'tag','tri31');
        ch.FaceColor = 'interp';
        ch.FaceAlpha=0.85;
        title2=findall(fig,'tag','gsv');
        
        StressSmooth=findall(fig,'tag','StressSmoothMenu');
        
        switch [title2.String{3},' ',StressSmooth.Checked]
            case 'sigma xx on'  , hObject.String = 'sigma yy';ch.CData=tri31.syy_avg';
            case 'sigma yy on'  , hObject.String =   'tau xy';ch.CData=tri31.sxy_avg';
            case 'tau xy on'    , hObject.String = 'sigma xx';ch.CData=tri31.sxx_avg';
            case 'sigma xx off' , hObject.String = 'sigma yy';ch.CData=tri31.syy';
            case 'sigma yy off' , hObject.String =   'tau xy';ch.CData=tri31.sxy';
            case 'tau xy off'   , hObject.String = 'sigma xx';ch.CData=tri31.sxx';
        end
    end
    
    if ~isempty(quad)
        ch  = findall(ax,'tag','quad');
        ch.FaceColor = 'interp';
        ch.FaceAlpha=0.85;
        title2=findall(fig,'tag','gsv');
        
        StressSmooth=findall(fig,'tag','StressSmoothMenu');
        
        switch [title2.String{3},' ',StressSmooth.Checked]
            case 'sigma xx on'  , hObject.String = 'sigma yy';ch.CData=quad.syy_avg';
            case 'sigma yy on'  , hObject.String =   'tau xy';ch.CData=quad.sxy_avg';
            case 'tau xy on'    , hObject.String = 'sigma xx';ch.CData=quad.sxx_avg';
            case 'sigma xx off' , hObject.String = 'sigma yy';ch.CData=quad.syy';
            case 'sigma yy off' , hObject.String =   'tau xy';ch.CData=quad.sxy';
            case 'tau xy off'   , hObject.String = 'sigma xx';ch.CData=quad.sxx';
        end
    end
    
    title2.String{3}=hObject.String;
end
end

