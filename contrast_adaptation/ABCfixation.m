classdef ABCfixation < neurostim.stimulus
    % Draw a fixation point for high-stability fixation from 
    % from https://doi.org/10.1016/j.visres.2012.10.012 
    % Adjustable variables:
    %   size - with relation to the 'physical' size of the window.
    %   size2 - second required size, i.e. width of oval, inner star/donut size.
    %   color2 - color of inner donut.
    
    properties
    end
    

    methods (Access = public)
        function o = ABCfixation(c,name)
            o = o@neurostim.stimulus(c,name);
            o.addProperty('size',0.75,'validate',@isnumeric);
            o.addProperty('size2',0.15,'validate',@isnumeric);
            o.addProperty('color2',[1 1 1]*0.5,'validate',@isnumeric); 
            o.on = 0;
        end
       
                
        function beforeFrame(o)
            locSize = o.size; % Local copy, to prevent repeated expensive "getting" of NS param    
            tinySize = o.size2;
            
            Screen('FillOval', o.window, o.color,[-(locSize/2) -(locSize/2) (locSize/2) (locSize/2)]);
            Screen('FillRect', o.window, o.color2, [-(tinySize/2) -(locSize/2) (tinySize/2) (locSize/2)]);
            Screen('FillRect', o.window, o.color2, [-(locSize/2) -(tinySize/2) (locSize/2) (tinySize/2)]);
            Screen('FillOval', o.window, o.color,[-(tinySize/2) -(tinySize/2) (tinySize/2) (tinySize/2)]);
            
            
        end
        
        
        
    end
end