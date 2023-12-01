classdef BRVT_STE < neurostim.plugins.adaptive
    %Class to implement a BRVT visual acuity (VA) test
    %
    %  Usage: see adaptiveDemo
    %
    % For some practical recommendations on the design of efficient and
    % trustworthy FSS staircases, see:
    %
    %   Bailey IL, Jackson AJ, Minto H, Greer RB, Chu MA. 
    %   The Berkeley Rudimentary Vision Test. Optom Vis Sci. 2012 
    %   Sep;89(9):1257-64. doi: 10.1097/OPX.0b013e318264e85a. 
    
    % 2021-11-25 - Haozhe Wang
    
    properties (Access = private)
        cnt = 0; % counts the number of correct trials
        wcnt = 0; % counts the number of wrong trials
        value = []; % Current value, initialized in constructor
        pool =[]; % pool of conditions
    end
    
    properties (Access = public)
        n;          % this is the maximum number of trails
        threshold; % this is the portion of correct trials
%         min;
%         max;
%         delta;
%         weights; % 1x2, [up, down]
    end
%     
    methods
        function o = BRVT_STE(c,trialResult,startValue,varargin)
            % This constructor takes three required arguments :
            % c  -  handle to CIC
            % trialResult -  a NS function string that evaluates to true
            % (correct) or false (incorrect) at the end of a trial.
            % startValue - start value of the parameter 
            %
            % varargin - Further required arguments, specified as name-value pairs

            p = inputParser;
            p.KeepUnmatched = true;
            p.addParameter('n',1, @(x) validateattributes(x,{'double'},{'numel',1})); 
            p.addParameter('threshold',1, @(x) validateattributes(x,{'double'},{'numel',1}));
            p.parse(varargin{:});
            
                        
            % call the parent constructor
            o = o@neurostim.plugins.adaptive(c,trialResult);
            o.n = p.Results.n;
            o.threshold = p.Results.threshold;
%             o.min = p.Results.min;
%             o.max = p.Results.max;
%             o.delta = p.Results.delta;
%             o.weights = p.Results.weights;               
            o.pool = shuffle(startValue, o.n);
            o.value = o.pool(1); % intialize condition o.value with the first condition in o.pool
        end
        
        function update(o)
            % calculate and return the updated property value
            v = o.lastValue;
            va_idx = ceil(v/4); % this is transmission between my conidtions and image index, 
            %in general cases, v and va_idx are the same thing, the
            %condition you want to change each trial

            % things to do after the getting trial out come
            if o.lastOutcome % if last trial is successful
                o.cnt = o.cnt + 1;   
            else 
                o.wcnt = o.wcnt + 1;
            end
            cnt_sum = o.cnt+o.wcnt; % count number of total trials
            if cnt_sum >= o.n % if finish number of presentation, I compare corret rate vs o.threshold after o.n number of trials
                flag = o.cnt/cnt_sum> o.threshold; % this is the flag to determine if portion correct trial meet our criteria
                if flag 
                    %following is what to do if corret rate meets the criteria(o.threshold)
                    switch va_idx
                        case 5
                            va_idx = 4;
                            o.pool = shuffle(va_idx,o.n);
                        case {1, 6, 9} 
                            save('v_STE.mat', 'va_idx' , 'flag')
                            o.value = 0; % end experiment, threshold found
                        case {8, 7, 12, 11, 10 ...
                                4, 3, 2} % {2, 3, 5, 6, 7}
                            va_idx = va_idx-1;
                            o.pool = shuffle(va_idx,o.n);
                    end
                else % fail the criteria, 
                    %following is what to do if corret rate fails the criteria(o.threshold)
                    switch va_idx
                        case 5 
                            va_idx = 8;
                            o.pool = shuffle(va_idx,o.n);
                        case 8 
                            va_idx= 12;
                            o.pool = shuffle(va_idx,o.n);
                        case {7, 6, 12, 11, 10, 9, 4, 3, 2, 1} 
                            save('v_STE.mat', 'va_idx' , 'flag')
                            o.value = 0; % end experiment, threshould found
                    end
                end %flag
                % reset parameters before moving to next image, you may
                % not need this
                o.wcnt = 0; 
                o.cnt = 0;
                cnt_sum = 0;
            end %  if cnt_sum >= o.n
%             o.pool
            if o.value ~= 0
                o.value = o.pool(cnt_sum+1); % move on the the next condition in the pool
            end            
        end
         
        function v= getAdaptValue(o)
            % Return the current, internally stored, value, grap what is
            % happening in previous trial
            if o.value ==0
                o.cic.endExperiment() % when o.value is 0, end the experiment
            end
            v = o.value; %otherwise assign value to v, start next trial
        end  
    end % methods
    
end % classdef

function seq = shuffle(v,n)
% this function was used to shuffle the conditions needed
% v - start value
% n - total number of trials
    angle_pool = (v-1)*4+1:v*4;
    pool_o = [angle_pool randsample(angle_pool,n-4, true)];
    seq = pool_o(randperm(length(pool_o)));
end