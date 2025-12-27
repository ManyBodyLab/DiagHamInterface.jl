"""
Setup script to install DiagHam for testing.

This script checks out and builds DiagHam from source following the installation
instructions at https://www.nick-ux.org/diagham/index.php/Install
"""

const DIAGHAM_SOURCE_DIR = joinpath(dirname(@__DIR__), "diagham_source")
const DIAGHAM_BUILD_DIR = joinpath(DIAGHAM_SOURCE_DIR, "build")
const DIAGHAM_RUN_DIR = joinpath(DIAGHAM_BUILD_DIR, "run")

using DiagHamInterface: install_diagham

# Delegate installation to the exported package function so tests and users
# use the shared implementation. The test constants are still defined here
# for convenience and passed to the package function below.

function diagham_available(build_dir::AbstractString = DIAGHAM_BUILD_DIR)
    possible_paths = [
        joinpath(build_dir, "FQHE", "src", "Programs", "FQHEOnDisk", "FQHEDiskFermionsTwoBodyGeneric"),
        joinpath(build_dir, "FQHE", "src", "Programs", "FQHEOnTorus", "FQHETorusFermionsTwoBodyGeneric"),
        joinpath(build_dir, "FTI", "src", "Programs", "FTI", "FTIGenericInteractionFromFileTwoBands"),
        joinpath(build_dir, "src", "Programs", "GenericHamiltonianDiagonalization"),
        joinpath(build_dir, "src", "Programs", "GenericOverlap"),
    ]
    return any(isfile, possible_paths)
end


"""
Call the package `install_diagham` with the test-local defaults.
"""
function ensure_diagham_installed()
    if diagham_available(DIAGHAM_BUILD_DIR)
        @info "DiagHam already installed at $DIAGHAM_BUILD_DIR"
        return DIAGHAM_BUILD_DIR
    end

    @info "DiagHam not installed, attempting installation..."
    try
        install_diagham(; source_dir = DIAGHAM_SOURCE_DIR)
    catch e
        @warn "Failed to install DiagHam: $e"
    end
    return DIAGHAM_BUILD_DIR
end
