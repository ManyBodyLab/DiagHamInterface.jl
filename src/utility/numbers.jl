const _e_formatters = [generate_formatter("%.$(p)e") for p in 0:40]
const _f_formatters = [generate_formatter("%.$(p)f") for p in 0:40]

"""
    absprint(x; atol=1e-14, mode=:auto, maxdigits=20)

Return a string for x with approximately fixed absolute precision `atol`.
- mode = :auto chooses %f for |x| in [1e-3, 1e6), else %e.
- mode = :f forces fixed-point; mode = :e forces scientific.
- maxdigits caps digits after decimal to avoid impractically long strings.
"""
function absprint(x::T; atol=eps(float(T)), mode::Symbol=:auto, maxdigits::Int=20) where {T <: Real}
    # For x = 0, print atol scale directly
    x == 0 && return "0.0"
    # Cache absolute values to avoid repeated calls
    absx = abs(x)
    abs_atol = abs(atol)

    # Choose format if :auto
    use_e = mode==:e || (mode==:auto && (absx < 1e-3 || absx >= 1e6))

    if use_e
        # %e prints mantissa with p digits after decimal; absolute step ≈ 10^(exp10 - p)
        exp10 = floor(Int, log10(absx))
        # p is the number of digits after the decimal in the mantissa
        # so that the absolute step is about 10^(exp10 - p) ≈ atol
        # Precompute log10(atol)
        log10_atol = log10(abs_atol)
        p = ceil(Int, exp10 - log10_atol)
        p = clamp(p, 0, maxdigits)
        return _e_formatters[p+1](x)
    else
        # %f prints p digits after decimal; absolute step ≈ 10^(-p)
        p = ceil(Int, -log10(abs_atol))
        p = clamp(p, 0, maxdigits)
        return _f_formatters[p+1](x)
    end
end

function read_number(V::AbstractString)::Union{Float64, ComplexF64}
    ## Function to turn "(1.234,5.678)" into 1.234+5.678im or if just a single element is given, i.e. 1.234, turn it into a Float64
    (V[1]=='(' && V[end]==')') && return _read_number_bracket(V)

    return _read_number_space(V)
end
function _read_number_space(V::AbstractString)
    V = split(V, ' ')
    if length(V) == 1
        return parse(Float64, V[1])
    else 
        real = parse(Float64, V[1])
        imag = parse(Float64, V[2])
        return ComplexF64(real, imag)
    end
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
    imag = parse(Float64, V[2][1:end-1])
    return ComplexF64(real, imag)
end

function write_number(V::Number; atol::Real=eps(real(float(V))))
    return absprint(V; atol=atol)
end

function write_number(V::Complex; atol::Real=eps(real(float(V))))
    return string("(", absprint(real(V); atol=atol), ",", absprint(imag(V); atol=atol), ")")
end

function write_number_space(V::Number; atol::Real=eps(real(float(V))))
    return absprint(V; atol=atol)
end

function write_number_space(V::Complex; atol::Real=eps(real(float(V))))
    return "$(absprint(real(V); atol=atol)) $(absprint(imag(V); atol=atol))"
end
