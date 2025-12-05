# DiagHamInterface.jl

| **Documentation** | **Downloads** |
|:-----------------:|:-------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![Downloads][downloads-img]][downloads-url]

| **Build Status** | **Coverage** | **Style Guide** | **Quality assurance** |
|:----------------:|:------------:|:---------------:|:---------------------:|
| [![CI][ci-img]][ci-url] | [![Codecov][codecov-img]][codecov-url] | [![code style: runic][codestyle-img]][codestyle-url] | [![Aqua QA][aqua-img]][aqua-url] |

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://manybodylab.github.io/DiagHamInterface.jl/stable

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://manybodylab.github.io/DiagHamInterface.jl/dev

[downloads-img]: https://img.shields.io/badge/dynamic/json?url=http%3A%2F%2Fjuliapkgstats.com%2Fapi%2Fv1%2Ftotal_downloads%2FDiagHamInterface&query=total_requests&label=Downloads
[downloads-url]: http://juliapkgstats.com/pkg/DiagHamInterface

[ci-img]: https://github.com/ManyBodyLab/DiagHamInterface.jl/actions/workflows/Tests.yml/badge.svg
[ci-url]: https://github.com/ManyBodyLab/DiagHamInterface.jl/actions/workflows/Tests.yml

[codecov-img]: https://codecov.io/gh/ManyBodyLab/DiagHamInterface.jl/branch/main/graph/badge.svg
[codecov-url]: https://codecov.io/gh/ManyBodyLab/DiagHamInterface.jl

[aqua-img]: https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg
[aqua-url]: https://github.com/JuliaTesting/Aqua.jl

[codestyle-img]: https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black
[codestyle-url]: https://github.com/fredrikekre/Runic.jl

DiagHamInterface.jl is a Julia package that provides an interface to [DiagHam](https://www.nick-ux.org/diagham/index.php/Main_Page), a suite of exact diagonalization programs for quantum many-body systems.

## Installation

The package is not yet registered in the Julia general registry. It can be installed trough the package manager with the following command:

```julia-repl
pkg> add git@github.com:ManyBodyLab/DiagHamInterface.jl.git
```

## Code Samples

```julia
julia> using DiagHamInterface
julia> open("pseudopotentials.dat", "w") do io
           write(io, "Pseudopotentials = 0.0 1.0 \n")
       end
julia> execute_diagham_script(
           "FQHE/src/Programs/FQHEOnTorus/FQHETorusFermionsTwoBodyGeneric";
           p = 3,        # Number of particles
           l = 9,        # Number of flux quanta (N_phi = p * q = 3 * 3 = 9 for 1/3 filling)
           interaction_file = "pseudopotentials.dat",
           interaction_name = "V1",
       )
julia> A = rand(ComplexF64,100, 100); Ham = A' * A; # Create a random positive definite Hamiltonian
julia> write_to_txt(A, "hamiltonian.txt") # Write Hamiltonian to text file
julia> execute_diagham_script(
           "src/Programs/GenericHamiltonianDiagonalization";
           c = true,
           data_columns = 2,
           use_lapack = true,
           hamiltonian = "hamiltonian.txt",
           o = "spectrum.txt",
           all_eigenstates = true,
           eigenstate_file = "eigenstates.txt",
       )
```

## License

DiagHamInterface.jl is licensed under the [APL2 License](LICENSE). By using or interacting with this software in any way, you agree to the license of this software.
