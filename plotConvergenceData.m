function plotConvergenceData(pathName)

% Function plots all reward convergence files in a directory

fileList = dir(pathName);

% Remove directories
isFile = ~[fileList.isdir];
fileList = fileList(isFile);

numFiles = length(fileList);

for i = 1:numFiles
    
    [~,~,ext] = fileparts(fileList(i).name);
    if (~strcmp(ext,'.mat'));
        continue;
    end
    
    figure(1); hold on;
    data = load([fileList(i).folder,'/',fileList(i).name]);
    plot(movmean(data.agent.rewardHistory,200));
    
end % for i

end % function