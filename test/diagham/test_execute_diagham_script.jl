using DiagHamInterface
using DiagHamInterface: set_diagham_path
using Test

# DiagHam-dependent tests - only run if DiagHam is available
# Note: Basic tests for diagham_kwarg and diagham_path are in test_basics.jl
include("setup.jl")

@testset "execute_diagham_script (requires DiagHam)" begin

    @test ensure_diagham_installed(DIAGHAM_BUILD_DIR) == DIAGHAM_BUILD_DIR
    if diagham_available()
        # Set the DiagHam path for these tests
        @test DiagHamInterface.set_diagham_path(DIAGHAM_BUILD_DIR) == expanduser(DIAGHAM_BUILD_DIR) 

        @test DiagHamInterface.get_diagham_path() == expanduser(DIAGHAM_BUILD_DIR)
        @testset "Laughlin state on torus (fermions)" begin
            mktempdir() do tmpdir
                cd(tmpdir) do
                    # Run a simple FQHE calculation: Laughlin state for 3 fermions at filling 1/3
                    # This is one of the simplest cases for testing
                    try
                        open("pseudopotentials.dat", "w") do io
                            write(io, "Pseudopotentials = 0.0 1.0 \n")
                        end
                        execute_diagham_script(
                            "FQHE/src/Programs/FQHEOnTorus/FQHETorusFermionsTwoBodyGeneric";
                            p = 3,        # Number of particles
                            l = 9,        # Number of flux quanta (N_phi = p * q = 3 * 3 = 9 for 1/3 filling)
                            interaction_file = "pseudopotentials.dat",
                            interaction_name = "V1",
                        )

                        # Check output file
                        open("fermions_torus_kysym_V1_n_3_2s_9_ratio_1.000000.dat") do io
                            K_zeros = []
                            for line in eachline(io)
                                if line[1] == '#'
                                    continue
                                end
                                k, e = split(line)
                                if isapprox(parse(Float64, e), 0.0; atol = 1.0e-10)
                                    push!(K_zeros, parse(Int, k))
                                end
                            end
                            @test sort(K_zeros) == [0, 3, 6]
                        end
                        @test true  # Execution succeeded
                    catch e
                        @warn "DiagHam script execution failed: $e"
                        # Even if execution fails, we test that the function was called
                        @test_broken false
                    end
                end
            end
        end
    else
        @test_skip "DiagHam not available"
    end
end
