cogsci.pdf: cogsci.tex
	latexmk -pdf $(basename $<)

cogsci.tex: cogsci.md latexpaper/cogsci_template.tex
	pandoc -o $@ --biblatex --bibliography=/home/dave/Documents/papers/zotero.bib --template=latexpaper/cogsci_template.tex --filter pandoc-crossref $<

