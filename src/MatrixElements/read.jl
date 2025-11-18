function read_matrix_elements(
    file_name::AbstractString;
    conjugate::Bool=false,
)
    Vs, header = readdlm(file_name; header=true)
    if header[1] == "#"
        header = header[2:(end - 1)]
        Vs = Vs[:, 1:(end - 1)]
    end
    coeffs = read_number.(Vs[:, end])
    coeffs = convert(Vector{typeof(coeffs[1])}, coeffs)
    conjugate && (conj!(coeffs))
    indices = convert(Matrix{Int}, Vs[:, 1:(end - 1)])
    return header, indices, coeffs
end
