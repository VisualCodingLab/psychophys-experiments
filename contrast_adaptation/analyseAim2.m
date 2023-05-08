%% Specify and load the data
clear all; clc

subject = 'QQ'; 


path = '~/Desktop/Data/Aim 2/';
switch subject
    case 'QV'
        dFile = {'QV.test.141911.mat', ...
                 'QV.test.114927.mat', ...
                 'QV.test.094750.mat', ...
                 'QV.test.143447.mat', ...
                 'QV.test.144834.mat'};
    case 'QQ'
        dFile = {'QQ.test.115445.mat', ...
                 'QQ.test.103116.mat', ...
                 'QQ.test.111849.mat', ...
                 'QQ.test.111439.mat', ...
                 'QQ.test.102818.mat'};
             

end

[allTrials, params, n] = loadResults(path, dFile);
%% Organise the trials by condition of interest
for iAdapt = 1:n.Adapt
    thresholds{iAdapt} = table('Size', [n.Freq*n.Phase 5], ...
                   'VariableNames', ["SF", 'Phase', "Thresh", "SE", "p-val"], ...
                   'VariableTypes', ["double", "double", "double", "double", "double"]);
    for iFreq = 1:n.Freq
    for iPhase = 1:n.Phase 
        nTrials{iAdapt, iFreq, iPhase} = zeros(1, n.Cont); 
        perCorr{iAdapt, iFreq, iPhase} = zeros(1, n.Cont);
        for iCont = 1:n.Cont
            if params.Adapt(iAdapt) == 1 % separate phase for adaptation
                theseTrials = allTrials.Adapt == params.Adapt(iAdapt) & ...
                              allTrials.Conts == params.Cont(iCont)  & ...
                              allTrials.Freqs == params.Freq(iFreq) & ...
                              allTrials.Phases == params.Phase(iPhase); 
            else % pool phases in no-adapt condition
                theseTrials = allTrials.Adapt == params.Adapt(iAdapt) & ...
                              allTrials.Conts == params.Cont(iCont)  & ...
                              allTrials.Freqs == params.Freq(iFreq);
            end
            if sum(theseTrials) > 0
                trialInds = find(theseTrials == 1);
                nTrials{iAdapt, iFreq, iPhase}(iCont) = length(trialInds); 
                perCorr{iAdapt, iFreq, iPhase}(iCont) = sum(allTrials.Resps(trialInds));
            end
        end
    end %end phase loop
    end %end freq loop
end % end adapt loop

%% Perform fits
PF = @PAL_Weibull;         
paramsValues = [0.01 3 0.5 0.02]; % entries 3+4 are guess/lapse rate 
B = 1000; % should really be 1000 or more. Using 100 cause it's faster.

figure(1); clf;

ind = 1; 

for iFreq = 1:n.Freq
for iPhase = 1:n.Phase
    StimLevels = [params.Cont; params.Cont];                                %contrasts/levels
    OutOfNum   = [nTrials{1, iFreq, iPhase}; nTrials{2, iFreq, iPhase}];    %number of trials
    NumPos     = [perCorr{1, iFreq, iPhase}; perCorr{2, iFreq, iPhase}];    %number correct

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

        thresholds{a}(ind,:) = {params.Freq(iFreq),params.Phase(iPhase), 1/paramsF(a,1), SD(a,1), pTLR};
    end

    subplot(n.Freq, n.Phase, ind)
    semilogx(StimLevels', NumPos'./OutOfNum','-o')
    hold on
    semilogx(StimLevelsFine, pModelL,'m')
    semilogx(StimLevelsFine, pModelF,'k')
    title(['p=' num2str(pTLR)])
    if iFreq == 1
       ylabel('Prop. Correct'); 
       xlabel('Contrast');
    end
    ind = ind + 1;
end
end