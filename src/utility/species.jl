using HDF5

## TODO: When ITensor supports non-abelian symmetries, we should modify this struct in the following way:
## 1. We add an extra field "symmetry_group, which can be :U1, :Zn, :SU2 etc...
## 2. When we have a non-abelian symmetry, we restrict the matrix elements of that species to only one component, e.g. ("Sz",(1,)) and then let the MPO constructor or DiagHam (with --use-szsymmetry) handle the SU2 symmetry properly.
struct Species ## This struct is for keeping track of the species, i.e. QNs of the system, like spin or valley
    labels::Vector{String}
    symmetry_group::Vector{Symbol} ## e.g. :U1, :Zn, :SU2 etc...
    values::Vector{<:Tuple}
    tags::Vector{String}
    tag_dict::Dict{String,Int}
    dict::Dict{Int,<:Tuple}
    inv_dict::Dict{<:Tuple,Int} ## This is the inverse dictionary to get the index of a species from its tag
end

function Base.copy(sp::Species)
    return Species(copy(sp.labels), copy(sp.symmetry_group), copy(sp.values), copy(sp.tags), copy(sp.tag_dict), copy(sp.dict), copy(sp.inv_dict))
end
function tags(sp::Species)
    return sp.tags
end
function labels(sp::Species)
    return sp.labels
end
function symmetry_groups(sp::Species)
    return sp.symmetry_group
end
function Base.iterate(sp::Species)
    return iterate(sp.tags)
end

function abelian_species(sp::Species) ## This is the convenience function used in matrixelements and the bloch2hybridwannier and hybrid_matelem to restrict the non-abelian symmetries to a single component (which we choose to be the first one wlog)
    abelian_qns = findall(x->x==:U1 || string(x)[1]=='Z', sp.symmetry_group)
    values_new = map(i->i in abelian_qns ? sp.values[i] : tuple(sp.values[i][1]), eachindex(sp.values))
    return Species(
        copy(sp.labels),
        values_new,
        copy(sp.symmetry_group)
    )
end

function Species(x::Vector{Pair{String,<:Tuple}}, symmetry_group::Vector{Symbol}=fill(:U1, length(x)))
    return Species(first.(x), last.(x), symmetry_group)
end
function Species(x::Vector{Pair{Symbol,<:Tuple}}, symmetry_group::Vector{Symbol}=fill(:U1, length(x)))
    return Species(first.(x), last.(x), symmetry_group)
end
function Species(labels::Vector{Symbol}, values::Vector{<:Tuple}, symmetry_group::Vector{Symbol}=fill(:U1, length(labels)))
    return Species(String.(labels), values, symmetry_group)
end
function Species(labels::Vector{String}, values::Vector{<:Tuple}, symmetry_group::Vector{Symbol}=fill(:U1, length(labels)))
    if isempty(labels) && isempty(values)
        return Species(
            [""], [:U1], [tuple(0)], [""], Dict("" => 1), Dict(1 => tuple(0)), Dict(tuple(0)=>1)
        )
    end
    @assert all(x->isa(x, NTuple{N,Int} where {N}), values) "The values of the species must be integer!\n Here they are $(eltype.(values))"
    @assert length(labels) == length(values) "The number of labels must match the number of values!\n Here they are $(length(labels)) and $(length(values))"
    @assert length(labels) == length(symmetry_group) "The number of labels must match the number of symmetry groups!\n Here they are $(length(labels)) and $(length(symmetry_group))"


    tags = Vector{String}(undef, prod(length(values[i]) for i in eachindex(values); init=1))
    counter=1
    for i in Iterators.product([eachindex(values[k]) for k in eachindex(values)]...)
        tags[counter] = prod(
            string(labels[j]) * "=" * string(values[j][i[j]]) * "," for
            j in eachindex(labels)
        )[1:(end - 1)]
        counter += 1
    end
    @assert length(tags) == prod(length(values[i]) for i in eachindex(values); init=1)
    dict=Dict(zip(1:length(tags), Iterators.product(values...)))
    tag_dict=Dict(zip(tags, 1:length(tags)))
    inv_dict = Dict(zip(Iterators.product(values...), 1:length(tags)))
    return Species(labels, symmetry_group, values, tags, tag_dict, dict, inv_dict)
end

function Base.length(sp::Species)
    return length(sp.tags) ## This is the total dimension of the multicomponent space
end

function Base.getindex(sp::Species, i::Int)
    return sp.tags[i]
end
function Base.eachindex(sp::Species)
    return eachindex(sp.tags)
end

## This is a constructor for the most common species
function Species(; Sz::Bool=false, val::Bool=false)
    labels = String[]
    symmetry_groups = Symbol[]
    Sz && push!(labels, standard_spin_label())
    Sz && push!(symmetry_groups, :U1)  ## TODO: Should be switched to :SU2 when non-abelian symmetries are supported
    val && push!(labels, standard_valley_label())
    val && push!(symmetry_groups, :U1)

    values = Tuple[]
    Sz && push!(values, (1, -1))
    val && push!(values, (1, -1))

    return Species(labels, values, symmetry_groups)
end

function HDF5.write(
    parent::Union{HDF5.File,HDF5.Group}, name::AbstractString, species::Species
)
    g = create_group(parent, name)
    HDF5.attributes(g)["type"] = "Species"
    HDF5.attributes(g)["version"] = 1
    write(g, "labels", species.labels)
    write(g, "symmetry_group", string.(species.symmetry_group))
    write(g, "values", species.values)
    write(g, "tags", species.tags)
    write(g, "tag_dict", species.tag_dict)
    write(g, "dict", species.dict)
    write(g, "inv_dict", species.inv_dict)
    return nothing
end

function HDF5.read(
    parent::Union{HDF5.File,HDF5.Group}, name::AbstractString, ::Type{Species}
)
    g = open_group(parent, name)
    if read(HDF5.attributes(g)["type"]) != "Species"
        @warn "HDF5 group or file does not contain Species data"
    end
    labels = read(g, "labels")
    symmetry_group = Symbol.(read(g, "symmetry_group"))
    values = read(g, "values", Vector{Tuple})
    tags = read(g, "tags")
    tag_dict = read(g, "tag_dict", Dict{String})
    dict = read(g, "dict", Dict{Int,Tuple})
    inv_dict = read(g, "inv_dict", Dict{Tuple,Int})
    return Species(labels, symmetry_group, values, tags, tag_dict, dict, inv_dict)
end

function valleys(sp::Species)
    whereisval = findfirst(isequal("val"), sp.labels)
    if isnothing(whereisval)
        return fill(1, length(sp))
    else
        return [sp.dict[i][whereisval] for i in eachindex(sp)]
    end
end
function distinguish_valley_from_spins(specie::Species)::Tuple{Vector{Int64}, Dict{Int64,Vector{Int64}}}
    # Check if valley is present, and form a dict of all valleys
    whereisval = findfirst( isequal("val"), specie.labels)
    if isnothing(whereisval)
        allvalleys = [1]
        whichvalleys = Dict(1 => [x for x in eachindex(specie.tags)])
    else
        allvalleys = unique([v[whereisval] for (i,v) in specie.dict])
        whichvalleys = Dict(
            val => [i for (i,v) in specie.dict if v[whereisval]==val]
            for val in allvalleys
        )
    end
    return allvalleys, whichvalleys
end
