function write_to_txt(Ham::AbstractMatrix{T}, filename::String; atol::Real=eps(real(float(T)))) where {T<:Number}
    filename = fix_fileending(filename, ".txt")

    open(filename, "w") do io
        for i in axes(Ham, 1)   ## This is sorted by rows first for DiagHam.
            for j in axes(Ham, 2)
                @inbounds val = Ham[i, j]
                if abs(val) > atol
                    println(io, "$(i-1) $(j-1) $(write_number_space(val; atol=atol))")
                end
            end
        end
    end
    return nothing
end

function write_to_txt(Ham::SparseMatrixCSC, filename::String; atol::Real=eps(real(float(eltype(Ham)))))
    if !endswith(filename, ".txt")
        filename *= ".txt"
    end
    rows, cols, vals = findnz(Ham)
    open(filename, "w") do io
        for i in eachindex(vals)
            println(io, "$(rows[i]-1) $(cols[i]-1) $(write_number_space(vals[i]; atol=atol))")
        end
    end
    return nothing
end


function read_matrix_from_txt(filename::String;sparsity::Number=0.05)
    filename = fix_fileending(filename, ".txt")
    row_inds = Int[]
    col_inds = Int[]

    fid = open(filename, "r")
    rows,cols=Int[],Int[]
    len=length(split(readline(fid), " "))
    T = len==3 ? Float64 : ComplexF64
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
    dim_row, dim_col = maximum(rows), maximum(cols)
    if length(vals) / (dim_row * dim_col) > sparsity
        dense_mat = zeros(T, dim_row, dim_col)
        for i in eachindex(vals)
            dense_mat[row_inds[i], col_inds[i]] = vals[i]
        end
        return dense_mat
    end
    return sparse(rows, cols, vals, dim_row, dim_col)
end
