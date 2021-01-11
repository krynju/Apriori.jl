using Apriori

itemset1 = [1,2,4]
itemset2 = [1,2,5]
itemset3 = [1,2,7]
itemset4 = [1,3,7]
itemset5 = [1,3,4]

itemsets = [itemset1, itemset2, itemset3, itemset4, itemset5]

test_merge4 = merge_vectors(itemsets)
test_merge5 = merge_vectors(test_merge4)
print(test_merge4)
print(test_merge5)
# df = dummy_dataset_biased(10,10, ['a'], ['b'], 0.5, 1)