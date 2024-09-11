%% Specify and load the data
clear all; clc;

subject = 'QQ';
background = 'off'; %on/off
threshMode = 'discrim'; %discrim/detect
path = '';
% B = 100; %how many simulations for bootstrapping

sList = {'CI', 'YQ'};     % {'CI', 'YQ'};


% loop through all the subjects for a given background condition
for iSubj = 1:length(sList)

    subject = sList{iSubj};

    switch subject
        case 'CI'
            switch threshMode
                case 'detect'
                    dFile = { };


                case 'discrim'
                    dFile = {'CI.PhaseComboGabor.214419.mat'};
            end
        case 'YQ'
            switch threshMode
                case 'detect'
                    dFile = { };


                case 'discrim'
                    dFile = { };
            end

    end

    if ~isempty(dFile)
        for iFile = 1:length(dFile)
            load([path dFile{iFile}], 'c');

            switch threshMode
                case 'discrim'


                    a = zeros(sum(c.staircaseIndexes)-length(c.staircaseIndexes), 1);
                    b = zeros(size(a));


                    c.staircaseIndexes

                    c.staircaseResults(~isnan(c.staircaseResults))


                    contrasts = get(c.gabor_test.prms.contrast, 'atTrialTime', Inf);
                    phases = get(c.gabor_test.prms.phase, 'atTrialTime', Inf);
                    figNum = 1;

                case 'detect'
                    % contrasts = get(c.gabor_f1.prms.contrast, 'atTrialTime', Inf);
                    % phases = get(c.gabor_f3.prms.phase, 'atTrialTime', Inf);
                    % figNum = 2;
            end

            pCond = unique(cell2mat(c.gabor_test.prms.phase.log));

            if iFile == 1
                thresh = zeros(length(dFile), length(pCond));
            end

            for pInd = 1:length(pCond)
                lastContrast = find(phases == pCond(pInd), 1, 'last');
                thresh(iFile, pInd) = contrasts(lastContrast);
            end
        end

        figure(figNum);

        testThresh = mean(thresh, 1); % thresholds by condition
        refThresh = testThresh(1); % what condition is acting as reference
        sterror = var(thresh, 1); % calculate based on ests from different files

        % ---- digression: basic michelson contrast model
        pList = deg2rad(pCond);
        peak2peak = zeros(1,length(pList));
        rms = zeros(1, length(pList));
        x = 0:0.01:2*pi;
        for ph = 1:length(pList)
            f1 = sin(x);
            f2 = sin((x+pList(ph))*3);
            f3 = f1+f2*0.3;
            peak2peak(ph) = range(f3);
            rms(ph) = std(f3);
        end


        % --- summarise thresholds
        figure(figNum);
        subplot(2,2,iSubj);
        threshElev = testThresh/refThresh; % calculate threshold elevation (thresholds are "thresh" in new code)
        sterrorElev = var(thresh/refThresh)/sqrt(size(thresh, 1));  % calculate SE in units of threshold elevation
        SEnorm = sqrt(sterrorElev(1)^2+sterrorElev.^2);                  % combine standard errors

        % errorbar(pCond, threshElev, SEnorm, 'o-'); hold on;

        plot(pCond, threshElev, 'LineWidth', 2); hold on;
        plot([0 180], [1 1], '--k');
        xlabel('Phase (deg)'); ylabel('Threshold Elevation');
        title([subject ', bg = ' background]);


        subplot(2,2,iSubj+2)
        [x, ~] = meshgrid(1:size(thresh, 2), 1:size(thresh, 1));
        plot(x(:), thresh(:)/refThresh ,'o');
    end
end
