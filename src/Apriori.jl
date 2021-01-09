module Apriori

using DataFrames
using Combinatorics

# calculates the support of an itemset
function count_support(data::DataFrame, attrs::Set{Symbol})::Pair{Set{Symbol},Int64}
    attrs => nrow(data[reduce((x, y) -> x .& y, [data[!, attr] .== true for attr in attrs]),:])
end


# to jest wolniejsze od tego wyżej, dziwne xd
function count_support2(data::DataFrame, attrs::Set{Symbol})::Pair{Set{Symbol},Int64}
    res = 0
   
    for i in eachrow(data)
        if (all(getindex.(Ref(i), attrs)))
            res +=1
        end
    end
    attrs => res
end

# takes a pair of sets and creates an union set containing the elements
function squash(arr::Array{Set{Symbol},1})
    union(arr[1], arr[2])
end

# takes a list of itemsets and generates i+1 itemsets
function gen_new_itemsets(km1::Array{Pair{Set{Symbol},Int64},1})::Array{Set{Symbol},1}
    unique(squash.(combinations(getindex.(km1, 1), 2)))
end

# generates all subsets of an itemset
function subsets(set::Set{Symbol})
    vcat([Set.(combinations([set...], i)) for i in length(set) - 1:-1:1]...)
end

function subsets(set, len)
    Set.(combinations([set...], len))
end
 
function subset_iteration(infrequent_itemsets, set) 
    for i in subsets(set) 
        if (i in infrequent_itemsets) 
            return false 
        end 
    end
    true
end

function apriori(data::DataFrame, min_relative_support=0.2, min_confidence=0.3)
    apriori_rule_gen(apriori_frequent_itemsets(data, min_relative_support), min_confidence)
end

function apriori_frequent_itemsets(data::DataFrame, min_relative_support=0.2)
    supp = floor(min_relative_support * nrow(data))

    freq_itemsets = Array{Pair{Set{Symbol},Int64},1}()
    infrequent_itemsets = Set{Set{Symbol}}()

    attributes = propertynames(data)::Array{Symbol,1}

    itemsets = [Set([i]) for i in attributes]::Array{Set{Symbol},1}

    while true
        itemsets_w_supp = map(x-> count_support(data,x), itemsets)
        freq_itemsets_w_supp = filter(x -> x[2] >= supp, itemsets_w_supp)
        append!(freq_itemsets, freq_itemsets_w_supp)
        union!(infrequent_itemsets, map(y -> y[1], filter(x -> x[2] < supp, itemsets_w_supp)))
        
        if (length(freq_itemsets_w_supp) <= 1) break end

        itemsets = filter(x -> subset_iteration(infrequent_itemsets, x), gen_new_itemsets(freq_itemsets_w_supp)) 
        # add special filters here
    end

    freq_itemsets
end

function apriori_rule_gen(frequent_itemsets::Array{Pair{Set{Symbol},Int64},1}, min_confidence=0.3)
    df = Dict(frequent_itemsets)

    all_strong_rules = []

    for (Z_set,Z_sup) in frequent_itemsets
        if (length(Z_set) == 1) continue end

        i = 1
        Y = subsets(Z_set, i)
        while true
            strong_rules = filter(x -> x[2] >= min_confidence, map(x -> (setdiff(Z_set, x), x) => Z_sup / df[setdiff(Z_set, x)], Y))
            
            append!(all_strong_rules, strong_rules)
            i += 1
            if (i == length(Z_set) || length(strong_rules) == 0) break end
       
            Y = filter(x -> length(x) != i, unique(squash.(combinations(map(x -> x[1][2], strong_rules), 2))))
        end
    end
    all_strong_rules
end


function dummy_dataset(attrs, rows)
    @assert attrs <= 26 "TODO the attr label fun to generate more"
    attr_names = collect('a':'z')[1:attrs]
    DataFrame([Symbol(i) => rand(Bool, rows) for i in attr_names])
end

export apriori, dummy_dataset, apriori_rule_gen, apriori_frequent_itemsets

end
