""" 
    set_diagham_path(path)

Set the path to the DiagHam build directory.
"""
function set_diagham_path(path)
    path = expanduser(path)

    @set_preferences!("diagham_path" => path)
    if !occursin("build", path)
        @warn "The DiagHam path should point to the build directory of DiagHam. This path does not seem to do so, so please double check if this is correct!"
    end
    @info "Set DiagHam path to $path."
    diagham_path[] = path
    return path
end

const diagham_path = Ref(expanduser(@load_preference("diagham_path", "~/DiagHam/build")))

""" 
    get_diagham_path()
Get the current path to the DiagHam build directory.
"""
function get_diagham_path()
    return diagham_path[]
end

function warn_about_diagham_path()
    # Set the default path for DiagHam
    if !@has_preference("diagham_path")
        @info "Setting default DiagHam path to $(diagham_path[]), if you want to change it,\n use the `DiagHamInterface.set_diagham_path(path)` function." maxlog = 1
    end
    return nothing
end
