using DiagHamInterface
using DiagHamInterface: _parse_density_header
using Test

# ── helpers ──────────────────────────────────────────────────────────────────

function write_tmp(content::String)
    path, io = mktemp()
    write(io, content)
    close(io)
    return path
end

# ── header parsing ────────────────────────────────────────────────────────────

@testset "Header parsing" begin
    @testset "1-band" begin
        f = write_tmp("# kx ky <c^+ c>\n0 0 1.0\n")
        is2, hspin, ncols = _parse_density_header(f)
        @test !is2
        @test !hspin
        @test ncols == 2
    end

    @testset "2-band" begin
        f = write_tmp("# kx ky sigma sigma' <c^+ c>\n0 0 0 0 1.0\n")
        is2, hspin, ncols = _parse_density_header(f)
        @test !is2
        @test !hspin
        @test ncols == 4
    end

    @testset "4-band (spin)" begin
        f = write_tmp("# kx ky spin sigma sigma' <c^+ c>\n0 0 0 0 0 1.0\n")
        is2, hspin, ncols = _parse_density_header(f)
        @test !is2
        @test hspin
        @test ncols == 5
    end

    @testset "two-body 2-band" begin
        f = write_tmp("# kx1 ky1 sigma1 kx2 ky2 sigma2 kx3 ky3 sigma3 kx4 ky4 sigma4 <c^+ c^+ c c>\n0 0 0 0 0 0 0 0 0 0 0 0 1.0\n")
        is2, hspin, ncols = _parse_density_header(f)
        @test is2
        @test !hspin
        @test ncols == 12
    end
end

# ── one-body reader ───────────────────────────────────────────────────────────

@testset "read_one_body_density" begin
    @testset "1-band, 2x2 lattice, real" begin
        content = """# kx ky <c^+ c>
        0 0 0.5
        0 1 0.25
        1 0 0.125
        1 1 0.0625
        # partial density sigma=0 = 0.9375
        # total density = 0.9375
        """
        f = write_tmp(content)
        rho = read_one_body_density(f)

        @test eltype(rho) == Float64
        @test size(rho) == (4, 1, 1, 4, 1, 1)

        # k = kx*Nky + ky + 1  (Nky=2)
        @test rho[1, 1, 1, 1, 1, 1] ≈ 0.5       # k=0*2+0+1=1
        @test rho[2, 1, 1, 2, 1, 1] ≈ 0.25      # k=0*2+1+1=2
        @test rho[3, 1, 1, 3, 1, 1] ≈ 0.125     # k=1*2+0+1=3
        @test rho[4, 1, 1, 4, 1, 1] ≈ 0.0625    # k=1*2+1+1=4

        # Off-diagonal k entries must be zero
        @test rho[1, 1, 1, 2, 1, 1] == 0
        @test rho[2, 1, 1, 3, 1, 1] == 0
    end

    @testset "2-band, 1x1 lattice, complex" begin
        content = """# kx ky sigma sigma' <c^+ c>
        0 0 0 0 1.0
        0 0 0 1 (0.1,0.2)
        0 0 1 0 (0.1,-0.2)
        0 0 1 1 0.3
        """
        f = write_tmp(content)
        rho = read_one_body_density(f)

        @test eltype(rho) == ComplexF64
        @test size(rho) == (1, 2, 1, 1, 2, 1)

        @test rho[1, 1, 1, 1, 1, 1] ≈ 1.0
        @test rho[1, 1, 1, 1, 2, 1] ≈ 0.1 + 0.2im
        @test rho[1, 2, 1, 1, 1, 1] ≈ 0.1 - 0.2im
        @test rho[1, 2, 1, 1, 2, 1] ≈ 0.3

        # Hermiticity
        @test rho[1, 1, 1, 1, 2, 1] ≈ conj(rho[1, 2, 1, 1, 1, 1])
    end

    @testset "4-band (spin), 1x1 lattice" begin
        content = """# kx ky spin sigma sigma' <c^+ c>
        0 0 0 0 0 0.8
        0 0 0 0 1 0.0
        0 0 0 1 0 0.0
        0 0 0 1 1 0.2
        0 0 1 0 0 0.6
        0 0 1 0 1 0.0
        0 0 1 1 0 0.0
        0 0 1 1 1 0.4
        """
        f = write_tmp(content)
        rho = read_one_body_density(f)

        @test eltype(rho) == Float64
        @test size(rho) == (1, 2, 2, 1, 2, 2)

        @test rho[1, 1, 1, 1, 1, 1] ≈ 0.8   # spin=0, sigma=0→0
        @test rho[1, 2, 1, 1, 2, 1] ≈ 0.2   # spin=0, sigma=1→1
        @test rho[1, 1, 2, 1, 1, 2] ≈ 0.6   # spin=1, sigma=0→0
        @test rho[1, 2, 2, 1, 2, 2] ≈ 0.4   # spin=1, sigma=1→1

        # Cross-spin entries must be zero
        @test rho[1, 1, 1, 1, 1, 2] == 0
        @test rho[1, 1, 2, 1, 1, 1] == 0
    end

    @testset "Comment lines interspersed with data" begin
        # DiagHam inserts partial-density comments between data blocks
        content = """# kx ky sigma sigma' <c^+ c>
        0 0 0 0 1.0
        # partial density sigma=0 = (1.0,0.0)
        0 0 1 1 0.5
        # partial density sigma=1 = (0.5,0.0)
        # total density = (1.5,0.0)
        """
        f = write_tmp(content)
        rho = read_one_body_density(f)
        @test size(rho) == (1, 2, 1, 1, 2, 1)
        @test rho[1, 1, 1, 1, 1, 1] ≈ 1.0
        @test rho[1, 2, 1, 1, 2, 1] ≈ 0.5
    end

    @testset "Real detection: purely real values → Float64" begin
        content = "# kx ky <c^+ c>\n0 0 0.7\n"
        f = write_tmp(content)
        rho = read_one_body_density(f)
        @test eltype(rho) == Float64
    end

    @testset "Complex detection: nonzero imaginary → ComplexF64" begin
        content = "# kx ky <c^+ c>\n0 0 (0.7,0.1)\n"
        f = write_tmp(content)
        rho = read_one_body_density(f)
        @test eltype(rho) == ComplexF64
    end
