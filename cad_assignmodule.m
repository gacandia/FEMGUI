
objclick=findall(handles.figure1,'tag','objclick');
delete(objclick)

%% return conditions
if assign==3 && handles.fem.nElements(1)==0, return, end
if assign==4 && sum(handles.fem.nElements(2:3))==0, return, end


if assign==-1 % Cancel Assignment
    handles.AssignButton.Visible='off';
    handles.CancelButton.Visible='off';
    delete(findobj(handles.figure1,'tag','uipanel','-or','tag','uicontrol'))
    delete(findall(handles.ax,'tag','polytemp'));
end

if assign==0 % assign objects
    handles.AssignButton.Visible='off';
    handles.CancelButton.Visible='off';
    hp=findobj(handles.figure1,'tag','uipanel');
    
    switch hp(1).Title
        case 'Joint restraints'
            ch      = findobj(hp,'tag','uicontrol');
            Obj     = handles.ObjSelect.joint;
            Obj(:,2)=ch(1).Value;
            Obj(:,3)=ch(2).Value;
            Obj(:,4)=ch(3).Value;
            
            % delete previous assignment
            fix  = handles.fem.restraints;
            Del  = ismember(fix(:,1),Obj(:,1));
            fix(Del,:)=[];
            
            % stores assignment
            newfix = sortrows([fix;Obj],1);
            Del    = sum(newfix(:,2:4),2)==0; % no fix assigned
            newfix(Del,:)=[];
            handles.fem.restraints = newfix;
            
        case 'Equaldof constraints'
            ch      = findobj(hp,'tag','uicontrol');
            Obj     = handles.ObjSelect.joint;
            handles.fem.constraints = cad_constraintinterference(handles.fem.constraints,Obj);
            EDOF    = find([ch(1).Value,ch(2).Value,ch(3).Value]);
            SEP     = ch(4).Value;
            if numel(Obj)>1
                switch SEP
                    case 1 % apply separate constraints at different Y-levels
                        [subxy,b]   = sortrows(handles.fem.xy(Obj,2:3),[2 1]);
                        Obj=Obj(b);
                        [~,b,c] = unique(subxy(:,2));
                        for i=1:numel(b)
                            jc.type   = 'equaldof';
                            ObjY      = Obj(c==i);
                            Ns        = numel(ObjY)-1;
                            jc.slave  = [ObjY(2:end) repmat(EDOF,Ns,1)];
                            jc.master = [ObjY(1),EDOF];
                            handles.fem.constraints(end+1,1)=jc;
                        end
                        
                    case 0 % apply a single constraint
                        jc.type   = 'equaldof';
                        Ns        = numel(Obj)-1;
                        jc.slave  = [Obj(2:end) repmat(EDOF,Ns,1)];
                        jc.master = [Obj(1),EDOF];
                        handles.fem.constraints(end+1,1)=jc;
                end
            end
            
        case 'Rigid Body constraint'
            Obj     = handles.ObjSelect.joint;
            handles.fem.constraints = cad_constraintinterference(handles.fem.constraints,Obj);
            if numel(Obj)>1
                jc.type = 'rigidbody';
                jc.slave = Obj(2:end);
                jc.master = Obj(1);
                handles.fem.constraints(end+1,1)= jc;
            end
            
        case 'Edge constraint'
            Obj1 = handles.ObjSelect.joint;
            handles.fem.constraints = cad_constraintinterference(handles.fem.constraints,Obj1);
            selectTria = [];if handles.fem.nElements(2), selectTria = handles.fem.tri31(handles.ObjSelect.tri31,1);end
            selectQuad = [];if handles.fem.nElements(3), selectQuad = handles.fem.quad(handles.ObjSelect.quad,1);end
            Obj2 = [selectQuad;selectTria];
            areaID = cad_getelemID(handles.fem,'quad','tri31');
            if numel(Obj1)>0 && numel(Obj2)>0
                jc.type   = 'edgeconstraint';
                jc.slave  = Obj1(:)';
                [~,jc.master] = intersect(areaID,Obj2);
                jc.master = jc.master(:)';
                if test_edge_constraint(jc,handles.fem)
                    handles.fem.constraints(end+1,1)= jc;
                else
                    warndlg('Edge constraint is ill defined')
                end
            end
            
        case 'Joint loads'
            ch      = findobj(hp,'tag','uicontrol');
            Obj     = handles.ObjSelect.joint;
            Obj(:,2) = eval(ch(1).String);
            Obj(:,3) = eval(ch(2).String);
            Obj(:,4) = eval(ch(3).String);
            
            % delete previous assignment
            jload  = handles.loads.joint;
            Del  = ismember(jload(:,1),Obj(:,1));
            jload(Del,:)=[];
            
            % stores assignment
            newjload = sortrows([jload;Obj],1);
            Del      = sum(abs(newjload(:,2:4)),2)==0; % no load assigned
            newjload(Del,:)=[];
            handles.loads.joint = newjload;
            
        case 'Joint displacements'
            ch      = findobj(hp,'tag','uicontrol');
            Obj     = handles.ObjSelect.joint;
            Obj(:,2) = eval(ch(1).String);
            Obj(:,3) = eval(ch(2).String);
            Obj(:,4) = eval(ch(3).String);
            
            % delete previous assignment
            jload  = handles.loads.jointdisp;
            Del  = ismember(jload(:,1),Obj(:,1));
            jload(Del,:)=[];
            
            % stores assignment
            newjload = sortrows([jload;Obj],1);
            Del      = sum(abs(newjload(:,2:4)),2)==0; % no disp assigned
            newjload(Del,:)=[];
            handles.loads.jointdisp = newjload;
            
        case 'Line loads'
            
            % lineloads
            ch1 = findobj(hp(1),'tag','uicontrol');
            Obj = handles.ObjSelect.beam;
            ltype = ch1(1).Value;
            ref   = ch1(2).Value;
            x     = eval(['[',ch1(3).String,']']);
            P1    = eval(['[',ch1(4).String,']']);
            P2    = eval(['[',ch1(5).String,']']);
            
            % delete previous assignment
            IDS = vertcat(handles.loads.eleload.id);
            a   = ismember(IDS,handles.fem.elasticBeamColumn(Obj,1));
            handles.loads.eleload(a)=[];
            
            % newloads
            if any([P1(:);P2(:)])
                newload(1:numel(Obj),1) = cad_CreateObj(2.1);
                % stores assignment
                for i=1:numel(Obj)
                    newload(i).etype    = 1;
                    newload(i).id       = handles.fem.elasticBeamColumn(Obj(i),1);
                    newload(i).loadtype = ltype;
                    newload(i).frame    = ref;
                    newload(i).station  = x;
                    newload(i).values   = [P1;P2];
                end
                handles.loads.eleload = [handles.loads.eleload;newload];
            end
            
        case 'Area loads'
            ch     = findobj(hp,'tag','uicontrol');
            qx     = eval(ch(1).String);
            qy     = eval(ch(2).String);
            IDS    = vertcat(handles.loads.eleload.id);
            
            %% arealoads on quad
            Obj  = handles.ObjSelect.quad;
            a1   = [];
            if any([qx;qy]) && numel(Obj)>0
                a1 = ismember(IDS,handles.fem.quad(Obj,1));
                newload(1:numel(Obj),1) = cad_CreateObj(2.1);
                % stores assignment
                for i=1:numel(Obj)
                    newload(i).etype    = 3;
                    newload(i).id       = handles.fem.quad(Obj(i),1);
                    newload(i).values   = [qx;qy];
                end
                handles.loads.eleload = [handles.loads.eleload;newload];
            end
            
            %% arealoads on tri31
            Obj  = handles.ObjSelect.tri31;
            a2   = [];
            if any([qx;qy]) && numel(Obj)>0
                a2   = ismember(IDS,handles.fem.tri31(Obj,1));
                newload(1:numel(Obj),1) = cad_CreateObj(2.1);
                % stores assignment
                for i=1:numel(Obj)
                    newload(i).etype    = 2;
                    newload(i).id       = handles.fem.tri31(Obj(i),1);
                    newload(i).values   = [qx;qy];
                end
                handles.loads.eleload = [handles.loads.eleload;newload];
            end
            
            handles.loads.eleload([find(a1(:));find(a2(:))])=[];
            
        case 'Line section'
            ch  = findobj(hp,'tag','uicontrol');
            Obj  = handles.ObjSelect.beam;
            
            sect_label   = ch(1).String{ch(1).Value};
            [~,sect_ptr] = ismember(sect_label,{handles.fem.section.label});
            mat_ptr  = handles.fem.section(sect_ptr).mat;
            newline  = [sect_ptr,mat_ptr];
            handles.fem.elasticBeamColumn(Obj,[4,7]) = repmat(newline,numel(Obj),1);
            
        case 'End moment relaease'
            ch  = findobj(hp,'tag','uicontrol');
            Obj  = handles.ObjSelect.beam;
            
            if ch(1).Value, newline=[0 0];end
            if ch(2).Value, newline=[1 0];end
            if ch(3).Value, newline=[0 1];end
            if ch(4).Value, newline=[1 1];end
            handles.fem.elasticBeamColumn(Obj,[5,6]) = repmat(newline,numel(Obj),1);
            
        case 'Area section'
            ch      = findobj(hp,'tag','uicontrol');
            sim_ptr =  ch(1).Value;
            mat_ptr =  ch(2).Value;
            th      = str2double(ch(3).String);
            
            if isnan(th)
                newline = [sim_ptr mat_ptr];
                if handles.fem.nElements(2)
                    Obj = handles.ObjSelect.tri31;
                    handles.fem.tri31(Obj,5:7) = repmat(newline,numel(Obj),1);
                end
                
                if handles.fem.nElements(3)
                    Obj = handles.ObjSelect.quad;
                    handles.fem.quad(Obj,6:8) = repmat(newline,numel(Obj),1);
                end
            else
                newline = [th sim_ptr mat_ptr];
                if handles.fem.nElements(2)
                    Obj = handles.ObjSelect.tri31;
                    handles.fem.tri31(Obj,5:7) = repmat(newline,numel(Obj),1);
                end
                
                if handles.fem.nElements(3)
                    Obj = handles.ObjSelect.quad;
                    handles.fem.quad(Obj,6:8) = repmat(newline,numel(Obj),1);
                end
                
            end
            
        case 'Section parameters'
            load tempsect vsect
            if handles.fem.nElements(1)
                old_ID = vertcat(handles.fem.section(handles.fem.elasticBeamColumn(:,4)).id);
                new_ID = vertcat(vsect.id);
                ZeroFind = ismember(old_ID,new_ID);
                if any(ZeroFind==0)
                    warndlg('Section deleted was already assigned. Frame sections re-assigned automatically, check your model')
                    fixed_ID = old_ID;
                    fixed_ID(ZeroFind==0)=vsect(1).id;
                    [~,handles.fem.elasticBeamColumn(:,4)]=ismember(fixed_ID,new_ID);
                end
            end
            handles.fem.section=vsect;
            
        case 'Node shift'
            ch   = findobj(hp,'tag','uicontrol');
            Obj  = handles.ObjSelect.joint;
            DX   = eval(ch(1).String);
            DY   = eval(ch(2).String);
            
            % apply shift to selected nodes
            handles.fem.xy(Obj,2:3)=handles.fem.xy(Obj,2:3)+[DX DY];
            
        case 'Node stretch'
            ch   = findobj(hp,'tag','uicontrol');
            Obj  = handles.ObjSelect.joint;
            Xfactor = eval(ch(1).String);
            Yfactor = eval(ch(2).String);
            
            % apply shift to selected nodes
            handles.fem.xy(Obj,2:3)=handles.fem.xy(Obj,2:3).*[Xfactor Yfactor];
            handles.sys.XLim=handles.sys.XLim*Xfactor;
            handles.sys.YLim=handles.sys.YLim*Yfactor;
            handles.sys.XTick=handles.sys.XTick*Xfactor;
            handles.sys.YTick=handles.sys.YTick*Yfactor;
            
        case 'Replicate'
            
            ch   = findobj(hp,'tag','uicontrol');
            DX   = str2double(ch(1).String);
            DY   = str2double(ch(2).String);
            N    = str2double(ch(3).String);
            newtag   = cad_newtag(handles.fem);
            
            % replicate beams
            Obj  = handles.ObjSelect.beam;
            for i=1:numel(Obj)
                leg = handles.fem.elasticBeamColumn(Obj(i),:);
                leg(1)=newtag;
                for j=1:N
                    rI   = handles.fem.xy(leg(2),2:3)+[DX DY]*j;
                    rJ   = handles.fem.xy(leg(3),2:3)+[DX DY]*j;
                    n_xy = [rI;rJ];
                    [handles.fem.xy,handles.fem.elasticBeamColumn]=cad_addelement(handles.fem.xy,handles.fem.elasticBeamColumn,n_xy,leg);
                    leg(1)=leg(1)+1;
                end
                newtag=leg(1);
            end
            
            % replicate quads
            Obj  = handles.ObjSelect.quad;
            for i=1:numel(Obj)
                leg = handles.fem.quad(Obj(i),:);
                leg(1)=newtag;
                for j=1:N
                    rI   = handles.fem.xy(leg(2),2:3)+[DX DY]*j;
                    rJ   = handles.fem.xy(leg(3),2:3)+[DX DY]*j;
                    rK   = handles.fem.xy(leg(4),2:3)+[DX DY]*j;
                    rL   = handles.fem.xy(leg(5),2:3)+[DX DY]*j;
                    n_xy = [rI;rJ;rK;rL];
                    [handles.fem.xy,handles.fem.quad]=cad_addelement(handles.fem.xy,handles.fem.quad,n_xy,leg);
                    leg(1)=leg(1)+1;
                end
                newtag=leg(1);
            end
            
            % replicate trias
            Obj  = handles.ObjSelect.tri31;
            for i=1:numel(Obj)
                leg = handles.fem.tri31(Obj(i),:);
                leg(1)=newtag;
                for j=1:N
                    rI   = handles.fem.xy(leg(2),2:3)+[DX DY]*j;
                    rJ   = handles.fem.xy(leg(3),2:3)+[DX DY]*j;
                    rK   = handles.fem.xy(leg(4),2:3)+[DX DY]*j;
                    n_xy = [rI;rJ;rK];
                    [handles.fem.xy,handles.fem.tri31]=cad_addelement(handles.fem.xy,handles.fem.tri31,n_xy,leg);
                    leg(1)=leg(1)+1;
                end
                newtag=leg(1);
            end
            
            
            
        case 'Subdivide lines'
            ch       = findobj(hp,'tag','uicontrol');
            
            if numel(handles.ObjSelect.beam)
                mesh_opt = [horzcat(ch(1:4).Value),str2double({ch(7:8).String})];
                newtag   = cad_newtag(handles.fem);
                [handles.fem.xy,handles.fem.elasticBeamColumn,handles.loads.eleload]=cadd_meshlines(...
                    handles.fem.xy,...
                    handles.fem.elasticBeamColumn,...
                    handles.loads.eleload,...
                    handles.ObjSelect.joint,...
                    handles.ObjSelect.beam,...
                    mesh_opt,...
                    newtag);
            end
            
            Nareas=numel(handles.ObjSelect.quad)+numel(handles.ObjSelect.tri31);
            if Nareas
                mesh_opt      = [horzcat(ch(5:6).Value),str2double({ch(9:11).String}),ch(12).Value];
                [handles.fem,handles.loads.eleload] = cadd_meshareas(handles.fem,handles.loads.eleload,handles.ObjSelect,mesh_opt);
            end
            
        case 'Subdivide polygon'
            ch          = findobj(hp,'tag','uicontrol');
            mesh_opt    = [str2double(ch(1).String),horzcat(ch(2:3).Value)];
            obj         = findall(handles.ax,'tag','polytemp');
            leg         = str2num(ch(4).String);
            handles.fem = cadd_meshpolygons(handles.fem,obj.Vertices,mesh_opt,leg);
            delete(obj)
            
        case 'Remove Assignments'
            ch   = findobj(hp,'tag','uicontrol');
            obj1 = handles.ObjSelect.joint;
            
            if ch(1).Value % remove restraints
                b=ismember(handles.fem.restraints(:,1),obj1);
                handles.fem.restraints(b,:)=[];
            end
            
            if ch(2).Value % remove joint displacements
                b=ismember(handles.loads.jointdisp(:,1),obj1);
                handles.loads.jointdisp(b,:)=[];
            end
            
            if ch(3).Value % remove joint constraints
                obj4=handles.ObjSelect.const;
                handles.fem.constraints(obj4,:)=[];
                handles.ObjSelect.const=zeros(0,1);
            end
            
            if ch(4).Value % remove element loads
                % joint loads
                b=ismember(handles.loads.joint(:,1),obj1);
                handles.loads.joint(b,:)=[];
            end
            
            if ch(5).Value % remove element loads
                n       = handles.fem.nElements;
                objBeam = handles.ObjSelect.beam;
                objTria = handles.ObjSelect.tri31;
                objQuad = handles.ObjSelect.quad;
                etype   = vertcat(handles.loads.eleload.etype);
                tag     = vertcat(handles.loads.eleload.id);
                IND = false(numel(handles.loads.eleload),1);
                if n(1) && numel(objBeam)
                    tagBeam = handles.fem.elasticBeamColumn(objBeam,1);
                    b       = and(ismember(tag,tagBeam),etype==1);
                    IND(b)  = true;
                end
                
                if n(2)
                    tagTria = handles.fem.tri31(objTria,1);
                    b       = and(ismember(tag,tagTria),etype==2);
                    IND(b)  = true;
                end
                
                if n(3)
                    tagQuad = handles.fem.quad(objQuad,1);
                    b       = and(ismember(tag,tagQuad),etype==3);
                    IND(b)  = true;
                end
                handles.loads.eleload(IND)=[];
            end
            
            if ch(6).Value % remove end moment releas
                n       = handles.fem.nElements;
                objBeam = handles.ObjSelect.beam;
                if n(1) && numel(objBeam)
                    handles.fem.elasticBeamColumn(objBeam,5:6)=0;
                end
            end
    end
    
    delete(findobj(handles.figure1,'tag','uipanel','-or','tag','uicontrol'))
    return
