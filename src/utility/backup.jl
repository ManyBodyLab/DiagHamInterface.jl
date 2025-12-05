function backup_file!(filename::AbstractString)
    if isfile(filename)
        backup_name = filename * ".bak"
        if isfile(backup_name)
            backup_2_name = backup_name * ".bak"
            if isfile(backup_2_name)
                rm(backup_2_name; force = true)
            end
            mv(backup_name, backup_2_name; force = true)
        end
        mv(filename, backup_name; force = true)
    end
    return nothing
end
