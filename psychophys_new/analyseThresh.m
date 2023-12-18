%% Specify and load the data
clear all; close all; clc

subject = 'QQ'; 
background = 'off'; 
path = '/home/marmolab/data/phaseCombo/';
% B = 100; %how many simulations for bootstrapping

sList = {'QQ', 'QV'};     % {'QQ', 'QV', 'OY', 'EK'};


% loop through all the subjects for a given background condition
for iSubj = 1:length(sList)
    
    subject = sList{iSubj};
    
    switch subject
        case 'QV'
            switch background 
                case 'off'
                    dFile = {'QV.PhaseComboGabor.133847.mat','QV.PhaseComboGabor.111144.mat',...
                             'QV.PhaseComboGabor.113014.mat','QV.PhaseComboGabor.114647.mat'};
                case 'on'
                    dFile = { };
            end
        case 'QQ'
            switch background 
                case 'off'
                    dFile = {'QQ.PhaseComboGabor.140229.mat','QQ.PhaseComboGabor.104635.mat',...
                             'QQ.PhaseComboGabor.111114.mat','QQ.PhaseComboGabor.114746.mat',...
                             'QQ.PhaseComboGabor.115540.mat','QQ.PhaseComboGabor.131116.mat',...
                             'QQ.PhaseComboGabor.132609.mat','QQ.PhaseComboGabor.140145.mat'};
                case 'on'
                    dFile = { }; 
            end

    end

    for iFile = 1:length(dFile)
        load([path dFile{iFile}], 'c');

        contrasts = get(c.gabor_test.prms.contrast, 'atTrialTime', Inf);
        phases = get(c.gabor_test.prms.phase, 'atTrialTime', Inf);

        pCond = unique(phases);
        if iFile == 1
           thresh = zeros(length(dFile), length(pCond)); 
        end

        for pInd = 1:length(pCond)
            lastContrast = find(phases == pCond(pInd), 1, 'last');
            thresh(iFile, pInd) = contrasts(lastContrast); 
        end
    end

    testThresh = mean(thresh, 1); % thresholds by condition
    refThresh = testThresh(1); % what condition is acting as reference
    sterror = var(thresh, 1); % calculate based on ests from different files 
    
    % --- summarise thresholds
    figure(1);
    subplot(2,2,iSubj); 
    threshElev = testThresh/refThresh; % calculate threshold elevation (thresholds are "thresh" in new code)
    sterrorElev = var(thresh/refThresh)/sqrt(size(thresh, 1));  % calculate SE in units of threshold elevation
    SEnorm = sqrt(sterrorElev(1)^2+sterrorElev.^2);                  % combine standard errors
   
    errorbar(pCond, threshElev, SEnorm, 'o-'); hold on;
  %  isSig = thresholds.p_val < 0.05;
  %  plot(thresholds.Phase(isSig), threshElev(isSig)+0.1, '*'); 
    plot([0 180], [1 1], '--k');
    xlabel('Phase (deg)'); ylabel('Threshold Elevation'); 
    title([subject ', bg = ' background]);
    
    
    subplot(2,2,iSubj+2)
    [x, ~] = meshgrid(1:size(thresh, 2), 1:size(thresh, 1));
    plot(x(:), thresh(:)/refThresh ,'o');
    
end
