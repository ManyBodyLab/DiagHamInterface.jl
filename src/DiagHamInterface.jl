"""
Placeholder for a short summary about DiagHamInterface.
"""
module DiagHamInterface

export read_matrix_elements, read_matrix_from_txt, write_to_txt
export execute_diagham_script
export Species

using DelimitedFiles 
using Format 
using SparseArrays 
using Preferences
using HDF5

include("utility/backup.jl")
include("utility/diagham_path.jl")
include("utility/execute_script.jl")
include("utility/fileending.jl")
include("utility/numbers.jl")
include("utility/species.jl")

include("MatrixElements/read.jl")
include("Hamiltonian/hamiltonian_txt.jl")

end
