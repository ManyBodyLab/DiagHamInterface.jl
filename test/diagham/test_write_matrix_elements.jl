using DiagHamInterface
using DiagHamInterface: read_matrix_elements  # Not exported, but needed for testing
using Test
using DelimitedFiles

# Default tolerance for coefficient comparison in tests
const TEST_ATOL_REAL = 1.0e-14
const TEST_ATOL_COMPLEX = 1.0e-10

@testset "write_matrix_elements and read_matrix_elements" begin
    @testset "One-body matrix elements write/read roundtrip" begin
        mktempdir() do tmpdir
            # One-body terms have labels with _1 and _2 suffix (representing creation/annihilation)
            # The function recognizes this and processes accordingly
            label = ["kx_1", "kx_2"]

            # For one-body: diagonal elements (same indices for _1 and _2)
            indices = [
                0 0;
                1 1;
                2 2
            ]

            # Create corresponding coefficients
            coeffs = [1.0, 2.0, 3.0]

            filename = joinpath(tmpdir, "test_one_body.dat")

            # Write matrix elements
            write_matrix_elements(label, indices, coeffs, filename)

            # Verify file exists
            @test isfile(filename)

            # Read back the matrix elements
            header, read_indices, read_coeffs = read_matrix_elements(filename)

            # The function simplifies one-body terms - check coefficients are preserved
            @test all(isapprox.(read_coeffs, coeffs; atol = TEST_ATOL_REAL))

            # Header should contain the simplified label
            @test "kx" in header || any(occursin("kx", h) for h in header)
        end
    end

    @testset "Matrix elements with momentum labels" begin
        mktempdir() do tmpdir
            # Test with kx, ky type labels (diagonal in momentum)
            label = ["kx_1", "ky_1", "kx_2", "ky_2"]

            # Diagonal elements: kx_1=kx_2, ky_1=ky_2
            indices = [
                0 0 0 0;
                0 1 0 1;
                1 0 1 0;
                1 1 1 1
            ]

            coeffs = [1.0, 0.5, 0.25, 0.125]

            filename = joinpath(tmpdir, "test_momentum.dat")
            write_matrix_elements(label, indices, coeffs, filename)

            @test isfile(filename)

            # Read back and verify coefficients are preserved
            header, read_indices, read_coeffs = read_matrix_elements(filename)
            @test all(isapprox.(read_coeffs, coeffs; atol = TEST_ATOL_REAL))
            @test read_indices == indices
            @test label == header
        end
    end

    @testset "Complex coefficient matrix elements" begin
        mktempdir() do tmpdir
            # Test with complex coefficients using simple labels
            label = ["i_1", "i_2"]

            # Diagonal indices
            indices = [
                0 0;
                1 1;
                2 2
            ]

            # Complex coefficients
            coeffs = ComplexF64[1.0 + 0.5im, 0.25 - 0.1im, 0.5 + 0.25im]

            filename = joinpath(tmpdir, "test_complex_matrix_elements.dat")

            # Write matrix elements
            write_matrix_elements(label, indices, coeffs, filename)

            # Verify file exists
            @test isfile(filename)

            # Read back the matrix elements
            header, read_indices, read_coeffs = read_matrix_elements(filename)

            # Check that complex coefficients are preserved
            @test all(isapprox.(read_coeffs, coeffs; atol = TEST_ATOL_COMPLEX))
            @test read_indices == indices
            @test label == header

            header, read_indices, read_coeffs = read_matrix_elements(filename; conjugate = true)
            @test all(isapprox.(read_coeffs, conj.(coeffs); atol = TEST_ATOL_COMPLEX))
        end
    end

    @testset "File content format verification" begin
        mktempdir() do tmpdir
            # One-body term format
            label = ["kx_1", "ky_1", "kx_2", "ky_2"]
            indices = [0 0 0 0; 1 1 1 1]
            coeffs = [1.5, 2.5]

            filename = joinpath(tmpdir, "test_format.dat")
            write_matrix_elements(label, indices, coeffs, filename)

            # Read the file content directly and verify format
            content = readlines(filename)

            # First line should be header starting with #
            @test startswith(content[1], "#")

            # Should have a term type (one_body_term or matrix_element)
            @test occursin("one_body_term", content[1]) || occursin("matrix_element", content[1])

            # Data lines should exist and have numeric data
            @test length(content) >= 3  # header + 2 data rows
            data_line = split(content[2])
            @test length(data_line) >= 2  # At least indices + coefficient
        end
    end

    @testset "Real coefficients precision" begin
        mktempdir() do tmpdir
            label = ["x_1", "x_2"]
            indices = [0 0; 1 1]

            # Test with various precision levels
            coeffs = [1.23456789012345, 9.87654321098765]

            filename = joinpath(tmpdir, "test_precision.dat")
            write_matrix_elements(label, indices, coeffs, filename)

            header, read_indices, read_coeffs = read_matrix_elements(filename)

            # Check precision is maintained
            @test all(isapprox.(read_coeffs, coeffs; atol = TEST_ATOL_REAL))
        end
    end
end
