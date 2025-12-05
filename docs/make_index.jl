using Literate: Literate
using DiagHamInterface

Literate.markdown(
    joinpath(pkgdir(DiagHamInterface), "docs", "files", "README.jl"),
    joinpath(pkgdir(DiagHamInterface), "docs", "src");
    flavor = Literate.DocumenterFlavor(),
    name = "index",
)
