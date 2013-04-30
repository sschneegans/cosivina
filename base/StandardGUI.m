% StandardGUI (COSIVINA toolbox)
%   Creates customized graphical user interfaces to show evolution of
%   activation patterns in neurodynamic architectures and change element
%   parameters online.
%
% Constructor call:
% StandardGUI(simulatorHandle, figurePosition, pauseDuration, ...
%   visGridPosition, visGridSize, visGridPadding, 
%   controlGridPosition, controlGridSize, elementGroups, elementsInGroups)
% Arguments (all optional except for the first two):
%   simulatorHandle - handle to the simulator object which should be run in
%     the GUI (maybe 0, then simulator has to be connected at a later time)
%   figurePosition - screen position and size of the GUI main window in the
%     form [posX, posY, width, height]
%   pauseDuration - duration of pause for every simulation step (default =
%     0.1, should be set lower for computationally costly simulations)
%   visGridPosition - position of the visualizations grid in the GUI window
%     in the format [posX, posY, width, height], in normalized coordinates
%     (relative to figure size)
%   visGridSize - grid size of the visualizations grid in the form 
%     [rows, cols]
%   visGridPadding - padding around each visualization element in grid,
%     relative to figure size, as scalar or vector [padHor, padVert]
%   controlGridPosition - relative position of the controls grid in the GUI
%     window in the form [posX, posY, width, height]
%   controlGridSize - grid size of the controls grid in the form 
%     [rows, cols]
%   elementGroups - labels for elements or groups of elements listed in the
%     parameter panel dropdown menu as cell array of strings
%   elementsInGroups - elements accessed by each list item in the parameter
%     panel dropdown menu; each list item may access a single element or a
%     group of elements of the same type that share parameters; given as
%     cell array of strings or cell array of cell arrays of strings
%
% Methods to design the GUI:
% addVisualization(visualization, positionInGrid, sizeInGrid) - adds a
%   new visualization element to the GUI at positionInGrid (two-element
%   vector [row, col]) that extends over sizeInGrid (two-element vector
%   [rows, cols]; optional, default is [1, 1])
% addControl(visualization, positionInGrid, sizeInGrid) - adds a
%   new control element to the GUI, analogous to addVisualization
%
% Methods to run the GUI:
% run(tMax, initializeSimulator, simulatorHandle) - runs the
%   simulation in the GUI until simulation time tMax (optional, default is
%   inf) is reached or GUI is quit manually; optional boolean argument
%   initializeSimulator forces re-initialization of the simulator at the
%   start of the GUI, optional argument simulatorHandle can specify the
%   simulator object that is run in the GUI (if not specified at creation)
% connect(simulatorHandle) - connect GUI with a simulator object (if not
%   done during creation, or to change connected simulator object)


