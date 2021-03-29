
classdef (Abstract) Silo < matlab.mixin.CustomDisplay 



properties (Access = private)

end % private props

properties

	Size (1,1) {mustBeInteger} = 0

end % props



methods (Access = protected)
	function displayScalarObject(self)
		props = properties(self);
		if self.Size == 1
			self.details;
		else
			disp([class(self) ' with ' mat2str(self.Size)  ' elements and with properties:'])
			disp(props)
		end
		
	end
end


methods 

	function self = Silo()

	end % constructor


	% add must fill out all properties of the object
	function self = add(self,S)
		arguments
			self (1,1) Silo
			S (1,1) struct
		end

		fn = sort(fieldnames(S));
		props = sort(properties(self));

		assert(all(strcmp(fn,props)),'Properties of Silo and fieldnames of structure do not match')

		for i = 2:length(fn)
			assert(length(S.(fn{i})) == length(S.(fn{1})),'Structure has fields with different lengths')
		end

		NewSilo = self.new;

		for i = 1:length(fn)
			NewSilo.(fn{i}) = S.(fn{i});
		end
		NewSilo.Size = length(S.(fn{1}));


		self = [self NewSilo];

	end



	% insert one element at a particular location
	% if you run this backwards in a loop you can grow
	% an array efficiently 
	function self = insertAt(self,S, loc)
		arguments
			self (1,1) Silo
			S (1,1) struct
			loc (1,1) double
		end


		props = properties(self);
		for i = 1:length(props)

			% allow for some type robustness
			if ischar(S.(props{i})) & isa(self.(props{i}),'double')
				S.(props{i}) = str2double(S.(props{i}));
			end

			self.(props{i})(loc) = S.(props{i});
		end
		self.Size = length(self.(props{i}));

	end


	function X = new(self)
		f = str2func(class(self));
		X = f();
	end

	function self = horzcat(self, X)
		if nargin == 1
			return
		end
		self = self.cat(X);
	end

	function self = vertcat(self, X)
		self = self.cat(X);
	end

	function self = cat(self,X)
		props = properties(self);

		if X.Size == 0
			return
		end


		if self.Size == 0
			self = X;
			self.Size = X.Size;
			return
		else
			for i = 1:length(props)
				self.(props{i}) = [self.(props{i}); X.(props{i})];
			end
		end
		self.Size = self.Size + X.Size;

	end

	function ok = checkSize(self)
		props = properties(self);
		ok = false;
		for i = 2:length(props)
			disp(props{i})
			assert(length(self.(props{i})) == length(self.(props{1})))
		end
		ok = true;
	end

	function props = properties(self)
		props = builtin('properties',self);
		props = setdiff(props,'Size');
	end



	function value = subsref(self,key)

		if strcmp(key(1).type,'()')
			value = self.new;
			props = properties(self);
			for i = 1:length(props)
				value.(props{i}) = self.(props{i})(key(1).subs{1});
			end
			value.Size = length(value.(props{1}));

			if length(key) > 1
				key = key(2:end);
				value = value.subsref(key);
			end

		else
			value = builtin('subsref',self,key);
		end



	end

end % methods



methods (Static)

end % static methods







end % classdef

