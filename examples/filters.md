# Implementation of constraints with examples

## Implementing separate constraints (one at a time)

All examples presented below assume initial itemset Z = {abcdefghij}.
Initial consequent candidates are denoted as Y_0.
Itemset X is a parameter for all constraints.
In all presented examples X = {abij}.

Since all constraints can be implemented by modifying the starting conditions of the algorithm, the examples present the content of Y_0.

For the sake of simplicity, in general case, before proceeding with the algorithm, the set X is processed.
+ If the constraint is "antecedent/consequent in X", the set X is reduced to only contain elements from set Z 
```X = X ⋂ Z```
+ If the constraint is "X in antecedent/consequent", it is necessary to check whether all of the elements of X are in set Z.
If not, no association rules can be derived from initial itemset Z.
```if |X-Z|==0 (continue algorithm) else (return empty)```

### X in antecedent
Initiating consequent candidates only with elements that do not belong to set X will ensure that all of the elements from set X will remain as antecedent.

```Y_0 = Z-X = {{c}, {d}, {e}, {f}, {g}, {h}}```

### Antecedent in X
Adding the prefix (Z-X) to each consequent candidate will ensure, that only elements of set X will remain as antecedent. 
In this case an additional single check of a rule ```X => (Z-X)``` must be performed

```Y_0 = {{(Z-X), x} for x in X} = {{(cdefgh)a}, {(cdefgh)b}, {(cdefgh)i}, {(cdefgh)j}}```

### X in consequent
Adding the prefix (X) to each consequent candidate will ensure that all of the consequents will contain all elements of X.
In this case an additional single check of a rule ```(Z-X) => X``` must be performed

```Y_0 = {{(X),z} for z in (Z-X)} = {{(abij)c}, {(abij)d}, {(abij)e}, {(abij)f}, {(abij)g}, {(abij)h}}```

### consequent in X
Initiating consequent candidates only with elements that belong to X will ensure that all conseqent elements are from set X

```Y_0 = {X} = {a,b,i,j}```

## Implementing multiple constraints

As mentioned in previous section, constraints can be implemented by modifying starting conditions (i.e. consequent candidates set) with 2 methods
+ adding a prefix to each constrain candidate
+ limiting the initial consequent candidate set

Those methods can be used together. 
For constraints that require filtering the initial candidate set, the filters can be applied in series.
After the filters have removed some elements from Y_0, prefixes can be joined and appended to each element.

### Processing of set X
In case of multiple constraints, additional checks must be performed before continuing the algorithm.

+ If "X1 in antecedent" and "X2 in consequent" constraints are active, it is necessary to check whether those sets have any common items.
If they do, no rules can be found.
