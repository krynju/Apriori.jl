module Apriori

using DataFrames
using Combinatorics

# calculates the support of an itemset
function count_support(data::DataFrame, attrs::Set{Symbol})::Pair{Set{Symbol},Int64}
    attrs => nrow(data[reduce((x, y) -> x .& y, [data[!, attr] .== true for attr in attrs]),:])
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

function subsets(set::Set{Symbol}, len)
    Set.(combinations([set...], len))
end
 
function subsets(vec::Vector{idx_int}, len)where idx_int <: Signed
    Vector.(combinations([vec...], len))
end

function antecedent(fvec, vec)
    filter(x -> x ∉ vec, fvec)
end

function subset_iteration(infrequent_itemsets, set) 
    for i in subsets(set)  # TODO , subsets(set,length(set))
        if (i in infrequent_itemsets) 
            return false 
        end 
    end
    true
end

function apriori(
    data::DataFrame, 
    min_relative_support=0.2, 
    min_confidence=0.3;
    X_in_antecedent=Vector{Symbol}()::Vector{Symbol},
    antecedent_in_X=Vector{Symbol}()::Vector{Symbol},
    X_in_consequent=Vector{Symbol}()::Vector{Symbol},
    consequent_in_X=Vector{Symbol}()::Vector{Symbol},
    )
    
    t = [
        :x_in_ant => X_in_antecedent, 
        :ant_in_x => antecedent_in_X, 
        :x_in_con => X_in_consequent, 
        :con_in_x => consequent_in_X
    ]
    filters = Dict(filter(x -> length(x[2]) > 0, t))

    fr = apriori_frequent_itemsets(data, min_relative_support)
    apriori_rule_gen(fr, propertynames(data), min_confidence,  X_filters=filters)
end

function apriori_frequent_itemsets(data::DataFrame, min_relative_support=0.2)
    supp = floor(min_relative_support * nrow(data))

    freq_itemsets = Array{Pair{Set{Symbol},Int64},1}()
    infrequent_itemsets = Set{Set{Symbol}}()

    attributes = propertynames(data)::Array{Symbol,1}
    itemsets = [Set([i]) for i in attributes]::Array{Set{Symbol},1}

    while true
        itemsets_w_supp = map(x -> count_support(data, x), itemsets)
        freq_itemsets_w_supp = filter(x -> x[2] >= supp, itemsets_w_supp)
        append!(freq_itemsets, freq_itemsets_w_supp)
        union!(infrequent_itemsets, map(y -> y[1], filter(x -> x[2] < supp, itemsets_w_supp)))
        
        if (length(freq_itemsets_w_supp) <= 1) break end

        itemsets = filter(x -> subset_iteration(infrequent_itemsets, x), gen_new_itemsets(freq_itemsets_w_supp)) 
        # TODO infrequent itemsets should be only of n-1 length in the line above, so postpone mergning in the union of line 83 to after this line
    end

    freq_itemsets
end

function merge_vectors(itemsets::Vector{Vector{idx_int}}) where idx_int <: Signed
    result = Vector{Vector{idx_int}}()
    for i in 1:length(itemsets)
        itemset1 = itemsets[i]
        prefix = itemset1[1:end - 1]
        suffixes = []
        for j in i + 1:length(itemsets)
            itemset2 = itemsets[j]
            if prefix != itemset2[1:end - 1]
                break
            end
            push!(suffixes, sort([itemset1[end], itemset2[end]]))
        end
        merged_itemsets = map(x -> vcat(prefix, x), sort(suffixes))
        append!(result, merged_itemsets)
    end
    result
end

function translate_itemset(element, dict)
    Vector{Int32}(getindex.(Ref(dict), element))
end

function translate_rule(rule, dict)
    ((getindex.(Ref(dict), rule[1][1]), getindex.(Ref(dict), rule[1][2])) => rule[2] )
end

