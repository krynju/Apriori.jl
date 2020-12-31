module Apriori

using DataFrames
using Combinatorics

function count_support(data, attrs) 
    attrs => nrow(data[reduce((x, y) -> x .& y, [data[!, attr] .== true for attr in attrs]),:]) 
end

function squash(arr)
    union(arr[1], arr[2])
end

function gen_new_itemsets(km1)
    unique(squash.(combinations(getindex.(km1,1), 2)))
end

function apriori(data::DataFrame, min_relative_support=0.2)
    supp = floor(min_relative_support * nrow(data))

    freq_itemsets= []

    # k1
    itemsets = [Set([i]) for i in propertynames(data)]

    while true

        itemsets_w_supp = count_support.(Ref(data), itemsets)
        freq_itemsets_w_supp = filter(x-> x[2] >= supp, itemsets_w_supp)
        append!(freq_itemsets, freq_itemsets_w_supp)
        
        if (length(freq_itemsets_w_supp ) <= 1)
            break
        end

        itemsets = gen_new_itemsets(freq_itemsets_w_supp)
        # check whether subsets of new itemsets are frequent
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
