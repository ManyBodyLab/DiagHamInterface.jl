function _parse_density_header(filename::AbstractString)
    header_line = open(filename) do io
        for line in eachline(io)
            startswith(strip(line), '#') && return line
        end
        error("No header line found in $filename")
    end

    is_two_body = occursin("c^+ c^+ c c", header_line)

    tokens = split(header_line)
    # Remove leading '#' and drop everything from the first '<…>' group onward
    filter!(t -> t != "#", tokens)
    bracket_start = findfirst(t -> startswith(t, "<"), tokens)
    if !isnothing(bracket_start)
        resize!(tokens, bracket_start - 1)
    end
    Ncols_index = length(tokens)

    has_spin = any(t -> t == "spin" || startswith(t, "spin"), tokens)

    # Catch unsupported modes
    if any(occursin(t, "psi_i") || occursin(t, "phi_j") for t in tokens)
        error("Off-diagonal mode (--off-diagonal) output is not supported")
    end
    if any(t -> t == "kz" || startswith(t, "kz"), tokens)
        error("3D lattice output is not supported")
    end

    return is_two_body, has_spin, Ncols_index
end

function _read_density_rows(filename::AbstractString, Ncols_index::Int)
    index_rows = Vector{Int}[]
    value_strs = String[]

    open(filename) do io
        first_header_seen = false
        for line in eachline(io)
            stripped = strip(line)
            isempty(stripped) && continue
            if startswith(stripped, '#')
                first_header_seen = true
                continue
            end
            first_header_seen || continue  # skip anything before first header
            tokens = split(stripped)
            length(tokens) < Ncols_index + 1 && continue
            push!(index_rows, parse.(Int, tokens[1:Ncols_index]))
            push!(value_strs, join(tokens[(Ncols_index + 1):end], " "))
        end
    end

    isempty(index_rows) && return Matrix{Int}(undef, 0, Ncols_index), Number[]
    index_matrix = reduce(hcat, index_rows)'  # (nrows, Ncols_index)
    values = read_number.(value_strs)
    return index_matrix, values
end

function _determine_type(values::AbstractVector, atol::Real)
    isempty(values) && return Float64
    return any(v -> abs(imag(v)) > atol, values) ? ComplexF64 : Float64
end

"""
    read_one_body_density(filename; atol=1e-14) -> Array{T,6}

Read a one-body density matrix file produced by DiagHam's FTIDensity program.

Returns an array of shape `(Nk, Nband, Nspin, Nk, Nband, Nspin)` where
`result[k1, b1, s1, k2, b2, s2] = ⟨c†_{k1-1, b1-1, s1-1} c_{k2-1, b2-1, s2-1}⟩`.

The momentum index `k` is linearized as `k = kx*Nky + ky` (0-based in file,
1-based in the returned array). Nkx, Nky, Nband, Nspin are inferred from the
data. For single-band files Nband=1 and Nspin=1. For files with a `spin` column
(NbrBands=4 or 6) Nspin=2.

Since FTIDensity only writes diagonal-in-k entries, all off-diagonal-k entries
are zero.
"""
function read_one_body_density(filename::AbstractString; atol::Real = 1.0e-14)
    is_two_body, has_spin, Ncols_index = _parse_density_header(filename)
    is_two_body && error("File contains two-body density; use read_two_body_density instead")

    index_matrix, values = _read_density_rows(filename, Ncols_index)

    if isempty(values)
        T = Float64
        return zeros(T, 0, 1, 1, 0, 1, 1)
    end

    T = _determine_type(values, atol)

    kx_col = index_matrix[:, 1]
    ky_col = index_matrix[:, 2]
    Nkx = maximum(kx_col) + 1
    Nky = maximum(ky_col) + 1
    Nk = Nkx * Nky

    if Ncols_index == 2
        # 1-band: kx ky val
        Nband = 1
        Nspin = 1
        result = zeros(T, Nk, Nband, Nspin, Nk, Nband, Nspin)
        for (i, val) in enumerate(values)
            k = kx_col[i] * Nky + ky_col[i] + 1
            v = T == Float64 ? real(val) : convert(T, val)
            result[k, 1, 1, k, 1, 1] = v
        end
    elseif !has_spin
        # 2/3-band: kx ky sigma_cr sigma_an val
        sigcr_col = index_matrix[:, 3]
        sigan_col = index_matrix[:, 4]
        Nband = maximum(max.(sigcr_col, sigan_col)) + 1
        Nspin = 1
        result = zeros(T, Nk, Nband, Nspin, Nk, Nband, Nspin)
        for (i, val) in enumerate(values)
            k = kx_col[i] * Nky + ky_col[i] + 1
            bcr = sigcr_col[i] + 1
            ban = sigan_col[i] + 1
            v = T == Float64 ? real(val) : convert(T, val)
            result[k, bcr, 1, k, ban, 1] = v
        end
    else
        # 4/6-band: kx ky spin sigma_cr sigma_an val
        spin_col = index_matrix[:, 3]
        sigcr_col = index_matrix[:, 4]
        sigan_col = index_matrix[:, 5]
        Nband = maximum(max.(sigcr_col, sigan_col)) + 1
        Nspin = maximum(spin_col) + 1
        result = zeros(T, Nk, Nband, Nspin, Nk, Nband, Nspin)
        for (i, val) in enumerate(values)
            k = kx_col[i] * Nky + ky_col[i] + 1
            s = spin_col[i] + 1
            bcr = sigcr_col[i] + 1
            ban = sigan_col[i] + 1
            v = T == Float64 ? real(val) : convert(T, val)
            result[k, bcr, s, k, ban, s] = v
        end
    end

    return result
