
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


	function X = new(self)
		f = str2func(class(self));
		X = f();
	end

	function self = horzcat(self, X)
		self = self.cat(X);
	end

	function self = vertcat(self, X)
		self = self.cat(X);
	end

	function self = cat(self,X)
		props = properties(self);
		for i = 1:length(props)
			self.(props{i}) = [self.(props{i}); X.(props{i})];
		end
		self.Size = self.Size + X.Size;

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
				value.(props{i}) = self.(props{i})(key.subs{1});
			end
			value.Size = length(value.(props{1}));
		else
			value = builtin('subsref',self,key);
		end



	end

end % methods



methods (Static)

end % static methods







end % classdef

