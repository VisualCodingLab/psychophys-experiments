%analyseAim3_prelim
%% Specify and load the data
clear all; clc

test = 'nTrials'; %contrastsBg | contrasts | nTrials


path = '~/Desktop/Data/Aim3 Prelim/';
switch test
    case 'contrasts'
        dFile = {'test.test.134422.mat'};
    case 'contrastsBg'
        dFile = {'test.test.141328.mat'};
    case 'nTrials'
        dFile = {'test.test.120847.mat'};
end

[allTrials, params, n] = loadResults(path, dFile);

%% Organise the trials by condition

switch test
    case 'nTrials'
        
        for iCont = 1:n.Cont
            theseTrials = allTrials.Conts == params.Cont(iCont); 
            if sum(theseTrials) > 0
                trialInds = find(theseTrials == 1);
                rByC{iCont} = allTrials.Resps(trialInds);
            end
        end
    case {'contrasts', 'contrastsBg'}
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
    otherwise
        warning('Nothing to do - unknown test');
end

%% Analyse data 

figure(1); clf; figure(2); clf;
PF = @PAL_Weibull;         
paramsValues = [0.05 3 0.5 0.01]; % entries 3+4 are guess/lapse rate 

%for testing necessary contrast range
lowStart = 3; %this indexes the lowest contrast
highEnd = 2;  %this is the number of contrasts in from the highest
switch test 
    case 'nTrials'
        StimLevels = params.Cont(lowStart:end-highEnd); 
        fprintf('%i Contrast levels\n', length(StimLevels));
        countList = 10:2:300;
        plotList = 30:90:360;
        threshList = nan(1, length(countList));
        ind = 1;
        for iCount = 1:length(countList)
            nTrials    = countList(iCount); 
            OutOfNum   = nTrials*ones(size(StimLevels));    %number of trials
            NumPos     = cellfun(@(x) sum(x(50:50+nTrials) == 1), rByC);    %number correct
            %NumPos     = cellfun(@(x) sum(x(randsample(1:360, nTrials)) == 1), rByC);    %number correct
            NumPos     = NumPos(lowStart:end-highEnd); 
            
            [paramsFit, LL, scenario, output] = PAL_PFML_Fit(StimLevels, ...
                NumPos, OutOfNum, paramsValues, [1 1 0 0], PF);
            threshList(iCount) = paramsFit(1); 
            StimLevelsFine = linspace(StimLevels(1),StimLevels(end),100);
            if ismember(countList(iCount), plotList)
                figure(1);
                subplot(1, length(plotList), ind)
                ind = ind+1;
                semilogx(StimLevels', NumPos'./OutOfNum','-o')
                hold on
                semilogx(StimLevelsFine, PF(paramsFit, StimLevelsFine),'k')
                tString = sprintf('nTrials=%i, Thresh=%1.3f',nTrials,paramsFit(1));
                title(tString);
                   ylabel('Prop. Correct'); 
                   xlabel('Contrast');
            end
        
        end
        figure(2); plot(countList,threshList, '-o'); hold on;
        plot([0  360], mean(threshList)*ones(1,2), '--k');
        legend;
        
    case {'contrasts', 'contrastsBg'}
    	StimLevels = params.Cont(lowStart:end-highEnd);                 %contrasts/levels
        
        for iPhase = 1:n.Phase
            OutOfNum   = nTrials{iPhase}(lowStart:end-highEnd);    %number of trials
            NumPos     = perCorr{iPhase}(lowStart:end-highEnd);    %number correct
            
            [paramsFit, LL, scenario, output] = PAL_PFML_Fit(StimLevels, ...
                NumPos, OutOfNum, paramsValues, [1 1 0 1], PF);
            
            StimLevelsFine = linspace(StimLevels(1),StimLevels(end),100);

            subplot(1, n.Phase, iPhase)
            semilogx(StimLevels', NumPos'./OutOfNum','-o')
            hold on
            semilogx(StimLevelsFine, PF(paramsFit, StimLevelsFine),'k')
            tString = sprintf('Phase=%i, Thresh=%1.3f',params.Phase(iPhase),paramsFit(1));
            title(tString);
            if iPhase == 1
               ylabel('Prop. Correct'); 
               xlabel('Contrast');
            end
        end

    otherwise
        warning('Nothing to do - unknown test');
end
        

