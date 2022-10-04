function c = csfPostProcessing(filename, obj) 
% Performs any post data processing on neurostim data
% either via filename, in which a string is entered
% for the filename, and random object input
% or via object, in which object is passed, 
% and filename is set as 0

% If in same workspace as recently run script:
% csfPostProcessing(c.fullFile, 0)

if (filename == 0)
    % Use obj
    c = obj;
else
    c = load(filename).c;
end

% Load data from cic
[data,trial] = get(c.choice.prms.correct,'atTrialTime',Inf);
data = double(data);

% Plot successes on graph
figure(1)
plot(trial, data,  '-o')
title("Correct Choices")
ylabel("1 = Yes, 0 = No")
xlabel("Trial No.")
ylim([-0.2 1.2])

%% Plot contrast/freq on axes, and then set colour as green for success / red for failure
% Organise data
freqAxis = unique(sort(c.inputs.frequency)); % x
contrastAxis = unique(sort(c.inputs.contrast)); % y
outArr = zeros(length(freqAxis), length(contrastAxis));
repCount = outArr; % Count repetitions of same value <- used for averaging without storing values

% Sort data 
for tri = 1:c.inputs.numTrials
    xIndex = find(freqAxis==c.inputs.freqFull(tri));
    yIndex = find(contrastAxis==c.inputs.contrastFull(tri));
    repCount(xIndex, yIndex) = repCount(xIndex, yIndex) + 1;
    outArr(xIndex, yIndex) = (outArr(xIndex, yIndex) * (repCount(xIndex, yIndex)-1) + data(tri)) / repCount(xIndex, yIndex);
end
figure(2)
h = heatmap(freqAxis, contrastAxis, outArr);
numColours = 1000; %max(repCount(:)); % <-- Dynamic colour bar
mapColours = ((0:numColours)/numColours).' .* repmat([0 1 0], numColours+1, 1) + ((numColours:-1:0)/numColours).' .* repmat([1 0 0], numColours+1, 1);
colormap(mapColours)
h.Title = 'Effect of contrast-freq on success';
h.YLabel = 'Contrast';
h.XLabel = 'Frequency';
h.ColorLimits = [0 1];


end

