using DiagHamInterface
using Test
using SparseArrays
using DiagHamInterface: fix_fileending

@testset "write_to_txt and read_matrix_from_txt" begin

    for T in (Float64, ComplexF64)
        @testset "Dense matrix write/read roundtrip" begin
            mktempdir() do tmpdir
                # Create a simple Hermitian matrix for testing
                H = [
                    1.0 0.5 0.0;
                    0.5 2.0 0.25;
                    0.0 0.25 3.0
                ]
                H = T.(H)

                filename = joinpath(tmpdir, "test_matrix.txt")

                # Write the matrix to file
                write_to_txt(H, filename)

                # Read the matrix back
                H_read = read_matrix_from_txt(filename)

                @test H ≈ H_read
            end
        end

        @testset "Sparse matrix write/read roundtrip" begin
            mktempdir() do tmpdir
                # Create a sparse Hermitian matrix for testing
                I = [1, 1, 2, 2, 3, 3]
                J = [1, 2, 1, 2, 2, 3]
                V = [1.0, 0.5, 0.5, 2.0, 0.25, 3.0]
                V = T.(V)
                H = sparse(I, J, V, 3, 3)

                filename = joinpath(tmpdir, "test_sparse_matrix.txt")

                # Write the matrix to file
                write_to_txt(H, filename)

                # Read the matrix back
                H_read = read_matrix_from_txt(filename)

                @test H ≈ H_read
            end
        end
    end

    @testset "File extension handling" begin
        mktempdir() do tmpdir
            H = [1.0 0.5; 0.5 2.0]

            # Test without extension
            filename = joinpath(tmpdir, "test_no_ext")
            write_to_txt(H, filename)
            @test isfile(joinpath(tmpdir, "test_no_ext.txt"))

            # Test with different extension
            filename = joinpath(tmpdir, "test_wrong_ext.dat")
            write_to_txt(H, filename)
            @test isfile(joinpath(tmpdir, "test_wrong_ext.txt"))


            @test fix_fileending(filename, "txt") == joinpath(tmpdir, "test_wrong_ext.txt")
            @test fix_fileending(filename, ".h5") == joinpath(tmpdir, "test_wrong_ext.h5")
        end
    end

    @testset "File format verification" begin
        mktempdir() do tmpdir
            H = [1.0 0.5; 0.5 2.0]

            filename = joinpath(tmpdir, "test_format.txt")
            write_to_txt(H, filename)

            # Read file and verify format (0-indexed row col value)
            content = readlines(filename)
            @test length(content) == 4  # 4 non-zero entries

            # First line should be "0 0 1.0..."
            parts = split(content[1])
            @test parse(Int, parts[1]) == 0
            @test parse(Int, parts[2]) == 0
            @test isapprox(parse(Float64, parts[3]), 1.0; atol = 1.0e-10)
        end
    end
end
