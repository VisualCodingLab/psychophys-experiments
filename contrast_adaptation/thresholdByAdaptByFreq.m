clear

path = '~/Desktop/Data/';
% % this is a list of all the files you want to combine
dFile =  

% {'QV.test.132208.mat', 'QV.test.141506.mat', 'QV.test.141618.mat', ...
% 'QV.test.104437.mat'}

% {'RW.test.151006.mat', 'RW.test.165456.mat', 'RW.test.153831.mat', ...
% 'RW.test.154036.mat', 'RW.test.082126.mat', 'RW.test.155613.mat'};

% {'QQ.test.111124.mat', 'QQ.test.105904.mat', 'QQ.test.121354.mat', ... 
% 'QQ.test.113827.mat', 'QQ.test.132633.mat', 'QQ.test.103253.mat'}

allResps = [];
allConts = [];
allAdapt = [];
allFreqs = [];

% combine relevant trial-related information across files
for iFile = 1:length(dFile)
    load([path dFile{iFile}]);
    tmp = get(c.choice.prms.correct,'atTrialTime',Inf)';
    if iscell(tmp) % convert to array if cell array (this can happen with early-abort)
        tmp = cellfun(@(x) islogical(x)&&x, tmp);
    end
    allResps = [allResps tmp];
    allConts = [allConts get(c.gabor_test.prms.contrast, 'atTrialTime', Inf)'];
    allFreqs = [allFreqs get(c.gabor_test.prms.frequency, 'atTrialTime', Inf)'];
    allAdapt = [allAdapt get(c.gL_adapt.prms.contrast, 'atTrialTime', Inf)'];
end
%%


cList = unique(allConts); nCont = length(cList); 
aList = unique(allAdapt); nAdapt = length(aList); 
fList = unique(allFreqs); nFreq = length(fList); 

% set up some of the options for the analysis    
options.sigmoidName = 'norm';   % choose a cumulative Gaussian as the sigmoid
options.expType     = '2AFC';   % choose 2-AFC as the paradigm of the experiment
                                % this sets the guessing rate to .5 and
                                % fits the rest of the parameters
                                

                   
plotInd = 1;
for iAdapt = 1:nAdapt
    thresholds{iAdapt} = table('Size', [nFreq 4], ...
                       'VariableNames', ["SF", "Thresh", "95CIU", "95CIL"], ...
                       'VariableTypes', ["double", "double", "double", "double"]);
                   
    for iFreq = 1:nFreq
        nTrials{iAdapt, iFreq} = zeros(1, nCont); 
        perCorr{iAdapt, iFreq} = zeros(1, nCont);
        for iCont = 1:nCont
            theseTrials = allAdapt == aList(iAdapt) & ...
                          allConts == cList(iCont)  & ...
                          allFreqs == fList(iFreq); 
            if sum(theseTrials) > 0
                trialInds = find(theseTrials == 1);
                nTrials{iAdapt, iFreq}(iCont) = length(trialInds); 
                perCorr{iAdapt, iFreq}(iCont) = sum(allResps(trialInds));
            end
        end



        data = [log(cList') perCorr{iAdapt, iFreq}' nTrials{iAdapt, iFreq}']; % note that the contrast list is log transformed
        data = data(logical(nTrials{iAdapt, iFreq}), :); % remove values with no trials 
        [nVals, ~] = size(data); 
        
        if nVals > 3
            result = psignifit(data,options);
            subplot(nAdapt,nFreq, plotInd);
            plotInd = plotInd + 1;
            plotPsych(result);
            
            thresh = result.Fit(1);
            ciu = result.conf_Intervals(1,1,3);
            cil = result.conf_Intervals(1,2,3);
            
            thresholds{iAdapt}(iFreq,:) = {fList(iFreq),1/thresh, 1/ciu, 1/cil};
            
        end
    end
end

    