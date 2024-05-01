vis_joint = handles.DisplayNodes.Checked;
vis_line  = handles.DisplayLines.Checked;
vis_area  = handles.DisplayAreas.Checked;
vis_fix   = handles.DispJointRestraintsMenu.Checked;
WireFrame = strcmp(handles.DeformedWireFrameMenu.Checked,'on');

ch1 = findall(handles.ax,'tag','point');
ch2 = findall(handles.ax,'tag','point_deformed');
if vis_joint
    ch1.EdgeColor       = 'none';
    ch1.MarkerFaceColor = 'none';
    
    ch2.MarkerFaceColor=[0 0 0];
    ch2.MarkerEdgeColor = [0 0 0];
else
    ch1.EdgeColor='none';
    ch2.EdgeColor='none';
end

ch1 = findall(handles.ax,'tag','area');
ch2 = findall(handles.ax,'tag','area_deformed');
ch1.EdgeColor='none'; ch1.FaceColor='none';
if vis_line
    if WireFrame
        ch1.EdgeColor=[0.76 0.76 0.76];  ch1.FaceColor = [0.9 0.9 0.9];
    end
    ch2.EdgeColor=[0 0.7490 0.7490]; ch2.FaceColor = [0.8500    0.3250    0.0980];
else
    ch2.EdgeColor='none'; ch2.FaceColor='none';
end

ch1 = findall(handles.ax,'tag','line');
ch2 = findall(handles.ax,'tag','line_deformed');
ch1.EdgeColor='none';
if vis_line
    if WireFrame
        ch1.EdgeColor=[0.76 0.76 0.76];
    end
    ch2.EdgeColor=[0.5 0.6 1];
else
    ch2.EdgeColor='none';
end

ch1 = findall(handles.ax,'tag','fix');
ch2 = findall(handles.ax,'tag','fix_deformed');
ch1.Color='none';
if vis_fix
    if WireFrame
        ch1.Color=[0.76 0.76 0.76];
    end
    ch2.Color=[0 0 0];
else
    ch2.Color='none';
end