end

"""
    read_two_body_density(filename; atol=1e-14) -> Array{T,12}

Read a two-body density matrix file produced by DiagHam's FTIDensity program
(output of the `--rhorho` flag).

Returns an array of shape `(Nk,Nb,Ns, Nk,Nb,Ns, Nk,Nb,Ns, Nk,Nb,Ns)` where
`result[k1,b1,s1, k2,b2,s2, k3,b3,s3, k4,b4,s4] = ⟨c†_1 c†_2 c_3 c_4⟩`.
All indices are 1-based; k is linearized as `k = kx*Nky + ky + 1`.
"""
function read_two_body_density(filename::AbstractString; atol::Real = 1.0e-14)
    is_two_body, has_spin, Ncols_index = _parse_density_header(filename)
    !is_two_body && error("File contains one-body density; use read_one_body_density instead")

    index_matrix, values = _read_density_rows(filename, Ncols_index)

    if isempty(values)
        T = Float64
        return zeros(T, ntuple(_ -> 1, 12)...)
    end

    T = _determine_type(values, atol)

    stride = has_spin ? 4 : 3  # columns per particle: kx, ky, [spin,] sigma

    kx_cols = [index_matrix[:, 1 + (p - 1) * stride] for p in 1:4]
    ky_cols = [index_matrix[:, 2 + (p - 1) * stride] for p in 1:4]
    if has_spin
        spin_cols = [index_matrix[:, 3 + (p - 1) * stride] for p in 1:4]
        sigma_cols = [index_matrix[:, 4 + (p - 1) * stride] for p in 1:4]
    else
        sigma_cols = [index_matrix[:, 3 + (p - 1) * stride] for p in 1:4]
    end

    Nkx = maximum(maximum.(kx_cols)) + 1
    Nky = maximum(maximum.(ky_cols)) + 1
    Nk = Nkx * Nky
    Nband = maximum(maximum.(sigma_cols)) + 1
    Nspin = has_spin ? maximum(maximum.(spin_cols)) + 1 : 1

    result = zeros(T, Nk, Nband, Nspin, Nk, Nband, Nspin, Nk, Nband, Nspin, Nk, Nband, Nspin)

    for (i, val) in enumerate(values)
        ks = [kx_cols[p][i] * Nky + ky_cols[p][i] + 1 for p in 1:4]
        bs = [sigma_cols[p][i] + 1 for p in 1:4]
        ss = has_spin ? [spin_cols[p][i] + 1 for p in 1:4] : [1, 1, 1, 1]
        v = T == Float64 ? real(val) : convert(T, val)
        result[ks[1], bs[1], ss[1], ks[2], bs[2], ss[2], ks[3], bs[3], ss[3], ks[4], bs[4], ss[4]] = v
    end

    return result
end

