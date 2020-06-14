using Test

include("./julisp.jl")
using .Julisp

@testset "tokenize" begin
    tokenize = Julisp.tokenize
    @test ["1"] == Julisp.tokenize("1")
    program1 = "(define x 1)"
    @test ["(", "define", "x", "1", ")"] == Julisp.tokenize(program1)
    program2 = "(* (+ 1 2) 3)"
    @test ["(", "*", "(", "+", "1", "2", ")", "3", ")"] ==
        Julisp.tokenize(program2)
end

@testset "read_from_tokens!" begin
    tokens = Julisp.tokenize("(inc 1)")
    @test ["inc", 1] == Julisp.read_from_tokens!(tokens)
end

@testset "read_list" begin
    tokens1 = Julisp.tokenize("inc 1)")
    @test ["inc", 1] == Julisp.read_list_from_tokens!(tokens1)
    tokens2 = Julisp.tokenize("inc (dec 1))")
    @test ["inc", ["dec", 1]] == Julisp.read_list_from_tokens!(tokens2)
end

@testset "atom" begin
    atom = Julisp.atom
    @test 1 == atom("1")
    @test 1.0 == atom("1.0")
    @test "xyz" == atom("xyz")
end

@testset "parse" begin
   program1 = "(+ 2 (inc 3))" 
   @test ["+", 2, ["inc", 3]] == Julisp.parse(program1)
end

@testset "eval" begin
    @test 1 == Julisp.eval(1)
    program1 = Julisp.parse("(+ 1 2)")
    @test 3 == Julisp.eval(program1)
    program2 = Julisp.parse("(begin (define r 10) (* pi (* r r)))")
    @test 100pi ≈ Julisp.eval(program2)
    program3 = Julisp.parse("(if (= 2 1) (+ 1 3) (* 1 2))")
    @test 2 == Julisp.eval(program3)
end