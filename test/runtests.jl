using Apriori
using Test
using Random

@testset "Apriori.jl" begin

    #testy uruchamia się z konsoli, wpisujesz ]test
    # ten pierwszy znak ] przejdzie do trybu obsługi paczek i wtedy na niebieski kolor zmieny prompt
    # jak zmieni kolor to dopisujesz test i enter
    # tak powinien prompt wyglądać przed enter
    # (Apriori) pkg> test

    let  #IZOLOWANY SCOPE, przydatny jak chcesz tych samych zmiennych używać i mieć pewność że nic nie wycieka poza test
        df = dummy_dataset_biased(20,100, 0.3, ['a'], ['b'], 1)
        result = apriori(df, 0.9, 0.9)
        rules = map(x->x[1], result)
        @test ([:b], [:a]) in rules
        @test ([:a], [:b]) in rules
        
        df = dummy_dataset_biased(20,100, 0.2, ['a', 'b'], ['c','d'], 1, 0.8)
        result = apriori(df, 0.9, 0.9)
        rules = map(x->x[1], result)
        @test !(([:a, :b], [:c, :d]) in rules)
        result = apriori(df, 0.7, 0.7)
        rules = map(x->x[1], result)
        @test ([:a, :b], [:c, :d]) in rules




        #CONSTRAINTS
        X = [:a]
        df = dummy_dataset_biased(20,100, 0.3, ['a', 'b'], ['c','d'], 1)
        result = apriori(df, 0.9, 0.9, X_in_antecedent=X)
        rules = map(x->x[1], result)
        for rule in rules
            for item in X
                @test item in rule[1]
            end
        end

        X = [:a]
        df = dummy_dataset_biased(20,100, 0.3, ['a', 'b'], ['c','d'], 1)
        result = apriori(df, 0.9, 0.9, 
                        X_in_antecedent=Vector{Symbol}()::Vector{Symbol},
                        antecedent_in_X=X)
        rules = map(x->x[1], result)
        for rule in rules
            for item in rule[1]
                @test item in X
            end
        end

        X = [:a]
        df = dummy_dataset_biased(20,100, 0.3, ['a', 'b'], ['c','d'], 1)
        result = apriori(df, 0.9, 0.9, 
                        X_in_antecedent=Vector{Symbol}()::Vector{Symbol},
                        antecedent_in_X=Vector{Symbol}()::Vector{Symbol},
                        X_in_consequent=X)
        rules = map(x->x[1], result)
        for rule in rules
            for item in X
                @test item in rule[2]
            end
        end

        df = dummy_dataset_biased(20,100, 0.3, ['a', 'b'], ['c','d'], 1)
        result = apriori(df, 0.9, 0.9, 
                        X_in_antecedent=Vector{Symbol}()::Vector{Symbol},
                        antecedent_in_X=Vector{Symbol}()::Vector{Symbol},
                        X_in_consequent=Vector{Symbol}()::Vector{Symbol},
                        consequent_in_X=X)
        rules = map(x->x[1], result)
        for rule in rules
            for item in rule[2]
                @test item in X
            end
        end
    end
    
    # ale nie musisz w tych blokach let/end pisać, możesz zrobić jakiś tu globalny d i sprawdzać wieloma @test
    
end