"""
    two_body_normal_to_density_density(rho2, rho1; statistics=:fermi) -> Array{T,12}

Convert the normal-ordered two-body density matrix `⟨c†_1 c†_2 c_3 c_4⟩` to
the density-density ordering `⟨c†_1 c_3 c†_2 c_4⟩` using commutation relations.

For fermions (`statistics=:fermi`, anticommutator `{c,c†}=δ`):
    ⟨c†_1 c_3 c†_2 c_4⟩ = δ_{23} ⟨c†_1 c_4⟩ - ⟨c†_1 c†_2 c_3 c_4⟩

For bosons (`statistics=:bose`, commutator `[b,b†]=δ`):
    ⟨b†_1 b_3 b†_2 b_4⟩ = δ_{23} ⟨b†_1 b_4⟩ + ⟨b†_1 b†_2 b_3 b_4⟩

`rho2` has shape `(Nk,Nb,Ns, Nk,Nb,Ns, Nk,Nb,Ns, Nk,Nb,Ns)` (from
`read_two_body_density`). `rho1` has shape `(Nk,Nb,Ns, Nk,Nb,Ns)` (from
`read_one_body_density`). The returned array has the same shape as `rho2`, with
index semantics `[k1,b1,s1, k3,b3,s3, k2,b2,s2, k4,b4,s4]`.
"""
function two_body_normal_to_density_density(
        rho2::Array{T, 12}, rho1::Array{T, 6}; statistics::Symbol = :fermi
    ) where {T}
    coeff = _rho2_permuted_coeff(statistics)
    # Permute rho2: swap particle-2 block (dims 4-6) and particle-3 block (dims 7-9)
    rho_dd = coeff .* permutedims(rho2, [1, 2, 3, 7, 8, 9, 4, 5, 6, 10, 11, 12])
    _add_delta_rho1!(rho_dd, rho1)
    return rho_dd
end

"""
    density_density_to_two_body_normal(rho_dd, rho1; statistics=:fermi) -> Array{T,12}

Convert the density-density ordering `⟨c†_1 c_3 c†_2 c_4⟩` back to the
normal-ordered two-body density matrix `⟨c†_1 c†_2 c_3 c_4⟩`.

For fermions: `⟨c†_1 c†_2 c_3 c_4⟩ = δ_{23} ⟨c†_1 c_4⟩ - ⟨c†_1 c_3 c†_2 c_4⟩`
For bosons:   `⟨b†_1 b†_2 b_3 b_4⟩ = δ_{23} ⟨b†_1 b_4⟩ + ⟨b†_1 b_3 b†_2 b_4⟩`

`rho_dd` has index semantics `[k1,b1,s1, k3,b3,s3, k2,b2,s2, k4,b4,s4]` as
returned by `two_body_normal_to_density_density`. The returned array has the
same shape with index semantics `[k1,b1,s1, k2,b2,s2, k3,b3,s3, k4,b4,s4]`.
"""
function density_density_to_two_body_normal(
        rho_dd::Array{T, 12}, rho1::Array{T, 6}; statistics::Symbol = :fermi
    ) where {T}
    coeff = _rho2_permuted_coeff(statistics)
    # Same permutation: swap particle-2 block (dims 7-9 in rho_dd) and particle-3 block (dims 4-6)
    rho2 = coeff .* permutedims(rho_dd, [1, 2, 3, 7, 8, 9, 4, 5, 6, 10, 11, 12])
    _add_delta_rho1!(rho2, rho1)
    return rho2
end

# Coefficient applied to the permuted rho2 (or rho_dd) in the conversion formula:
#   fermi: rho_dd = -rho2_perm + δ·rho1  → coeff = -1
#   bose:  rho_dd = +rho2_perm + δ·rho1  → coeff = +1
function _rho2_permuted_coeff(statistics::Symbol)
    statistics == :fermi && return -1
    statistics == :bose  && return +1
    error("Unknown statistics $statistics; expected :fermi or :bose")
end

# Add δ_{23} ⟨c†_1 c_4⟩ to result[k1,b1,s1, k2,b2,s2, k2,b2,s2, k4,b4,s4]
# (dims 4-6 and 7-9 are the two α2=α3 blocks, dims 1-3=α1, 10-12=α4)
function _add_delta_rho1!(result::Array{T, 12}, rho1::Array{T, 6}) where {T}
    Nk, Nb, Ns = size(rho1, 1), size(rho1, 2), size(rho1, 3)
    for s2 in 1:Ns, b2 in 1:Nb, k2 in 1:Nk
        @views result[:, :, :, k2, b2, s2, k2, b2, s2, :, :, :] .+= rho1[:, :, :, :, :, :]
    end
    return result
end
