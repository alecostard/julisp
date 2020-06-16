module Julisp

Symbol = Base.String
Number = Union{Base.Int, Base.Float64}
Atom   = Union{Symbol, Number}
List   = Base.Vector
Exp    = Union{Atom, List}

""""An environment: a dict of {"var" => val} with an outer Env."""
struct Env
    table::Base.Dict
    outer::Union{Nothing, Env}
end
Env(keys, vals, env) = Env(Dict(zip(keys, vals)), env)

"Find the innermost Env where var appears."
find(env, var)::Env = haskey(env.table, var) ? env : find(env.outer, var)

"Methods for [] syntax."
Base.getindex(env::Env, i) = find(env, i).table[i]
Base.setindex!(env::Env, val, key) = setindex!(env.table, val, key)

"An environment with some Scheme standard procedures."
function standard_env()
    env = Env(Base.Dict(), nothing)
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
        error("Unexpected EOF")
    end

    token = popfirst!(tokens)
    if token == "("
        read_list_from_tokens!(tokens)
    elseif token == ")"
        error("Unexpected ')'")
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
eval(expr::Symbol, env = global_env) = env[expr]
eval(expr::Number, _) = expr
eval(expr::List, env = global_env) = eval_list(expr[1], expr[2:end], env)

"Evaluate a list in an environment."
function eval_list(op::Exp, args::List, env)
    if op == "if"
        eval_if(args, env)
    elseif op == "define"
        eval_define(args, env)
    else 
        eval_procedure(op, args, env)
    end
end

"Evaluate an if expression."
function eval_if((test, conseq, alt), env) 
    x = eval(test, env) ? conseq : alt
    eval(x, env)
end

"Evaluate a define expression."
function eval_define((symbol, exp), env) 
    env[symbol] = eval(exp, env)
    nothing
end

"Evaluate procedure call."
function eval_procedure(proc_name, args, env)
    proc = eval(proc_name, env)
    evaluated_args = [eval(arg, env) for arg in args]
    proc(evaluated_args...)
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