"""
    format_with_precision(x; atol=0.0, maxdigits=typemax(Int))

Format number `x` as a string with absolute precision `atol` and a maximum of 
`maxdigits` significant digits. 
Uses scientific notation for very small or large numbers.
"""
function format_with_precision(x::T; atol = 0.0, maxdigits::Int = typemax(Int)) where {T <: Real}
    iszero(x) && return "0.0"

    if iszero(atol)
        maxdigits == typemax(Int) && return string(x)
        return string(round(x, sigdigits = maxdigits))
    end

    mag_x = floor(Int, log10(abs(x)))
    mag_atol = floor(Int, log10(abs(atol)))

    required_sigdigits = max(1, mag_x - mag_atol + 1)
    s = min(required_sigdigits, maxdigits)

    rounded_x = round(x, sigdigits = s)
    return string(rounded_x)
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

function write_number(V::Number; kwargs...)
    return format_with_precision(V; kwargs...)
end

function write_number(V::Complex; kwargs...)
    return string("(", format_with_precision(real(V); kwargs...), ",", format_with_precision(imag(V); kwargs...), ")")
end

function write_number_space(V::Number; kwargs...)
    return format_with_precision(V; kwargs...)
end

function write_number_space(V::Complex; kwargs...)
    return "$(format_with_precision(real(V); kwargs...)) $(format_with_precision(imag(V); kwargs...))"
end
