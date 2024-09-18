%% Specify and load the data
clear all; clc;

subject = 'QQ';
background = 'off'; %on/off
threshMode = 'original'; %original/target35
path = 'data/';

switch threshMode
    case 'original'
        path= sprintf('%soriginal/', path);

    case 'target35'
        path= sprintf('%starget35/', path);
end

% B = 100; %how many simulations for bootstrapping

sList = {'CI', 'YQ'};     % {'CI', 'YQ', 'QV'};


% loop through all the subjects for a given background condition
for iSubj = 1:length(sList)

    subject = sList{iSubj};

    switch subject
        case 'CI'
            switch threshMode
                case 'original'

                    dFile = {'CI.PhaseComboGabor.142353.mat', 'CI.PhaseComboGabor.144736.mat', ...
                        'CI.PhaseComboGabor.151346.mat', 'CI.PhaseComboGabor.155600.mat'};

                case 'target35'
                    dFile = {'CI.PhaseComboGabor.162054.mat', 'CI.PhaseComboGabor.180747.mat', ...
                        'CI.PhaseComboGabor.122510.mat', 'CI.PhaseComboGabor.135311.mat'};

            end


        case 'YQ'
            switch threshMode
                case 'original'
                    dFile = {'YQ.PhaseComboGabor.113004.mat', 'YQ.PhaseComboGabor.114847.mat',  ...
                        'YQ.PhaseComboGabor.164019.mat', 'YQ.PhaseComboGabor.162130.mat'};


                case 'target35'
                    dFile = {'YQ.PhaseComboGabor.165923.mat', ...
                        'YQ.PhaseComboGabor.171917.mat', 'YQ.PhaseComboGabor.164518.mat', ...
                        'YQ.PhaseComboGabor.170640.mat'};
            end


        case 'QV'
            switch threshMode
                case 'target35'
                    dFile = {'QV.PhaseComboGabor.125233.mat', 'QV.PhaseComboGabor.130651.mat', ...
                        'QV.PhaseComboGabor.155957.mat'};

            end

    end

    if ~isempty(dFile)
        for iFile = 1:length(dFile)
            load([path dFile{iFile}], 'c');

            a = zeros(sum(c.staircaseIndexes)-length(c.staircaseIndexes), 1);
            b = zeros(size(a));

            switch threshMode
                case 'original'
                    pCond = unique(cell2mat(c.gabor_test.prms.phase.log));

                case 'target35'
                    pCond = unique(cell2mat(c.gabor_test3.prms.phase.log));
            end

            phases = NaN(sum(c.staircaseIndexes), 1);
            contrasts= NaN(sum(c.staircaseIndexes), 1);

            c.staircaseIndexes

            c.staircaseResults(~isnan(c.staircaseResults))

            c.blocks(1, 1).designs.factorSpecs

            count = 1;
            for i=1:length(c.staircaseIndexes)
                for j=1:c.staircaseIndexes(i)-1
                    phases(count)= pCond(i);
                    contrasts(count)=c.staircaseResults(i,j);
                    count = count + 1;
                end
            end

            figNum = 1;



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
            peak2peak(ph) = max(f3) - min(f3);
            rms(ph) = std(f3);
        end


        % --- summarise thresholds
        figure(figNum);
        subplot(2,length(sList),iSubj);
        threshElev = testThresh/refThresh; % calculate threshold elevation (thresholds are "thresh" in new code)
        sterrorElev = var(thresh/refThresh)/sqrt(size(thresh, 1));  % calculate SE in units of threshold elevation
        SEnorm = sqrt(sterrorElev(1)^2+sterrorElev.^2);                  % combine standard errors

        % errorbar(pCond, threshElev, SEnorm, 'o-'); hold on;

        plot(pCond, threshElev, 'LineWidth', 2); hold on;
        plot([0 180], [1 1], '--k');
        xlabel('Phase (deg)'); ylabel('Threshold Elevation');
        title([subject ', bg = ' background]);


        subplot(2,length(sList),iSubj+length(sList))
        [x, ~] = meshgrid(1:size(thresh, 2), 1:size(thresh, 1));
        plot(x(:), thresh(:)/refThresh ,'o');
    end
end
