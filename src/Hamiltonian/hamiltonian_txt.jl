"""
    write_to_txt(Ham, filename; atol)

Write Hamiltonian matrix to DiagHam-format text file (sparse coordinate format, 0-based indexing).
Elements with `abs(val) ≤ atol` are omitted. Existing files are backed up.
"""
function write_to_txt(Ham::AbstractMatrix{T}, filename::String; atol::Real = eps(real(float(T)))) where {T <: Number}
    filename = fix_fileending(filename, ".txt")
    backup_file!(filename)

    open(filename, "w") do io
        for i in axes(Ham, 1)   ## This is sorted by rows first for DiagHam.
            for j in axes(Ham, 2)
                @inbounds val = Ham[i, j]
                if abs(val) > atol
                    println(io, "$(i - 1) $(j - 1) $(write_number_space(val; atol = atol))")
                end
            end
        end
    end
    return nothing
end

"""
Optimized `write_to_txt` for `SparseMatrixCSC`. Converts to CSR internally.
"""
function write_to_txt(Ham::SparseMatrixCSC, filename::String; atol::Real = eps(real(float(eltype(Ham)))))
    filename = fix_fileending(filename, ".txt")
    backup_file!(filename)

    cols, rows, vals = findnz(permutedims(Ham, (2, 1)))   ## DiagHam uses CSR instead of CSC, this way the rows are sorted and per row the columns are sorted
    open(filename, "w") do io
        for i in eachindex(vals)
            println(io, "$(rows[i] - 1) $(cols[i] - 1) $(write_number_space(vals[i]; atol = atol))")
        end
    end
    return nothing
end


"""
    read_matrix_from_txt(filename; sparsity=0.1)

Read Hamiltonian from DiagHam-format text file. Auto-detects real/complex.
Returns dense matrix if non-zero fraction > `sparsity`, else sparse.
"""
function read_matrix_from_txt(filename::String; sparsity::Number = 0.1)
    filename = fix_fileending(filename, ".txt")
    row_inds = Int[]
    col_inds = Int[]

    fid = open(filename, "r")
    len = length(split(readline(fid), " "))
    T = len == 3 ? Float64 : ComplexF64
    vals = T[]
    close(fid)

    open(filename, "r") do io
        for line in eachline(io)
            splits = split(line)
            push!(row_inds, parse(Int, splits[1]) + 1)  ## Convert to 1-based indexing
            push!(col_inds, parse(Int, splits[2]) + 1)
            push!(vals, _read_number_space(splits[3:end])::T)
        end
    end
    dim_row, dim_col = maximum(row_inds), maximum(col_inds)
    if length(vals) / (dim_row * dim_col) > sparsity
        dense_mat = zeros(T, dim_row, dim_col)
        for i in eachindex(vals)
            dense_mat[row_inds[i], col_inds[i]] = vals[i]
        end
        return dense_mat
    end
    return sparse(row_inds, col_inds, vals, dim_row, dim_col)
end
