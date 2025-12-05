"""
    execute_diagham_script(execute; kwargs...)

Run a DiagHam executable. Kwargs are converted to CLI flags (`_` → `-`).
Single-char keys use `-k`, multi-char use `--key`. Boolean `true` adds flag, `false` omits.

The kwargs of `Cmd()` are supported.
"""
function execute_diagham_script(execute::AbstractString; kwargs...)
    return execute_diagham_script([execute]; kwargs...)
end

function execute_diagham_script(
        execute::AbstractVector{<:AbstractString};
        diagham_path::AbstractString = get_diagham_path(),
        ignorestatus::Bool = false,
        detach::Bool = false,
        windows_verbatim::Bool = false,
        windows_hide::Bool = false,
        env = nothing,
        dir = "",
        kwargs...
    )
    warn_about_diagham_path()

    ex_file = first(execute)
    execute[1] = joinpath(diagham_path, ex_file)
    execute = prod(execute)

    ## Now, we add kwargs to the command:
    for (k, v) in kwargs
        execute *= diagham_kwarg(k, v)
    end

    execute = Cmd(split(execute, " "))
    cmd = Cmd(execute; ignorestatus = ignorestatus, detach = detach, windows_verbatim = windows_verbatim, windows_hide = windows_hide, env = env, dir = dir)
    return run(cmd)
end

function diagham_kwarg(key, value)
    key = replace("$key", "_" => "-")
    key_print = length(key) == 1 ? " -$(key)" : " --$(key)"
    if value isa Bool
        if value
            return key_print
        end
    else
        return "$(key_print) $(value)"
    end
    return ""
end
