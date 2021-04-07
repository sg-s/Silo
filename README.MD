# SILO: fast saving, loading and operations on vectors of objects 

[![View Silo on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/89917-silo)

## Problem description

Often, we want to write a class to enforce a certain data structure and to associate bound functions (methods) to that object. For example, here is a simple class that defines some object:

```matlab
classdef ScalarClass
properties

	X (1,1) double = 0
	Y (1,1) double = 0
	Z (1,1) double = 0

	Type (:,1) string = "A"

end % props

end % classdef
```

Now that we have our nice object, we often want to create vectors of objects, because, that's just nice. We can do something like this:

```matlab
N = 5e3;
A = repmat(ScalarClass,N,1);
```

This is great. However, there is a big problem: loading this vector of objects from disk is extremely slow, because MATLAB has to type-check every element and every property on load:

```matlab
tic; save('as_class.mat','A');
load('as_class.mat','A'); toc

Elapsed time is 2.237674 seconds.
```

which is awful. 

In fact, even saving and loading vectors of `structs` is pretty slow:

```matlab

for i = length(A):-1:1
	B(i) = struct(A(i));
end
B = B(:);
tic
save('as_struct.mat','B');
load('as_struct.mat','B'); 
toc

Elapsed time is 1.302606 seconds.
```

1.3 s to just save and load a structure array that contains the data in those objects! And we're not even counting the time taken to reconstitute those objects. Is there a better way? 

## A single object with vectors

Why yes there is. If we instead rewrite our class to look like this:

```matlab

classdef VectorClass
properties

	X (:,1) double = 0
	Y (:,1) double = 0
	Z (:,1) double = 0
	Type (:,1) string = "A"

end % props
end % classdef

```

we see we explicitly allow for arrays of variables. However, this creates a new set of problems:

- there is nothing forcing `X` to be the same length as `Y`, etc.
- We've lost the ability to index into the array: we could do `A(1)`, but we can't really do that in this new architecture. 

Oh well, let's soldier on. How performant is this architecture for saving and reading from disk? 


```matlab
V = VectorClass;
V.A = zeros(N,1);
V.B = zeros(N,1);
V.C = zeros(N,1);
V.Type = repmat("A",N,1);

tic; save('V.mat','V');
load('V.mat','V'); toc

Elapsed time is 0.011277 seconds.
```

That's a **200X** speedup! We can't throw that away...

Let's instead focus on trying to get this new architecture to behave like the first one. 

## The solution: `Silo`

One solution is the `Silo` abstract class, which allows us to write a new class to encapsulate our data that looks like:

```matlab

classdef SiloClass < Silo 
properties

	A (:,1) double = []
	B (:,1) double = []
	C (:,1) double = []
	Type (:,1) string  {mustBeMember(Type, ["A","B"])} 

end % props
end % classdef

```

So it's identical to the previous class, except it inherits from `Silo`. 

Because it's identical to the previous class, it's still extremely fast at writing to disk and loading objects from disk:

```matlab
S = SiloClass;
S = S.add(struct(V));

tic; save('S.mat','S');
load('S.mat','S'); toc

Elapsed time is 0.011494 seconds.

```

But it solves the problems with the previous solution. Specfically:

### Indexing

`S` contains 5000 records, as we can see:

```
S

S = 

SiloClass with 5000 elements and with properties:
    'A'
    'B'
    'C'
    'Type'
```

but we can index into it as though it were a vector of objects:

```
S(1)

ans = 

  SiloClass with properties:

       A: 0
       B: 0
       C: 0
    Type: "A"
```

### Data structure

All fields of classes inheriting from `Silo` are forced to be the same length. If you modify or create `Silo`s using the `add` method, it is impossible to end up in a situation where one field is longer than another. 

