function outputModel = build_model_layout_auto_comp10()
%BUILD_MODEL_LAYOUT_AUTO_COMP10 仅整理 AutoComp9 的层次、位置和接线。
root = fileparts(fileparts(mfilename('fullpath')));
sourceFile = fullfile(root,'AI6109_MOA_AutoComp9.slx');
outputFile = fullfile(root,'AI6109_MOA_AutoComp10.slx');
sourceModel = 'AI6109_MOA_AutoComp9';
outputModel = 'AI6109_MOA_AutoComp10';
assert(isfile(sourceFile),'build_model_layout:MissingSource','缺少 %s',sourceFile);
if bdIsLoaded(sourceModel), close_system(sourceModel,0); end
if bdIsLoaded(outputModel), close_system(outputModel,0); end
copyfile(sourceFile,outputFile,'f');
load_system(outputModel);
cleanup = onCleanup(@() close_if_loaded(outputModel));

% 先为跨层级信号命名，createSubsystem 将据此命名自动端口。
signalMap = { ...
    'uA','uA'; 'uB','uB'; 'uC','uC'; ...
    'iA_R_true','iA_R'; 'iB_R_true','iB_R'; 'iC_R_true','iC_R'; ...
    'iA_total','iA_total'; 'iB_total','iB_total'; 'iC_total','iC_total'; ...
    'Cs1_true','Cs1_true'; 'Cs2_true','Cs2_true'; ...
    'iA_R_raw','iA_R_raw'; 'iB_R_raw','iB_R_raw'; 'iC_R_raw','iC_R_raw'};
for k = 1:size(signalMap,1)
    name_workspace_source(outputModel,signalMap{k,1},signalMap{k,2});
end

% 根级外部接口保持原名称和端口号；插入纯直通的动态 Cs 输入子系统。
inputBlocks = ordered_root_inports(outputModel);
inputNames = cellfun(@(p) get_param(p,'Name'),inputBlocks,'UniformOutput',false);
inputSubsystem = [outputModel '/Dynamic Coupling Capacitance'];
add_block('simulink/Ports & Subsystems/Subsystem',inputSubsystem, ...
    'Position',[205 85 425 310]);
clear_subsystem(inputSubsystem);
for k = 1:numel(inputBlocks)
    y = 45+45*(k-1);
    add_block('simulink/Ports & Subsystems/In1', ...
        [inputSubsystem '/' inputNames{k}], ...
        'Port',num2str(k),'Position',[35 y 65 y+14]);
    add_block('simulink/Ports & Subsystems/Out1', ...
        [inputSubsystem '/' inputNames{k} '_out'], ...
        'Port',num2str(k),'Position',[180 y 210 y+14]);
    add_line(inputSubsystem,[inputNames{k} '/1'],[inputNames{k} '_out/1'], ...
        'autorouting','on');
end
insert_pass_through(outputModel,inputBlocks,inputSubsystem,inputNames);

% 将现有计算块原样包入功能子系统，不改变 MATLAB Function 内容。
dynamicBlock = find_system(outputModel,'SearchDepth',1,'Name','DynamicLeakageCurrentModel');
calcSubsystem = group_blocks(outputModel,dynamicBlock, ...
    'Coupling Current Calculation and Total Leakage Current');
add_note(calcSubsystem, ...
    sprintf(['Internal variables:\n' ...
    'iA_coupling, iB_coupling, iC_coupling\n' ...
    'Outputs: iA_total, iB_total, iC_total']),[35 20 335 75]);

% 所有 To Workspace 块收纳到统一测量子系统，变量名完全保留。
workspaceBlocks = find_system(outputModel,'SearchDepth',1,'BlockType','ToWorkspace');
measurementSubsystem = group_blocks(outputModel,workspaceBlocks,'Measurement and Output');

% 电压源保持独立；其余原物理网络和 MOA 模块归入 MOA 子系统。
sourceBlock = find_system(outputModel,'SearchDepth',1,'Name','Three-Phase Programmable Voltage Source');
assert(isscalar(sourceBlock),'build_model_layout:VoltageSource','无法唯一定位三相电压源。');
set_param(sourceBlock{1},'Name','Three-Phase Voltage Source');
sourceBlock = {[outputModel '/Three-Phase Voltage Source']};
powergui = find_system(outputModel,'SearchDepth',1,'Name','powergui');
terminate_unused_measurements(outputModel);
allRoot = find_system(outputModel,'SearchDepth',1,'Type','Block');
exclude = [{outputModel}; inputBlocks(:); {inputSubsystem}; {calcSubsystem}; ...
    {measurementSubsystem}; sourceBlock(:); powergui(:)];
