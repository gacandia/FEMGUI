
db   =dbstack;
name =db(2).name;

if strcmp(name,'SelectAllMenu_Callback')
    do_p=0;
else
    do_p=1;
end


% intersect points
if strcmp(handles.DisplayNodes.Checked,'on')
    if do_p
        in = inpolygon(handles.fem.xy(:,2),handles.fem.xy(:,3),p(:,1),p(:,2));
        handles.ObjSelect.joint=unique([handles.ObjSelect.joint;find(in)]);
    end
    in = handles.ObjSelect.joint;
    pv = handles.fem.xy(in,2:3);
    delete(findobj(handles.ax,'tag','int_joint'))
    plot(handles.ax,pv(:,1),pv(:,2),'s','color',[0.9290    0.6940    0.1250],'tag','int_joint','markersize',8);
end

% intersect line
if handles.fem.nElements(1) && strcmp(handles.DisplayLines.Checked,'on')
    if do_p
        in = findIntersectedObj(handles.fem.xy(:,2:3),handles.fem.elasticBeamColumn(:,2:3),p);
        handles.ObjSelect.beam=unique([handles.ObjSelect.beam;in]);
    end
    in = handles.ObjSelect.beam;
    ch = findall(handles.ax,'tag','int_beam');
    t  = handles.fem.elasticBeamColumn(:,[2,3]);
    if isempty(ch)
        patch('vertices',handles.fem.xy(:,2:3),'faces',t(in,:),'facecolor','b','facealpha',0.1,'edgecolor',[0.8500    0.3250    0.0980],'linewidth',0.6,'tag','int_beam');
    else
        ch.Faces=t(handles.ObjSelect.beam,:);
    end
end

% intersect tri31
if handles.fem.nElements(2) && strcmp(handles.DisplayAreas.Checked,'on')
    if do_p
        in = findIntersectedObj(handles.fem.xy(:,2:3),handles.fem.tri31(:,2:4),p);
        handles.ObjSelect.tri31=unique([handles.ObjSelect.tri31;in]);
    end
    in = handles.ObjSelect.tri31;
    ch=findall(handles.ax,'tag','int_tri31');
    t = handles.fem.tri31(:,2:4);
    if isempty(ch)
        patch('vertices',handles.fem.xy(:,2:3),'faces',t(in,:),'facecolor','b','facealpha',0.2,'edgecolor',[0.8500    0.3250    0.0980],'linewidth',0.6,'tag','int_tri31');
    else
        ch.Faces=t(handles.ObjSelect.tri31,:);
    end
end

% intersect quads
if handles.fem.nElements(3) && strcmp(handles.DisplayAreas.Checked,'on')
    if do_p
        in = findIntersectedObj(handles.fem.xy(:,2:3),handles.fem.quad(:,2:5),p);
        handles.ObjSelect.quad=unique([handles.ObjSelect.quad;in]);
    end
    in = handles.ObjSelect.quad;
    ch=findall(handles.ax,'tag','int_quad');
    t = handles.fem.quad(:,2:5);
    if isempty(ch)
        patch('vertices',handles.fem.xy(:,2:3),'faces',t(in,:),'facecolor','b','facealpha',0.2,'edgecolor',[0.8500    0.3250    0.0980],'linewidth',0.6,'tag','int_quad');
    else
        ch.Faces=t(handles.ObjSelect.quad,:);
    end
end

% intersect joint constraint objects
Nc = numel(handles.fem.constraints);
if Nc && strcmp(handles.DispJointConstraintMenu.Checked,'on')
    ch   = flipud(findall(handles.ax,'tag','constraints'));
    in   = false(Nc,1);
    if do_p
        for i=1:Nc
            con_i = handles.fem.constraints(i);
            switch con_i.type
                case 'edgeconstraint'
                    xyd   = handles.fem.xy(con_i.slave,2:3);
                    b     = inpolygon(xyd(:,1),xyd(:,2),p(:,1),p(:,2));
                    c     = ismember(con_i.master(:),handles.ObjSelect.quad(:));
                    in(i) = any([b;c]);
                otherwise
                    xyd   = handles.fem.xy([con_i.slave(:,1);con_i.master(:,1)],2:3);
                    b     = inpolygon(xyd(:,1),xyd(:,2),p(:,1),p(:,2));
                    in(i) = any(b);
            end
            
        end
        handles.ObjSelect.const=unique([handles.ObjSelect.const;find(in)]);
    end
end
