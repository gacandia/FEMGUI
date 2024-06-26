SS=get(0,'screensize');
handles.figure1.Position(1:2)=(SS(3:4)-handles.figure1.Position(3:4))/2;
handles.Lock.Open   = imread('LockOpen.jpg');
handles.Lock.Closed = imread('LockClosed.jpg');

% Enable/Dissable groups
handles.Disable=[...
    handles.ReplicateMenu;...
    handles.MoveMenu;...
    handles.StretchMenu;...
    handles.FrameSectionMenu;...
    handles.DeleteSelectionMenu;...
    handles.DrawPointToolbar;...
    handles.DrawPolyLineToolbar;...
    handles.DrawAreaToolbar;...
    handles.DrawPolygoneToolbar;...
    handles.AutoDrawToolbar;...
    handles.DeleteSelectionToolbar;...
    handles.SubdivideToolbar;...
    handles.AssignMenu];

handles.Enable = handles.PrintMenu;

% setup GSV (gui state variables)
uicontrol('parent',handles.figure1,...
    'position',[9 25 140 154],...
    'style','listbox',...
    'string',{'0 1 0 1','Bending Moment','sigma xx'},...
    'tag','gsv',...
    'visible','off');