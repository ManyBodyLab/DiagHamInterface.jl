"""
    install_diagham(; source_dir, build_dir=nothing, run_dir=nothing, configure_options=["--enable-fqhe","--enable-fti","--with-blas-libs=-lopenblas","--with-lapack-libs=","--enable-lapack"])

Checkout and build DiagHam from source. Returns the path to the build directory.

Parameters are keyword-only and intended to be easily overridden from tests or user code.
"""
function install_diagham(;
        source_dir,
        build_dir = nothing,
        run_dir = nothing,
        configure_options = ["--enable-fqhe", "--enable-fti", "--with-blas-libs=-lopenblas", "--with-lapack-libs=", "--enable-lapack"],
    )
    source_dir = expanduser(source_dir)

    isnothing(build_dir) && (build_dir = joinpath(source_dir, "build"))
    build_dir = expanduser(build_dir)
    !isnothing(run_dir) && (run_dir = expanduser(run_dir))

    # Check if already built (look for a known executable)
    exe_check = joinpath(build_dir, "FQHE", "src", "Programs", "FQHEOnTorus", "FQHETorusFermionsTwoBodyGeneric")
    if isdir(build_dir) && isfile(exe_check)
        @info "DiagHam already installed at $build_dir"
        return build_dir
    end

    # Checkout DiagHam
    if !isdir(source_dir)
        @info "Checking out DiagHam from SVN repository..."
        run(`svn checkout "https://www.nick-ux.org/diagham/svn/DiagHam/trunk" $source_dir`)
    else
        @info "DiagHam source already exists at $source_dir"
    end

    !isdir(build_dir) && mkdir(build_dir)
    # Check if it uses autotools or cmake
    if isfile(joinpath(source_dir, "CMakeLists.txt"))
        # CMake-based build

        @info "Configuring DiagHam with CMake..."
        cd(build_dir) do
            run(`cmake $source_dir -DBUILD_FQHE=ON`)
        end

        @info "Building DiagHam..."
        cd(build_dir) do
            nprocs = Sys.CPU_THREADS
            run(`make -j$nprocs`)
        end
    elseif isfile(joinpath(source_dir, "configure"))
        # Autotools-based build (older DiagHam versions)
        @info "Configuring DiagHam with autotools..."

        cd(build_dir) do
            # Run configure from build dir pointing to source dir with FQHE and LAPACK enabled
            configure_script = joinpath(source_dir, "configure")
            run(`$configure_script $(configure_options...)`)

            @info "Building DiagHam..."
            nprocs = Sys.CPU_THREADS
            run(`make -j$nprocs`)
        end
    elseif isfile(joinpath(source_dir, "configure.in")) || isfile(joinpath(source_dir, "Makefile.am"))
        # Need to run autoreconf first
        @info "Running autoreconf to generate configure script..."
        cd(source_dir) do
            run(`autoreconf -i`)
        end

        cd(build_dir) do
            # Run configure from build dir pointing to source dir with FQHE and LAPACK enabled
            configure_script = joinpath(source_dir, "configure")
            run(`$configure_script --enable-fqhe --enable-fti --with-blas-libs=-lopenblas --with-lapack-libs= --enable-lapack`)

            @info "Building DiagHam..."
            nprocs = Sys.CPU_THREADS
            run(`make -j$nprocs`)
        end
    else
        error("Could not determine build system for DiagHam")
    end

    !isdir(run_dir) && !isnothing(run_dir) && mkdir(run_dir)

    @info "DiagHam installed successfully at $build_dir"

    if !@has_preference("diagham_path")
        set_diagham_path(build_dir)
    end

    return build_dir
end
