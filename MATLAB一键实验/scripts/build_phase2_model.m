function outputModel = build_phase2_model()
%BUILD_PHASE2_MODEL 从 AutoComp8 可复现构建动态耦合模型 AutoComp9。
root = fileparts(fileparts(mfilename('fullpath')));
sourceFile = fullfile(root,'AI6109_MOA_AutoComp8.slx');
outputFile = fullfile(root,'AI6109_MOA_AutoComp9.slx');
sourceModel = 'AI6109_MOA_AutoComp8';
outputModel = 'AI6109_MOA_AutoComp9';
assert(isfile(sourceFile),'build_phase2_model:MissingSource','缺少 %s',sourceFile);
if bdIsLoaded(sourceModel), close_system(sourceModel,0); end
if bdIsLoaded(outputModel), close_system(outputModel,0); end
copyfile(sourceFile,outputFile,'f');
load_system(outputModel);
cleanup = onCleanup(@() close_if_loaded(outputModel));

source.uA = workspace_source(outputModel,'uA');
source.uB = workspace_source(outputModel,'uB');
source.uC = workspace_source(outputModel,'uC');
source.irA = workspace_source(outputModel,'iA_R_true');
source.irB = workspace_source(outputModel,'iB_R_true');
source.irC = workspace_source(outputModel,'iC_R_true');

inputNames = {'Cs1_true_pF','Cs2_true_pF','B_fault_scale','noiseA_A','noiseB_A','noiseC_A'};
for k = 1:numel(inputNames)
    y = 80+45*(k-1);
    add_block('simulink/Sources/In1',[outputModel '/' inputNames{k}], ...
        'Port',num2str(k),'Position',[1120 y 1230 y+22]);
end

template = find_system(outputModel,'SearchDepth',1,'Name','MATLAB Function');
equationPath = [outputModel '/DynamicLeakageCurrentModel'];
add_block(template{1},equationPath,'Position',[1320 70 1640 370]);
chart = chart_for_path(equationPath);
chart.Script = equation_script();
inputData = {'uA','uB','uC','iA_R_raw','iB_R_raw','iC_R_raw', ...
    'Cs1_pF','Cs2_pF','B_fault_scale','noiseA','noiseB','noiseC'};
outputData = {'iA_total','iB_total','iC_total','iA_R_true','iB_R_true','iC_R_true'};
for k = 1:numel(inputData), ensure_scope(chart,inputData{k},'Input',k); end
for k = 1:numel(outputData), ensure_scope(chart,outputData{k},'Output',k); end
ensure_scope(chart,'Ts_model','Parameter',NaN);
ensure_scope(chart,'Cself_pF','Parameter',NaN);
save_system(outputModel,outputFile);

branches = {'Series RLC Branch9','Series RLC Branch10','Series RLC Branch11','耦合电容'};
for k = 1:numel(branches)
    set_param([outputModel '/' branches{k}],'Capacitance','Ccoupling_disabled_F');
end
ports = get_param(equationPath,'PortHandles');
assert(numel(ports.Inport)==12 && numel(ports.Outport)==6, ...
    'build_phase2_model:Interface','动态电流模块端口数量异常。');
baseInputs = {source.uA,source.uB,source.uC,source.irA,source.irB,source.irC};
for k = 1:numel(baseInputs)
    add_line(outputModel,baseInputs{k},ports.Inport(k),'autorouting','on');
end
for k = 1:numel(inputNames)
    p = get_param([outputModel '/' inputNames{k}],'PortHandles');
    add_line(outputModel,p.Outport,ports.Inport(k+6),'autorouting','on');
end
replace_workspace_source(outputModel,'iA_total',ports.Outport(1));
replace_workspace_source(outputModel,'iB_total',ports.Outport(2));
replace_workspace_source(outputModel,'iC_total',ports.Outport(3));
replace_workspace_source(outputModel,'iA_R_true',ports.Outport(4));
replace_workspace_source(outputModel,'iB_R_true',ports.Outport(5));
replace_workspace_source(outputModel,'iC_R_true',ports.Outport(6));
add_workspace_sink(outputModel,'Cs1_true',port_of(inputNames{1}),[1690 390 1815 415]);
add_workspace_sink(outputModel,'Cs2_true',port_of(inputNames{2}),[1690 425 1815 450]);
add_workspace_sink(outputModel,'iA_R_raw',source.irA,[1690 500 1815 525]);
add_workspace_sink(outputModel,'iB_R_raw',source.irB,[1690 535 1815 560]);
add_workspace_sink(outputModel,'iC_R_raw',source.irC,[1690 570 1815 595]);
save_system(outputModel,outputFile);
clear cleanup;
close_system(outputModel,0);
fprintf('已生成 Phase 2 模型：%s\n',outputFile);

    function h = port_of(name)
        p = get_param([outputModel '/' name],'PortHandles'); h = p.Outport;
    end
