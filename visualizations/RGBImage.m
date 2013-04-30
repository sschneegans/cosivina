classdef RGBImage < Visualization
  properties
    imageElementHandle
    imageElementLabel
    imageComponent
    
    axesHandle
    axesProperties
    
    imageHandle
    imageProperties
    
    title = '';
    xlabel = '';
    ylabel = '';
    
    titleHandle = 0;
    xlabelHandle = 0;
    ylabelHandle = 0;
  end
  
  methods
    % Constructor    
    function obj = RGBImage(imageElement, imageComponent, axesProperties, imageProperties, ...
        title, xlabel, ylabel, position)
      obj.imageElementLabel = imageElement;
      obj.imageComponent = imageComponent;
      obj.axesProperties = {};
      obj.imageProperties = {};
      obj.position = [];
      obj.axesHandle = 0;
      obj.imageHandle = 0;
      
      if nargin >= 3
        obj.axesProperties = axesProperties;
      end
      if nargin >= 4
        obj.imageProperties = imageProperties;
      end
      if nargin >= 5 && ~isempty(title)
        obj.title = title;
      end
      if nargin >= 6 && ~isempty(xlabel)
        obj.xlabel = xlabel;
      end
      if nargin >= 7 && ~isempty(ylabel)
        obj.ylabel = ylabel;
      end
      if nargin >= 8
        obj.position = position;
      end
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      if simulatorHandle.isElement(obj.imageElementLabel)
        obj.imageElementHandle = simulatorHandle.getElement(obj.imageElementLabel);
        if ~obj.imageElementHandle.isComponent(obj.imageComponent) ...
            && ~obj.imageElementHandle.isParameter(obj.imageComponent)
          error('RGBImage:connect:invalidComponent', 'Invalid component %s for element %s in simulator object.', ...
            obj.imageComponent, obj.imageElementLabel);
        end
      else
        error('RGBImage:connect:elementNotFound', 'No element %s in simulator object.', obj.imageElementLabel);
      end
    end
    
    
    % initialization
    function obj = init(obj, figureHandle)
      obj.axesHandle = axes('Parent', figureHandle, 'Position', obj.position);
%       obj.imageHandle = image(obj.imageElementHandle.(obj.imageComponent));
      obj.imageHandle = image(obj.imageElementHandle.(obj.imageComponent), 'Parent', obj.axesHandle, ...
        obj.imageProperties{:});
      if ~isempty(obj.axesProperties)
        set(obj.axesHandle, obj.axesProperties{:});
      end
      
      if ~isempty(obj.title)
       obj.titleHandle = title(obj.title); %#ok<CPROP>
     end
     if ~isempty(obj.xlabel)
       obj.xlabelHandle = xlabel(obj.xlabel); %#ok<CPROP>
     end
     if ~isempty(obj.ylabel)
       obj.ylabelHandle = ylabel(obj.ylabel); %#ok<CPROP>
     end
    end
    
    
    % update
    function obj = update(obj)
      set(obj.imageHandle, 'CData', obj.imageElementHandle.(obj.imageComponent));
    end
    
  end
  
end