% Written by LZ Mar 2023

% Prerequisites. 
import neurostim.*



%============= Enter inputs =====================
contrastList   = logspace(-2.1, -0.38, 8);
freqList       = logspace(-0.2, 0.76, 5); 
nRepeatsPerCond = 2;    % conditions: SF/Contrast combos
testEccentricity = 5;
pedestalFrequency = 1;
testDuration = 1000;
nBlocks = 2;

% Setup CIC and the stimuli.
c =  marmolab.rigcfg;   

c.addScript('BeforeTrial',@beginTrial); % Script that varies adapter
c.itiClear = 0;
c.trialDuration = Inf; % A trial can only be ended by a mouse click
c.cursor = 'none'; % hide? 
c.screen.color.background = 0.5*ones(1,3);

            
%===== Create Stimuli
% Add center point fixation 
% Note: Could possible add eye tracker to see if participant
% is looking at the center point fixation
f = stimuli.fixation(c,'centerPoint');       % Add a fixation point stimulus
f.shape             = 'ABC';
f.color             = [1 1 1];
f.color2            = c.screen.color.background;
f.size              = 0.75; 
f.size2             = 0.15;
f.X                 = 0;
f.Y                 = 0;
f.on                = 0;                % Always on
f.duration          = Inf;

% Test gabor to display left or right
g=stimuli.gabor(c,'gabor_test'); % Gabor to display during testing (either left or right) 
g.color = [0.5 0.5 0.5];
g.sigma = 0.75;
g.frequency = 1;
g.phaseSpeed = 0;
g.orientation = 90;
g.width = 5;
g.height = 5;
g.mask ='GAUSS3';
g.duration = testDuration;
g.on = 0;
g.X = testEccentricity;
g.Y = 0;

% Pedestal gabors
% Any changes should be only made to gL (as gR copies from gL)
% Realisatically, the only changes made should be to frequency,
% contrast (although should be 1) and duration (vector of
% durations)
gL = duplicate(g,'gL_pedestal'); % Additional gabor to display for adapting image (left acts as master)
% Below statement: If duration is 0 (i.e. no adapter), then
% turn the stimuli on immediately (don't wait for fixation) to
% prevent double fixation waiting time
gL.duration = 0; % Default no adapter
gL.X = -1*testEccentricity;
gL.contrast = 1;
gL.frequency = pedestalFrequency;

gR = duplicate(gL, 'gR_pedestal'); % Right adapter (duplicates gL)
gR.X = testEccentricity;
            
%===== Create Behaviours
% Key behaviour (L for left, R for right)
k = behaviors.keyResponse(c,'choice');
k.verbose = false;
k.from = '@gabor_test.on'; % Only start recording after test turns on
k.maximumRT= Inf;                   %Allow inf time for a response
k.keys = {'a' 'l'};                                 %Press 'A' for "left" gabor, 'L' for "right" gabor -> 
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
           
if ~ismac
    plugins.sound(c); 
    s= plugins.soundFeedback(c,'soundFeedback');
    s.add('waveform','skCorrect.wav','when','afterTrial','criterion','@ choice.correct');
    s.add('waveform','skIncorrect.wav','when','afterTrial','criterion','@ ~choice.correct');
end 


% Experimental setup
% Define experimental setup
d{1}= design('Pedestal-Test');
d{1}.fac1.gL_pedestal.contrast = 0;
d{1}.fac2.gabor_test.contrast = contrastList; 
d{1}.fac3.gabor_test.frequency = freqList; 

% load designs into blocks

for i=1:nBlocks
    myBlock{i}=block([d{1}.name num2str(i)],d{1});             %Create a block of trials using the factorial. Type "help neurostim/block" for more options.
    myBlock{i}.nrRepeats=nRepeatsPerCond;
    myBlock{i}.afterMessage = 'Take a break!';
    myBlock{i}.beforeMessage = ['Block ', num2str(i) ' of ' num2str(nBlocks)];
end

%%
c.run(myBlock{:});

%% Functions
function beginTrial(c)

  % Randomise position of gabor_test (left or right)
  randLogical = (rand()<0.5); % 1 or 0
  eccentricity = c.gR_pedestal.X;
  c.gabor_test.X = randLogical*eccentricity + ~randLogical * (-1*eccentricity);
  
end