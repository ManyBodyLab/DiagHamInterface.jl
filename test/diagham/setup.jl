"""
Setup script to install DiagHam for testing.

This script checks out and builds DiagHam from source following the installation
instructions at https://www.nick-ux.org/diagham/index.php/Install
"""

const DIAGHAM_SOURCE_DIR = joinpath(dirname(@__DIR__), "diagham_source")
const DIAGHAM_BUILD_DIR = joinpath(DIAGHAM_SOURCE_DIR, "build")
const DIAGHAM_RUN_DIR = joinpath(DIAGHAM_BUILD_DIR, "run")

"""
    install_diagham()

Checkout and build DiagHam from source. Returns the path to the build directory.
"""
function install_diagham()
    # Check if already built
    if isdir(DIAGHAM_BUILD_DIR) && isfile(joinpath(DIAGHAM_BUILD_DIR, "FQHE", "src", "Programs", "FQHEOnTorus", "FQHETorusFermionsTwoBodyGeneric"))
        @info "DiagHam already installed at $DIAGHAM_BUILD_DIR"
        return DIAGHAM_BUILD_DIR
    end

    # Checkout DiagHam if not exists
    if !isdir(DIAGHAM_SOURCE_DIR)
        @info "Checking out DiagHam from SVN repository..."
        mkdir(dirname(DIAGHAM_SOURCE_DIR))
        run(`svn checkout https://www.nick-ux.org/diagham/svn/DiagHam/trunk $DIAGHAM_SOURCE_DIR`)
    else
        @info "DiagHam source already exists at $DIAGHAM_SOURCE_DIR"
    end

    # Check if it uses autotools or cmake
    if isfile(joinpath(DIAGHAM_SOURCE_DIR, "CMakeLists.txt"))
        # CMake-based build
        if !isdir(DIAGHAM_BUILD_DIR)
            mkdir(DIAGHAM_BUILD_DIR)
        end

        @info "Configuring DiagHam with CMake..."
        cd(DIAGHAM_BUILD_DIR) do
            run(`cmake $DIAGHAM_SOURCE_DIR -DBUILD_FQHE=ON`)
        end

        @info "Building DiagHam..."
        cd(DIAGHAM_BUILD_DIR) do
            nprocs = Sys.CPU_THREADS
            run(`make -j$nprocs`)
        end
    elseif isfile(joinpath(DIAGHAM_SOURCE_DIR, "configure"))
        # Autotools-based build (older DiagHam versions)
        @info "Configuring DiagHam with autotools..."

        if !isdir(DIAGHAM_BUILD_DIR)
            mkdir(DIAGHAM_BUILD_DIR)
        end

        cd(DIAGHAM_BUILD_DIR) do
            # Run configure from build dir pointing to source dir with FQHE and LAPACK enabled
            configure_script = joinpath(DIAGHAM_SOURCE_DIR, "configure")
            run(`$configure_script --enable-fqhe --enable-fti --with-blas-libs=-lopenblas --with-lapack-libs= --enable-lapack`)

            @info "Building DiagHam..."
            nprocs = Sys.CPU_THREADS
            run(`make -j$nprocs`)
        end
    elseif isfile(joinpath(DIAGHAM_SOURCE_DIR, "configure.in")) || isfile(joinpath(DIAGHAM_SOURCE_DIR, "Makefile.am"))
        # Need to run autoreconf first
        @info "Running autoreconf to generate configure script..."
        cd(DIAGHAM_SOURCE_DIR) do
            run(`autoreconf -i`)
        end

        if !isdir(DIAGHAM_BUILD_DIR)
            mkdir(DIAGHAM_BUILD_DIR)
        end

        cd(DIAGHAM_BUILD_DIR) do
            # Run configure from build dir pointing to source dir with FQHE and LAPACK enabled
            configure_script = joinpath(DIAGHAM_SOURCE_DIR, "configure")
            run(`$configure_script --enable-fqhe --enable-fti --with-blas-libs=-lopenblas --with-lapack-libs= --enable-lapack`)

            @info "Building DiagHam..."
            nprocs = Sys.CPU_THREADS
            run(`make -j$nprocs`)
        end
    else
        error("Could not determine build system for DiagHam")
    end

    if !isdir(DIAGHAM_RUN_DIR)
        mkdir(DIAGHAM_RUN_DIR)
    end

    @info "DiagHam installed successfully at $DIAGHAM_BUILD_DIR"
    return DIAGHAM_BUILD_DIR
end

"""
    diagham_available()

Check if DiagHam is available (built and ready to use).
"""
function diagham_available()
    # Check for common FQHE executables
    possible_paths = [
        joinpath(DIAGHAM_BUILD_DIR, "FQHE", "src", "Programs", "FQHEOnDisk", "FQHEDiskFermionsTwoBodyGeneric"),
        joinpath(DIAGHAM_BUILD_DIR, "FQHE", "src", "Programs", "FQHEOnTorus", "FQHETorusFermionsTwoBodyGeneric"),
        joinpath(DIAGHAM_BUILD_DIR, "FTI", "src", "Programs", "FTI", "FTIGenericInteractionFromFileTwoBands"),
        joinpath(DIAGHAM_BUILD_DIR, "src", "Programs", "GenericHamiltonianDiagonalization"),
        joinpath(DIAGHAM_BUILD_DIR, "src", "Programs", "GenericOverlap"),
    ]
    return any(isfile, possible_paths)
end

if !diagham_available()
    @info "DiagHam not installed, attempting installation..."
    try
        install_diagham()
    catch e
        @warn "Failed to install DiagHam: $e"
    end
end
