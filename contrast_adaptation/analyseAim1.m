%% Find and load the data
clear all; clc; 
analyse = 'aim1_phaseRev'; % aim1 | aim1_phaseRev
subject = 'RW'; 

switch analyse
    case 'aim1'
        path = '~/Desktop/Data/Aim 1/';
        switch subject 
            case 'RW'
                dFile = {'RW.test.151006.mat', 'RW.test.165456.mat', 'RW.test.153831.mat',... 
                         'RW.test.154036.mat', 'RW.test.082126.mat', 'RW.test.155613.mat'};
            case 'QQ'
                dFile = {'QQ.test.111124.mat', 'QQ.test.105904.mat', 'QQ.test.121354.mat',...
                        'QQ.test.113827.mat', 'QQ.test.132633.mat', 'QQ.test.103253.mat'};
            case 'QV'
                dFile = {'QV.test.132208.mat', 'QV.test.141506.mat', 'QV.test.141618.mat',...
                         'QV.test.104437.mat', 'QV.test.135940.mat', 'QV.test.132027.mat'};
        end
       
    case 'aim1_phaseRev'
        path = '~/Desktop/Data/Aim 1 (w phaseRev)/';
        switch subject
            case 'RW'
                dFile = {'RW.test.142237.mat', 'RW.test.155852.mat'};
            case 'OY'
                dFile = {'OY.test.093927.mat', 'OY.test.121812.mat', 'OY.test.124203.mat',... 
                         'OY.test.141628.mat', 'OY.test.143447.mat'}; 
            case 'QV'
                dFile = {'QV.test.110012.mat', 'QV.test.113624.mat', 'QV.test.091652.mat'...
                         'QV.test.120514.mat', 'QV.test.093946.mat', 'QV.test.124757.mat'};
            case 'QQ'
                dFile = {'QQ.test.120206.mat', 'QQ.test.131240.mat', 'QQ.test.124719.mat'...
                         'QQ.test.125555.mat', 'QQ.test.94336.mat'};
        end
end

[allTrials, params, n] = loadResults(path, dFile);
%% Organise the trials by condition

for iAdapt = 1:n.Adapt
    thresholds{iAdapt} = table('Size', [n.Freq 4], ...
                       'VariableNames', ["SF", "Thresh", "SE", "p-val"], ...
                       'VariableTypes', ["double", "double", "double", "double"]);
    for iFreq = 1:n.Freq
            nTrials{iAdapt, iFreq} = zeros(1, n.Cont); 
            perCorr{iAdapt, iFreq} = zeros(1, n.Cont);
            for iCont = 1:n.Cont
                theseTrials = allTrials.Adapt == params.Adapt(iAdapt) & ...
                              allTrials.Conts == params.Cont(iCont)  & ...
                              allTrials.Freqs == params.Freq(iFreq); 
                if sum(theseTrials) > 0
                    trialInds = find(theseTrials == 1);
                    nTrials{iAdapt, iFreq}(iCont) = length(trialInds); 
                    perCorr{iAdapt, iFreq}(iCont) = sum(allTrials.Resps(trialInds));
                end
            end
    end
end

%% Fit the psychometric functions
PF = @PAL_Weibull;         
paramsValues = [0.01 3 0.5 0.02]; % entries 3+4 are guess/lapse rate 
B = 100; % should really be 1000 or more. Using 100 cause it's faster.


figure(1); clf;
for iFreq = 1:n.Freq
    StimLevels = [params.Cont; params.Cont];                 %contrasts/levels
    OutOfNum   = [nTrials{1, iFreq}; nTrials{2, iFreq}];    %number of trials
    NumPos     = [perCorr{1, iFreq}; perCorr{2, iFreq}];    %number correct

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
        if ~isempty(pTLR)
            thresholds{a}(iFreq,:) = {params.Freq(iFreq), 1/paramsF(a,1), ...
                                                std(1./paramsSim(:, a, 1)), pTLR};
        end
    end

    subplot(1, n.Freq, iFreq)
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
