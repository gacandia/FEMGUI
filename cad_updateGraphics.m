
fig = handles.figure1;
ax  = handles.ax;

%% prepdata
joint    = findall(ax,'tag','joint');
jointID  = flipud(findall(ax,'tag','jointID'));
beamID   = flipud(findall(ax,'tag','beamID'));
triID    = flipud(findall(ax,'tag','triID'));
quadID   = flipud(findall(ax,'tag','quadID'));

line        = findall(ax,'tag','elasticBeamColumn','type','patch');
linehinges  = findall(ax,'tag','elasticBeamColumn','type','line');
beamprofile = findall(ax,'tag','beamprofile');
tri31    = findall(ax,'tag','tri31');
quad     = findall(ax,'tag','quad');
ax_title = findall(ax,'tag','ax_title');
line_for = findall(ax,'tag','line_forces');

fix         = findall(ax,'tag','fix');
constraints = findall(ax,'tag','constraints');
fixdata  = handles.fem.restraints;

switch handles.DefToggle.State
    case 'on'  ,xy  = handles.def.xyd(:,2:3);
    case 'off' ,xy  = handles.fem.xy(:,2:3);
end

%% displaced nodes
joint.Vertices =xy;
joint.ButtonDownFcn={@objclick,handles.fem,handles.loads};
for i=1:numel(jointID)
    jointID(i).Position(1:2) =xy(i,:);
end
[fix.XData,fix.YData] = getsupportnodes2(handles.ax,handles.fem.restraints,xy);

Nc =numel(handles.fem.constraints);
for i=1:Nc
    j=Nc+1-i;
    cons = handles.fem.constraints(i);
    switch cons.type
        case 'equaldof',       b = [cons.master(:,1);cons.slave(:,1)];
        case 'rigidbody',      b = [cons.master(:,1);cons.slave(:,1)];
        case 'jointcons',      b = [cons.master(:,1);cons.slave(:,1)];
        case 'edgeconstraint', b = cons.slave;
    end
    b = unique(b,'stable');
    constraints(j).XData = xy(b,1);
    constraints(j).YData = xy(b,2);
end

%% deformed tri31
if ~isempty(tri31)
    t = handles.fem.tri31(:,2:4);
    X = [xy(t(:,1),1),xy(t(:,2),1),xy(t(:,3),1)]';
    Y = [xy(t(:,1),2),xy(t(:,2),2),xy(t(:,3),2)]';
    tri31.Vertices  =[X(:),Y(:)];
    tri31.ButtonDownFcn={@objclick,handles.fem,handles.loads};
    switch handles.AreaStressToggle.State
        case 'off'
            tri31.FaceColor = [0.5 0.5 0.9];
            tri31.FaceAlpha=0.1;
        case 'on'
            tri31.FaceColor = 'interp';
            switch [handles.title2.String,' ',handles.StressSmoothMenu.Checked]
                case 'sigma xx on'  ,tri31.CData=handles.tri31.sxx_avg';
                case 'sigma yy on'  ,tri31.CData=handles.tri31.syy_avg';
                case 'tau xy on'    ,tri31.CData=handles.tri31.sxy_avg';
                case 'sigma xx off' ,tri31.CData=handles.tri31.sxx';
                case 'sigma yy off' ,tri31.CData=handles.tri31.syy';
                case 'tau xy off'   ,tri31.CData=handles.tri31.sxy';
            end
            tri31.FaceAlpha=0.85;
    end
end

%% deformed quad
if ~isempty(quad)
    t = handles.fem.quad(:,2:5);
    X = [xy(t(:,1),1),xy(t(:,2),1),xy(t(:,3),1),xy(t(:,4),1)]';
    Y = [xy(t(:,1),2),xy(t(:,2),2),xy(t(:,3),2),xy(t(:,4),2)]';
    quad.Vertices  =[X(:),Y(:)];
    quad.ButtonDownFcn={@objclick,handles.fem,handles.loads};
    switch handles.AreaStressToggle.State
        case 'off'
            quad.FaceColor = [0.5 0.5 0.9];
            quad.FaceAlpha=0.1;
        case 'on'
            quad.FaceColor = 'interp';
            switch [handles.title2.String,' ',handles.StressSmoothMenu.Checked]
                case 'sigma xx on'  ,quad.CData=handles.quad.sxx_avg';
                case 'sigma yy on'  ,quad.CData=handles.quad.syy_avg';
                case 'tau xy on'    ,quad.CData=handles.quad.sxy_avg';
                case 'sigma xx off' ,quad.CData=handles.quad.sxx';
                case 'sigma yy off' ,quad.CData=handles.quad.syy';
                case 'tau xy off'   ,quad.CData=handles.quad.sxy';
            end
            quad.FaceAlpha=0.85;
    end
end

