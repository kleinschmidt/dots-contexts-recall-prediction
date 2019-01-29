# compile with Weave

using
    Revise,
    Weave

function make()
    weave("cogsci.jmd",
          doctype="pandoc",
          pandoc_options=["--filter", "pandoc-crossref", 
                          "--template", "latexpaper/cogsci_template.tex",
                          "--biblatex"],
          mod=Main)
end