end

# ── two-body reader ───────────────────────────────────────────────────────────

@testset "read_two_body_density" begin
    @testset "2-band, 2x1 lattice" begin
        # kx1 ky1 sig1 kx2 ky2 sig2 kx3 ky3 sig3 kx4 ky4 sig4 val
        # Momentum conservation: kx4 = (kx1+kx2-kx3) mod Nkx
        content = """# kx1 ky1 sigma1 kx2 ky2 sigma2 kx3 ky3 sigma3 kx4 ky4 sigma4 <c^+ c^+ c c>
        0 0 0 1 0 1 0 0 0 1 0 1 0.5
        1 0 0 0 0 1 1 0 0 0 0 1 0.25
        """
        f = write_tmp(content)
        rho2 = read_two_body_density(f)

        # Nkx=2, Nky=1 → Nk=2; Nband=2; Nspin=1
        @test size(rho2) == (2, 2, 1, 2, 2, 1, 2, 2, 1, 2, 2, 1)
        @test eltype(rho2) == Float64

        # k=kx*Nky+ky+1; Nky=1
        # row 1: k1=1,b1=1,s1=1; k2=2,b2=2,s2=1; k3=1,b3=1,s3=1; k4=2,b4=2,s4=1
        @test rho2[1, 1, 1, 2, 2, 1, 1, 1, 1, 2, 2, 1] ≈ 0.5
        # row 2: k1=2,b1=1,s1=1; k2=1,b2=2,s2=1; k3=2,b3=1,s3=1; k4=1,b4=2,s4=1
        @test rho2[2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 2, 1] ≈ 0.25
    end
end

# ── commutation converters ────────────────────────────────────────────────────

