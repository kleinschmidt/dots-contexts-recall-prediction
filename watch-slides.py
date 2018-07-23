#!/usr/bin/env python
from livereload import Server, shell
import nbconvert

# from nbconvert.writers import FilesWriter
# from nbconvert import SlidesExporter

nb_name = 'mathpsych-2018-slides'

exporter = nbconvert.SlidesExporter()
# exporter.reveal_url_prefix = "https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.6.0"
exporter.reveal_url_prefix = "reveal.js/"
exporter.reveal_transition = "none"
# exporter.reveal_theme = "blood"

writer = nbconvert.writers.FilesWriter()

def export_slides():
    print("regenerating {}".format(nb_name))
    slides, resources = exporter.from_filename("{}.ipynb".format(nb_name))
    writer.write(slides, resources, notebook_name=nb_name)

export_slides()

server = Server()
server.watch('{}.ipynb'.format(nb_name), export_slides, delay=2)
server.serve()

