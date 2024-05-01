vis_joint = handles.DisplayNodes.Checked;
vis_line  = handles.DisplayLines.Checked;
vis_area  = handles.DisplayAreas.Checked;
vis_fix   = handles.DispJointRestraintsMenu.Checked;

ch1 = findall(handles.ax,'tag','point');
ch2 = findall(handles.ax,'tag','point_deformed');
if vis_joint
    ch1.EdgeColor = [0 0 0];
    ch1.MarkerFaceColor = [0 0 0];
    ch2.MarkerFaceColor='none';
    ch2.MarkerEdgeColor='none';
else
    ch2.EdgeColor='none';
end

ch1 = findall(handles.ax,'tag','area');
ch2 = findall(handles.ax,'tag','area_deformed');
if vis_line
    ch1.EdgeColor=[0 0.7490 0.7490]; ch1.FaceColor = [0.8500    0.3250    0.0980];
    ch2.EdgeColor='none'; ch2.FaceColor='none';
else
    
    ch2.EdgeColor='none'; ch2.FaceColor='none';
end

ch1 = findall(handles.ax,'tag','line');
ch2 = findall(handles.ax,'tag','line_deformed');
if vis_line
    ch1.EdgeColor=[0.5000 0.6000 1];
    ch2.EdgeColor='none';
else
    ch2.EdgeColor='none';
end

ch1 = findall(handles.ax,'tag','fix');
ch2 = findall(handles.ax,'tag','fix_deformed');

if vis_fix
    ch1.Color=[0 0 0];
    ch2.Color='none';
else
    ch2.Color='none';
end



