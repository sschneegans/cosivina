% Demonstration of attractor dynamics for robot control. The output of a
% dynamic neural field sets an attractor for a single value dynamical
% system, effectively transforming space into rate code. The dynamical
% system is coupled to the orientation control of a robot (in the simulated
% version without robot connection, dynamical system does not change its
% state).

%% setting up the simulator

% shared parameters
fieldSize = 100;
sigma_exc = 5;
sigma_inh = 12.5;

% create simulator object
sim = Simulator();

% create inputs (and sum for visualization)
sim.addElement(GaussStimulus1D('stimulus 1', fieldSize, sigma_exc, 0, round(1/4*fieldSize), 1, 0));
sim.addElement(GaussStimulus1D('stimulus 2', fieldSize, sigma_exc, 0, round(1/2*fieldSize), 1, 0));
sim.addElement(GaussStimulus1D('stimulus 3', fieldSize, sigma_exc, 0, round(3/4*fieldSize), 1, 0));
sim.addElement(SumInputs('stimulus sum', fieldSize), {'stimulus 1', 'stimulus 2', 'stimulus 3'});

% create neural field
sim.addElement(NeuralField('field u', fieldSize, 5, -5, 4), 'stimulus sum');
sim.addElement(SumInputs('shifted stimulus sum', fieldSize), {'stimulus sum', 'field u'}, {'output', 'h'});

% create interactions
sim.addElement(MexicanHatKernel1D('u -> u (mexican hat)', fieldSize, sigma_exc, 0, sigma_inh, 0, 1, 1), ...
  'field u', 'output', 'field u');
sim.addElement(SumDimension('u -> u (global)', 2, 1, 0), 'field u', 'output', 'field u');

% create noise stimulus and noise kernel
sim.addElement(NormalNoise('noise', fieldSize, 1));
sim.addElement(GaussKernel1D('noise kernel', fieldSize, 0, 0, 1, 1), 'noise', 'output', 'field u');

% attractor dynamics with E-Puck robot
% sim.addElement(AttractorDynamics('attractor dynamics', fieldSize, 0.1), 'field u', 'output');
% sim.addElement(DynamicRobotController('robot controller', 3, 250), 'attractor dynamics', 'phiDot', ...
%   'attractor dynamics', 'orientation');

% simulated attractor dynamics
sim.addElement(BoostStimulus('phi', 0));
sim.addElement(AttractorDynamics('attractor dynamics', fieldSize, 0.1), {'field u', 'phi'}, {'output', 'amplitude'});


%% setting up the GUI

elementGroups = {'field u', 'u -> u (mexican hat)', 'u -> u (global)', 'stimulus 1', 'stimulus 2', 'stimulus 3', ...
  'noise kernel', 'attractor dynamics'};

gui = StandardGUI(sim, [50, 50, 800, 600], 0.05, [0.0, 1/4, 1.0, 3/4], [3, 1], 0.05, [0.0, 0.0, 1.0, 1/4], [6, 4], ...
  elementGroups, elementGroups);

gui.addVisualization(MultiPlot({'field u', 'field u', 'shifted stimulus sum'}, {'activation', 'output', 'output'}, ...
  [1, 10, 1], 'horizontal', {'YLim', [-15, 15], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 3}, {'r', 'LineWidth', 2}, {'Color', [0, 0.75, 0], 'LineWidth', 2}}), [1, 1]);
gui.addVisualization(MultiPlot({'attractor dynamics', 'attractor dynamics'}, {'phiDotAll', 'phiDot'}, [10, 10], ...
  'horizontal', {'XLim', [-pi, pi], 'YLim', [-5, 5], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'r', 'LineWidth', 2, 'XData', (1:fieldSize) * (2*pi/fieldSize) - pi - pi/fieldSize}, {'ro', 'XData', 0}}), [2, 1]);
% gui.addVisualization(MultiPlot({'robot controller'}, {'orientation'}, 1, ...
%   'Vertical', {'YLim', [0.5, 1.5], 'XLim', [-pi, pi], 'XGrid', 'on', 'YGrid', 'on'}, ...
%   {{'ko'}}), [3, 1]);
gui.addVisualization(MultiPlot({'phi'}, {'amplitude'}, 1, ...
  'Vertical', {'YLim', [0.5, 1.5], 'XLim', [-pi, pi], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'ko'}}), [3, 1]);


% add sliders
% resting level and noise
gui.addControl(ParameterSlider('h', 'field u', 'h', [-10, 0], '%0.1f', 1, 'resting level of field u'), [1, 1]);
gui.addControl(ParameterSlider('q', 'noise kernel', 'amplitude', [0, 10], '%0.1f', 1, ...
  'noise level for field u'), [1, 3]);
% lateral interactions
gui.addControl(ParameterSlider('c_exc', 'u -> u (mexican hat)', 'amplitudeExc', [0, 40], '%0.1f', 1, ...
  'strength of lateral excitation'), [2, 1]);
gui.addControl(ParameterSlider('c_inh', 'u -> u (mexican hat)', 'amplitudeInh', [0, 40], '%0.1f', 1, ...
  'strength of lateral inhibition'), [2, 2]);
gui.addControl(ParameterSlider('c_gi', 'u -> u (global)', 'amplitude', [0, 1], '%0.1f', -1, ...
  'strength of global inhibition'), [2, 3]);
% stimuli
gui.addControl(ParameterSlider('w_s1', 'stimulus 1', 'sigma', [0, 20], '%0.1f', 1, 'width of stimulus 1'), [3, 1]);
gui.addControl(ParameterSlider('p_s1', 'stimulus 1', 'position', [0, fieldSize], '%0.1f', 1, ...
  'position of stimulus 1'), [3, 2]);
gui.addControl(ParameterSlider('c_s1', 'stimulus 1', 'amplitude', [0, 20], '%0.1f', 1, ...
  'stength of stimulus 1'), [3, 3]);
gui.addControl(ParameterSlider('w_s2', 'stimulus 2', 'sigma', [0, 20], '%0.1f', 1, 'width of stimulus 2'), [4, 1]);
gui.addControl(ParameterSlider('p_s2', 'stimulus 2', 'position', [0, fieldSize], '%0.1f', 1, ...
  'position of stimulus 2'), [4, 2]);
gui.addControl(ParameterSlider('c_s2', 'stimulus 2', 'amplitude', [0, 20], '%0.1f', 1, ...
  'stength of stimulus 2'), [4, 3]);
gui.addControl(ParameterSlider('w_s3', 'stimulus 3', 'sigma', [0, 20], '%0.1f', 1, 'width of stimulus 3'), [5, 1]);
gui.addControl(ParameterSlider('p_s3', 'stimulus 3', 'position', [0, fieldSize], '%0.1f', 1, ...
  'position of stimulus 3'), [5, 2]);
gui.addControl(ParameterSlider('c_s3', 'stimulus 3', 'amplitude', [0, 20], '%0.1f', 1, ...
  'stength of stimulus 3'), [5, 3]);

% gui.addControl(ParameterSlider('a_rot', 'attractor dynamics', 'amplitude', [0, 10], '%0.1f', 1, ...
%   'amplitude of attractor dynamics for robot rotation'), [6, 1]);
gui.addControl(ParameterSlider('phi', 'phi', 'amplitude', [-pi, pi], '%0.1f', 1, ...
  'direct rotation velocity input'), [6, 3]);

% add buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [1, 4]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [2, 4]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [3, 4]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, false, 'save parameter settings'), [4, 4]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [5, 4]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [6, 4]);

%% run the simulator in the GUI

gui.run(inf);