end

if any(assign==[1,1.5,1.6,1.7,2,2.2,3,4,6,8,9,10,12,13])
    if enableButtons
        handles.AssignButton.String='Assign';
        handles.AssignButton.Visible='on';
        handles.CancelButton.Visible='on';
    end
    delete(findobj(handles.figure1,'tag','uipanel','-or','tag','uicontrol'))
    hp = uipanel(...
        'parent',handles.figure1,...
        'BackgroundColor','w',...
        'Units','normalized',...
        'Position',[0.055 0.6 0.17 0.33],...
        'FontWeight','Bold',...
        'ForegroundColor',[0 0.3 1],...
        'BorderType','none',...
        'tag','uipanel');
end

if assign==1 % Create Joint Restraints pannel
    % mind the order
    hp.Title='Joint restraints';
    im1=uicontrol('parent',handles.figure1,'Style','pushbutton','tag','uicontrol','BackgroundColor','w','units','pixels', 'position',[ 70 445 25 25],'CData' ,imread('000.png'));
    im2=uicontrol('parent',handles.figure1,'Style','pushbutton','tag','uicontrol','BackgroundColor','w','units','pixels', 'position',[100 445 25 25],'CData' ,imread('111.png'));
    im3=uicontrol('parent',handles.figure1,'Style','pushbutton','tag','uicontrol','BackgroundColor','w','units','pixels', 'position',[130 445 25 25],'CData', imread('110.png'));
    im4=uicontrol('parent',handles.figure1,'Style','pushbutton','tag','uicontrol','BackgroundColor','w','units','pixels', 'position',[160 445 25 25],'CData' ,imread('010.png'));
    im5=uicontrol('parent',handles.figure1,'Style','pushbutton','tag','uicontrol','BackgroundColor','w','units','pixels', 'position',[190 445 25 25],'CData' ,imread('100.png'));
    im6=uicontrol('parent',handles.figure1,'Style','pushbutton','tag','uicontrol','BackgroundColor','w','units','pixels', 'position',[220 445 25 25],'CData' ,imread('011.png'));
    im7=uicontrol('parent',handles.figure1,'Style','pushbutton','tag','uicontrol','BackgroundColor','w','units','pixels', 'position',[250 445 25 25],'CData' ,imread('101.png'));
    
    im8  = uicontrol('parent',hp,'Style','checkbox','String','RZ','tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.08 0.52 0.53 0.12]);
    im9  = uicontrol('parent',hp,'Style','checkbox','String','Y' ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.08 0.66 0.53 0.12]);
    im10 = uicontrol('parent',hp,'Style','checkbox','String','X' ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.08 0.80 0.53 0.12]);
    
    im1.Callback = {@setfix,im10,im9,im8,0,0,0};
    im2.Callback = {@setfix,im10,im9,im8,1,1,1};
    im3.Callback = {@setfix,im10,im9,im8,1,1,0};
    im4.Callback = {@setfix,im10,im9,im8,0,1,0};
    im5.Callback = {@setfix,im10,im9,im8,1,0,0};
    im6.Callback = {@setfix,im10,im9,im8,0,1,1};
    im7.Callback = {@setfix,im10,im9,im8,1,0,1};
    return
