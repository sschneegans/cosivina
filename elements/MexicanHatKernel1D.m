% MexicanHatKernel1D (COSIVINA toolbox)
%   Connective element that performs a 1D convolution with a Mexican hat
%   kernel (difference of two Gaussians).
%
% Constructor call:
% MexicanHatKernel1D(label, size, sigmaExc, amplitudeExc, ...
%     sigmaInh, amplitudeInh, circular, normalized, cutoffFactor)
%   size - size of input and output of the convolution
%   sigmaExc - width parameter of excitatory Gaussian
%   amplitudeExc - amplitude of excitatory Gaussian
%   sigmaInh - width parameter of inhibitory Gaussian
%   amplitudeInh - amplitude of inhibitory Gaussian
%   circular - flag indicating whether convolution is circular
%   normalized - flag indicating whether kernel components are normalized
%     before scaling with amplitudes
%   cutoffFactor - multiple of larger sigma at which the kernel is cut off


classdef MexicanHatKernel1D < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'sigmaExc', ParameterStatus.InitRequired, ...
      'amplitudeExc', ParameterStatus.InitRequired, 'sigmaInh', ParameterStatus.InitRequired, ...
      'amplitudeInh', ParameterStatus.InitRequired, 'circular', ParameterStatus.InitRequired, ...
      'normalized', ParameterStatus.InitRequired, 'cutoffFactor', ParameterStatus.InitRequired);
    components = {'kernel', 'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    sigmaExc = 1;
    amplitudeExc = 0;
    sigmaInh = 1;
    amplitudeInh = 0;
    circular = true;
    normalized = true;
    cutoffFactor = 5;
    
    % accessible structures
    kernel
    output
  end
  
  properties (SetAccess = private)
    kernelRangeLeft
    kernelRangeRight
    extIndex
  end
  
  methods
    % constructor
    function obj = MexicanHatKernel1D(label, size, sigmaExc, amplitudeExc, sigmaInh, amplitudeInh, ...
        circular, normalized, cutoffFactor)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 3
        obj.sigmaExc = sigmaExc;
      end
      if nargin >= 4
        obj.amplitudeExc = amplitudeExc;
      end
      if nargin >= 5
        obj.sigmaInh = sigmaInh;
      end
      if nargin >= 6
        obj.amplitudeInh = amplitudeInh;
      end
      if nargin >= 7
        obj.circular = circular;
      end
      if nargin >= 8
        obj.normalized = normalized;
      end
      if nargin >= 9
        obj.cutoffFactor = cutoffFactor;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      if obj.circular
        obj.output = conv2(1, obj.kernel, obj.inputElements{1}.(obj.inputComponents{1})(obj.extIndex), 'valid');
      else
        obj.output = conv2(1, obj.kernel, obj.inputElements{1}.(obj.inputComponents{1}), 'same');
      end
    end
    
    
    % initialization
    function obj = init(obj)
      kernelRange = obj.cutoffFactor ...
          * max( (obj.amplitudeExc ~= 0) * obj.sigmaExc, (obj.amplitudeInh ~= 0) * obj.sigmaInh );
      if obj.circular
        obj.kernelRangeLeft = min(ceil(kernelRange), floor((obj.size(2)-1)/2));
        obj.kernelRangeRight = min(ceil(kernelRange), ceil((obj.size(2)-1)/2));
        obj.extIndex = [obj.size(2) - obj.kernelRangeRight + 1 : obj.size(2), 1 : obj.size(2), 1 : obj.kernelRangeLeft];
      else
        obj.kernelRangeLeft = min(ceil(kernelRange), (obj.size(2)-1));
        obj.kernelRangeRight = obj.kernelRangeLeft;
        obj.extIndex = [];
      end
      
      if obj.normalized
        obj.kernel = obj.amplitudeExc * gaussNorm(-obj.kernelRangeLeft : obj.kernelRangeRight, 0, obj.sigmaExc) ...
          - obj.amplitudeInh * gaussNorm(-obj.kernelRangeLeft : obj.kernelRangeRight, 0, obj.sigmaInh);
      else
        obj.kernel = obj.amplitudeExc * gauss(-obj.kernelRangeLeft : obj.kernelRangeRight, 0, obj.sigmaExc) ...
          - obj.amplitudeInh * gauss(-obj.kernelRangeLeft : obj.kernelRangeRight, 0, obj.sigmaInh);
      end
      obj.output = zeros(obj.size);
    end

  end
end

