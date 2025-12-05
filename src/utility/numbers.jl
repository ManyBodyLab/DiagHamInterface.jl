"""
    format_with_precision(x; atol=eps(float(T)), mode=:auto, maxdigits=20)

Format number `x` as a string with absolute precision `atol`.
Mode `:auto` uses `%f` for `[1e-3, 1e6)`, else `%e`. Use `:f` or `:e` to force format.
"""
function format_with_precision(x::T; atol = eps(float(T)), mode::Symbol = :auto, maxdigits::Int = 20) where {T <: Real}
    x == 0 && return "0.0"
    absx = abs(x)
    abs_atol = abs(atol)

    use_e = mode == :e || (mode == :auto && (absx < 1.0e-3 || absx >= 1.0e6))

    if use_e
        exp10 = floor(Int, log10(absx))
        log10_atol = log10(abs_atol)
        p = ceil(Int, exp10 - log10_atol)
        p = clamp(p, 0, maxdigits)
        return cfmt("%.$(p)e", x)
    else
        p = ceil(Int, -log10(abs_atol))
        p = clamp(p, 0, maxdigits)
        return cfmt("%.$(p)f", x)
    end
end

read_number(V::Number) = V
function read_number(V::AbstractString)::Union{Float64, ComplexF64}
    ## Function to turn "(1.234,5.678)" into 1.234+5.678im or if just a single element is given, i.e. 1.234, turn it into a Float64
    (V[1] == '(' && V[end] == ')') && return _read_number_bracket(V)

    return _read_number_space(V)
end
function _read_number_space(V::AbstractString)
    return _read_number_space(split(V, ' '))
end
function _read_number_space(V::AbstractVector{<:AbstractString})
    if length(V) == 1
        return parse(Float64, V[1])
    else
        real = parse(Float64, V[1])
        imag = parse(Float64, V[2])
        return ComplexF64(real, imag)
    end
end

function _read_number_bracket(V::AbstractString)
    V = split(V, ',')
    real = parse(Float64, V[1][2:end])
    imag = parse(Float64, V[2][1:(end - 1)])
    return ComplexF64(real, imag)
end

function write_number(V::Number; atol::Real = eps(real(float(V))))
    return format_with_precision(V; atol = atol)
end

function write_number(V::Complex; atol::Real = eps(real(float(V))))
    return string("(", format_with_precision(real(V); atol = atol), ",", format_with_precision(imag(V); atol = atol), ")")
end

function write_number_space(V::Number; atol::Real = eps(real(float(V))))
    return format_with_precision(V; atol = atol)
end

function write_number_space(V::Complex; atol::Real = eps(real(float(V))))
    return "$(format_with_precision(real(V); atol = atol)) $(format_with_precision(imag(V); atol = atol))"
end
