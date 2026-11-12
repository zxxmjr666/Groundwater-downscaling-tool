function d = datetime(varargin)
% Forward to MATLAB's built-in datetime. This project file exists only to
% avoid an old toolbox shim shadowing normal datetime behavior.
d = builtin('datetime',varargin{:});
end
