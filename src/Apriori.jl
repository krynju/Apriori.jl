module Apriori

using DataFrames
using Combinatorics

function count_support(data::DataFrame, attrs::Set{Symbol})::Pair{Set{Symbol}, Int64}
    attrs => nrow(data[reduce((x, y) -> x .& y, [data[!, attr] .== true for attr in attrs]),:])
end

function squash(arr::Array{Set{Symbol},1})
    union(arr[1],arr[2])
end

function gen_new_itemsets(km1::Array{Pair{Set{Symbol},Int64},1})
    unique(squash.(combinations(getindex.(km1,1), 2)))
end

function subsets(set::Set{Symbol})
    subs = Array{Set{Symbol},1}()
    for i in length(set)-1:-1:2
        append!(subs, Set.(combinations([set...], i)))
    end
    append!(subs, Set([i]) for i in set)
    subs
end

function subset_iteration(infrequent_itemsets,set)
    for i in subsets(set) 
        if(i in infrequent_itemsets) 
            false 
        end 
    end
    true
end

function apriori(data::DataFrame, min_relative_support=0.2)
    supp = floor(min_relative_support * nrow(data))

    freq_itemsets = Array{Pair{Set{Symbol},Int64},1}()
    infrequent_itemsets = Set{Set{Symbol}}()

    attributes = propertynames(data) ::Array{Symbol,1}

    itemsets = [Set([i]) for i in attributes]::Array{Set{Symbol},1}

    while true
        itemsets_w_supp = count_support.(Ref(data), itemsets)
        freq_itemsets_w_supp = filter(x-> x[2] >= supp, itemsets_w_supp)
        append!(freq_itemsets, freq_itemsets_w_supp)
        union!(infrequent_itemsets, map(y-> y[1] ,filter(x-> x[2] < supp, itemsets_w_supp)))
        
        if (length(freq_itemsets_w_supp ) <= 1) break end

        itemsets = gen_new_itemsets(freq_itemsets_w_supp)
        itemsets = filter(x-> subset_iteration(infrequent_itemsets,x), itemsets) 
    end
    freq_itemsets
end


function dummy_dataset(attrs, rows)
    @assert attrs <= 26 "TODO the attr label fun to generate more"
    attr_names = collect('a':'z')[1:attrs]
    DataFrame([Symbol(i) => rand(Bool, rows) for i in attr_names])
end

export apriori, dummy_dataset

end
