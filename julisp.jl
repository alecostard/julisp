module Julisp

Symbol = Base.String
Number = Union{Base.Int, Base.Float64}
Atom   = Union{Symbol, Number}
List   = Base.Vector
Exp    = Union{Atom, List}
Env    = Base.Dict

"An environment with some Scheme standard procedures."
function standard_env()
    env = Env()
    env["begin"] = (x...) -> x[end]
    env["pi"] = pi
    env["+"] = +
    env["-"] = -
    env["*"] = *
    env["/"] = /
    env["="] = ==
    env["<"] = <
    env[">="] = >=
    env[">"] = >
    env["<="] = <=    
    env["first"] = x -> x[1]
    env["rest"] = x -> x[2:end]
    env["list"] = (x...) -> [y for y in x]
    env["list?"] = x -> isa(x, List)
    env["null?"] = x -> x == []
    env["symbol?"] = x -> isa(x, Symbol)
    env["number?"] = x -> isa(x, Number)
    env
end
global_env = standard_env()

"Convert a string of characters into a list of tokens."
function tokenize(chars)
    (
        chars
        |> s -> replace(s, "(" => " ( ")
        |> s -> replace(s, ")" => " ) ")
        |> split
    )
end

"Read a Scheme expr from a string."
function parse(program)
    program |> tokenize |> read_from_tokens!
end

"Read an expr from a sequence of tokens."
function read_from_tokens!(tokens)
    if length(tokens) == 0
        throw("Unexpected EOF")
    end

    token = popfirst!(tokens)
    if token == "("
        return read_list_from_tokens!(tokens)
    elseif token == ")"
        throw("Unexpected ')'")
    else
        atom(token)
    end
end

"Read a list from a sequence of tokens."
function read_list_from_tokens!(tokens)
    L = []
    while tokens[1] != ")"
        push!(L, read_from_tokens!(tokens))
    end
    popfirst!(tokens) # pop closing paren
    return L    
end

"Numbers become numbers. Every other token is a symbol."
function atom(token)
    if tryparse(Int, token) |> !isnothing
        tryparse(Int, token)
    elseif tryparse(Float64, token) |> !isnothing
        tryparse(Float64, token)
    else
        Symbol(token)
    end
end
"Evaluate an expr in an environment."
eval(expr::Symbol, env=global_env) = env[expr]
eval(expr::Number, env=global_env) = expr
function eval(expr::List, env=global_env)
    if expr[1] == "if"
        (_, test, conseq, alt) = expr
        x = eval(test, env) ? conseq : alt
        eval(x, env)
    elseif expr[1] == "define"
        (_, symbol, exp) = expr
        env[symbol] = eval(exp, env)
    else 
        proc = eval(expr[1], env)
        args = [eval(arg, env) for arg in expr[2:end]]
        proc(args...)
    end
end

"A prompt-read-eval-print loop."
function repl(prompt="julisp> ")
    while true
        print(prompt)
        readline(stdin) |> parse |> eval |> schemestr |> println
    end
end

"Convert a Julia object back into a Scheme-readable string."
schemestr(atom::Atom) = string(atom)
schemestr(list::List) = "(" * join(list, " ") * ")"

end # module