classdef StandardGUI < handle
  
  properties (SetAccess = protected)
    connected = false;
    
    simulatorHandle = 0;
    figureHandle
    paramPanelHandle
    
    nVisualizations = 0;
    visualizations = {};
        
    nControls = 0;
    controls = {};
    
    paramPanelActive = false;
  end
  
  properties (SetAccess = public)  
    figurePosition = [];
    pauseDuration = 0.01;
    pauseDurationWhilePaused = 0.1;

    visGridPosition = [0, 1/3, 1, 2/3];
    visGridSize = [2, 1];
    visGridPadding = [0.05, 0.05];
    
    controlGridPosition = [0, 0, 1, 1/3];
    controlGridSize = [5, 4];
    
    % these flags can be set via GUI controls (like buttons)
    pauseSimulation = false; % should remain true as long as simulator should remain paused
    quitSimulation = false; % set to true once, is automatically reset after quit (to allow restart) 
    resetSimulation = false; % set to true once, is automatically reset after simulator is re-initialized
    saveParameters = false; % set to true once, is automatically reset after parameters are saved
    loadParameters = false; % set to true once, is automatically reset after parameters are loaded
    paramPanelRequest = false; % should remain true as long as panel should remain active
    loadFile = ''; % file name from which presets are loaded, empty when no preset is loaded
  end
  
  methods
    % constructor
    function obj = StandardGUI(simulatorHandle, figurePosition, pauseDuration, ...
        visGridPosition, visGridSize, visGridPadding, controlGridPosition, controlGridSize, ...
        elementGroups, elementsInGroups)
      
      if ~isempty(simulatorHandle) && simulatorHandle ~= 0
        obj.simulatorHandle = simulatorHandle;
        obj.connected = true;
      end
      obj.figurePosition = figurePosition;
      
      if nargin >= 3
        obj.pauseDuration = pauseDuration;
      end
      if nargin >= 6
        obj.visGridPosition = visGridPosition;
        obj.visGridSize = visGridSize;
        obj.visGridPadding = visGridPadding;
        if numel(obj.visGridPadding) == 1
          obj.visGridPadding = repmat(obj.visGridPadding, [1, 2]);
        end
      end
      if nargin >= 8
        obj.controlGridPosition = controlGridPosition;
        obj.controlGridSize = controlGridSize;
      end
      
      if nargin < 10
        elementGroups = {};
        elementsInGroups = {};
      end
      obj.paramPanelHandle = ParameterPanel(simulatorHandle, elementGroups, elementsInGroups, obj.figurePosition);
    end
    
    
    % destructor
    function delete(obj)
      obj.simulatorHandle = [];
      obj.paramPanelHandle = [];
    end
    
    
    % connect to a simulator obj
    function obj = connect(obj, simulatorHandle)
      obj.simulatorHandle = simulatorHandle;
      
      connect(obj.paramPanelHandle, simulatorHandle);
      for i = 1 : obj.nVisualizations
        connect(obj.visualizations{i}, obj.simulatorHandle);
      end
      for i = 1 : obj.nControls
        connect(obj.controls{i}, obj.simulatorHandle);
      end
      
      obj.connected = true;
    end
    
    
    % initialization
    function obj = init(obj)
      if ~obj.connected
        error('StandardGUI:init:notConnected', ...
          'Cannot initialize StandardGUI object before it has been connected to a Simulator object');
      end
      
      obj.figureHandle = figure('Position', obj.figurePosition, 'Color', 'w');
      for i = 1 : obj.nVisualizations
        init(obj.visualizations{i}, obj.figureHandle);
      end
      for i = 1 : obj.nControls
        init(obj.controls{i}, obj.figureHandle);
      end
    end
    
    
    % run simulation in GUI
    function obj = run(obj, tMax, initializeSimulator, simulatorHandle)      
      if nargin < 2 || isempty(tMax)
        tMax = inf;
      end
      if nargin < 3 || isempty(initializeSimulator)
        initializeSimulator = false;
      end
      if nargin >= 4
        connect(obj, simulatorHandle);
      end
      
      if ~obj.connected
        warning('StandardGUI:run:notConnected', ...
          'Cannot run StandardGUI object before it has been connected to a Simulator object');
        return;
      end
      
      if initializeSimulator || ~obj.simulatorHandle.initialized
        init(obj.simulatorHandle);
      end
      
      obj.init();
      
      while ~obj.quitSimulation && obj.simulatorHandle.t < tMax
        if ~ishandle(obj.figureHandle)
          break;
        end
        
        % checking for changes in controls and param panel
        updatePanel = false;
        for i = 1 : obj.nControls
          updatePanel = check(obj.controls{i}) || updatePanel;
        end
        updateControls = false;
        if obj.paramPanelActive
          updateControls = check(obj.paramPanelHandle);
        end
        
        % opening and closing param panel
        if obj.paramPanelActive && ~obj.paramPanelHandle.panelOpen % panel figure was closed manually
          obj.paramPanelActive = false;
          obj.paramPanelRequest = false;
        end
        if obj.paramPanelRequest && ~obj.paramPanelActive
          open(obj.paramPanelHandle);
          obj.paramPanelActive = true;
        elseif ~obj.paramPanelRequest && obj.paramPanelActive
          close(obj.paramPanelHandle);
          obj.paramPanelActive = false;
        end
        
        % reset
        if obj.resetSimulation
          obj.simulatorHandle.init();
          obj.resetSimulation = false;
        end
        
        % save
        if obj.saveParameters
          if exist('savejson', 'file') ~= 2
            warndlg(['Cannot save parameters to file: File SAVEJSON.M not found. ' ...
              'Install JSONLAB and add it to the Matlab path to be able to save parameters to file.']);
          else
            [paramFile, paramPath] = uiputfile('*.json', 'Save parameter file');
            if ~(length(paramFile) == 1 && paramFile == 0)
              if ~saveSettings(obj.simulatorHandle, [paramPath paramFile])
                warndlg('Could not write to file. Saving of parameters failed.');
              end
            end
          end
          obj.saveParameters = false;
        end
        
        % load
        if obj.loadParameters
          if exist('loadjson', 'file') ~= 2
            warndlg(['Cannot load parameters from file: File LOADJSON.M not found. ' ...
              'Install JSONLAB and add it to the Matlab path to be able to load parameters from file.']);
          else
            if isempty(obj.loadFile)
              [paramFile, paramPath] = uigetfile('*.json', 'Load parameter file');
              if ~(length(paramFile) == 1 && paramFile == 0)
                obj.loadFile = fullfile(paramPath, paramFile);
              end
            end
            if ~isempty(obj.loadFile)
              if ~obj.simulatorHandle.loadSettings(obj.loadFile)
                warndlg(['Could not read file ' obj.loadFile '. Loading of parmeters failed.'], 'Warning');
              end
              init(obj.simulatorHandle);
              updateControls = true;
              updatePanel = true;
            end
            obj.loadFile = '';
          end
          obj.loadParameters = false;
        end
          
        % the actual simulation step
        if ~obj.pauseSimulation
          step(obj.simulatorHandle);
        end
        
        % updating visualizations, controls and panel
        for i = 1 : obj.nVisualizations
          update(obj.visualizations{i});
        end
        if updatePanel && obj.paramPanelActive
          update(obj.paramPanelHandle);
        end
        if updateControls
          for i = 1 : obj.nControls
            update(obj.controls{i});
          end
        end
        
        drawnow;
        if obj.pauseSimulation
          pause(obj.pauseDurationWhilePaused);
        else
          pause(obj.pauseDuration);
        end
      end
      
      obj.quitSimulation = false;
      
      % close everything
      obj.simulatorHandle.close();
      if obj.paramPanelActive
        obj.paramPanelHandle.close();
        obj.paramPanelActive = false;
        obj.paramPanelRequest = false;
      end
      if ishandle(obj.figureHandle)
        delete(obj.figureHandle);
      end
      
    end
    
    
    % add visualization object
    function obj = addVisualization(obj, visualization, positionInGrid, sizeInGrid)
      obj.visualizations{end+1} = visualization;
      obj.nVisualizations = obj.nVisualizations + 1;
      
      if obj.connected
        connect(obj.visualizations{end}, obj.simulatorHandle);
      end
      if nargin < 4
        sizeInGrid = [1, 1];
      end
      if nargin >= 3 && ~isempty(positionInGrid)
        obj.visualizations{end}.position = obj.gridToRelPosition('visualization', positionInGrid, sizeInGrid);
      end
      if isempty(obj.visualizations{end}.position)
        error('StandardGUI:addVisualization:noPosition', ...
          'Position must be specified for each visualization, either in the element itself or via its grid position');
      end
    end
    
    
    % add control object and connect it to the simulator object
    function obj = addControl(obj, control, positionInGrid, sizeInGrid)
      obj.controls{end+1} = control;
      obj.nControls = obj.nControls + 1;
      
      if obj.connected
        connect(obj.controls{end}, obj.simulatorHandle);
      end
      if nargin < 4
        sizeInGrid = [1, 1];
      end
      if nargin >= 3
        obj.controls{end}.position = obj.gridToRelPosition('control', positionInGrid, sizeInGrid);
      end
      if isempty(obj.controls{end}.position)
        error('StandardGUI:addControl:noPosition', ...
          'Position must be specified for each control element, either in the element itself or via its grid position');
      end
    end
    
   
    % compute relative position in figure from grid position
    function relPosition = gridToRelPosition(obj, type, positionInGrid, sizeInGrid)
      % note: position information is given in format [x, y, w, h], with origin at
      if strcmp(type, 'control')
        gridSize = obj.controlGridSize;
        gridPosition = obj.controlGridPosition;
        padding = [0, 0];
      elseif strcmp(type, 'vis') || strcmp(type, 'visualization')
        gridSize = obj.visGridSize;
        gridPosition = obj.visGridPosition;
        padding = obj.visGridPadding;
      else
        error('StandardGUI:gridToRelPosition:invalidArgument', ...
          'Argument TYPE must be either ''control'' or ''visualization''.');
      end
      
      cellSize = [gridPosition(3)/gridSize(2), gridPosition(4)/gridSize(1)]; % [x, y]
      relPosition = [gridPosition(1) + (positionInGrid(2) - 1) * cellSize(1) + padding(1), ...
        gridPosition(2) + gridPosition(4) - (positionInGrid(1) + sizeInGrid(1) - 1) * cellSize(2) + padding(2), ...
        sizeInGrid(2) * cellSize(1) - 2*padding(1), sizeInGrid(1) * cellSize(2) - 2*padding(2)];
    end
    
  end
  
end
