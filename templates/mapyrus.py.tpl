#!/usr/bin/env python

from __future__ import print_function
from os.path import join as joindir
import os

debug = False

cwd = os.getcwd()
mapyrus_src_dir = joindir(cwd, 'mapyrus')
mapyrus_output_dir = joindir(cwd, 'assets/images')

mapyrus_header = """
let px = Mapyrus.screen.resolution.mm

newpage "%s", "%s", \
%s * px, %s * px, \
"background=@background@"
"""

mapyrus_body_tpl= """
move %s * px, %s * px
icon "%s", 0
clearpath
"""

# elabora le immagini nella directory dir
def exec_mapyrus(dir, max_sizes, fmt='png'):

    global mapyrus_src_dir
    global mapyrus_output_dir
    global mapyrus_header

    images = os.listdir(dir)
    categoria = os.path.split(dir)[1]

    _mapyrus_src_dir = joindir(mapyrus_src_dir, categoria)
    _mapyrus_output_dir = mapyrus_output_dir
    mapyrus_image_output = joindir(_mapyrus_output_dir, categoria + '.' + fmt)

    # conta numero di immagini
    noi = 0
    for image in images:
        if os.path.isfile and os.path.splitext(image)[1] == '.' + fmt:
            noi = noi + 1

    x = int(max_sizes[categoria][0])
    y = int(max_sizes[categoria][1])

    # imposta header mapyrus
    mapyrus_src = mapyrus_header % (fmt, mapyrus_image_output, x * noi, y)

    # crea directory sorgente se mancante
    if not os.path.isdir(_mapyrus_src_dir):
        os.mkdir(_mapyrus_src_dir)

    # crea directory di output se mancante
    if not os.path.isdir(_mapyrus_output_dir):
        os.mkdir(_mapyrus_output_dir)

    # aggiunge ogni immagine creata da tex2im
    # al sorgente mapyrus (affiancandola orizzontalmente
    _x = x / 2
    y = y / 2
    mapyrus_body = ''
    for image in images:
        if image.endswith('.' + fmt):
            image_path = joindir(dir, image)
            mapyrus_body = mapyrus_body + mapyrus_body_tpl % (_x, y, image_path)
            _x = _x + x

    # scrive il sorgente su file
    print('\nmapyrus ', end='')
    mapyrus_src = mapyrus_src + mapyrus_body
    fname = categoria + '.mapyrus'
    mapyrus_fname = joindir(_mapyrus_src_dir, fname)
    if not os.path.isfile(mapyrus_fname):
        fp = open(mapyrus_fname, 'w')
        fp.write(mapyrus_src)
        del(fp)

    # crea immagine dal sorgente mapyrus
    if not os.path.isfile(mapyrus_image_output):
        os.system('mapyrus ' + mapyrus_fname)
        print('[%s]' % (fname), end='')
    else:
        print('[]', end='')

if __name__ == '__main__':
    exec_mapyrus('.')
