% loads from a cell array of data files to create lists of the experiment
% parameters.
function [allTrials, params, n] = loadResults(path, dFile)

allTrials.Resps = [];
allTrials.Conts = [];
allTrials.Adapt = [];
allTrials.Freqs = [];
allTrials.Phases = [];


% combine relevant trial-related information across files
for iFile = 1:length(dFile)
    load([path dFile{iFile}], 'c');
    
    tmp = get(c.choice.prms.correct,'atTrialTime',Inf)';
    if iscell(tmp) % convert to array if cell array (this can happen with early-abort)
        tmp = cellfun(@(x) islogical(x)&&x, tmp);
    end
    
    allTrials.Resps = [allTrials.Resps tmp];
    allTrials.Conts = [allTrials.Conts get(c.gabor_test.prms.contrast, 'atTrialTime', Inf)'];
    allTrials.Freqs = [allTrials.Freqs get(c.gabor_test.prms.frequency, 'atTrialTime', Inf)'];
    allTrials.Adapt = [allTrials.Adapt get(c.gL_adapt.prms.contrast, 'atTrialTime', Inf)'];
    allTrials.Phases = [allTrials.Phases get(c.gabor_test.prms.phase, 'atTrialTime', Inf)'];
end



params.Cont = unique(allTrials.Conts); n.Cont = length(params.Cont); 
params.Adapt = unique(allTrials.Adapt); n.Adapt = length(params.Adapt); 
params.Freq = unique(allTrials.Freqs); n.Freq = length(params.Freq); 
params.Phase = unique(allTrials.Phases); n.Phase = length(params.Phase); 
