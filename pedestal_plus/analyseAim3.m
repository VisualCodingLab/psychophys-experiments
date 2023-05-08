%% Specify and load the data
clear all; clc

subject = 'EK'; %contrastsBg | contrasts | nTrials
background = 'off'; 

path = '~/Desktop/Data/Aim 3/';

switch subject
    case 'QV'
        switch background 
            case 'off'
                dFile = {'QV.PhaseComboGabor.153458.mat','QV.PhaseComboGabor.160555.mat',...
                         'QV.PhaseComboGabor.095508.mat' };
            case 'on'
                dFile = {'QV.PhaseComboGabor.092847.mat','QV.PhaseComboGabor.094554.mat',...
                         'QV.PhaseComboGabor.102356.mat'};
        end
    case 'QQ'
        switch background 
            case 'off'
                dFile = {'QQ.PhaseComboGabor.094629.mat','QQ.PhaseComboGabor.113435.mat',...
                         'QQ.PhaseComboGabor.120804.mat' };
            case 'on'
                dFile = {'QQ.PhaseComboGabor.121551.mat','QQ.PhaseComboGabor.124306.mat',...
                         'QQ.PhaseComboGabor.131643.mat'};
        end
    case 'OY'
        switch background 
            case 'off'
                dFile = {'OY.PhaseComboGabor.131512.mat','OY.PhaseComboGabor.135004.mat',...
                         'OY.PhaseComboGabor.083535.mat' };
            case 'on'
                dFile = {'OY.PhaseComboGabor.090921.mat','OY.PhaseComboGabor.102235.mat',...
                         'OY.PhaseComboGabor.105723.mat'};
        end
    case 'EK'
        switch background 
            case 'off'
                dFile = {'EK.PhaseComboGabor.101926.mat','EK.PhaseComboGabor.105557.mat',...
                         'EK.PhaseComboGabor.111316.mat' };
            case 'on'
                dFile = {'EK.PhaseComboGabor.113645.mat','EK.PhaseComboGabor.112324.mat',...
                         'EK.PhaseComboGabor.114737.mat'};
        end
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
B = 1000;
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
    
    thresholds(iPhase,:) = {params.Phase(iPhase), 1/paramsF(2,1), SD(2,1), pTLR};
    

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