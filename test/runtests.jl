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
        @test true
        Random.seed!(2137) # jak raz ustawisz seed i potem chccesz jakiś test losowy to zmień na np. random.seed(current_time)
        d = dummy_dataset(20, 100)
        @test 370 == length(apriori(d))
    end
    
    # ale nie musisz w tych blokach let/end pisać, możesz zrobić jakiś tu globalny d i sprawdzać wieloma @test
    
end
