# compile with Weave

using
    Revise,
    Weave

function make()
    weave("cogsci.jmd",
          doctype="pandoc2pdf",
          pandoc_options=["--filter", "pandoc-crossref", 
                          "--template", "latexpaper/cogsci_template.tex",
                          "--biblatex", "--pdf-engine=pdflatex"],
          mod=Main)
end
