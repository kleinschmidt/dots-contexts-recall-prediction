# compile with Weave

using
    Revise,
    Weave

function make_paper()
    weave("cogsci.jmd",
          doctype="pandoc",
          fig_ext=".pdf",
          pandoc_options=["--filter", "pandoc-crossref",
                          "--template", "latexpaper/cogsci_template.tex",
                          "--biblatex", "--pdf-engine=pdflatex"],
          mod=Main)
    run(`make cogsci.pdf`)
end


function make_poster()
    weave("poster.jmd",
          doctype="pandoc",
          fig_ext=".svg",
          pandoc_options=["--filter", "pandoc-crossref"],
          mod=Main)
    run(`make poster.html`)
end
