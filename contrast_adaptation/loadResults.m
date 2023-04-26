% loads from a cell array of data files to create lists of the experiment
% parameters.
function [allTrials, params, n] = loadResults(path, dFile)

allTrials.Resps = [];
allTrials.Conts = [];
allTrials.Adapt = [];
allTrials.Freqs = [];


% combine relevant trial-related information across files
for iFile = 1:length(dFile)
    load([path dFile{iFile}], 'c');
    allTrials.Resps = [allTrials.Resps get(c.choice.prms.correct,'atTrialTime',Inf)'];
    allTrials.Conts = [allTrials.Conts get(c.gabor_test.prms.contrast, 'atTrialTime', Inf)'];
    allTrials.Freqs = [allTrials.Freqs get(c.gabor_test.prms.frequency, 'atTrialTime', Inf)'];
    allTrials.Adapt = [allTrials.Adapt get(c.gL_adapt.prms.contrast, 'atTrialTime', Inf)'];
end

if iscell(allTrials.Resps) % convert to array if cell array (this can happen with early-abort)
    allTrials.Resps = cellfun(@(x) islogical(x)&&x, allTrials.Resps);
end

params.Cont = unique(allTrials.Conts); n.Cont = length(params.Cont); 
params.Adapt = unique(allTrials.Adapt); n.Adapt = length(params.Adapt); 
params.Freq = unique(allTrials.Freqs); n.Freq = length(params.Freq); 
