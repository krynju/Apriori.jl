module Apriori

using DataFrames
using Combinatorics


function apriori(
    data::DataFrame, 
    min_relative_support=0.2, 
    min_confidence=0.3;
    X_in_antecedent=Vector{Symbol}()::Vector{Symbol},
    antecedent_in_X=Vector{Symbol}()::Vector{Symbol},
    X_in_consequent=Vector{Symbol}()::Vector{Symbol},
    consequent_in_X=Vector{Symbol}()::Vector{Symbol},
    )

    attributes = propertynames(data)::Array{Symbol,1}

    symbol2index = Dict([x => y for (x, y) in zip(attributes, 1:length(attributes))])

    filters = __prepare_filters(symbol2index, X_in_antecedent, antecedent_in_X, X_in_consequent, consequent_in_X)

    frequent_itemsets = __apriori_frequent_itemsets(data, min_relative_support)

    rules = __apriori_rule_gen(frequent_itemsets, min_confidence, filters)
    map(x -> translate_rule(x, attributes), rules)
end

function apriori_frequent_itemsets(data::DataFrame, min_relative_support=0.2)
    attributes = propertynames(data)
    freq_itemsets = __apriori_frequent_itemsets(data, min_relative_support)
    symbol2index = Dict([x => y for (x, y) in zip(attributes, 1:length(attributes))])
    frequent_itemsets = map(x -> Set{Symbol}(getindex.(Ref(attributes), x[1])) => x[2], freq_itemsets)
end

function __apriori_frequent_itemsets(data::DataFrame, min_relative_support=0.2)
    supp = floor(min_relative_support * nrow(data))

    frequent_itemsets = Vector{Pair{Vector{Int32},Int64}}()
    attributes = propertynames(data)

    itemsets = [Vector{Int32}([i]) for i in 1:length(attributes)]
    infrequents = Set{Vector{Int32}}()

    while true
        itesmets_w_support = map(x -> x => support(data, x), itemsets)
        frequent_itesmets_w_support = filter(x -> x[2] > supp, itesmets_w_support)
        append!(frequent_itemsets, frequent_itesmets_w_support)
        
        if (length(frequent_itesmets_w_support) <= 1) break end

        itemsets = filter(x -> !any(subsets(x, length(x) - 1) .∈ (infrequents,)), merge_vectors(map(x -> x[1], frequent_itesmets_w_support))) 
        infrequents = map(y -> y[1], filter(x -> x[2] <= supp, itesmets_w_support))
    end
    
    frequent_itemsets
end

function __prepare_filters(translate_dict,
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

    filters = Dict(filter(x -> length(x[2]) > 0, map(x -> x[1] => sort(translate_itemset(x[2], translate_dict)), t)))
end

function apriori_rule_gen(
    frequent_itemsets::Vector{Pair{Set{Symbol},supp_int}}, 
    attribute_names::Vector{Symbol}, 
    min_confidence=0.3; 
    X_in_antecedent=Vector{Symbol}()::Vector{Symbol},
    antecedent_in_X=Vector{Symbol}()::Vector{Symbol},
    X_in_consequent=Vector{Symbol}()::Vector{Symbol},
    consequent_in_X=Vector{Symbol}()::Vector{Symbol},
    ) where {supp_int <: Signed}

    symbol2index = Dict([x => y for (x, y) in zip(attribute_names, 1:length(attribute_names))])
    frequent_itemsets = map(x -> sort(Vector{Int32}(getindex.(Ref(symbol2index), x[1]))) => x[2], frequent_itemsets)

    filters = __prepare_filters(symbol2index, X_in_antecedent, antecedent_in_X, X_in_consequent, consequent_in_X)

    rules = __apriori_rule_gen(frequent_itemsets, min_confidence, filters)
    map(x -> translate_rule(x, attribute_names), rules)
end

function __apriori_rule_gen(
    frequent_itemsets::Vector{Pair{Vector{Int32},supp_int}}, 
    min_confidence=0.3,
    filters=Dict()
    ) where {supp_int <: Signed}

    df = Dict(frequent_itemsets)

    all_strong_rules = Vector{Pair{Tuple{Vector{Int32},Vector{Int32}},Float64}}()

    for (Z_set, Z_sup) in frequent_itemsets
        if (length(Z_set) == 1) continue end

        Z = Z_set
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
                    append!(all_strong_rules,  [sp])
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
                        append!(all_strong_rules, [sp])
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
                
                append!(all_strong_rules, strong_rules)
                i += 1
                if (i == length(Z_set) || length(strong_rules) == 0) break end
                
                Y = merge_vectors(map(x -> x[1][2], strong_rules))
            end
        end
    end
    all_strong_rules
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
    (getindex.(Ref(dict), rule[1][1]), getindex.(Ref(dict), rule[1][2])) => rule[2] 
end

function support(data::DataFrame, attrs::Vector{Int32})
    nrow(data[reduce((x, y) -> x .& y, [data[!, attr] .== true for attr in attrs]),:])
end

function subsets(vec::Vector{idx_int}, len)where idx_int <: Signed
    Vector.(combinations([vec...], len))
end

function antecedent(fvec, vec)
    filter(x -> x ∉ vec, fvec)
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

export apriori, dummy_dataset, dummy_dataset_biased, apriori_rule_gen, apriori_frequent_itemsets, merge_vectors

end
