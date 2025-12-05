function read_matrix_elements(
        file_name::AbstractString;
        conjugate::Bool = false,
        atol::Real = eps(Float64)
    )
    Vs, header = readdlm(file_name; header = true)
    if header[1] == "#"
        header = header[2:(end - 1)]
        Vs = Vs[:, 1:(end - 1)]
    end
    coeffs = read_number.(Vs[:, end])

    imag_part = sum(abs2, imag.(coeffs)) / sum(abs2, coeffs)

    if sqrt(imag_part) < atol
        coeffs = real.(coeffs)
    end
    isempty(coeffs) && (coeffs = Float64[])
    if !isempty(coeffs)
        coeffs = convert(Vector{typeof(coeffs[1])}, coeffs)
    end
    conjugate && (conj!(coeffs))
    indices = convert(Matrix{Int}, Vs[:, 1:(end - 1)])
    return reinstate_indices(header, indices, coeffs)
end

function reinstate_indices(header, indices, coeffs) ## This function takes care of dropped indices e.g. in the 1-body term and renamed band indices to n
    band_n = findall(x -> occursin("n", x), header)
    @assert length(band_n) in [0, 1]
    if length(band_n) == 1
        i = band_n[1]
        header[i] = "m_2"
        band_m = only(findall(x -> occursin("m", x), header))
        header[band_m] = "m_1"
    end
    has_index = findall(x -> occursin("_", x), header)
    no_index = setdiff(1:length(header), has_index)
    num_index = length(unique([parse(Int, split(h, "_")[2]) for h in header[has_index]]))
    if iszero(num_index)    # Then it is a 1-body term
        num_index = 2
    end
    for i in no_index
        h = header[i]
        header[i] = h * "_1"
        for j in 2:num_index
            push!(header, h * "_$(j)")
            indices = hcat(indices, indices[:, i])
        end
    end

    # Build a permutation that, for each suffix _i, sorts the columns
    # within that suffix (by their label) and then concatenates the groups
    # in order _1, _2, ...
    suffixes = [parse(Int, split(h, "_")[2]) for h in header]
    perm = Int[]
    for s in unique(sort(suffixes))
        # positions of headers with suffix s
        pos = findall(x -> suffixes[x] == s, 1:length(header))
        if !isempty(pos)
            # local order within the group: sort by label string (stable)
            local_order = sortperm(header[pos])
            append!(perm, pos[local_order])
        end
    end
    header = header[perm]
    indices = indices[:, perm]
    return header, indices, coeffs
end
