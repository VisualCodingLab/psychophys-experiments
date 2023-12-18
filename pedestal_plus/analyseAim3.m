%% Specify and load the data
clear all; close all; clc

subject = 'EK'; 
background = 'off'; 
path = '~/Desktop/data/Aim3/';
B = 10; %how many simulations for bootstrapping

sList = {'QQ', 'QV', 'OY', 'EK'};


% loop through all the subjects for a given background condition
for iSubj = 1:length(sList)
    
    subject = sList{iSubj};
    
    switch subject
        case 'QV'
            switch background 
                case 'off'
                    dFile = {'QV.PhaseComboGabor.153458.mat'};
                case 'on'
                    dFile = {'QV.PhaseComboGabor.092847.mat'};
            end
        case 'QQ'
            switch background 
                case 'off'
                    dFile = {'QQ.PhaseComboGabor.094629.mat'};
                case 'on'
                    dFile = {'QQ.PhaseComboGabor.121551.mat','QQ.PhaseComboGabor.124306.mat',...
                             'QQ.PhaseComboGabor.131643.mat'};
            end
        case 'OY'
            switch background 
                case 'off'
                    dFile = {'OY.PhaseComboGabor.131512.mat'};
                case 'on'
                    dFile = {'OY.PhaseComboGabor.090921.mat','OY.PhaseComboGabor.102235.mat',...
                             'OY.PhaseComboGabor.105723.mat'};
            end
        case 'EK'
            switch background 
                case 'off'
                    dFile = {'EK.PhaseComboGabor.101926.mat'};
                case 'on'
                    dFile = {'EK.PhaseComboGabor.113645.mat','EK.PhaseComboGabor.112324.mat',...
                             'EK.PhaseComboGabor.114737.mat'};
            end
    end
    
    % handle the file loading
    [allTrials, params, n] = loadResults(path, dFile);
    
    % Collect trials by condition
    for iPhase = 1:n.Phase

        nTrials{iPhase} = zeros(1, n.Cont); 
        perCorr{iPhase} = zeros(1, n.Cont);
        
        for iCont = 1:n.Cont % select trials by contrast & phase
            theseTrials = allTrials.Conts == params.Cont(iCont)  & ...
                          allTrials.Phases == params.Phase(iPhase); 

            if sum(theseTrials) > 0 % if there were trials
                trialInds = find(theseTrials == 1);
                nTrials{iPhase}(iCont) = length(trialInds); % count them
                perCorr{iPhase}(iCont) = sum(allTrials.Resps(trialInds)); % how many were correct?
            end
        end
    end
    
    StimLevels = [params.Cont; params.Cont];              %contrasts/levels

    % Fit psychometric functions
    PF = @PAL_Weibull;  %fit with a Weibull function
   
    % prepare data structure for outputs
    thresholds = table('Size', [n.Phase 6], ...
                       'VariableNames', ['Phase', "Thresh", "slope", "SE_thresh", "SE_slope", "p_val"], ...
                       'VariableTypes', ["double", "double", "double", "double", "double", "double"]);
    
    % where to look for the initial parameters
    searchGrid.alpha = 0.01:0.002:0.05;    %structure defining grid to
    searchGrid.beta = 0.5:0.1:10; %search for initial values
    searchGrid.gamma = 0.3:0.025:0.6;
    searchGrid.lambda = 0:0.002:0.05;

    % look for starting condition for phase = 0. 
    [paramsfixed_0,~,~,~] = PAL_PFML_Fit(StimLevels(1,:), ...
                perCorr{1}, nTrials{1}, searchGrid, [1 1 0 1], PF);

    for iPhase = 1:n.Phase % go through phase conditions

        % we're comparing each phase to the baseline phase = 0. 
        %            [data for p0; data for this cond]
        OutOfNum   = [nTrials{1}; nTrials{iPhase}];    %number of trials
        NumPos     = [perCorr{1}; perCorr{iPhase}];    %number correct
        
        % look for starting parameters for this conditon 
        [paramsfixed,~,~,~] = PAL_PFML_Fit(StimLevels(2,:), ...
                    NumPos(2,:), OutOfNum(2,:), searchGrid, [1 1 0 1], PF);

        % ---------- do the model comparison        
        % paramsL - fit the "lesser" model with 2-parameters (Threshold + Slope shared between conds)
        % paramsF - fit the "full" model, with 4-parameters (i.e. Threshold
        % can vary between the two conditions, so we have Thresh1&2 + Slope1&2
        [TLR, pTLR, paramsL, paramsF, TLRSim, converged] = ...
            PAL_PFLR_ModelComparison(StimLevels, NumPos, OutOfNum, ...
            [paramsfixed_0; paramsfixed], B, PF, ...
               'fullerThresholds', 'unconstrained', ...
               'fullerSlopes', 'unconstrained');
           
        % estimate the variability of the parameters of the fuller model
        [SD, ~,~,~] = ...
            PAL_PFML_BootstrapNonParametricMultiple(StimLevels, NumPos, ...
            OutOfNum, paramsF, B, PF); 
        
        % put the outputs of interest in our data structure
        if ~isempty(pTLR)
            thresholds(iPhase,:) = {params.Phase(iPhase), paramsF(2,1),paramsF(2,2), SD(2,1),SD(2,2) pTLR};
        else 
            thresholds(iPhase,:) = {params.Phase(iPhase),nan, nan, nan, nan};
        end

        % ---------- make some plots
        figure(iSubj); %put each observer's psychometric functions in a new figure
        StimLevelsFine = linspace(StimLevels(1),StimLevels(end),100);
        pModelL = PF(paramsL(1,:),StimLevelsFine);
        for a = 1:2
            pModelF(a,:) = PF(paramsF(a,:),StimLevelsFine);
        end
        
        subplot(1, n.Phase, iPhase)
        semilogx(StimLevels', NumPos'./OutOfNum','--o')
        hold on
        titleString = sprintf('%s, p=%1.3f', ...
            subject, pTLR);
        if ~isempty(pTLR)
            semilogx(StimLevelsFine, pModelL,'m')
            semilogx(StimLevelsFine, pModelF,'k')
        end
        title(titleString)
        if iPhase == 1
           ylabel('Prop. Correct'); 
           xlabel('Contrast');
        end
    end

    % --- summarise thresholds
    figure(length(sList)+1);
    subplot(2,2,iSubj); 
    threshElev = thresholds.Thresh/(thresholds.Thresh(1)); % calculate threshold elevation
    SEElev = thresholds.SE_thresh/(thresholds.Thresh(1));         % calculate SE in units of threshold elevation
    SEnorm = sqrt(SEElev(1)^2+SEElev.^2);                  % combine standard errors
    thresholds.threshElev = threshElev; 
    thresholds.SEnorm = SEnorm; 

    errorbar(thresholds.Phase, threshElev, SEnorm, 'o-'); hold on;
    isSig = thresholds.p_val < 0.05;
    plot(thresholds.Phase(isSig), threshElev(isSig)+0.1, '*'); 
    plot([0 180], [1 1], '--k');
    xlabel('Phase (deg)'); ylabel('Threshold Elevation'); 
    title([subject ', bg = ' background]);

     % --- summarise slopes
    figure(length(sList)+2); 
    subplot(2,2,iSubj);  
    errorbar(thresholds.Phase, thresholds.slope, thresholds.SE_slope, 'o-'); hold on;
    plot(thresholds.Phase(isSig), thresholds.slope(isSig)+2, '*'); 
    plot([0 180],  thresholds.slope(1)*ones(1,2), '--k');
    xlabel('Phase (deg)'); ylabel('Slope'); 
    title([subject ', bg = ' background]);
    
    allResults.(sList{iSubj}) = thresholds;
end