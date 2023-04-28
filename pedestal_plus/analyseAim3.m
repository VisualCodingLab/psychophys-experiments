%% Specify and load the data
clear all; clc

subject = 'QV'; %contrastsBg | contrasts | nTrials
background = 'off'; 

path = '~/Desktop/Data/Aim 3/';

switch subject
    case 'QV'
        switch background 
            case 'off'
                dFile = {'QV.PhaseComboGabor.102804.mat','QV.PhaseComboGabor.153458.mat' };
            case 'on'
                error('no files');
        end
    case 'QQ'
        switch background 
            case 'off'
                error('no files');
            case 'on'
                error('no files');
        end
    otherwise 
        error('Unknown subject');
end

[allTrials, params, n] = loadResults(path, dFile);
%% Collect trials by condition

for iPhase = 1:n.Phase
    
    nTrials{iPhase} = zeros(1, n.Cont); 
    perCorr{iPhase} = zeros(1, n.Cont);
    for iCont = 1:n.Cont
        theseTrials = allTrials.Conts == params.Cont(iCont)  & ...
                      allTrials.Phases == params.Phase(iPhase); 
        if sum(theseTrials) > 0
            trialInds = find(theseTrials == 1);
            nTrials{iPhase}(iCont) = length(trialInds); 
            perCorr{iPhase}(iCont) = sum(allTrials.Resps(trialInds));
        end
    end
end

%% Fit psychometric function
% ["SF", 'Phase', "Thresh", "SE", "p-val"]

figure(1); clf; figure(2); clf;
PF = @PAL_Weibull;         
paramsValues = [0.05 3 0.5 0.01]; % entries 3+4 are guess/lapse rate 
B = 100;
StimLevels = [params.Cont; params.Cont];              %contrasts/levels
thresholds = table('Size', [n.Phase 4], ...
                   'VariableNames', ['Phase', "Thresh", "SE", "p-val"], ...
                   'VariableTypes', ["double", "double", "double", "double"]);

for iPhase = 1:n.Phase
      
    OutOfNum   = [nTrials{1}; nTrials{iPhase}];    %number of trials
    NumPos     = [perCorr{1}; perCorr{iPhase}];    %number correct

    % paramsL - fit the "lesser" model with 2-parameters (Threshold + Slope)
    % paramsF - fit the "full" model, with 3-parameters (i.e. Threshold
    % can vary between the two conditions, so we have Thresh1 + Thresh2 + Slope
    [TLR, pTLR, paramsL, paramsF, TLRSim, converged] = ...
        PAL_PFLR_ModelComparison(StimLevels, NumPos, OutOfNum, ...
        paramsValues, B, PF,'fullerSlopes','constrained', ...
        'lesserLapserates', 'unconstrained'); 
    
    [SD, paramsSim, LLSim, converged] = ...
        PAL_PFML_BootstrapNonParametricMultiple(StimLevels, NumPos, ...
        OutOfNum, paramsF, B, PF); 
    
    StimLevelsFine = linspace(StimLevels(1),StimLevels(end),100);
    pModelL = PF(paramsL(1,:),StimLevelsFine);

    for a = 1:2
        pModelF(a,:) = PF(paramsF(a,:),StimLevelsFine);
    end
    
    thresholds(iPhase,:) = {params.Phase(iPhase), paramsF(2,1), SD(2,1), pTLR};
    

    subplot(1, n.Phase, iPhase)
    semilogx(StimLevels', NumPos'./OutOfNum','-o')
    hold on
    semilogx(StimLevelsFine, pModelL,'m')
    semilogx(StimLevelsFine, pModelF,'k')
    title(['p=' num2str(pTLR)])
    if iPhase == 1
       ylabel('Prop. Correct'); 
       xlabel('Contrast');
    end
end