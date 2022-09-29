function gaborAdaptiveContrast
% Contrast detection experiment. 
% Shows Gabor patches in random locations, user is required to click on
% them 

%% Prerequisites. 
import neurostim.*

%% Setup CIC and the stimuli.
c = myRig;   
c.trialDuration = Inf; % A trial can only be ended by a mouse click
c.cursor = 'arrow';
c.screen.color.background = 0.5*ones(1,3);



%% Create Stimuli
% Add center point fixation 
% Note: Could possible add eye tracker to see if participant
% is looking at the center point fixation
f = stimuli.fixation(c,'centerPoint');       % Add a fixation point stimulus
f.color             = [1 1 1];
f.shape             = 'STAR';           % Shape of the fixation point
f.size              = 0.25;
f.X                 = 0;
f.Y                 = 0;
f.on                = 0;                % Always on
f.duration          = Inf;

% Add a Gabor stimuli (left and right) .
% NOTE: SHOULD CHANGE TO JUST A SINGLE GABOR AND THEN RANDOMISE THE X POSITION
% AS EITHER -5 OR 5 (i.e. with jitter plugin) => WILL MAKE ANALYSIS EASIER
gR=stimuli.gabor(c,'gabor_right');           
gR.color = [0.5 0.5 0.5];
gR.sigma = 0.5;    
gR.frequency = 3;
gR.phaseSpeed = 0;
gR.orientation = 90;
gR.mask ='GAUSS3';
gR.duration = Inf;
gR.X = 5;
gR.Y = 0;

gL=stimuli.gabor(c,'gabor_left');           
gL.color = [0.5 0.5 0.5];
gL.sigma = 0.5;    
gL.frequency = 3;
gL.phaseSpeed = 0;
gL.orientation = 90;
gL.mask ='GAUSS3';
gL.duration = Inf;
gL.X = -5;
gL.Y = 0;

%% Create Behaviours
% Key behaviour (L for left, R for right)
k = behaviors.keyResponse(c,'choice');
k.from = 0;
k.maximumRT= Inf;                   %Allow inf time for a response
k.keys = {'l' 'r'};                                 %Press 'L' for "left" gabor, 'R' for "right" gabor
k.correctFun = '@(gabor_right.on == 0) + 1';   %Function returns the index of the correct response (i.e., key 1 -> L or 2 -> R)
k.required = false; % Do not repeat if incorrect response
% Define trial duration
c.trialDuration = '@choice.stopTime';       %End the trial as soon as the 2AFC response is made.
k.failEndsTrial = false;
k.successEndsTrial  = false;

%% Create Inputs 
% Contrasts & Frequencies to investigate
input_Contrast = [0.5 0.7 1];
input_Freq = [3 10 15];

% Combine variables 
% Note: We could do it via .fac1, .fac2, however this would mean that one
% contrast or frequency would remain constant whilst going through fac2
% (i.e. not random on both dimensions). So only use one .fac1
% The lengths of both arrays should now match, and each corresponding point represents a
% trial
inputContrast = reshape(repmat(input_Contrast, length(input_Freq), 1), 1, []); % i.e. If inputContrast = [1 2 3] and len(inputFreq) = 2, this generates: [1 1 2 2 3 3]
inputFreq = repmat(input_Freq, 1, length(input_Contrast)); % i.e. If inputFreq = [1 2 3], and len(inputContrast) = 2, this generates: [1 2 3 1 2 3]

% Repetitions
repeatContrast = 1;
repeatFreq = 1;
inputContrast = repmat(inputContrast, 1, repeatContrast);
inputFreq = repmat(inputFreq, 1, repeatFreq);

numTrials = length(inputContrast);

% Randomise
randomise = true;
if (randomise)
    randVector = randperm(numTrials); % Generate random vector and use for BOTH of the input arrays to randomise but keep correspondance
    inputContrast = inputContrast(randVector);
    inputFreq = inputFreq(randVector);
end

% Generate random array to determine if gabor displays left/right
gaborRightOff = (rand(1, numTrials)>0.5); % 1 means right gabor off, 0 means right gabor on
inputGaborRight = abs(gaborRightOff); % Use abs to convert from logical
inputGaborLeft = abs(inputGaborRight - 1); % Inverted version of inputGaborRight
% Mult. by infinity so that inf. means off, and 0 means on (as these are
% inputs for Start Time)
% Can't multiply 0 * inf as this  = NaN. Therefore use forloop based off
% inputGaborRight for if statements
for i=1:numTrials
    if (inputGaborRight(i) == 1)
        inputGaborRight(i) = Inf;
        inputGaborLeft(i) = 0;
    else
        inputGaborRight(i) = 0;
        inputGaborLeft(i) = Inf;
    end

end

% Inf for Off, 0 for On

%% Create expermental setup
% Define experimental setup
d = design('contrast-freq');

% Contrast
d.fac1.gabor_right.contrast = inputContrast; % Factorial design; single factor with five levels.
d.fac1.gabor_left.contrast = inputContrast; 

% Frequency
d.fac1.gabor_right.frequency = inputFreq;
d.fac1.gabor_left.frequency = inputFreq;

% Right or left
d.fac1.gabor_right.on = inputGaborRight;
d.fac1.gabor_left.on = inputGaborLeft;


blk = block('contrast-freq',d);
blk.nrRepeats = 1;
c.subject = 'easyD';
c.run(blk);

%% Analyse data

end 