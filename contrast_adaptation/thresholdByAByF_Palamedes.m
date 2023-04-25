clear

path = '~/Desktop/Data/';
% % this is a list of all the files you want to combine
dFile =  {};

% {'RW.test.151006.mat', 'RW.test.165456.mat', 'RW.test.153831.mat',... 
%  'RW.test.154036.mat', 'RW.test.082126.mat', 'RW.test.155613.mat'};
% {'QQ.test.111124.mat', 'QQ.test.105904.mat', 'QQ.test.121354.mat',...
%  'QQ.test.113827.mat', 'QQ.test.132633.mat', 'QQ.test.103253.mat'}
% {'QV.test.132208.mat', 'QV.test.141506.mat', 'QV.test.141618.mat',...
%  'QV.test.104437.mat', 'QV.test.135940.mat', 'QV.test.132027.mat'}

% withPhaseRev
% {'RW.test.142237.mat', 'RW.test.155852.mat'};
% {'OY.test.093927.mat', 'OY.test.121812.mat', 'OY.test.124203.mat',... 
%  'OY.test.141628.mat', 'OY.test.143447.mat'};  
% {'QV.test.110012.mat', 'QV.test.113624.mat', 'QV.test.091652.mat'};
% {'QQ.test.120206.mat', 'QQ.test.131240.mat'};


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

% get the data in the correct format
cList = unique(allConts); nCont = length(cList); 
aList = unique(allAdapt); nAdapt = length(aList); 
fList = unique(allFreqs); nFreq = length(fList); 

for iAdapt = 1:nAdapt
    thresholds{iAdapt} = table('Size', [nFreq 4], ...
                       'VariableNames', ["SF", "Thresh", "SE", "p-val"], ...
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
    end
end

%% Make the no-adapt v adapt comparisons at each frequency

PF = @PAL_Weibull;         
paramsValues = [0.02 1 0.5 0]; % entries 3+4 are guess/lapse rate - these are fixed to 0
B = 1000; % should really be 1000 or more. Using 100 cause it's faster.
figure(1); clf;
for iFreq = 1:nFreq
    StimLevels = [cList; cList];                  %contrasts/levels
    OutOfNum   = [nTrials{1, iFreq}; nTrials{2, iFreq}];    %number of trials
    NumPos     = [perCorr{1, iFreq}; perCorr{2, iFreq}];    %number correct
    
    % paramsL - fit the "lesser" model with 2-parameters (Threshold + Slope)
    % paramsF - fit the "full" model, with 3-parameters (i.e. Threshold
    % can vary between the two conditions, so we have Thresh1 + Thresh2 + Slope
    [TLR, pTLR, paramsL, paramsF, TLRSim, converged] = ...
        PAL_PFLR_ModelComparison(StimLevels, NumPos, OutOfNum, ...
        paramsValues, B, PF,'fullerSlopes','unconstrained'); 
    
    [SD paramsSim LLSim converged] = ...
        PAL_PFML_BootstrapNonParametricMultiple(StimLevels, NumPos, ...
        OutOfNum, paramsF, B, PF, 'fullerSlopes','constrained'); 

    StimLevelsFine = linspace(StimLevels(1),StimLevels(end),100);
    pModelL = PF(paramsL(1,:),StimLevelsFine);
    
    for a = 1:2
        pModelF(a,:) = PF(paramsF(a,:),StimLevelsFine);
        
        thresholds{a}(iFreq,:) = {fList(iFreq),paramsF(a,1), SD(a,1), pTLR};
    end
    
    subplot(1, nFreq, iFreq)
    semilogx(StimLevels', NumPos'./OutOfNum','-o')
    hold on
    semilogx(StimLevelsFine, pModelL,'m')
    semilogx(StimLevelsFine, pModelF,'k')
    title(['p=' num2str(pTLR)])
    if iFreq == 1
       ylabel('Prop. Correct'); 
       xlabel('Contrast');
    end

end
%
