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
gR=stimuli.gabor(c,'gabor_test'); % Gabor to display during testing (either left or right)       
gR.color = [0.5 0.5 0.5];
gR.sigma = 0.5;    
gR.frequency = 3;
gR.phaseSpeed = 0;
gR.orientation = 90;
gR.mask ='GAUSS3';
gR.duration = Inf;
gR.on = 0;
gR.X = 5;
gR.Y = 0;

gL=stimuli.gabor(c,'gabor_adapt'); % Additional gabor to display for adapting image
gL.color = [0.5 0.5 0.5];
gL.sigma = 0.5;    
gL.frequency = 3;
gL.phaseSpeed = 0;
gL.orientation = 90;
gL.mask ='GAUSS3';
gL.duration = Inf;
gL.on = Inf; % Default off
gL.X = -5;
gL.Y = 0;

%% Create Behaviours
% Key behaviour (L for left, R for right)
k = behaviors.keyResponse(c,'choice');
k.verbose = false;
k.from = 0;
k.maximumRT= Inf;                   %Allow inf time for a response
k.keys = {'q' 'p'};                                 %Press 'Q' for "left" gabor, 'P' for "right" gabor -> 
                                                    %Note: This was changed
                                                    %from R & L because R
                                                    %is on the left side of
                                                    %the keyboard and L is
                                                    %on the right side of
                                                    %the keyboard
k.correctFun = '@(gabor_test.X > 0) + 1';   %Function returns the index of the correct response (i.e., key 1 -> L or 2 -> R)
k.required = false; % Do not repeat if incorrect response
% Define trial duration
c.trialDuration = '@choice.stopTime';       %End the trial as soon as the 2AFC response is made.
k.failEndsTrial = false;
k.successEndsTrial  = false;

%% Enforce Fixation at Center
%Make sure there is an eye tracker (or at least a virtual one)
if isempty(c.pluginsByClass('eyetracker'))
    e = neurostim.plugins.eyetracker(c);      %Eye tracker plugin not yet added, so use the virtual one. Mouse is used to control gaze position (click)
    e.useMouse = true;
end

fix = behaviors.fixate(c,'fixation');
fix.verbose = false;
fix.from            = 0;  % If fixation has not been achieved at this time, move to the next trial
fix.to              = '@choice.stopTime';   % Require fixation until the choice is done.
fix.X               = 0;
fix.Y               = 0; 
fix.tolerance       = 2;
fix.failEndsTrial  = false;

%% Create Inputs 
% Contrasts & Frequencies to investigate
input_Contrast = [0.1 0.2 0.3].^2;
input_Freq = [1 3 5].^2;

addprop(c, 'inputs'); % Create property for inputs, so that we can access them from cic
c.inputs.contrast = input_Contrast; % Save to cic
c.inputs.frequency = input_Freq; % Save to cic

% Combine variables 
% Note: We could do it via .fac1, .fac2, however this would mean that one
% contrast or frequency would remain constant whilst going through fac2
% (i.e. not random on both dimensions). So only use one .fac1
% The lengths of both arrays should now match, and each corresponding point represents a
% trial
inputContrast = reshape(repmat(input_Contrast, length(input_Freq), 1), 1, []); % i.e. If inputContrast = [1 2 3] and len(inputFreq) = 2, this generates: [1 1 2 2 3 3]
inputFreq = repmat(input_Freq, 1, length(input_Contrast)); % i.e. If inputFreq = [1 2 3], and len(inputContrast) = 2, this generates: [1 2 3 1 2 3]

% Repetitions
repeat = 3;
inputContrast = repmat(inputContrast, 1, repeat);
inputFreq = repmat(inputFreq, 1, repeat);

numTrials = length(inputContrast);
c.inputs.numTrials = numTrials; % Save to cic

% Randomise
randomise = true;
if (randomise)
    randVector = randperm(numTrials); % Generate random vector and use for BOTH of the input arrays to randomise but keep correspondance
    inputContrast = inputContrast(randVector);
    inputFreq = inputFreq(randVector);
end

c.inputs.contrastFull = inputContrast;
c.inputs.freqFull = inputFreq;

% Generate random array to determine if gabor displays left/right
inputX = double(rand(1, numTrials) > 0.5);
inputX = inputX*2 - 1; % Turn 0 -> -1
inputX = inputX * 5; % Scale by 5 to move X position outward


%% Create expermental setup
% Define experimental setup
d = design('contrast-freq');

% Contrast
d.fac1.gabor_test.contrast = inputContrast; 

% Frequency
d.fac1.gabor_test.frequency = inputFreq;

% Right or left
d.fac1.gabor_test.X = inputX;


blk = block('contrast-freq',d);
blk.nrRepeats = 1;
c.subject = 'easyD';
c.run(blk);

%% Analyse data
% Possible to do live plotting in between trials ?
% Gather data
gaborPostProcessing(0, c);