end

function text = equation_script()
text = sprintf([ ...
    'function [iA_total,iB_total,iC_total,iA_R_true,iB_R_true,iC_R_true] = dynamic_current(uA,uB,uC,iA_R_raw,iB_R_raw,iC_R_raw,Cs1_pF,Cs2_pF,B_fault_scale,noiseA,noiseB,noiseC)\n' ...
    '%%#codegen\n' ...
    'persistent a1 b1 c1 a2 b2 c2 count\n' ...
    'if isempty(count), a1=uA; b1=uB; c1=uC; a2=uA; b2=uB; c2=uC; count=uint8(0); end\n' ...
    'if count==0\n' ...
    ' duA=0; duB=0; duC=0; count=uint8(1);\n' ...
    'elseif count==1\n' ...
    ' duA=(uA-a1)/Ts_model; duB=(uB-b1)/Ts_model; duC=(uC-c1)/Ts_model; count=uint8(2);\n' ...
    'else\n' ...
    ' duA=(3*uA-4*a1+a2)/(2*Ts_model); duB=(3*uB-4*b1+b2)/(2*Ts_model); duC=(3*uC-4*c1+c2)/(2*Ts_model);\n' ...
    'end\n' ...
    'a2=a1; b2=b1; c2=c1; a1=uA; b1=uB; c1=uC;\n' ...
    'iA_R_true=-iA_R_raw; iB_R_true=-B_fault_scale*iB_R_raw; iC_R_true=-iC_R_raw;\n' ...
    'Cs1=Cs1_pF*1e-12; Cs2=Cs2_pF*1e-12; Cself=Cself_pF*1e-12;\n' ...
    'iA_total=Cself*duA+Cs1*(duA-duB)+iA_R_true+noiseA;\n' ...
    'iB_total=Cself*duB+Cs1*(duB-duA)+Cs2*(duB-duC)+iB_R_true+noiseB;\n' ...
    'iC_total=Cself*duC+Cs2*(duC-duB)+iC_R_true+noiseC;\n' ...
    'end\n']);
end

function chart = chart_for_path(path)
root = sfroot; charts = root.find('-isa','Stateflow.EMChart');
chart = charts(arrayfun(@(x) strcmp(x.Path,path),charts));
assert(isscalar(chart),'build_phase2_model:Chart','无法定位动态电流 MATLAB Function。');
end

function ensure_scope(chart,name,scope,port)
data = chart.find('-isa','Stateflow.Data');
match = data(arrayfun(@(x) strcmp(x.Name,name),data));
if isempty(match), match = Stateflow.Data(chart); match.Name = name; end
match.Scope = scope;
if isfinite(port), match.Port = port; end
end

function sourcePort = workspace_source(model,name)
block = find_system(model,'SearchDepth',1,'BlockType','ToWorkspace','VariableName',name);
assert(isscalar(block),'build_phase2_model:Sink','无法唯一定位 %s。',name);
line = get_param(block{1},'LineHandles'); sourcePort = get_param(line.Inport,'SrcPortHandle');
end

function replace_workspace_source(model,name,sourcePort)
block = find_system(model,'SearchDepth',1,'BlockType','ToWorkspace','VariableName',name);
line = get_param(block{1},'LineHandles'); delete_line(line.Inport);
p = get_param(block{1},'PortHandles'); add_line(model,sourcePort,p.Inport,'autorouting','on');
end

function add_workspace_sink(model,name,sourcePort,position)
template = find_system(model,'SearchDepth',1,'BlockType','ToWorkspace');
path = [model '/ToWorkspace_' name];
add_block(template{1},path,'VariableName',name,'SaveFormat','Structure With Time','Position',position);
p = get_param(path,'PortHandles'); add_line(model,sourcePort,p.Inport,'autorouting','on');
end

function close_if_loaded(model)
if bdIsLoaded(model), close_system(model,0); end
end
