clear

path = '~/Desktop/stimdev/';
% % this is a list of all the files you want to combine
dFile = {'2022/11/22/QQ.test.124919.mat'};

allResps = [];
allConts = [];
allAdapt = [];

% combine relevant trial-related information across files
for iFile = 1:length(dFile)
    load([path dFile{iFile}]);
    allResps = [allResps get(c.choice.prms.correct,'atTrialTime',Inf)'];
    allConts = [allConts get(c.gabor_test.prms.contrast, 'atTrialTime', Inf)'];
    allAdapt = [allAdapt get(c.gL_adapt.prms.contrast, 'atTrialTime', Inf)'];
end

if iscell(allResps) % convert to array
    allResps = cellfun(@(x) islogical(x)&&x, allResps);
end

cList = unique(allConts); nCont = length(cList); 
aList = unique(allAdapt); nAdapt = length(aList); 

% set up some of the options for the analysis    
options.sigmoidName = 'norm';   % choose a cumulative Gaussian as the sigmoid
options.expType     = '2AFC';   % choose 2-AFC as the paradigm of the experiment
                                % this sets the guessing rate to .5 and
                                % fits the rest of the parameters

for iAdapt = 1:nAdapt
    nTrials{iAdapt} = zeros(1, nCont); 
    perCorr{iAdapt} = zeros(1, nCont);
    for iCont = 1:nCont
        theseTrials = allAdapt == aList(iAdapt) & ...
                      allConts == cList(iCont); 
        if sum(theseTrials) > 0
            trialInds = find(theseTrials == 1);
            nTrials{iAdapt}(iCont) = length(trialInds); 
            perCorr{iAdapt}(iCont) = sum(allResps(trialInds));
        end
    end
    
    
    
    data = [log(cList') perCorr{iAdapt}' nTrials{iAdapt}']; % note that the contrast list is log transformed
    data = data(logical(nTrials{iAdapt}), :); % remove values with no trials 
    
    result = psignifit(data,options);
    subplot(1,2, iAdapt);
    plotPsych(result);
end

    