%% deformed lines
if ~isempty(line)
    line.ButtonDownFcn={@objclick,handles.fem,handles.loads};
    switch handles.DefToggle.State
        case 'off'
            line.Vertices = handles.fem.xy(:,2:3);
            line.Faces    = handles.fem.elasticBeamColumn(:,2:3);
            
            if ~isempty(linehinges)
                hingedElements= find(any(handles.fem.elasticBeamColumn(:,5:6),2));
                hingeI  = handles.fem.elasticBeamColumn(hingedElements,5);
                hingeJ  = handles.fem.elasticBeamColumn(hingedElements,6);
                Nhinge  = numel(hingedElements);
                xyhinge = NaN(2*Nhinge,2);
                
                for i = 1:Nhinge
                    I    = hingedElements(i);
                    rI   = handles.frame(I).rI;
                    rJ   = handles.frame(I).rJ;
                    alfa = min((diff(ax.XLim)/60)/norm(rJ-rI),0.05);
                    beta = 1-alfa;
                    if hingeI(i),xyhinge(2*i-1,:)=rI+alfa*(rJ-rI);end
                    if hingeJ(i),xyhinge(2*i  ,:)=rI+beta*(rJ-rI);end
                end
                linehinges.XData=xyhinge(:,1);
                linehinges.YData=xyhinge(:,2);
            end
            
            nbeam = handles.fem.nElements(1);
            xyprofile = NaN(6*nbeam,2);
            boxx = [0 -1/2;1 -1/2;1 1/2;0 1/2;0 -1/2];
            for i=1:nbeam
                rI  = handles.fem.xy(handles.fem.elasticBeamColumn(i,2),2:3);
                rJ  = handles.fem.xy(handles.fem.elasticBeamColumn(i,3),2:3);
                li  = norm(rJ-rI);
                wi  = handles.fem.section(handles.fem.elasticBeamColumn(i,4)).height;
                ang = atan2(rJ(2)-rI(2),rJ(1)-rI(1));
                box_i=rI+(boxx.*[li,wi])*[cos(ang),sin(ang);-sin(ang),cos(ang)];
                JND = (1:5)+6*(i-1);
                xyprofile(JND,:)=box_i;
            end
            beamprofile.XData=xyprofile(:,1);
            beamprofile.YData=xyprofile(:,2);
            
            
        case 'on'
            line.Vertices = handles.def.xyl;
            line.Faces    = 1:height(handles.def.xyl);
            if ~isempty(linehinges)
                hingedElements= find(any(handles.fem.elasticBeamColumn(:,5:6),2));
                hingeI  = handles.fem.elasticBeamColumn(hingedElements,5);
                hingeJ  = handles.fem.elasticBeamColumn(hingedElements,6);
                Nhinge  = numel(hingedElements);
                xyhinge = NaN(2*Nhinge,2);
                IND  = ~isnan(handles.def.xyl(:,1));
                JND  = cumsum(isnan(handles.def.xyl(:,1)))+1;
                
                for i = 1:Nhinge
                    I    = hingedElements(i);
                    rI   = handles.frame(I).rI;
                    rJ   = handles.frame(I).rJ;
                    alfa = min((diff(ax.XLim)/60)/norm(rJ-rI),0.05);
                    beta = 1-alfa;
                    x    = handles.frame(I).add;
                    KND  = and(JND==I,IND);
                    xyl  = handles.def.xyl(KND,:);
                    if hingeI(i),xyhinge(2*i-1,:)=interp1(x,xyl,alfa,'linear');end
                    if hingeJ(i),xyhinge(2*i  ,:)=interp1(x,xyl,beta,'linear');end
                end
                linehinges.XData=xyhinge(:,1);
                linehinges.YData=xyhinge(:,2);
            end
            
            nbeam = handles.fem.nElements(1);
            xyprofile = NaN(0,2);
            ampD = handles.def.ampD;
            for i=1:nbeam
                rI   = handles.frame(i).rI;
                rJ   = handles.frame(i).rJ;
                h    = handles.fem.section(handles.fem.elasticBeamColumn(i,4)).height;
                nbox = height(handles.frame(i).summary);
                x    = handles.frame(i).summary(:,1);
                u    = handles.frame(i).summary(:,2)*ampD;
                v    = handles.frame(i).summary(:,3)*ampD;
                th   = handles.frame(i).summary(:,7)*ampD;
                p1   = [x+u+h/2*th,v-h/2];
                p2   = flipud([x+u-h/2*th,v+h/2]);
                box  = [p1;p2;p1(1,:);NaN(1,2)];
                
                ang = atan2(rJ(2)-rI(2),rJ(1)-rI(1));
                box_i=rI+(box)*[cos(ang),sin(ang);-sin(ang),cos(ang)];
                xyprofile=[xyprofile;box_i];
            end
            beamprofile.XData=xyprofile(:,1);
            beamprofile.YData=xyprofile(:,2);
            
            
    end
    
    
end

%% line forces
set(line_for,'visible','off');
ax_title.Visible='off';

if strcmp(handles.ForceToggle.State,'on')
    set(line_for,'visible','on');
    ax_title.Visible='on';
    ax_title.String =handles.title1.String;
end

if strcmp(handles.AreaStressToggle.State,'on')
    ax_title.Visible='on';
    ax_title.String =handles.title2.String;
end

guidata(hObject,handles)

%% update position of element ID
if ~isempty(beamID)
    connL= handles.fem.elasticBeamColumn(:,2:3);
    cg = (xy(connL(:,1),:)+xy(connL(:,2),:))/2;
    for i=1:numel(beamID)
        beamID(i).Position(1:2) =cg(i,:);
    end
end

if ~isempty(triID)
    conn = handles.fem.tri31(:,2:4);
    cg = (xy(conn(:,1),:)+xy(conn(:,2),:)+xy(conn(:,3),:))/3;
    for i=1:numel(triID)
        triID(i).Position(1:2)=cg(i,:);
    end
end

if ~isempty(quadID)
    conn = handles.fem.quad(:,2:5);
    cg = (xy(conn(:,1),:)+xy(conn(:,2),:)+xy(conn(:,3),:)+xy(conn(:,4),:))/4;
    for i=1:numel(quadID)
        quadID(i).Position(1:2)=cg(i,:);
    end
end


%% update buttondown function to display results
if handles.status
    obj = findobj(handles.ax,...
        '-or','tag','joint',...
        '-or','tag','elasticBeamColumn',...
        '-or','tag','tri31',...
        '-or','tag','quad');
    set(obj,'ButtonDownFcn',{@objclick,handles.fem,handles.loads,handles.def,handles.frame,handles.tri31,handles.quad})
else
    set(obj,'ButtonDownFcn',{@objclick,handles.fem,handles.loads})
end