end

if assign==1.5 % Create EqualDOF pannel
    % mind the order
    hp.Title='Equaldof constraints';
    im6  = uicontrol('parent',hp,'Style','text','String',{'Apply independent constraints','at different Y-levels'},'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.19 0.14 0.83 0.20],'horizontalalignment','left');
    im7  = uicontrol('parent',hp,'Style','checkbox','String','','tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.08 0.2 0.1 0.12]);
    im8  = uicontrol('parent',hp,'Style','checkbox','String','Equal RZ','tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.08 0.52 0.53 0.12]);
    im9  = uicontrol('parent',hp,'Style','checkbox','String','Equal Y' ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.08 0.66 0.53 0.12]);
    im10 = uicontrol('parent',hp,'Style','checkbox','String','Equal X' ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.08 0.80 0.53 0.12]);
    return
end

if assign==1.6 % Create Rigid Body pannel
    % mind the order
    hp.Title='Rigid Body constraint';
    return
end

if assign==1.7 % Create Edge Constraint pannel
    % mind the order
    hp.Title='Edge constraint';
    return
end

if assign==2 % Create Joint Load pannel
    hp.Title='Joint loads';
    FX  = cad_getUnitSt(handles.units,'force','FX (%s)');
    FY  = cad_getUnitSt(handles.units,'force','FY (%s)');
    Mom = cad_getUnitSt(handles.units,'moment','M (%s)');
    uicontrol('parent',hp,'Style','text','String',Mom ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0 0.48 0.33 0.12],'HorizontalAlignment','right');
    uicontrol('parent',hp,'Style','text','String',FY  ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0 0.63 0.33 0.12],'HorizontalAlignment','right');
    uicontrol('parent',hp,'Style','text','String',FX  ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0 0.78 0.33 0.12],'HorizontalAlignment','right');
    
    b=ismember(handles.loads.joint(:,1),handles.ObjSelect.joint);
    b=find(b);
    uniqueLoadValues=unique(handles.loads.joint(b,2:4),'rows');
    if height(uniqueLoadValues)==1
        st1 = sprintf('%g',uniqueLoadValues(1));
        st2 = sprintf('%g',uniqueLoadValues(2));
        st3 = sprintf('%g',uniqueLoadValues(3));
    else
        st1 = '0';
        st2 = '0';
        st3 = '0';
    end
    
    uicontrol('parent',hp,'Style','edit','String',st3,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized', 'position',[0.45 0.49 0.4 0.12]);
    uicontrol('parent',hp,'Style','edit','String',st2,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized', 'position',[0.45 0.64 0.4 0.12]);
    uicontrol('parent',hp,'Style','edit','String',st1,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized', 'position',[0.45 0.79 0.4 0.12]);
    
    return
end

if assign==2.2 % Create Joint displacement pannel
    hp.Title='Joint displacements';
    DX  = cad_getUnitSt(handles.units,'length','DX (%s)');
    DY  = cad_getUnitSt(handles.units,'length','DY (%s)');
    ROT = 'ROT (rad)';
    uicontrol('parent',hp,'Style','text','String',ROT,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0 0.48 0.33 0.12],'HorizontalAlignment','right');
    uicontrol('parent',hp,'Style','text','String',DY  ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0 0.63 0.33 0.12],'HorizontalAlignment','right');
    uicontrol('parent',hp,'Style','text','String',DX  ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0 0.78 0.33 0.12],'HorizontalAlignment','right');
    
    b=ismember(handles.loads.jointdisp(:,1),handles.ObjSelect.joint);
    b=find(b);
    uniqueLoadValues=unique(handles.loads.jointdisp(b,2:4),'rows');
    if height(uniqueLoadValues)==1
        st1 = sprintf('%g',uniqueLoadValues(1));
        st2 = sprintf('%g',uniqueLoadValues(2));
        st3 = sprintf('%g',uniqueLoadValues(3));
    else
        st1 = '0';
        st2 = '0';
        st3 = '0';
    end
    
    uicontrol('parent',hp,'Style','edit','String',st3,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized', 'position',[0.45 0.49 0.4 0.12]);
    uicontrol('parent',hp,'Style','edit','String',st2,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized', 'position',[0.45 0.64 0.4 0.12]);
    uicontrol('parent',hp,'Style','edit','String',st1,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized', 'position',[0.45 0.79 0.4 0.12]);
    
    return
end

if assign==3 % Create Line Load pannel
    hp.Title='Line loads';
    st1 = {'local','global'};
    st2 = {'continuous','discrete'};
    
    strq2 = cad_getUnitSt(handles.units,'force/length','q2 (%s)');
    strq1 = cad_getUnitSt(handles.units,'force/length','q1 (%s)');
    
    txt2=uicontrol('parent',hp,'Style','text','String',strq2,'tag','uicontrol','BackgroundColor','w','units','normalized',              'position',[0.0 0.19 0.53 0.12],'HorizontalAlignment','right');
    txt1=uicontrol('parent',hp,'Style','text','String',strq1,'tag','uicontrol','BackgroundColor','w','units','normalized',              'position',[0.0 0.34 0.53 0.12],'HorizontalAlignment','right');
    txt0=uicontrol('parent',hp,'Style','text','String','x'     ,'tag','uicontrol','BackgroundColor','w','units','normalized',           'position',[0.0 0.49 0.53 0.12],'HorizontalAlignment','right');
    uicontrol('parent',hp,'Style','text','String','Reference Frame'     ,'tag','uicontrol','BackgroundColor','w','units','normalized',  'position',[0.0 0.64 0.53 0.12],'HorizontalAlignment','right');
    uicontrol('parent',hp,'Style','text','String','Load type'           ,'tag','uicontrol','BackgroundColor','w','units','normalized',  'position',[0.0 0.79 0.53 0.12],'HorizontalAlignment','right');
    
    loadedID = vertcat(handles.loads.eleload.id);
    selID = handles.fem.elasticBeamColumn(handles.ObjSelect.beam,1);
    [~,b]=ismember(selID,loadedID);
    b(b==0)=[];
    lineload = handles.loads.eleload(b);
    if numel(lineload)==0
        strx      = '0';
        strq1     = '0';
        strq2     = '0';
        val_ltype = 1;
        val_ref   = 1;
        
    elseif numel(lineload)==1
        strx      = mat2str(lineload.station);     strx  = strrep(strx,'[',''); strx  = strrep(strx,']','');
        strq1     = mat2str(lineload.values(1,:)); strq1 = strrep(strq1,'[','');strq1 = strrep(strq1,']','');
        strq2     = mat2str(lineload.values(2,:)); strq2 = strrep(strq2,'[','');strq2 = strrep(strq2,']','');
        val_ltype = lineload.loadtype;
        val_ref   = lineload.frame;
        
    else
        for i=1:numel(b)
            lineload(i).id=[];
        end
        areEqual = true;
        for i=2:numel(b)
            if ~structcmp(lineload(i),lineload(i-1))
                areEqual = false;
            end
        end
        
        switch areEqual
            case true
                lineload  = lineload(1);
                strx      = mat2str(lineload.station);     strx  = strrep(strx,'[',''); strx  = strrep(strx,']','');
                strq1     = mat2str(lineload.values(1,:)); strq1 = strrep(strq1,'[','');strq1 = strrep(strq1,']','');
                strq2     = mat2str(lineload.values(2,:)); strq2 = strrep(strq2,'[','');strq2 = strrep(strq2,']','');
                val_ltype = lineload.loadtype;
                val_ref   = lineload.frame;
            case false
                strx      = '0';
                strq1     = '0';
                strq2     = '0';
                val_ltype = 1;
                val_ref   = 1;
        end
        
    end
    uicontrol('parent',hp,'Style','edit','String',strq2,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',               'position',[0.58 0.19 0.4 0.12]);
    uicontrol('parent',hp,'Style','edit','String',strq1,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',               'position',[0.58 0.34 0.4 0.12]);
    edix=uicontrol('parent',hp,'Style','edit','String',strx,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',          'position',[0.58 0.49 0.4 0.12]);
    pop1=uicontrol('parent',hp,'Style','popupmenu','String',st1,'value',val_ref  ,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',          'position',[0.58 0.64 0.4 0.12]);
    pop2=uicontrol('parent',hp,'Style','popupmenu','String',st2,'value',val_ltype,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',     'position',[0.58 0.79 0.4 0.12]);
    pop1.Callback={@updateMethod,pop1,pop2,txt1,txt2,handles.units};
    pop2.Callback={@updateMethod,pop1,pop2,txt1,txt2,handles.units};
    
    return
    
end

if assign==4 % Create Area Load pannel
    hp.Title='Area loads';
    strqx = cad_getUnitSt(handles.units,'force/volume','qx (%s)');
    strqy = cad_getUnitSt(handles.units,'force/volume','qy (%s)');
    
    TXT2=uicontrol('parent',hp,'Style','text','String',strqy,'tag','uicontrol','BackgroundColor','w','units','normalized',  'position',[0.0 0.64 0.43 0.12],'HorizontalAlignment','right');
    TXT1=uicontrol('parent',hp,'Style','text','String',strqx,'tag','uicontrol','BackgroundColor','w','units','normalized',  'position',[0.0 0.79 0.43 0.12],'HorizontalAlignment','right');
    uicontrol('parent',hp,'Style','edit','String','0','tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',   'position',[0.55 0.64 0.4 0.12]);
    uicontrol('parent',hp,'Style','edit','String','0','tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',   'position',[0.55 0.79 0.4 0.12]);
end

if assign==5 % Line Section
    if enableButtons
        handles.AssignButton.String='Assign';
        handles.AssignButton.Visible='on';
        handles.CancelButton.Visible='on';
    end
    delete(findobj(handles.figure1,'tag','uipanel','-or','tag','uicontrol'))
    hp = uipanel('Title','Line section',...
        'parent',handles.figure1,...
        'BackgroundColor','w',...
        'Units','normalized',...
        'Position',[0.055 0.43 0.2 0.5],...
        'FontWeight','Bold',...
        'ForegroundColor',[0 0 0],...
        'BorderType','none',...
        'tag','uipanel');
    
    DS = 1;
    if handles.fem.nElements(1)
        selBeam = handles.fem.elasticBeamColumn(handles.ObjSelect.beam,:);
        selSect = unique(selBeam(:,4));
        if numel(selSect)==1
            DS = selSect;
        end
    end
    
    uicontrol('parent',hp,'Style','text','String','Label'           ,'tag','uicontrol','BackgroundColor','w','units','normalized',  'position',[0.0 0.85 0.4 0.06],'HorizontalAlignment','right');
    Label       = {handles.fem.section.label};
    labelpop    = uicontrol('parent',hp,'Style','popupmenu','String',Label,'value',DS,'tag','uicontrol','units','normalized',  'position',[0.45 0.875 0.4 0.05] ,'HorizontalAlignment','right','BackgroundColor',[1 1 0.7]);
    
end

if assign==5.5 % Moment Release
    if enableButtons
        handles.AssignButton.String='Assign';
        handles.AssignButton.Visible='on';
        handles.CancelButton.Visible='on';
    end
    delete(findobj(handles.figure1,'tag','uipanel','-or','tag','uicontrol'))
    hp = uibuttongroup('Title','End moment relaease',...
        'parent',handles.figure1,...
        'BackgroundColor','w',...
        'Units','normalized',...
        'Position',[0.055 0.43 0.2 0.5],...
        'FontWeight','Bold',...
        'ForegroundColor',[0 0 0],...
        'BorderType','none',...
        'tag','uipanel');
    
    uicontrol('parent',hp,'Style','radiobutton','String','Both nodes' ,'tag','uicontrol','units','normalized',  'position',[0.10 0.635 0.4 0.05] ,'HorizontalAlignment','right','BackgroundColor',[1 1 1]);
    uicontrol('parent',hp,'Style','radiobutton','String','node J'     ,'tag','uicontrol','units','normalized',  'position',[0.10 0.715 0.4 0.05] ,'HorizontalAlignment','right','BackgroundColor',[1 1 1]);
    uicontrol('parent',hp,'Style','radiobutton','String','node I'     ,'tag','uicontrol','units','normalized',  'position',[0.10 0.795 0.4 0.05] ,'HorizontalAlignment','right','BackgroundColor',[1 1 1]);
    uicontrol('parent',hp,'Style','radiobutton','String','None'       ,'tag','uicontrol','units','normalized',  'position',[0.10 0.875 0.4 0.05] ,'HorizontalAlignment','right','BackgroundColor',[1 1 1],'value',1);
end

if assign==6 % Area Section
    hp.Title='Area section';
    
    if handles.units.Value~=12
        un = horzcat(regexp(handles.units.String{handles.units.Value},', ','split'));
        stunits = sprintf('Thickness (%s)',un{2});
    else
        stunits = 'Thickness';
    end
    uicontrol('parent',hp,'Style','text','String',stunits ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0  0.50-0.02 0.53 0.12],'HorizontalAlignment','right');
    uicontrol('parent',hp,'Style','text','String','Material '      ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0  0.65-0.02 0.53 0.12],'HorizontalAlignment','right');
    uicontrol('parent',hp,'Style','text','String','Formulation'    ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0  0.80-0.02 0.53 0.12],'HorizontalAlignment','right');
    
    st1 = {handles.fem.material.label};
    st2 = {'plain stress','plain strain'};
    
    param = zeros(0,3);
    if handles.fem.nElements(2)
        param=unique(handles.fem.tri31(handles.ObjSelect.tri31,5:7),'rows');
    end
    
    if handles.fem.nElements(3)
        param=unique([param;handles.fem.quad(handles.ObjSelect.quad,6:8)],'rows');
    end
    
    st0='1';
    sim_ptr=1;
    mat_ptr=1;
    if height(param)==1
        st0=sprintf('%g',param(1));
        sim_ptr=param(2);
        mat_ptr=param(3);
    end
    
    uicontrol('parent',hp,'Style','edit','String',st0,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',        'position',[0.58 0.50 0.4 0.12]);
    uicontrol('parent',hp,'Style','popupmenu','String',st1,'value',mat_ptr,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized','position',[0.58 0.65 0.4 0.12]);
    uicontrol('parent',hp,'Style','popupmenu','String',st2,'value',sim_ptr,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized','position',[0.58 0.80 0.4 0.12]);
end

if assign==7 % Edit Section Pannel
    if enableButtons
        handles.AssignButton.String='Save';
        handles.AssignButton.Visible='on';
        handles.CancelButton.Visible='on';
    end
    delete(findobj(handles.figure1,'tag','uipanel','-or','tag','uicontrol'))
    hp = uipanel('Title','Section parameters',...
        'parent',handles.figure1,...
        'BackgroundColor','w',...
        'Units','normalized',...
        'Position',[0.055 0.43 0.2 0.5],...
        'FontWeight','Bold',...
        'ForegroundColor',[0 0 0],...
        'BorderType','none',...
        'tag','uipanel');
    
    DS = 1;
    if handles.fem.nElements(1)
        selBeam = handles.fem.elasticBeamColumn(handles.ObjSelect.beam,:);
        selSect = unique(selBeam(:,4));
        if numel(selSect)==1
            DS = selSect;
        end
    end
    
    sect   = handles.fem.section(DS);
    Labels = {handles.fem.section.label};
    
    txth    = cad_getUnitSt(handles.units,'length','height (%s)');
    txtIyy  = cad_getUnitSt(handles.units,'length4','Iyy (%s)');
    txtIxx  = cad_getUnitSt(handles.units,'length4','Ixx (%s)');
    txtArea = cad_getUnitSt(handles.units,'length2','Area (%s)');
    
    uicontrol('parent',hp,'Style','text','String',txth    ,'tag','uicontrol','BackgroundColor','w','units','normalized',  'position',[0.1 0.12 0.35 0.06],'HorizontalAlignment','left');
    uicontrol('parent',hp,'Style','text','String',txtIyy  ,'tag','uicontrol','BackgroundColor','w','units','normalized',  'position',[0.1 0.22 0.35 0.06],'HorizontalAlignment','left');
    uicontrol('parent',hp,'Style','text','String',txtIxx  ,'tag','uicontrol','BackgroundColor','w','units','normalized',  'position',[0.1 0.32 0.35 0.06],'HorizontalAlignment','left');
    uicontrol('parent',hp,'Style','text','String',txtArea ,'tag','uicontrol','BackgroundColor','w','units','normalized',  'position',[0.1 0.42 0.35 0.06],'HorizontalAlignment','left');
    uicontrol('parent',hp,'Style','text','String','Label' ,'tag','uicontrol','BackgroundColor','w','units','normalized',  'position',[0.1 0.52 0.35 0.06],'HorizontalAlignment','left');
    
    E5=uicontrol('parent',hp,'Style','edit','String',sect.height   ,'tag','uicontrol','units','normalized', 'position',[0.5 0.12 0.4 0.06] ,'HorizontalAlignment','center','BackgroundColor',[1 1 1]);
    E4=uicontrol('parent',hp,'Style','edit','String',sect.values(3),'tag','uicontrol','units','normalized', 'position',[0.5 0.22 0.4 0.06] ,'HorizontalAlignment','center','BackgroundColor',[1 1 1]);
    E3=uicontrol('parent',hp,'Style','edit','String',sect.values(2),'tag','uicontrol','units','normalized', 'position',[0.5 0.32 0.4 0.06] ,'HorizontalAlignment','center','BackgroundColor',[1 1 1]);
    E2=uicontrol('parent',hp,'Style','edit','String',sect.values(1),'tag','uicontrol','units','normalized', 'position',[0.5 0.42 0.4 0.06] ,'HorizontalAlignment','center','BackgroundColor',[1 1 1]);
    E1=uicontrol('parent',hp,'Style','edit','String',sect.label    ,'tag','uicontrol','units','normalized', 'position',[0.5 0.52 0.4 0.06] ,'HorizontalAlignment','center','BackgroundColor',[1 1 1]);
    ES=[E1,E2,E3,E4,E5];
    set(ES,'enable','inactive')
    listbox = uicontrol('parent',hp,'Style','listbox','String',Labels ,'tag','uicontrol','units','normalized',  'position',[0.1 0.67 0.8 0.25] ,'HorizontalAlignment','right','BackgroundColor',[1 1 1]);
    
    
    vsect = handles.fem.section;
    for i=1:numel(vsect)
        vsect(i).status=1;
    end
    save tempsect vsect
    
    listbox.Callback = {@list_CallBack,listbox,ES};
    
    cm = uicontextmenu;
    uimenu(cm,'label','Edit','Callback'     ,{@SectionEdit   ,listbox,ES});
    uimenu(cm,'label','Delete','Callback'   ,{@SectionDelete ,listbox,ES});
    uimenu(cm,'label','Add copy','Callback' ,{@SectionCopy   ,listbox,ES});
    uimenu(cm,'label','Import Database','Callback' ,{@SectionImport,listbox});
    listbox.ContextMenu =cm;
end

if assign==8 % Move nodes
    handles.AssignButton.String='Apply';
    hp.Title='Node shift';
    DX  = cad_getUnitSt(handles.units,'length','DX (%s)');
    DY  = cad_getUnitSt(handles.units,'length','DY (%s)');
    uicontrol('parent',hp,'Style','text','String',DY  ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0 0.63 0.33 0.12],'HorizontalAlignment','right');
    uicontrol('parent',hp,'Style','text','String',DX  ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0 0.78 0.33 0.12],'HorizontalAlignment','right');
    st1 = '0';
    st2 = '0';
    uicontrol('parent',hp,'Style','edit','String',st2,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized', 'position',[0.45 0.64 0.4 0.12]);
    uicontrol('parent',hp,'Style','edit','String',st1,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized', 'position',[0.45 0.79 0.4 0.12]);
    return
end

if assign==9 % Stretch nodes
    handles.AssignButton.String='Apply';
    hp.Title='Node stretch';
    DX  = 'X-Factor';
    DY  = 'Y.Factor';
    uicontrol('parent',hp,'Style','text','String',DY  ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0 0.63 0.33 0.12],'HorizontalAlignment','right');
    uicontrol('parent',hp,'Style','text','String',DX  ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0 0.78 0.33 0.12],'HorizontalAlignment','right');
    st1 = '1';
    st2 = '1';
    uicontrol('parent',hp,'Style','edit','String',st2,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized', 'position',[0.45 0.64 0.4 0.12]);
    uicontrol('parent',hp,'Style','edit','String',st1,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized', 'position',[0.45 0.79 0.4 0.12]);
    return
end

if assign==10 % Replicate Elements
    handles.AssignButton.String='Apply';
    hp.Title='Replicate';
    DX  = cad_getUnitSt(handles.units,'length','DX (%s)');
    DY  = cad_getUnitSt(handles.units,'length','DY (%s)');
    N   = 'N°';
    uicontrol('parent',hp,'Style','text','String',N   ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0 0.48 0.33 0.12],'HorizontalAlignment','right');
    uicontrol('parent',hp,'Style','text','String',DY  ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0 0.63 0.33 0.12],'HorizontalAlignment','right');
    uicontrol('parent',hp,'Style','text','String',DX  ,'tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.0 0.78 0.33 0.12],'HorizontalAlignment','right');
    st1 = '0';
    st2 = '0';
    st3 = '1';
    uicontrol('parent',hp,'Style','edit','String',st3,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized', 'position',[0.45 0.49 0.4 0.12]);
    uicontrol('parent',hp,'Style','edit','String',st2,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized', 'position',[0.45 0.64 0.4 0.12]);
    uicontrol('parent',hp,'Style','edit','String',st1,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized', 'position',[0.45 0.79 0.4 0.12]);
    return
end

if assign==11 % mesh objects
    if enableButtons
        handles.AssignButton.String='Assign';
        handles.AssignButton.Visible='on';
        handles.CancelButton.Visible='on';
    end
    delete(findobj(handles.figure1,'tag','uipanel','-or','tag','uicontrol'))
    hp = uipanel(...
        'parent',handles.figure1,...
        'BackgroundColor','w',...
        'Units','normalized',...
        'Position',[0.055 0.4 0.17 0.55],...
        'FontWeight','Bold',...
        'ForegroundColor',[0 0.3 1],...
        'BorderType','none',...
        'tag','uipanel');
    
    handles.AssignButton.String='Apply';
    hp.Title='Subdivide lines';
    
    MAXSIZE = cad_getUnitSt(handles.units,'length','Maximum size (%s)');
    st1 = '2';
    maxSize = min([round(mean(diff(handles.ax.XTick))/2),round(mean(diff(handles.ax.YTick))/2)]);
    st2 = sprintf('%g',maxSize);
    he = 0.07;
    uicontrol('parent',hp,'Style','Text','String','Subdivide areas'  ,'tag','uicontrol','BackgroundColor','w','units','normalized'         ,      'position',[0.00  0.44 1.00 he] ,'HorizontalAlignment','left','fontweight','bold','ForegroundColor',[0 0.3 1]);
    uicontrol('parent',hp,'Style','text','String','Elements along 1-3' ,'tag','uicontrol','BackgroundColor','w','units','normalized',             'position',[0.135 0.264 0.52 he] ,'HorizontalAlignment','left');
    
    e6=uicontrol('parent',hp,'Style','checkbox','String','Force triangular elements','tag','uicontrol','BackgroundColor','w','units','normalized','position',[0.05 0.07 0.8   he] ,'HorizontalAlignment','left');
    e5=uicontrol('parent',hp,'Style','edit','String',st2,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',                      'position',[0.7  0.17 0.25 he]);
    e4=uicontrol('parent',hp,'Style','edit','String',st1,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',                      'position',[0.7  0.27 0.25 he]);
    e3=uicontrol('parent',hp,'Style','edit','String',st1,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',                      'position',[0.7  0.37 0.25 he]);
    e2=uicontrol('parent',hp,'Style','edit','String',st2,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',                      'position',[0.7  0.77 0.25 he]);
    e1=uicontrol('parent',hp,'Style','edit','String',st1,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',                      'position',[0.7  0.87 0.25 he]);
    
    a4=uicontrol('parent',hp,'Style','radiobutton','String',MAXSIZE          ,'tag','uicontrol','BackgroundColor','w','units','normalized',      'position',[0.05 0.17 0.6  he] ,'HorizontalAlignment','left','value',0);
    a3=uicontrol('parent',hp,'Style','radiobutton','String','Elements along 1-2' ,'tag','uicontrol','BackgroundColor','w','units','normalized',  'position',[0.05 0.36 0.6  he] ,'HorizontalAlignment','left','value',1);
    
    b4=uicontrol('parent',hp,'Style','radiobutton','String','Break at intersection with lines','tag','uicontrol','BackgroundColor','w','units','normalized',  'position',[0.05 0.58 0.95  he] ,'HorizontalAlignment','left','value',0);
    b3=uicontrol('parent',hp,'Style','radiobutton','String','Break at intersection with joints','tag','uicontrol','BackgroundColor','w','units','normalized', 'position',[0.05 0.675 0.95  he] ,'HorizontalAlignment','left','value',0);
    b2=uicontrol('parent',hp,'Style','radiobutton','String',MAXSIZE          ,'tag','uicontrol','BackgroundColor','w','units','normalized',      'position',[0.05 0.77 0.6  he] ,'HorizontalAlignment','left','value',0);
    b1=uicontrol('parent',hp,'Style','radiobutton','String','N° of elements' ,'tag','uicontrol','BackgroundColor','w','units','normalized',      'position',[0.05 0.87 0.6  he] ,'HorizontalAlignment','left','value',1);
    
    set(b1,'Callback',{@switchRadio3,b1,[b2,b3,b4]})
    set(b2,'Callback',{@switchRadio3,b2,[b1,b3,b4]})
    set(b3,'Callback',{@switchRadio3,b3,[b1,b2,b4]})
    set(b4,'Callback',{@switchRadio3,b4,[b1,b2,b3]})
    set(a3,'Callback',{@switchRadio3,a3,a4})
    set(a4,'Callback',{@switchRadio3,a4,a3})
    
    return
end

if assign==12 % mesh polygon
    handles.AssignButton.String='Apply';
    hp.Title='Subdivide polygon';
    hp.Position=[0.055 0.6 0.17 0.35];
    MAXSIZE = cad_getUnitSt(handles.units,'length','Maximum size (%s)');
    uicontrol('parent',hp,'Style','text','String',MAXSIZE          ,'tag','uicontrol','BackgroundColor','w','units','normalized',           'position',[0.05 0.80 0.6  0.1] ,'HorizontalAlignment','left','value',0);
    
    maxSize = min([round(mean(diff(handles.ax.XTick))/2),round(mean(diff(handles.ax.YTick))/2)]);
    st2 = sprintf('%g',maxSize);
    uicontrol('parent',hp,'Style','text','String',num2str(leg),'tag','uicontrol','visible','off');
    uicontrol('parent',hp,'Style','checkbox','String','Cuts based on lines','tag','uicontrol','BackgroundColor','w','units','normalized','position',[0.05 0.50 0.80  0.1] ,'HorizontalAlignment','left');
    uicontrol('parent',hp,'Style','checkbox','String','Cuts based on points','tag','uicontrol','BackgroundColor','w','units','normalized','position' ,[0.05 0.65 0.80  0.1] ,'HorizontalAlignment','left');
    uicontrol('parent',hp,'Style','edit','String',st2,'tag','uicontrol','BackgroundColor',[1 1 0.7],'units','normalized',                'position' ,[0.70 0.80 0.25 0.1]);
    
    return
end

if assign==13 % mesh polygon
    handles.AssignButton.String='Apply';
    hp.Title='Remove Assignments';
    hp.Position=[0.055 0.6 0.17 0.35];
    uicontrol('parent',hp,'Style','checkbox','String','Frame end releases' ,'tag','uicontrol','BackgroundColor','w','units','normalized','position' ,[0.05 0.27 0.80 0.1] ,'HorizontalAlignment','left');
    uicontrol('parent',hp,'Style','checkbox','String','Element loads'      ,'tag','uicontrol','BackgroundColor','w','units','normalized','position' ,[0.05 0.38 0.80 0.1] ,'HorizontalAlignment','left');
    uicontrol('parent',hp,'Style','checkbox','String','Joint loads'      ,'tag','uicontrol','BackgroundColor','w','units','normalized','position'   ,[0.05 0.49 0.80 0.1] ,'HorizontalAlignment','left');
    uicontrol('parent',hp,'Style','checkbox','String','Joint constraints'  ,'tag','uicontrol','BackgroundColor','w','units','normalized','position' ,[0.05 0.60 0.80 0.1] ,'HorizontalAlignment','left');
    uicontrol('parent',hp,'Style','checkbox','String','Joint displacements','tag','uicontrol','BackgroundColor','w','units','normalized','position' ,[0.05 0.71 0.80 0.1] ,'HorizontalAlignment','left');
    uicontrol('parent',hp,'Style','checkbox','String','Joint restraints'   ,'tag','uicontrol','BackgroundColor','w','units','normalized','position' ,[0.05 0.82 0.80 0.1] ,'HorizontalAlignment','left');
    return
end

function []=switchRadio3(hObject,eventdata,b1,bs)

switch b1.Value
    case 0,b1.Value=1;
    case 1,set(bs,'value',0)
end

end

function[]=SectionEdit(hObject,handles,listbox,E)

set(E,'BackgroundColor',[1 1 0.7],'enable','on')
load tempsect vsect
vsect(listbox.Value).status=0;
vsect(listbox.Value)
save tempsect vsect
end

function[]=SectionCopy(hObject,handles,listbox,E)

newStr = listbox.String{listbox.Value};
str    = [listbox.String;newStr];
listbox.String=str;

load tempsect vsect
newsect        = vsect(listbox.Value);
newsect.id     = ceil(max(abs(vertcat(vsect.id))))+1;
newsect.status = 0;
vsect          = [vsect;newsect];
save tempsect vsect

set(E,'BackgroundColor',[1 1 0.7],'enable','on')
listbox.Value=numel(vsect);
set(E(1),'String',newsect.label);
set(E(2),'String',newsect.values(1));
set(E(3),'String',newsect.values(2));
set(E(4),'String',newsect.values(3));
set(E(5),'String',newsect.height);
end

function[]=SectionDelete(hObject,handles,listbox,E)

load tempsect vsect
if numel(vsect)>1
    vsect(listbox.Value)=[];
    save tempsect vsect
    
    listbox.Value  = 1;
    listbox.String = {vsect.label};
    
    % update E's
    sect   = vsect(1);
    set(E(1),'String',sect.label);
    set(E(2),'String',sect.values(1));
    set(E(3),'String',sect.values(2));
    set(E(4),'String',sect.values(3));
    set(E(5),'String',sect.height);
end
end

function[]=list_CallBack(hObject,eventdata,listbox,E)

if strcmp(E(1).Enable,'on')
    set(E,'BackgroundColor',[1 1 1],'enable','inactive')
    load tempsect vsect
    val = find(vertcat(vsect.status)==0);
    
    ButtonName = questdlg('Update section parameters?', ...
        'FEMGUI', ...
        'Yes', 'No', 'Yes');
    
    vsect(val).status = 1;
    if strcmp(ButtonName,'Yes')
        vsect(val).label  = E(1).String;
        vsect(val).values = [str2double(E(2).String),str2double(E(3).String),str2double(E(4).String)];
        vsect(val).height = str2double(E(5).String);
        listbox.String    = {vsect.label};
        save tempsect vsect
    end
    
end


load tempsect vsect
val    = hObject.Value;
sect   = vsect(val);
set(E(1),'String',sect.label);
set(E(2),'String',sect.values(1));
set(E(3),'String',sect.values(2));
set(E(4),'String',sect.values(3));
set(E(5),'String',sect.height);
end

function[]=SectionImport(hObject,eventdata,listbox)

[filename, pathname, filterindex] = uigetfile('*.txt','Pick a file');
if filterindex==0,return;end
fname=fullfile(pathname,filename);
fid = fopen(fname);
data = textscan(fid,'%s','delimiter','\n');
data = data{1};
fclose(fid);
data = prep2read(data);
data = regexp(data,'\ ','split');
header = data{1};

cur_un = [contains(header{3},'(mm2)');
    contains(header{3},'(cm2)');
    contains(header{3},'(m2)');
    contains(header{3},'(in2)');
    contains(header{3},'(ft2)')];
fig    = hObject.Parent.Parent.Parent;
units  = findall(fig,'tag','units');
unstr  = units.String{units.Value};
new_un = [contains(unstr,', mm,');
    contains(unstr,', cm,');
    contains(unstr,', m,');
    contains(unstr,', in,');
    contains(unstr,', ft,')];
LEN   = [10, 1, 1/100, 50/127, 25/762]';
a_LEN     = LEN(new_un) / LEN(cur_un);

data   = vertcat(data{2:end});
label  = data(:,2);
value  = str2double(data(:,3:6));
load tempsect vsect
TAG  = ceil(max(abs(vertcat(vsect.id))))+1;
Nsect = height(data);
newsect(1:Nsect,1)=cad_CreateObj(3);
for i=1:Nsect
    newsect(i).id     = TAG;
    newsect(i).label  = label{i};
    newsect(i).mat    = 1;
    newsect(i).values = value(i,1:3).*[a_LEN^2 a_LEN^4 a_LEN^4];
    newsect(i).height = value(i,4)*a_LEN;
    newsect(i).status = 1;
    TAG = TAG+1;
end
vsect=[vsect;newsect];
listbox.String={vsect.label};
save tempsect vsect
end

function update_lineparam(hObject,eventdata,caller,labelpop,typepop,A,Ix,Iy,sections) %#ok<*INUSD>
Type      = {sections.type}';
TypeVal   = typepop.String{typepop.Value};

IND       = ismember(Type,TypeVal);
subtable  = sections(IND,:);
Label     = {subtable.label};
labelpop.Enable='on';

if caller==2
    labelpop.Value=1;
    labelpop.String=Label;
end
val       = labelpop.Value;
A.String  = subtable(val).values(1);
Ix.String = subtable(val).values(2);
Iy.String = subtable(val).values(3);
set([A,Ix,Iy],'Enable','inactive','BackgroundColor',[1 1 1])



end

function setfix(~,~,X,Y,RZ,val1,val2,val3)
X.Value  = val1;
Y.Value  = val2;
RZ.Value = val3;
end

function updateMethod(hObject,eventdata,ref,cont,t1,t2,un)

if cont.Value==1
    switch ref.Value
        case 1
            t1.String=cad_getUnitSt(un,'force/length','q1 (%s)');
            t2.String=cad_getUnitSt(un,'force/length','q2 (%s)');
        case 2
            t1.String=cad_getUnitSt(un,'force/length','qx (%s)');
            t2.String=cad_getUnitSt(un,'force/length','qy (%s)');
    end
else
    switch ref.Value
        case 1
            t1.String=cad_getUnitSt(un,'force','P1 (%s)');
            t2.String=cad_getUnitSt(un,'force','P2 (%s)');
        case 2
            t1.String=cad_getUnitSt(un,'force','Px (%s)');
            t2.String=cad_getUnitSt(un,'force','Py (%s)');
    end
end

end

function[data]=prep2read(data)

% Converts char arrays to cell
if ischar(data)
    data=cellstr(data);
end

% remove spacer "|"
data = strrep(data,'|','');

% removes multiple spaces
data=regexprep(data,'	',' ');
data=regexprep(data,' +',' ');

% removes comments
ind = strfind(data,'#');
ise = cellfun(@isempty,ind);
pos = find(~ise);
ind(ise)=[];
for i=1:size(ind,1)
    II = ind{i}(1);
    data{pos(i)}(II:end)=[];
end

% remove trailing spaces
data=strtrim(data);

% removes empty lines
a=cellfun(@isempty,data);data(a,:)=[];
end

function T=test_edge_constraint(cons,fem)

% checks that edge constraint is well posed
% T = false if all the slavenodes belong to corners from the master edges
% T = true otherwise, i.e., at least one node does not belong to master edges

nlist = cons.slave;
elist = cons.master;

% remove from nlist any corner node
n_tria = zeros(0,4);
n_quad = zeros(0,4);
if fem.nElements(2)
    n_tria      = fem.tri31(:,[2:4 2]);
end

if fem.nElements(3)
    n_quad = fem.quad(:,2:5);
end
nodes_elem = [n_quad;n_tria];
edges      = nodes_elem(elist,:);
b          = ismember(nlist,edges);
T          = ~all(b);

end