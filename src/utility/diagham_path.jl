function set_diagham_path(path::String)
    path=expanduser(path)

    @set_preferences!("diagham_path" => path)
    if !occursin("build", path)
        @warn "The DiagHam path should point to the build directory of DiagHam. This path does not seem to do so, so please double check if this is correct!"
    end
    @info "Set DiagHam path to $path; restart your Julia session for this change to take effect!"
    return nothing
end

const diagham_path = expanduser(@load_preference("diagham_path", "~/development/DiagHam/build"))

function warn_about_diagham_path()
    # Set the default path for DiagHam
    if !@has_preference("diagham_path")
        @info "Setting default DiagHam path to $(diagham_path), if you want to change it,\n use the HybridWanniers.set_diagham_path(path::String) function and restart your Julia session."
    end
    return nothing
end
