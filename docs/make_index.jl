using Literate: Literate
using DiagHamInterface

Literate.markdown(
    joinpath(pkgdir(DiagHamInterface), "examples", "README.jl"),
    joinpath(pkgdir(DiagHamInterface), "docs", "src");
    flavor = Literate.DocumenterFlavor(),
    name = "index",
)