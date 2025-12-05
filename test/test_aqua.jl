using DiagHamInterface
using Aqua: Aqua
using Test

@testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(DiagHamInterface)
end
