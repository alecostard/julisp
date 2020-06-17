using Test

include("./julisp.jl")
using .Julisp

@testset "Julisp" begin

    @testset "tokenize" begin
        tokenize = Julisp.tokenize

        @testset "returns an empty list when input is empty" begin
            @test [] == tokenize("")
        end

        @testset "treats the input as space separated list" begin
            @test ["1"] == tokenize("1")
            @test ["a", "1", "2"] == tokenize("a 1 2")
        end

        @testset "considers parenthesis a token even when not isolated" begin
            @test ["(", "inc", "1", ")"] == tokenize(" ( inc 1 )   ")

            @test ["(", "define", "x", "1", ")"] == tokenize("(define x 1)")
        
            @test ["(", "*", "(", "+", "1", "2", ")", "3", ")"] == 
                tokenize("(* (+ 1 2) 3)")
        end
    end

    @testset "parse" begin
        parse = Julisp.parse
        read_from_tokens! = Julisp.read_from_tokens!

        @testset "errors on empty input" begin
            @test_throws ErrorException parse("")
        end

        @testset "errors on closed parenthesis before open parenthesis" begin
            @test_throws ErrorException parse(")")
        end

        @testset "returns atoms on a single token" begin
            @test 1 == parse("1")
            @test 3.14 ≈ parse("3.14")
            @test "xyz" == parse("xyz")
        end

        @testset "returns lists if input is multiple valued" begin
            @test ["op"] == parse("(op)")
            @test ["inc", 1] == parse("(inc 1)")
            @test ["inc", ["+", 1, "x"]] == parse("(inc (+ 1 x))")
        end
    end

    @testset "eval evaluates" begin
        eval = Julisp.eval
        @testset "numbers to themselves" begin
            @test 1 == eval(1)
            @test 3.14 ≈ eval(3.14)
        end

        @testset "symbols to their values in the environment" begin
            @test pi == eval("pi")
        end
        
        @testset "define expressions by adding a new binding to the environment" begin
            eval(["define",  "x",  1])
            @test 1 == eval("x")
        end

        @testset "primitive function application to their result" begin
            @test 3 == eval(["+", 1, 2])
            @test 9 == eval(["*", ["+", 1, 2], 3])
        end

        @testset "only the correct branch of an if expression" begin
            @test_throws Exception eval("oops")
            @test 1 == eval(["if", ["=", 1, 1], 1, "oops"])
            @test 1 == eval(["if", ["=", 1, 2], "oops", 1])
        end

        @testset "anonymous procedure applications to their result" begin
            program = "((lambda (x y) (+ x y)) 1 2)"
            @test 3 == program |> Julisp.parse |> eval
        end
    end

end