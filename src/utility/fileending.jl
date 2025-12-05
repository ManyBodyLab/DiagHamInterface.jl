"""
    fix_fileending(filename, ending)

Return `filename` ensuring it ends with `ending`.

If `ending` does not start with a dot, a dot is prepended. If `ending` is empty,
the original `filename` is returned. The function is safe to call with full
paths; it only checks the final characters of `filename`.
"""
function fix_fileending(filename::AbstractString, ending::AbstractString)
    # If no ending requested, nothing to do
    if isempty(ending)
        return filename
    end

    # Normalize ending to start with a dot
    norm_end = startswith(ending, ".") ? ending : "." * ending

    # Work on the basename only so we preserve directories
    dir = dirname(filename)
    base = basename(filename)

    # If the whole filename already ends with the correct ending, return as-is
    if endswith(base, norm_end)
        return filename
    end

    # Find last dot in the basename (if any)
    lastdot = findlast(==('.'), base)

    # Determine whether a real extension exists.
    # We treat a leading dot (hidden files like ".bashrc") without another dot
    # as not having an extension.
    has_ext = !isnothing(lastdot)

    if lastdot === nothing || !has_ext
        # No extension present -> append normalized ending
        newbase = string(base, norm_end)
    else
        # Replace existing extension (or trailing dot) with normalized ending
        # If the dot is the last character, drop it and append ending
        base_noext = base[1:(lastdot - 1)]
        newbase = string(base_noext, norm_end)
    end

    # Reconstruct full path, preserving whether original had a directory
    if !isempty(dir)
        return joinpath(dir, newbase)
    else
        return newbase
    end
end
