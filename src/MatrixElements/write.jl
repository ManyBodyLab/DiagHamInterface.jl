function drop_bands(label, indices, coeffs; dropband::Bool = false)
    band_pos = findall([occursin(standard_band_label(), x) for x in label])
    isempty(band_pos) && return label, indices, coeffs
    all_bands = unique(@view indices[:, band_pos[1]])
    if isempty(all_bands) && !isempty(band_pos)
        all_bands = [0]
    end
    if length(all_bands) == 1 || (dropband && length(all_bands) > 0)
        band_to_keep = minimum(all_bands)
        ind = filter(x -> all(indices[x, idx] == band_to_keep for idx in band_pos), eachindex(coeffs))
        label_no_band = findall(.!startswith.(label, standard_band_label() * "_"))
        label = label[label_no_band]
        indices = indices[ind, label_no_band]
        coeffs = coeffs[ind]
    elseif length(all_bands) > 0 && minimum(all_bands; init = 0) != 0
        shift = -minimum(all_bands)
        for i in eachindex(coeffs)
            for idx in band_pos
                indices[i, idx] += shift
            end
        end
    end
    return label, indices, coeffs
end

function relabel_bands(label, indices, coeffs; full_single_particle::Bool = false)
    N_body = length(unique([parse(Int, split(h, "_")[2]) for h in label]))
    if N_body == 2 ## This is a one-body term
        label, indices, coeffs = format_kinetic(label, indices, coeffs; full_single_particle = full_single_particle)
    end
    return label, indices, coeffs
end

function format_kinetic(label, indices, coeffs; full_single_particle::Bool = false)
    band_pos = findall([occursin(standard_band_label(), x) for x in label])
    if length(band_pos) == 2
        if full_single_particle
            label[band_pos[1]] = "m"; label[band_pos[2]] = "n"
        else
            label[band_pos[1]] = "m"
            ind1 = band_pos[1]
            ind2 = band_pos[2]
            ind = filter(x -> indices[x, ind1] == indices[x, ind2], eachindex(coeffs))
            if ind != eachindex(coeffs)
                @warn "Dropping off-diagonal band terms! If this was by mistake, set full_single_particle=true to keep all terms."
            end
            label = label[setdiff(1:length(label), ind2)]
            indices = indices[ind, :]
            coeffs = coeffs[ind]
        end

        ## This brings the matrix elements into the form ....(e.g. kx, ky, species), m, (n)
        el1 = band_pos[1]
        switch = minimum(findall(x -> endswith(x, "_2"), label))
        reorder = [collect(1:(el1 - 1));collect((el1 + 1):(switch - 1));el1;collect(switch:length(label))]
        label = label[reorder]; indices = indices[:, reorder]
    end

    # Need to be diagonal in species and momenta, only keep one of them and reformat a little
    pos_1 = filter(x -> !occursin("_2", label[x]), eachindex(label))
    hybrid_pos_2 = filter(x -> occursin(standard_position_label(), label[x]) && occursin("_2", label[x]), eachindex(label))
    append!(pos_1, hybrid_pos_2)
    indices = indices[:, pos_1]; label = label[pos_1]

    label = map(x -> occursin(standard_position_label(), x) ? x : replace(x, "_1" => ""), label)

    ## For one-body valley should be the last index
    pos_val = findfirst(occursin(standard_valley_label()), label)
    if !isnothing(pos_val) && pos_val != length(label)
        reorder = [collect(1:(pos_val - 1)); collect((pos_val + 1):length(label)); pos_val]
        label = label[reorder]; indices = indices[:, reorder]
    end

    return label, indices, coeffs
end

"""
    write_matrix_elements(label, indices, coeffs, file_name; dropband=false, full_single_particle=false)

Write matrix elements to DiagHam-format file with header and data rows.
`dropband=true` removes band index for single-band data.
`full_single_particle=true` keeps both band indices for one-body terms.
"""
function write_matrix_elements(label, indices, coeffs, file_name::String; dropband::Bool = false, full_single_particle::Bool = false)
    N_body_interaction = div(length(unique([parse(Int, split(h, "_")[2]) for h in label])), 2)
    matrix_element_name = N_body_interaction == 1 ? "one_body_term" : "matrix_element"

    label, indices, coeffs = drop_bands(label, indices, coeffs; dropband = dropband)
    label, indices, coeffs = relabel_bands(label, indices, coeffs; full_single_particle = full_single_particle)


    # Finally store
    fid = open(file_name, "w")
    writedlm(fid, ["#" label... matrix_element_name], " ")
    writedlm(fid, cat(indices, write_number.(coeffs); dims = 2), " ")
    close(fid)

    return file_name
end
