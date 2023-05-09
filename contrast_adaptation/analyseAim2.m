%% Specify and load the data
clear all; close all; clc

sList = {'QQ', 'QV'}; 
path = '~/Desktop/Data/Aim 2/';
B = 100; % should really be 1000 or more. Using 100 cause it's faster.


for iSubj = 1:length(sList)
    subject = sList{iSubj};
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
    
    % Organise the trials by condition of interest
    for iAdapt = 1:n.Adapt
        thresholds{iAdapt} = table('Size', [n.Freq*n.Phase 5], ...
                       'VariableNames', ["SF", 'Phase', "Thresh", "SE", "p_val"], ...
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

    % Perform fits
    PF = @PAL_Weibull;         
    paramsValues = [0.01 3 0.5 0.02]; % entries 3+4 are guess/lapse rate 

    figure(iSubj); clf;

    ind = 1; 

    for iFreq = 1:n.Freq
    for iPhase = 1:n.Phase
        StimLevels = [params.Cont; params.Cont];                                %contrasts/levels
        OutOfNum   = [nTrials{1, iFreq, iPhase}; nTrials{2, iFreq, iPhase}];    %number of trials
        NumPos     = [perCorr{1, iFreq, iPhase}; perCorr{2, iFreq, iPhase}];    %number correct

        % paramsL - fit the "lesser" model with 2-parameters (Threshold + Slope)
        % paramsF - fit the "full" model, with 3-parameters (i.e. Threshold
        % can vary between the two conditions, so we have Thresh1 + Thresh2 + Slope
        [TLR, pTLR, paramsL, paramsF, TLRSim, ~] = ...
            PAL_PFLR_ModelComparison(StimLevels, NumPos, OutOfNum, ...
            paramsValues, B, PF,'fullerSlopes','constrained', ...
            'lesserLapserates', 'unconstrained'); 

        [SD, paramsSim, LLSim, ~] = ...
            PAL_PFML_BootstrapNonParametricMultiple(StimLevels, NumPos, ...
            OutOfNum, paramsF, B, PF); 
        
        StimLevelsFine = linspace(StimLevels(1),StimLevels(end),100);
        
        for a = 1:2
            pModelF(a,:) = PF(paramsF(a,:),StimLevelsFine);
            thresholds{a}(ind,:) = {params.Freq(iFreq),params.Phase(iPhase), paramsF(a,1), SD(a,1), pTLR};
        end

        pModelL = PF(paramsL(1,:),StimLevelsFine);
        
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
    
cList = {'r', 'b'};
lStyle = {':', '-'}; 
aCond = {'no-adapt', 'adapt'};
% --- show all thresholds
figure(length(sList)+1);
subplot(1,2,iSubj);
lList = {}; lInd = 1; 

for iAdapt = 1:2
    for iFreq = 1:length(params.Freq)
        lList{lInd} = sprintf('%s, %1.1fcpd',aCond{iAdapt}, params.Freq(iFreq)); 
        
        theseConds = thresholds{1}.SF == params.Freq(iFreq);
        pList(lInd) = errorbar(thresholds{1}.Phase(theseConds),...
                 thresholds{iAdapt}.Thresh(theseConds),...
                 thresholds{iAdapt}.SE(theseConds), 'o', ...
                 'LineWidth', 1, 'LineStyle', lStyle{iAdapt}, ...
                 'Color', cList{iFreq}); hold on;

        isSig = thresholds{1}.p_val < 0.05;
        lInd = lInd + 1;
        if iAdapt == 2
            plot(thresholds{1}.Phase(isSig&theseConds), thresholds{iAdapt}.Thresh(isSig&theseConds), ...
                '*', 'MarkerSize', 8, 'LineWidth', 2, 'Color', cList{iFreq}); 
        end
    end
end
legend(pList, lList); 
xlabel('Phase (deg)'); ylabel('Thresholds'); 
title(subject);


% --- summarise thresholds in terms of elevation
figure(length(sList)+2);
subplot(1,2,iSubj); 
threshElev = thresholds{2}.Thresh./(thresholds{1}.Thresh); % calculate threshold elevation
SEElev_adapt   = thresholds{1}.SE./(thresholds{1}.Thresh);         % calculate SE in units of threshold elevation
SEElev_noadapt = thresholds{2}.SE./(thresholds{1}.Thresh);         % calculate SE in units of threshold elevation
SEnorm = sqrt(SEElev_adapt.^2+SEElev_noadapt.^2);                  % combine standard errors
thresholds{2}.threshElev = threshElev; 
thresholds{2}.SEnorm = SEnorm; 


for iFreq = 1:length(params.Freq)
    theseConds = thresholds{1}.SF == params.Freq(iFreq);
    errorbar(thresholds{1}.Phase(theseConds),...
             threshElev(theseConds),...
             SEnorm(theseConds), 'o-', 'Color', cList{iFreq}, ...
             'LineWidth', 1); hold on;
    
    isSig = thresholds{1}.p_val < 0.05;
    plot(thresholds{1}.Phase(isSig&theseConds), threshElev(isSig&theseConds), ...
        '*', 'MarkerSize', 8, 'LineWidth', 2, 'Color', cList{iFreq}); 
end

xlabel('Phase (deg)'); ylabel('Threshold Elevation'); 
title(subject);

allResults.(sList{iSubj}) = thresholds;
end