physicalBlocks = setdiff(allRoot,exclude,'stable');
moaSubsystem = group_blocks(outputModel,physicalBlocks,'MOA Model');
add_note(moaSubsystem, ...
    sprintf(['Three-phase nonlinear MOA and self-capacitance network\n' ...
    'Legacy fixed-coupling branches are retained internally at 1e-18 F']), ...
    [25 15 385 65]);
internalize_unconnected_outputs(moaSubsystem);

% 仅用于记录的旁路使用少量 Goto/From，保留六路主输出的直连数据流。
compact_measurement_branches(outputModel,measurementSubsystem, ...
    {'Cs1_true','Cs2_true','uA','uB','uC', ...
    'iA_R_raw','iB_R_raw','iC_R_raw'});

% 统一主界面布局。只改 Position，不改任何功能参数。
set_param([outputModel '/Three-Phase Voltage Source'],'Position',[70 390 250 505]);
set_param(moaSubsystem,'Position',[340 350 575 545]);
set_param(calcSubsystem,'Position',[820 225 1090 545]);
set_param(measurementSubsystem,'Position',[1210 260 1425 515]);
set_param(inputSubsystem,'Position',[340 70 575 280]);
set_param(inputSubsystem,'Orientation','right');
set_param(moaSubsystem,'Orientation','right');
set_param(calcSubsystem,'Orientation','right');
set_param(measurementSubsystem,'Orientation','right');
set_param(powergui{1},'Position',[70 585 190 625]);
for k = 1:numel(inputBlocks)
    y = 85+38*(k-1);
    set_param(inputBlocks{k},'Position',[65 y 230 y+22]);
end

% 子系统内部使用自动正交布局；主界面重新路由为直角线。
Simulink.BlockDiagram.arrangeSystem(inputSubsystem);
delete_dangling_lines(inputSubsystem);
Simulink.BlockDiagram.arrangeSystem(calcSubsystem);
Simulink.BlockDiagram.arrangeSystem(measurementSubsystem);
route_root_lines(outputModel);
name_subsystem_output_lines(calcSubsystem);

add_note(outputModel, ...
    'Dynamic inter-phase coupling model for MOA resistive-current extraction', ...
    [330 5 1000 35]);
add_note(outputModel, ...
    'Cs1/Cs2: time-varying inter-phase coupling capacitances', ...
    [340 45 850 68]);
add_note(outputModel, ...
    'Internal coupling components: iA_coupling, iB_coupling, iC_coupling', ...
    [815 185 1190 210]);

% 仅设置顶层展示图标，隐藏子系统内部预览；不执行初始化代码。
apply_presentation_mask(inputSubsystem,'Cs1_true(t)   Cs2_true(t)','lightBlue');
apply_presentation_mask(moaSubsystem,'MOA resistive + self-capacitive currents','lightBlue');
apply_presentation_mask(calcSubsystem, ...
    sprintf('Inter-phase coupling currents\nand total leakage currents'),'lightBlue');
apply_presentation_mask(measurementSubsystem,'Named signals / workspace outputs','lightBlue');

set_param(outputModel,'ShowPortDataTypes','off');
save_system(outputModel,outputFile);
clear cleanup;
close_system(outputModel,0);
fprintf('已生成结构整理版模型：%s\n',outputFile);
end

function blocks = ordered_root_inports(model)
blocks = find_system(model,'SearchDepth',1,'BlockType','Inport');
ports = cellfun(@(p) str2double(get_param(p,'Port')),blocks);
[~,order] = sort(ports);
blocks = blocks(order);
end

