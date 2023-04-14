% Written by LZ Mar 2023

% Prerequisites. 
import neurostim.*

%============= Enter inputs =====================
% pedestal properties
pedestalFrequency = 1;
pedestalContrast  = 0.5;

% test properties
testPatt = 'gabor'; %gabor | nwave
contrastList   = [1]; %logspace(-0.5, 0, 4);          % the contrast of the test pattern

switch testPatt
    case 'gabor'
        testFreq = pedestalFrequency/3;
        phaseList = [0 2.5 5 10 20 45 90];
    case 'nwave'

end

% experiment properties
nRepeatsPerCond = 2;    % conditions: SF/Contrast combos
testEccentricity = 5;
testDuration = 10000;
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

% 1/f background noise
%bg = stimuli.texture(c, 'noise');
%bg.width = 20;
%bg.height = 20; 


%img = getNoiseIm(); 
%bg.add(1,img);



% Test gabor to display left or right
switch testPatt
    case 'gabor'
        g=stimuli.gabor(c,'gabor_test'); % Gabor to display during testing (either left or right) 
    case 'nwave'
        g = squarewaves.nWave(c,'nWave');
end
g.color = [0.5 0.5 0.5];
g.sigma = 0.75;
g.frequency = testFreq;
g.phaseSpeed = 0;
g.orientation = 90;
g.width = 5;
g.height = 5;
g.mask ='GAUSS3';
g.duration = testDuration;
g.on = 0;
g.X = testEccentricity;
g.Y = 2;

% Pedestal gabors
% Any changes should be only made to gL (as gR copies from gL)
% Realisatically, the only changes made should be to frequency,
% contrast (although should be 1) and duration (vector of
% durations)
gL = duplicate(g,'gL_pedestal'); % Additional gabor to display for adapting image (left acts as master)
% Below statement: If duration is 0 (i.e. no adapter), then
% turn the stimuli on immediately (don't wait for fixation) to
% prevent double fixation waiting time
gL.color = [0.5 0.5 0.5];
gL.duration = testDuration; % Default no adapter
gL.X = -1*testEccentricity;
gL.Y = 0;
gL.contrast = pedestalContrast;
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
d{1}.fac1.gabor_test.contrast = contrastList; 
d{1}.fac2.gabor_test.phase = phaseList;

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

function img = getNoiseIm
    img = makeNoisePatt(256, 0, 180, 1.3);
    img = img + abs(min(img(:))); 
    img = img/max(abs(img(:)));
    img = img*255;
end

function beginTrial(c)

   %generate a new noise pattern
%   img = getNoiseIm(); 
%   c.noise.replace(1,img);


  % Randomise position of gabor_test (left or right)
  randLogical = (rand()<0.5); % 1 or 0
  eccentricity = c.gR_pedestal.X;
  c.gabor_test.X = randLogical*eccentricity + ~randLogical * (-1*eccentricity);
  
end