function execute_diagham_script(execute::AbstractString; kwargs...)
    return execute_diagham_script([execute]; kwargs...)
end

function execute_diagham_script(execute::AbstractVector{<:AbstractString}; 
    diagham_path::AbstractString=diagham_path,
    ignorestatus::Bool=false, 
    detach::Bool=false, 
    windows_verbatim::Bool=false, 
    windows_hide::Bool=false, 
    env=nothing, 
    dir="",
    kwargs...)
    ex_file = first(execute)
    execute[1] = joinpath(diagham_path, ex_file)
    execute = prod(execute)
    
    ## Now, we add kwargs to the command:
    for (k,v) in kwargs 
        if v isa Bool 
            if v
                if length(k) == 1
                    execute *= " -$(k)"
                else
                    execute *= " --$(k)"
                end
            end
        elseif length(k) == 1
            # single character key -> single dash
            execute *= " -$(k) $(v)"
        else
            # multi character key -> double dash
            execute *= " --$(k)=$(v)"
        end
    end

    execute = Cmd(split(execute," "))
    cmd=Cmd(execute; ignorestatus=ignorestatus, detach=detach, windows_verbatim=windows_verbatim, windows_hide=windows_hide, env=env, dir=dir)
    run(cmd)
end
