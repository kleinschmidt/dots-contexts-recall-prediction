# compile with Weave

using
    Revise,
    Weave

function make()
    weave("cogsci.jmd",
          doctype="pandoc",
          fig_ext=".pdf",
          pandoc_options=["--filter", "pandoc-crossref",
                          "--template", "latexpaper/cogsci_template.tex",
                          "--biblatex", "--pdf-engine=pdflatex"],
          mod=Main)
    run(`make`)
end
