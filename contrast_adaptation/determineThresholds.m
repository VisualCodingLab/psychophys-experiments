% This code uses the psignifit toolbox: https://github.com/wichmann-lab/psignifit


% data
% First we need the data in the format (x | nCorrect | total)
nLevels = 10;
x = logspace(-1.8, 0, nLevels);
nTrials = 30;
y = round([.5 .48 .51 .45 .55 .60 .65 .86 1.00 .98]*nTrials);

data = [x' y' ones(nLevels,1)*nTrials];


options.sigmoidName = 'norm';   % choose a cumulative Gaussian as the sigmoid
options.expType     = '2AFC';   % choose 2-AFC as the paradigm of the experiment
                                % this sets the guessing rate to .5 and
                                % fits the rest of the parameters

result = psignifit(data,options);
plotPsych(result);

fprintf('Threshold: %3.3f -%3.3f, +%3.3f\n', ...
            result.Fit(1), result.conf_Intervals(1,1,3), result.conf_Intervals(1,2,3))