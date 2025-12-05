using DiagHamInterface
using Documenter: Documenter, DocMeta, deploydocs, makedocs

DocMeta.setdocmeta!(
    DiagHamInterface, :DocTestSetup, :(using DiagHamInterface); recursive = true
)

include("make_index.jl")

makedocs(;
    modules = [DiagHamInterface],
    authors = "Andreas Feuerpfeil <development@manybodylab.com>",
    sitename = "DiagHamInterface.jl",
    format = Documenter.HTML(;
        canonical = "https://manybodylab.github.io/DiagHamInterface.jl",
        edit_link = "main",
        assets = [#"assets/logo.png",
            "assets/extras.css",
        ],
    ),
    pages = ["Home" => "index.md", "Reference" => "reference.md"],
)

deploydocs(;
    repo = "github.com/ManyBodyLab/DiagHamInterface.jl", devbranch = "main", push_preview = true
)
