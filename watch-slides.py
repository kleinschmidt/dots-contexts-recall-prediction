#!/usr/bin/env python
from livereload import Server, shell
import nbconvert

# from nbconvert.writers import FilesWriter
# from nbconvert import SlidesExporter

nb_name = 'mathpsych-2018-slides'

exporter_standalone = nbconvert.SlidesExporter()
exporter_standalone.reveal_url_prefix = "https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.6.0"
exporter_standalone.reveal_transition = "none"

exporter_local = nbconvert.SlidesExporter()
exporter_local.reveal_url_prefix = "reveal.js/"
exporter_local.reveal_transition = "none"

writer = nbconvert.writers.FilesWriter()

def export_slides():
    print("regenerating {}".format(nb_name))
    slides, resources = exporter_local.from_filename("{}.ipynb".format(nb_name))
    writer.write(slides, resources, notebook_name="{}.local".format(nb_name))
    slides_standalone, resources_standalone = exporter_standalone.from_filename("{}.ipynb".format(nb_name))
    writer.write(slides_standalone, resources_standalone, notebook_name=nb_name)

export_slides()

server = Server()
server.watch('{}.ipynb'.format(nb_name), export_slides, delay=2)
server.serve()

