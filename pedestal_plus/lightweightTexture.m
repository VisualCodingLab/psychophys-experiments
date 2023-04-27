classdef lightweightTexture < neurostim.stimulus
  % Lightweight version of neurostim texture class that holds one texture
  % object and creates a new texture object when requested. 
  %
  % Settable properties:
  %   width   - width on screen (screen units)
  %   height  - height on screen (screen units)
  %   xoffset - offset applied to X coordinate (default: 0)
  %   yoffset - offset applied to Y coordinate (default: 0)
  %
  % Public methods:
  %   add(id,img)     - add img to the texture library, with identifier id
  %   mkwin(sz,sigma) - calculate a gaussian transparency mask/window
  %
  % Multiple textures can be rendered simultaneously by setting
  % any or all of the settable properties to be a 1xN vector.
 
  % 2023-04-14 - Shaun L. Cloherty <s.cloherty@ieee.org>
  
  properties (Access = private)
    % each entry in the texture library TEX contains a structure
    % with fields:
    %   id - a unique identifier (id)
    %   img - the image (L, LA, RGB or RGBA)
    %   ptr - the ptb texture pointer
    tex = {};
  end
        
  % dependent properties, calculated on the fly...
  properties (Dependent, SetAccess = private, GetAccess = public)
    texIds; % list of all texture ids
    numTex; % the number of textures
  end
  
  methods % set/get dependent properties
    function value = get.texIds(o)
      value = cellfun(@(x) x.id,o.tex,'UniformOutput',false);
    end
    
    function value = get.numTex(o)
      value = length(o.tex);
    end
  end
  
  methods (Access = public)
    function o = lightweightTexture(c,name)
      o = o@neurostim.stimulus(c,name);
            
      % add texture properties
      o.addProperty('ptr',[]); % id(s) of the texture(s) to show on the next frame
      o.addProperty('imgMask',[]); % id(s) of the texture(s) to show on the next frame
      o.addProperty('texImg',[]); % id(s) of the texture(s) to show on the next frame

      o.addProperty('width',1.0,'validate',@isnumeric);
      o.addProperty('height',1.0,'validate',@isnumeric);
      
      o.addProperty('xoffset',0.0,'validate',@isnumeric);
      o.addProperty('yoffset',0.0,'validate',@isnumeric);
      
      o.addProperty('filterMode',1,'validate',@isnumeric); % 1 -bilinear interpolation
      o.addProperty('globalAlpha',[],'validate',@isnumeric); % 1 fully opaque
    end
    

    
    function o = add(o,img,useMask)
      % add IMG to the texture library, with texture id ID
      %
      % IMG can be a NxM matrix of pixel luminance values (0..255), an
      % NxMx3 matrix containing pixel RGB values (0..255) or an NxMx4
      % matrix containing pixel RGBA values, or it can be a char with the
      % name of a file that contains the texture/image. This file will be
      % read with imread. Alpha values range between 0 (transparent) and 255
      % (opaque).

      if ischar(img)
         if ~exist(img,'file')
            error(['No such image file: ' img]);
         end
         img = imread(img);        
      end
      
      if useMask
          if isempty(o.imgMask)
              sz = size(img, 1);
              o.imgMask = createCosineWindow(sz, 25, 0);
          end
          img = cat(3, img, img, img, 255*0.3*o.imgMask);
      else
          img = cat(3, img, img, img, 0.3*255*ones(size(img)));
      end
      
      o.texImg = img;
      o.ptr = Screen('MakeTexture',o.window,o.texImg); 
    end

    function beforeExperiment(o)
    end
        
    function afterExperiment(o)
      % clean up the ptb textures
      if o.ptr
        Screen('Close',o.ptr);
      end
    end
    

    function beforeFrame(o)
      % x.tex is the texture library
      if isempty(o.ptr); return; end   
      
      rect = [-o.width -o.height o.width o.height]./2;
      % draw the texture
      Screen('DrawTextures',o.window,o.ptr,[],rect,[],o.filterMode);
    end    
  end % public methods

  
  methods (Static)
    function w = mkwin(sz,sigma)
      % make gaussian window
      %
      %   sz    - size of the image in pixels ([hght,wdth])
      %   sigma - sigma of the gaussian as a proportion
      %           of sz
      assert(numel(sz) >= 1 || numel(sz) <= 2, ...
        'SZ must be a scalar or 1x2 vector');
      
      sz(1:2) = sz; % force 1x2 vector

      x = (0:sz(2)-1)/sz(2);
      y = (0:sz(1)-1)/sz(1);
      [x,y] = meshgrid(x-0.5,y-0.5);
          
      [~,r] = cart2pol(x,y);
     
      w = normpdf(r,0.0,sigma);
      
      % normalize, 0.0..1.0
      w = w - min(w(:));
      w = w./max(w(:));
    end
  end % static methods
end % classdef
