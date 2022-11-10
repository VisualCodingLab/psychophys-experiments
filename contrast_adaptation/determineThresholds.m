% This code uses the psignifit toolbox: https://github.com/wichmann-lab/psignifit

path = '~/Desktop/stimdev/';
% this is a list of all the files you want to combine
dFile = {'2022/11/07/IHT.test.150754.mat', ...
         '2022/11/07/IHT.test.152405.mat'};

allResps = [];
allFreqs = [];
allConts = [];

% combine relevant trial-related information across files
for iFile = 1:length(dFile)
    load([path dFile{iFile}]);
    allResps = [allResps get(c.choice.prms.correct,'atTrialTime',Inf)'];
    allFreqs = [allFreqs c.inputs.freqFull];
    allConts = [allConts c.inputs.contrastFull];
end

%%
fList = unique(allFreqs); nFreq = length(fList);
cList = unique(allConts); nCont = length(cList); 

nTrials = cell(1, nFreq); 
perCorr = cell(1, nFreq); 

% loop through the frequency and contrast conditions and calculate the
% number of trials for each, and the percent correct.
for iFreq = 1:nFreq
    nTrials{iFreq} = zeros(1, nCont); 
    perCorr{iFreq} = zeros(1, nCont);
    for iCont = 1:nCont
        theseTrials = allFreqs == fList(iFreq) & ...
                      allConts == cList(iCont); 
        nTrials{iFreq}(iCont) = sum(theseTrials); 
        perCorr{iFreq}(iCont) = sum(allResps(theseTrials));
    end
end
    
% set up some of the options for the analysis    
options.sigmoidName = 'norm';   % choose a cumulative Gaussian as the sigmoid
options.expType     = '2AFC';   % choose 2-AFC as the paradigm of the experiment
                                % this sets the guessing rate to .5 and
                                % fits the rest of the parameters

threshTable = nan(nFreq, 4);
                                
figure(1); clf;
for iFreq = 1:nFreq % analyse each frequency separately
    subplot(1,nFreq, iFreq);
    data = [log(cList') perCorr{iFreq}' nTrials{iFreq}']; % note that the contrast list is log transformed
    result = psignifit(data,options);
    plotPsych(result);
    
    thresh = exp(result.Fit(1));
    ciu = exp(result.conf_Intervals(1,1,3));
    cil = exp(result.conf_Intervals(1,2,3));

    % put thresholds and confidence intervals in a table for further
    % analysis
    threshTable(iFreq,1) = fList(iFreq);
    threshTable(iFreq,2) = thresh; 
    threshTable(iFreq,3) = ciu;
    threshTable(iFreq,4) = cil;
    
    txt = sprintf('%1.1f cpd: %3.3f (%3.3f, %3.3f)', ...
                fList(iFreq), thresh, ciu, cil);
    title(txt);        
end