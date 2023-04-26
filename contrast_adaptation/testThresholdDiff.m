% add tools to path
addpath(genpath('~/Documents/code/toolboxes/pfcmp'));
addpath(genpath('~/Documents/code/toolboxes/psignifit'));

path = 'data/'; %where is the data? 

dFile = {'RW.test.151006.mat', 'RW.test.165456.mat', 'RW.test.153831.mat', ...
         'RW.test.154036.mat', 'RW.test.082126.mat'};

[allTrials, params, n] = loadResults(path, dFile);

%%
whichFreq = 5;

for iAdapt = 1:n.Adapt
    nTrials = zeros(1, n.Cont); 
    perCorr = zeros(1, n.Cont);
    
    data{iAdapt} = zeros(n.Cont, 3);
    for iCont = 1:n.Cont
        theseTrials = allTrials.Adapt == params.Adapt(iAdapt) & ...
                      allTrials.Conts == params.Cont(iCont)  & ...
                      allTrials.Freqs == params.Freq(whichFreq); 
        if sum(theseTrials) > 0
            trialInds = find(theseTrials == 1);
            nTrials(iCont) = length(trialInds); 
            perCorr(iCont) = sum(allTrials.Resps(trialInds));
        end
    end

    data{iAdapt} = [log(params.Cont)' ...
                    perCorr' ...
                   nTrials']; % note that the contrast list is log transformed

end
%%
[sFull, sSlim] = pfcmp(data{1}, data{2});