# # DiagHamInterface.jl

# DiagHamInterface.jl is a Julia package that provides an interface to [DiagHam](https://www.nick-ux.org/diagham/index.php/Main_Page), a suite of exact diagonalization programs for quantum many-body systems.

# ## Installation

# The package is not yet registered in the Julia general registry. It can be installed trough the package manager with the following command:

# ```julia-repl
# pkg> add git@github.com:ManyBodyLab/DiagHamInterface.jl.git
# ```

# ## Code Samples

# ```julia
# julia> using DiagHamInterface
# julia> open("pseudopotentials.dat", "w") do io
#            write(io, "Pseudopotentials = 0.0 1.0 \n")
#        end
# julia> execute_diagham_script(
#            "FQHE/src/Programs/FQHEOnTorus/FQHETorusFermionsTwoBodyGeneric";
#            p = 3,        # Number of particles
#            l = 9,        # Number of flux quanta (N_phi = p * q = 3 * 3 = 9 for 1/3 filling)
#            interaction_file = "pseudopotentials.dat",
#            interaction_name = "V1",
#        )
# julia> A = rand(ComplexF64,100, 100); Ham = A' * A; # Create a random positive definite Hamiltonian
# julia> write_to_txt(A, "hamiltonian.txt") # Write Hamiltonian to text file
# julia> execute_diagham_script(
#            "src/Programs/GenericHamiltonianDiagonalization";
#            c = true,
#            data_columns = 2,
#            use_lapack = true,
#            hamiltonian = "hamiltonian.txt",
#            o = "spectrum.txt",
#            all_eigenstates = true,
#            eigenstate_file = "eigenstates.txt",
#        )
# ```

# ## License

# DiagHamInterface.jl is licensed under the APL2 License. By using or interacting with this software in any way, you agree to the license of this software.
