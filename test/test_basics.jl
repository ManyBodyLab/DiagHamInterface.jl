using DiagHamInterface
using DiagHamInterface:
    backup_file!,
    fix_fileending,
    format_with_precision,
    read_number,
    write_number,
    write_number_space,
    diagham_kwarg,
    get_diagham_path,
    warn_about_diagham_path,
    standard_momentum_label,
    standard_band_label,
    standard_spin_label,
    standard_valley_label,
    standard_position_label
using Test

@testset "DiagHamInterface Basic Tests" begin

    @testset "backup_file!" begin
        mktempdir() do tmpdir
            # Test backup of non-existent file (should do nothing)
            nonexistent = joinpath(tmpdir, "nonexistent.txt")
            @test backup_file!(nonexistent) === nothing
            @test !isfile(nonexistent)

            # Test backup of existing file
            testfile = joinpath(tmpdir, "testfile.txt")
            write(testfile, "original content")
            @test isfile(testfile)

            backup_file!(testfile)
            @test !isfile(testfile)  # Original moved
            @test isfile(testfile * ".bak")  # Backup exists
            @test read(testfile * ".bak", String) == "original content"

            # Create new content and backup again
            write(testfile, "new content")
            backup_file!(testfile)
            @test !isfile(testfile)
            @test isfile(testfile * ".bak")
            @test isfile(testfile * ".bak.bak")
            @test read(testfile * ".bak", String) == "new content"
            @test read(testfile * ".bak.bak", String) == "original content"

            # Test third backup overwrites second backup
            write(testfile, "third content")
            backup_file!(testfile)
            @test !isfile(testfile)
            @test isfile(testfile * ".bak")
            @test isfile(testfile * ".bak.bak")
            @test read(testfile * ".bak", String) == "third content"
            @test read(testfile * ".bak.bak", String) == "new content"
        end
    end

    @testset "fix_fileending" begin
        # Test empty ending returns original
        @test fix_fileending("test", "") == "test"
        @test fix_fileending("test.txt", "") == "test.txt"

        # Test adding ending without dot
        @test fix_fileending("test", "txt") == "test.txt"
        @test fix_fileending("test", ".txt") == "test.txt"

        # Test replacing existing extension
        @test fix_fileending("test.dat", "txt") == "test.txt"
        @test fix_fileending("test.dat", ".txt") == "test.txt"

        # Test file already has correct ending
        @test fix_fileending("test.txt", "txt") == "test.txt"

        # Test with path (using joinpath for cross-platform compatibility)
        @test fix_fileending(joinpath("path", "to", "test"), "txt") == joinpath("path", "to", "test.txt")
        @test fix_fileending(joinpath("path", "to", "test.dat"), "txt") == joinpath("path", "to", "test.txt")
        @test fix_fileending(joinpath("path", "to", "test.txt"), "txt") == joinpath("path", "to", "test.txt")

        # Test h5 extension
        @test fix_fileending("data.dat", ".h5") == "data.h5"
        @test fix_fileending("data", "h5") == "data.h5"
    end

    @testset "format_with_precision" begin
        # Test zero
        @test format_with_precision(0.0) == "0.0"
        @test format_with_precision(0) == "0.0"

        # Test small numbers (use exponential format)
        result = format_with_precision(1.0e-5)
        @test occursin("e", result) || occursin("E", result)

        # Test large numbers (use exponential format)
        result = format_with_precision(1.0e7)
        @test occursin("e", result) || occursin("E", result)

        # Test normal range numbers
        result = format_with_precision(1.5)
        @test !occursin("e", result) && !occursin("E", result)

        # Test with forced mode
        result_e = format_with_precision(1.5; mode = :e)
        @test occursin("e", result_e) || occursin("E", result_e)

        result_f = format_with_precision(1.5; mode = :f)
        @test !occursin("e", result_f) && !occursin("E", result_f)

        # Test negative numbers
        result_neg = format_with_precision(-1.5)
        @test startswith(result_neg, "-")
    end

    @testset "read_number and write_number" begin
        # Test read_number with float string
        @test read_number("1.5") ≈ 1.5
        @test read_number("123.456") ≈ 123.456

        # Test read_number with complex bracket format "(real,imag)"
        @test read_number("(1.0,2.0)") ≈ 1.0 + 2.0im
        @test read_number("(-1.5,3.25)") ≈ -1.5 + 3.25im

        # Test read_number with space format "real imag"
        @test read_number("1.0 2.0") ≈ 1.0 + 2.0im

        # Test read_number passthrough
        @test read_number(1.5) ≈ 1.5
        @test read_number(1.0 + 2.0im) ≈ 1.0 + 2.0im

        # Test write_number for real
        str_real = write_number(1.5)
        @test parse(Float64, str_real) ≈ 1.5

        # Test write_number for complex
        str_complex = write_number(1.0 + 2.0im)
        @test startswith(str_complex, "(")
        @test endswith(str_complex, ")")
        @test occursin(",", str_complex)

        # Test write_number_space for real
        str_space_real = write_number_space(1.5)
        @test parse(Float64, str_space_real) ≈ 1.5

        # Test write_number_space for complex
        str_space_complex = write_number_space(1.0 + 2.0im)
        parts = split(str_space_complex)
        @test length(parts) == 2
        @test parse(Float64, parts[1]) ≈ 1.0
        @test parse(Float64, parts[2]) ≈ 2.0

        # Roundtrip test
        for val in [1.5, -2.3, 1.0e-5, 1.0e5]
            @test read_number(write_number(val)) ≈ val rtol = 1.0e-10
        end
        for val in [1.0 + 2.0im, -1.5 + 3.0im, 0.0 + 1.0im]
            @test read_number(write_number(val)) ≈ val rtol = 1.0e-10
        end
    end

    @testset "diagham_kwarg formatting" begin
        # Single character should use single dash
        kwarg_short = diagham_kwarg(:p, 3)
        @test kwarg_short == " -p 3"

        # Multi-character should use double dash and underscores become dashes
        kwarg_long = diagham_kwarg(:nbr_particles, 5)
        @test kwarg_long == " --nbr-particles 5"

        # Boolean true should just add the flag
        kwarg_bool_true = diagham_kwarg(:verbose, true)
        @test kwarg_bool_true == " --verbose"

        # Boolean false should return empty string
        kwarg_bool_false = diagham_kwarg(:verbose, false)
        @test kwarg_bool_false == ""

        # Test with string values
        kwarg_string = diagham_kwarg(:output_file, "test.dat")
        @test kwarg_string == " --output-file test.dat"

        # Test with float values
        kwarg_float = diagham_kwarg(:ratio, 1.5)
        @test kwarg_float == " --ratio 1.5"
    end

    @testset "diagham_path configuration" begin
        @testset "warn_about_diagham_path" begin
            # This just tests that the warning function doesn't throw
            @test warn_about_diagham_path() === nothing
        end

        @testset "diagham_path default" begin
            # Test that the default path is set
            @test isa(get_diagham_path(), String)
            @test !isempty(get_diagham_path())
        end
    end

    @testset "standard labels" begin
        @test standard_momentum_label() == "k"
        @test standard_band_label() == "m"
        @test standard_spin_label() == "sz"
        @test standard_valley_label() == "eta"
        @test standard_position_label() == "pos"
    end
end
