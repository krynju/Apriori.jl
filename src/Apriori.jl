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

function v_squash(pair)
    unique(vcat(pair[1],pair[2]))
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
 
function v_subsets(set, len)
    Vector.(combinations([set...], len))
end

function v_antecedent(fvec, vec)
    filter(x-> x ∉ vec, fvec)
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
    
    apriori_rule_gen(apriori_frequent_itemsets(data, min_relative_support),propertynames(data), min_confidence)
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
function merging(x)
    combinations(x,2)
end

function merge_vectors(itemsets)
    pool = [itemsets[1]]
    result = []
    for i in 1:length(itemsets)
        itemset1 = itemsets[i]
        prefix = itemset1[1:end-1]
        suffixes = []
        for j in i+1:length(itemsets)
            itemset2 = itemsets[j]
            if prefix != itemset2[1:end-1]
                break
            end
            push!(suffixes, sort([itemset1[end], itemset2[end]]))
        end
        suffixes = sort(suffixes)
        merged_itemsets = map(x->vcat(prefix, x), suffixes)
        append!(result, merged_itemsets)
    end
    # for itemset in itemsets[2:end]
    #     if (itemset[1:end-1] != pool[1][1:end-1])
    #         prefix = pool[1][1:end-1]
    #         suffixes = combinations(vcat(map(x->x[end], pool)),2)
    #         append!(result, sort(map(x->vcat(prefix,sort(x)), suffixes)))
    #         pool = []
    #     end
    #     push!(pool, itemset)
    # end
    # if length(pool)>1
    #     prefix = pool[1][1:end-1]
    #     suffixes = combinations(vcat(map(x->x[end], pool)),2)
    #     append!(result, sort(map(x->vcat(prefix,sort(x)), suffixes)))
    # end
    return(result)
end

function translate(element, dict)

end

function apriori_rule_gen(frequent_itemsets::Array{Pair{Set{Symbol},Int64},1}, attribute_names, min_confidence=0.3)
    s_to_i = Dict([x=>y for (x,y) in zip(attribute_names, 1:length(attribute_names))])

    df = Dict(map(x-> sort(Vector(getindex.(Ref(s_to_i), x[1]))) => x[2],frequent_itemsets))

    all_strong_rules = Vector{Pair{Tuple{Vector{Symbol}, Vector{Symbol}},Float64}}()

    for (Z_set,Z_sup) in frequent_itemsets
        if (length(Z_set) == 1) continue end

        v_Z_set = sort(Vector{Int64}(getindex.(Ref(s_to_i), Z_set)))
        i = 1
        Y = v_subsets(v_Z_set, i)
        while true
            strong_rules = filter(x -> x[2] >= min_confidence, map(x -> begin
                ant = v_antecedent(v_Z_set, x)
                (ant, x) => Z_sup / df[ant] 
            end, Y))
            
            append!(all_strong_rules, map(x-> (getindex.(Ref(attribute_names),x[1][1]), getindex.(Ref(attribute_names),x[1][2])) => x[2], strong_rules))
            i += 1
            if (i == length(Z_set) || length(strong_rules) == 0) break end
            
            Y = merge_vectors(map(x -> x[1][2], strong_rules))
        end
    end
    all_strong_rules
end


function apriori_rule_gen2(frequent_itemsets::Array{Pair{Set{Symbol},Int64},1}, min_confidence=0.3)
    df = Dict(frequent_itemsets)

    all_strong_rules = Vector{Pair{Tuple{Vector{Symbol}, Vector{Symbol}},Float64}}()

    for (Z_set,Z_sup) in frequent_itemsets
        if (length(Z_set) == 1) continue end

        v_Z_set = sort(Vector{Symbol}([Z_set...]))
        i = 1
        Y = sort(v_subsets(v_Z_set, i))
        while true
            strong_rules = filter(x -> x[2] >= min_confidence, map(x -> begin
                ant = v_antecedent(v_Z_set, x)
                (ant, x) => Z_sup / df[Set(ant)] 
            end, Y))
            
            append!(all_strong_rules, strong_rules)
            i += 1
            if (i == length(Z_set) || length(strong_rules) == 0) break end
            
            #Y = filter(x -> length(x) == i, v_squash.(merging(map(x -> x[1][2], strong_rules))))
            Y = merge_vectors(Y)
        end
    end
    all_strong_rules
end


function dummy_dataset(attrs, rows)
    @assert attrs <= 26 "TODO the attr label fun to generate more"
    attr_names = collect('a':'z')[1:attrs]
    DataFrame([Symbol(i) => rand(Bool, rows) for i in attr_names])
end

# Creates a semi-random dataset that exhibits a strong association rule
function dummy_dataset_biased(attrs, rows, antecedent, consequent, support)
    @assert attrs <= 26 "TODO the attr label fun to generate more"
    attr_names = collect('a':'z')[1:attrs]
    df = DataFrame([Symbol(i) => rand(Bool, rows) for i in attr_names])
    print(df)
    antecedent_indices = findall(col_name->col_name in antecedent, attr_names)
    consequent_indices = findall(col_name->col_name in consequent, attr_names)
    antecedent_count = nrow(filter(row->all([row[index] for index in antecedent_indices]), df))
    rule_count = nrow(filter(row->all([row[index] for index in vcat(antecedent_indices, consequent_indices)]), df))
    required_rule_count = rows*support
    for row in eachrow(df)
        if !all([row[index] for index in vcat(antecedent_indices, consequent_indices)])
            for index in vcat(antecedent_indices, consequent_indices)
                row[index] = true
            end
            rule_count = rule_count + 1
        end
        if rule_count>=required_rule_count
            break
        end
    end
    return (df)
end

export apriori, dummy_dataset, dummy_dataset_biased, apriori_rule_gen, apriori_rule_gen2, apriori_frequent_itemsets, merge_vectors

end
