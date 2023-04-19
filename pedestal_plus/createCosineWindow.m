% createCosineWindow 
% winSize: the square size of the final window (pixels)
% taperDist: the number of pixels over which to taper

function win = createCosineWindow(winSize, taperDist, padding)
   
    halfSize = ceil(winSize/2);

    [x, y] = meshgrid(-halfSize:halfSize-1, -halfSize:halfSize-1);
    [~, rho] = cart2pol(x,y); % polar space is a convenient way to get a circle.
                              % this is the part that won't work for
                              % rectangular images, because it's not good for
                              % ellipses. To get an ellipse, maybe start with a
                              % circle and imresize to stretch for the longer
                              % axis. 

    rad = halfSize-taperDist;
    rho(rho < rad) = rad;
    rho(rho > rad + taperDist) = rad+taperDist;
    rho = rho - rad;
    rho = rho/taperDist;
    rho = rho*(pi/2);
    win = cos(rho);
    win(win < 10^-15) = 0;
    
    if mod(winSize, 2)
       win = win(1:end-1, 1:end-1); 
    end

    tmp = zeros(size(win)+padding*2);
    tmp(padding+1:end-padding, padding+1:end-padding) = win; 
    win = tmp; 
    
    
end