function insert_pass_through(model,inputBlocks,subsystem,inputNames)
subPorts = get_param(subsystem,'PortHandles');
for k = 1:numel(inputBlocks)
    inPorts = get_param(inputBlocks{k},'PortHandles');
    line = get_param(inPorts.Outport,'Line');
    destinations = get_param(line,'DstPortHandle');
    destinations = destinations(destinations>0);
    delete_line(line);
    add_line(model,inPorts.Outport,subPorts.Inport(k),'autorouting','on');
    for d = 1:numel(destinations)
        add_line(model,subPorts.Outport(k),destinations(d),'autorouting','on');
    end
    outLine = get_param(subPorts.Outport(k),'Line');
    set_param(outLine,'Name',display_signal_name(inputNames{k}));
end
end

function name = display_signal_name(portName)
switch portName
    case 'Cs1_true_pF', name='Cs1_true';
    case 'Cs2_true_pF', name='Cs2_true';
    otherwise, name=portName;
end
end

function subsystem = group_blocks(model,blocks,newName)
assert(~isempty(blocks),'build_model_layout:EmptyGroup','%s 分组为空。',newName);
before = find_system(model,'SearchDepth',1,'Type','Block');
handles = cell2mat(get_param(blocks,'Handle'));
Simulink.BlockDiagram.createSubsystem(handles);
after = find_system(model,'SearchDepth',1,'Type','Block');
created = setdiff(after,before,'stable');
created = created(cellfun(@(p) strcmp(get_param(p,'BlockType'),'SubSystem'),created));
assert(isscalar(created),'build_model_layout:GroupCreation','无法识别新建子系统 %s。',newName);
set_param(created{1},'Name',newName);
subsystem = [model '/' newName];
end

function clear_subsystem(path)
blocks = find_system(path,'SearchDepth',1,'Type','Block');
blocks = blocks(~strcmp(blocks,path));
for k = 1:numel(blocks), delete_block(blocks{k}); end
end

function name_workspace_source(model,variableName,signalName)
block = find_system(model,'SearchDepth',1,'BlockType','ToWorkspace', ...
    'VariableName',variableName);
assert(isscalar(block),'build_model_layout:WorkspaceSignal','无法唯一定位 %s。',variableName);
lineHandles = get_param(block{1},'LineHandles');
sourcePort = get_param(lineHandles.Inport,'SrcPortHandle');
line = get_param(sourcePort,'Line');
if line>0, set_param(line,'Name',signalName); end
end

function add_note(parent,text,position)
note = Simulink.Annotation(parent,text);
note.Position = position;
note.FontSize = 12;
end

function route_root_lines(model)
lines = find_system(model,'FindAll','on','SearchDepth',1,'Type','line');
for k = 1:numel(lines)
    if get_param(lines(k),'SrcPortHandle')>0
        Simulink.BlockDiagram.routeLine(lines(k));
    end
end
end

function terminate_unused_measurements(model)
blocks = find_system(model,'SearchDepth',1,'BlockType','SubSystem', ...
    'Name','Current Measurement*');
number = 0;
for k = 1:numel(blocks)
    ports = get_param(blocks{k},'PortHandles');
    if ~isempty(ports.Outport) && get_param(ports.Outport(1),'Line')<0
        number = number+1;
        position = get_param(blocks{k},'Position');
        terminator = [model '/Legacy_Current_Terminator_' num2str(number)];
        add_block('simulink/Sinks/Terminator',terminator, ...
            'Position',[position(3)+35 position(2) position(3)+55 position(2)+20]);
        termPorts = get_param(terminator,'PortHandles');
        add_line(model,ports.Outport(1),termPorts.Inport,'autorouting','on');
    end
end
end

function delete_dangling_lines(scope)
lines = find_system(scope,'FindAll','on','SearchDepth',1,'Type','line');
for k = 1:numel(lines)
    source = get_param(lines(k),'SrcPortHandle');
    destination = get_param(lines(k),'DstPortHandle');
    if source<0 && all(destination<0)
        delete_line(lines(k));
    end
end
end

function apply_presentation_mask(subsystem,label,color)
set_param(subsystem,'BackgroundColor',color,'ShowPortLabels','FromPortIcon');
mask = Simulink.Mask.get(subsystem);
if isempty(mask)
    mask = Simulink.Mask.create(subsystem);
end
mask.Display = sprintf('disp(''%s'');',strrep(label,newline,'\n'));
if isprop(mask,'IconOpaque'), mask.IconOpaque = 'opaque'; end
if isprop(mask,'IconFrame'), mask.IconFrame = 'on'; end
end