@testset "Commutation converters" begin
    # Product state |ψ⟩ = c†_a c†_b |0⟩, a=(k=1,b=1,s=1), b=(k=2,b=1,s=1)
    # One-body: ⟨c†_a c_a⟩=1, ⟨c†_b c_b⟩=1, others=0
    # Two-body: ⟨c†_a c†_b c_b c_a⟩=1, ⟨c†_a c†_b c_a c_b⟩=-1, etc.
    Nk = 2; Nb = 1; Ns = 1
    rho1 = zeros(ComplexF64, Nk, Nb, Ns, Nk, Nb, Ns)
    rho1[1, 1, 1, 1, 1, 1] = 1.0
    rho1[2, 1, 1, 2, 1, 1] = 1.0

    rho2 = zeros(ComplexF64, Nk, Nb, Ns, Nk, Nb, Ns, Nk, Nb, Ns, Nk, Nb, Ns)
    # ⟨c†_a c†_b c_b c_a⟩ = 1
    rho2[1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 1, 1] = 1.0
    # ⟨c†_a c†_b c_a c_b⟩ = -1  (antisymmetry under c swap)
    rho2[1, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 1] = -1.0
    # ⟨c†_b c†_a c_b c_a⟩ = -1  (antisymmetry under c† swap)
    rho2[2, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1] = -1.0
    # ⟨c†_b c†_a c_a c_b⟩ = 1
    rho2[2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1] = 1.0

    @testset "normal → density-density, fermionic" begin
        rho_dd = two_body_normal_to_density_density(rho2, rho1; statistics = :fermi)

        # ⟨c†_a c_b c†_b c_a⟩ = δ_{b,b}⟨c†_a c_a⟩ - ⟨c†_a c†_b c_b c_a⟩ = 1·1 - 1 = 0
        # but in rho_dd indices are [k1,b1,s1, k3,b3,s3, k2,b2,s2, k4,b4,s4]
        # i.e. rho_dd[a,b,b,a] = δ_{b,b}⟨c†_a c_a⟩ - rho2[a,b,b,a]
        @test rho_dd[1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 1, 1] ≈ 0.0 atol = 1.0e-14

        # ⟨c†_a c_a c†_b c_b⟩ = δ_{a,a}⟨c†_b... wait, let's use the formula directly:
        # rho_dd[a,a,b,b] = δ_{a,b}⟨c†_... ⟩ - rho2[a,b,a,b]
        # a≠b so δ=0: rho_dd[a,a,b,b] = -rho2[a,b,a,b] = -(-1) = 1
        @test rho_dd[1, 1, 1, 1, 1, 1, 2, 1, 1, 2, 1, 1] ≈ 1.0 atol = 1.0e-14
    end

    @testset "round-trip: normal → dd → normal" begin
        rho2_rt = density_density_to_two_body_normal(
            two_body_normal_to_density_density(rho2, rho1; statistics = :fermi),
            rho1; statistics = :fermi
        )
        @test rho2_rt ≈ rho2 atol = 1.0e-14
    end

    @testset "round-trip: dd → normal → dd" begin
        rho_dd = two_body_normal_to_density_density(rho2, rho1; statistics = :fermi)
        rho_dd_rt = two_body_normal_to_density_density(
            density_density_to_two_body_normal(rho_dd, rho1; statistics = :fermi),
            rho1; statistics = :fermi
        )
        @test rho_dd_rt ≈ rho_dd atol = 1.0e-14
    end

    @testset "bosonic sign convention" begin
        # For bosons: ⟨b†_1 b_3 b†_2 b_4⟩ = δ_{23}⟨b†_1 b_4⟩ + ⟨b†_1 b†_2 b_3 b_4⟩
        # Use a simple non-antisymmetric rho2 for bosons
        rho2_bose = zeros(Float64, 2, 1, 1, 2, 1, 1, 2, 1, 1, 2, 1, 1)
        rho1_bose = zeros(Float64, 2, 1, 1, 2, 1, 1)
        rho2_bose[1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 1, 1] = 2.0
        rho1_bose[1, 1, 1, 1, 1, 1] = 1.5
        rho1_bose[2, 1, 1, 2, 1, 1] = 0.5

        rho_dd_b = two_body_normal_to_density_density(rho2_bose, rho1_bose; statistics = :bose)
        # rho_dd[a,b,b,a] = δ_{b,b}⟨b†_a b_a⟩ + rho2[a,b,b,a] = 1.5 + 2.0 = 3.5
        @test rho_dd_b[1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 1, 1] ≈ 3.5 atol = 1.0e-14
    end
end
