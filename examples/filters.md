# IMPLEMENTATION OF CONSTRAINTS - EXAMPLES

All examples presented below assume initial itemset Z = {abcdefghij}.
Initial consequent candidates are denoted as Y_0.
Itemset X is a parameter for all constraints.
In all presented examples X = {abij}

Since all constraints can be implemented by modifying the starting conditions of the algorithm, the examples present the content of Y_0

## X in antecedent
Initiating consequent candidates only with elements that do not belong to set X will ensure that all of the elements from set X will remain as antecedent.

```Y_0 = Z-X = {{c}, {d}, {e}, {f}, {g}, {h}}```

## Antecedent in X
Adding the prefix (Z-X) to each consequent candidate will ensure, that only elements of set X will remain as antecedent. 
In this case an additional single check of a rule ```X => (Z-X)``` must be performed

```Y_0 = {{(Z-X), x} for x in X} = {{(cdefgh)a}, {(cdefgh)b}, {(cdefgh)i}, {(cdefgh)j}}```

## X in consequent
Adding the prefix (X) to each consequent candidate will ensure that all of the consequents will contain all elements of X.
In this case an additional single check of a rule ```(Z-X) => X``` must be performed

```Y_0 = {{(X),z} for z in (Z-X)} = {{(abij)c}, {(abij)d}, {(abij)e}, {(abij)f}, {(abij)g}, {(abij)h}}```

## consequent in X
Initiating consequent candidates only with elements that belong to X will ensure that all conseqent elements are from set X

```Y_0 = {X} = {a,b,i,j}```
