"""
Interface to the DiagHam library.
"""
module DiagHamInterface

export execute_diagham_script
export diagham_command
export install_diagham

export read_matrix_from_txt
export write_to_txt
export write_matrix_elements

export read_one_body_density
export read_two_body_density
export two_body_normal_to_density_density
export density_density_to_two_body_normal

using DelimitedFiles
using SparseArrays
using Preferences

include("utility/backup.jl")
include("utility/diagham_path.jl")
include("utility/diagham_script.jl")
include("utility/diagham_install.jl")
include("utility/fileending.jl")
include("utility/numbers.jl")
include("utility/standards.jl")

include("MatrixElements/read.jl")
include("MatrixElements/write.jl")
include("Hamiltonian/hamiltonian_txt.jl")
include("FTIDensity/read_density.jl")

end