function apriori_rule_gen(
    frequent_itemsets::Vector{Pair{Set{Symbol},supp_int}}, 
    attribute_names::Vector{Symbol}, 
    min_confidence=0.3; 
    X_filters=Dict()
    ) where {supp_int <: Signed}

    symbol2index = Dict([x => y for (x, y) in zip(attribute_names, 1:length(attribute_names))])

    df = Dict(map(x -> sort(translate_itemset(x[1], symbol2index)) => x[2], frequent_itemsets))

    all_strong_rules = Vector{Pair{Tuple{Vector{Symbol},Vector{Symbol}},Float64}}()


    filters = Dict(map(x -> x[1] => sort(translate_itemset(x[2], symbol2index)), collect(X_filters)))

    for (Z_set, Z_sup) in frequent_itemsets
        if (length(Z_set) == 1) continue end

        Z = sort(Vector{Int32}(getindex.(Ref(symbol2index), Z_set)))
        i = 1
        Y = subsets(Z, i)
        
        if (haskey(filters, :x_in_ant)) 
            X = filters[:x_in_ant]
            if (all(X .∈ (Z,)))
                Y = filter(x -> x[1] ∉ X, Y)
            else continue end
        end

        if (haskey(filters, :con_in_x)) 
            X = filters[:con_in_x]
            Y = filter(x -> x[1] ∈ X, Y)
        end

        if (haskey(filters, :ant_in_x)) 
            X = filters[:ant_in_x]
            X = filter(x -> x[1] ∈ Z, X)
            ZmX = filter(x -> x ∉ X, Z)
            if (length(ZmX) > 0 && length(X) > 0)
                sp = ((X, ZmX) => Z_sup / df[X])
                if (sp[2] >= min_confidence)
                    append!(all_strong_rules,  [translate_rule(sp, attribute_names)])
                end 
            end
            Y = filter(x -> x[1] ∈ X, Y)
            Y = map(x -> vcat(ZmX, x), Y)
        end

        if (haskey(filters, :x_in_con)) 
            X = filters[:x_in_con]
            if (all(X .∈ (Z,))) # czy wszystkie elementy X są w Z
                ZmX = filter(x -> x ∉ X, Z)
                if (length(ZmX) > 0)
                    sp = (ZmX, X) => Z_sup / df[ZmX]
                    if (sp[2] >= min_confidence)
                        append!(all_strong_rules, [translate_rule(sp, attribute_names)])
                    end
                end
                Y = filter(x -> x[1] ∉ X, Y)
                Y = map(x -> vcat(X, x), Y)
            else continue end
        end

        if (length(Y) > 0 && length(Y[1]) < length(Z))
            i = length(Y[1])
            while true
                strong_rules = filter(x -> x[2] >= min_confidence, map(x -> begin
                    ant = antecedent(Z, x)
                    (ant, x) => Z_sup / df[ant] 
                end, Y))
                
                append!(all_strong_rules, map(x -> translate_rule(x, attribute_names), strong_rules))
                i += 1
                if (i == length(Z_set) || length(strong_rules) == 0) break end
                
                Y = merge_vectors(map(x -> x[1][2], strong_rules))
            end
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
    # print(df)
    antecedent_indices = findall(col_name -> col_name in antecedent, attr_names)
    consequent_indices = findall(col_name -> col_name in consequent, attr_names)
    antecedent_count = nrow(filter(row -> all([row[index] for index in antecedent_indices]), df))
    rule_count = nrow(filter(row -> all([row[index] for index in vcat(antecedent_indices, consequent_indices)]), df))
    required_rule_count = rows * support
    for row in eachrow(df)
        if !all([row[index] for index in vcat(antecedent_indices, consequent_indices)])
            for index in vcat(antecedent_indices, consequent_indices)
                row[index] = true
            end
            rule_count = rule_count + 1
        end
        if rule_count >= required_rule_count
            break
        end
    end
    return df
end

export apriori, dummy_dataset, dummy_dataset_biased, apriori_rule_gen, apriori_rule_gen2, apriori_frequent_itemsets, merge_vectors

end