function internalize_unconnected_outputs(subsystem)
outer = get_param(subsystem,'PortHandles');
outports = find_system(subsystem,'SearchDepth',1,'BlockType','Outport');
portNumbers = cellfun(@(p) str2double(get_param(p,'Port')),outports);
[~,order] = sort(portNumbers,'descend');
for n = 1:numel(order)
    idx = order(n);
    portNumber = str2double(get_param(outports{idx},'Port'));
    if portNumber<=numel(outer.Outport) && ...
            get_param(outer.Outport(portNumber),'Line')<0
        position = get_param(outports{idx},'Position');
        lineHandles = get_param(outports{idx},'LineHandles');
        sourcePort = get_param(lineHandles.Inport,'SrcPortHandle');
        if lineHandles.Inport>0, delete_line(lineHandles.Inport); end
        delete_block(outports{idx});
        terminator = [subsystem '/Unused_Measurement_Terminator_' num2str(portNumber)];
        add_block('simulink/Sinks/Terminator',terminator,'Position',position);
        terminatorPorts = get_param(terminator,'PortHandles');
        add_line(subsystem,sourcePort,terminatorPorts.Inport,'autorouting','on');
    end
end
end

function compact_measurement_branches(model,subsystem,variables)
for k = 1:numel(variables)
    sink = find_system(subsystem,'SearchDepth',1,'BlockType','ToWorkspace', ...
        'VariableName',variables{k});
    assert(isscalar(sink),'build_model_layout:MeasurementVariable', ...
        '无法唯一定位记录变量 %s。',variables{k});
    sinkLines = get_param(sink{1},'LineHandles');
    innerSource = get_param(sinkLines.Inport,'SrcPortHandle');
    inport = get_param(innerSource,'Parent');
    portNumber = str2double(get_param(inport,'Port'));
    outer = get_param(subsystem,'PortHandles');
    rootDestination = outer.Inport(portNumber);
    rootLine = get_param(rootDestination,'Line');
    rootSource = get_param(rootLine,'SrcPortHandle');

    tag = ['LOG_' variables{k}];
    gotoPosition = measurement_goto_position(variables{k});
    gotoPath = [model '/Goto_' variables{k}];
    add_block('simulink/Signal Routing/Goto',gotoPath, ...
        'GotoTag',tag,'TagVisibility','global','ShowName','off', ...
        'Position',gotoPosition);
    gotoPorts = get_param(gotoPath,'PortHandles');
    add_line(model,rootSource,gotoPorts.Inport,'autorouting','on');

    innerPosition = get_param(inport,'Position');
    delete_line(model,rootSource,rootDestination);
    delete_line(sinkLines.Inport);
    delete_block(inport);
    fromPath = [subsystem '/From_' variables{k}];
    add_block('simulink/Signal Routing/From',fromPath, ...
        'GotoTag',tag,'ShowName','off','Position',innerPosition);
    fromPorts = get_param(fromPath,'PortHandles');
    sinkPorts = get_param(sink{1},'PortHandles');
    add_line(subsystem,fromPorts.Outport,sinkPorts.Inport,'autorouting','on');
end
end

function position = measurement_goto_position(variable)
names = {'Cs1_true','Cs2_true','uA','uB','uC', ...
    'iA_R_raw','iB_R_raw','iC_R_raw'};
y = [100 135 360 390 420 455 485 515];
index = find(strcmp(names,variable),1);
assert(~isempty(index),'build_model_layout:GotoPosition','未知记录信号 %s。',variable);
position = [625 y(index) 735 y(index)+18];
end

function name_subsystem_output_lines(subsystem)
outer = get_param(subsystem,'PortHandles');
outports = find_system(subsystem,'SearchDepth',1,'BlockType','Outport');
for k = 1:numel(outports)
    portNumber = str2double(get_param(outports{k},'Port'));
    if portNumber<=numel(outer.Outport)
        line = get_param(outer.Outport(portNumber),'Line');
        if line>0, set_param(line,'Name',get_param(outports{k},'Name')); end
    end
end
end

function close_if_loaded(model)
if bdIsLoaded(model), close_system(model,0); end
end
