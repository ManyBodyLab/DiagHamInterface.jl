"""
Interface to the DiagHam library.
"""
module DiagHamInterface

export execute_diagham_script
export install_diagham

export read_matrix_from_txt
export write_to_txt
export write_matrix_elements

using DelimitedFiles
using Format: cfmt
using SparseArrays
using Preferences

include("utility/backup.jl")
include("utility/diagham_path.jl")
include("utility/execute_script.jl")
include("utility/diagham_install.jl")
include("utility/fileending.jl")
include("utility/numbers.jl")
include("utility/standards.jl")

include("MatrixElements/read.jl")
include("MatrixElements/write.jl")
include("Hamiltonian/hamiltonian_txt.jl")

end
