#!/usr/bin/env python
from __future__ import print_function
from cgi import escape as escape
from mapyrus import exec_mapyrus, mapyrus_output_dir
from os.path import join as joindir

import os
import subprocess
import string

create_html = True
debug = False

background_color = 'mybackground'
foreground_color = 'myforeground'

image_path = joindir('assets/images/', '1x1.gif')

#
# File: check_images.html
# HTML di controllo immagini generate
#
header_check_images = """<html>
    <head>
        <style type="text/css">
        body {
            background-color: #fffaea
        }

        .editor-formule-tab {
            margin-bottom: 20px;
            width: 500px;
        }

        img {
            border: 1px solid;
            border-color: @foreground@;
            border-radius: 4px;
            padding: 1px;
            background-color: @background@;
       }
       </style>
    </head>
    <body>"""

body_check_images = ""

footer_check_images = """
    </body>
</html>
"""

#
# File: editor.js
# Codice da incorporare in editor.js
#
header_editor_js = """ef_formule = {
"""

footer_editor_js = """};
"""

ef_formule = {}
ef_formule_el = """    %s: {
        latex: '%s',
        asciimathml: '%s'
    }"""


#
# File: matrix.js (parte di editor.js)
#
header_matrix_js = """matrix_ids = {
"""

footer_matrix_js = """},
"""

ef_matrix = {}
ef_matrix_el = """    %s: {
        latex: '%s',
        asciimathml: '%s'
    }"""

cwd = os.getcwd()

#
# Variabili tex2im
#
tex2im_extra_headers = joindir(cwd, 'bin/.tex2im_header')
tex2im_format = 'png'
tex2im_images_dir = joindir(os.getcwd(), 'tex2im_images')
tex2im_args = '-f %s -x %s -o ' % (tex2im_format, tex2im_extra_headers)
tex2im_cmd = joindir(cwd, 'bin/tex2im') + ' %s %s \'%s\''

##
# INIZIO PROGRAMMA 
#

categoria='dummy'
first_header = True
ids = []
images_list = {}
latex_codes = 'latex_codes.txt'
max_x = 0
max_y = 0
max_sizes = {}

# apre file codici
latex_codes_fp = open(latex_codes, 'r')
lines = latex_codes_fp.readlines()
i = 1
id_cat = {}

# legge righe del file
for line in lines:
    line = line.strip()
    if len(line) > 0:
        line_fields = line.split(':')
        if line.startswith('HEADER:'):
            print('\ntex2im ', end='')
            i = 1
            categoria = line_fields[1]
            id_number = 0
            max_x = max_y = 0
            if debug:
                print('  ==> Categoria: %s' % (categoria))
            ef_formule.update({'// ' + categoria : ''})
            ids.append('// ' + categoria)
        else:
            # calcola hash/id di ogni codice
            latex = line_fields[0]
            asciimathml = line_fields[1]
            # fix codice asciimathml per simbolo chimico
            if categoria == 'constructions' and line.startswith('{}^{14}'):
                asciimathml = asciimathml + '::' + line_fields[3]
            if latex == r'\div':
                asciimathml = '-:'
            line = latex
            code_id = categoria[0:2] + string.zfill(id_number, 2)
            id_number = id_number + 1
            ids.append(code_id)
            ef_formule.update({code_id : {'latex' : latex, 'asciimathml' : asciimathml}})
            id_cat[code_id] = categoria
            if debug:
                print('  ==> line: %s, code_id: %s' % (line, code_id))

            # crea immagine con tex2im
            tex2im_out = code_id + '.' + tex2im_format
            tex2im_output_dir = joindir(tex2im_images_dir, categoria)
            # controlla esistenza directory output
            if not os.path.isdir(tex2im_output_dir):
                os.mkdir(tex2im_output_dir)
                if debug:
                    print('  ==> Creata directory: %s' % (tex2im_output_dir))
            tex2im_out = joindir(tex2im_output_dir, tex2im_out)
            if not os.path.isfile(tex2im_out):
                cmd = tex2im_cmd % (tex2im_args, tex2im_out, line)
                os.system(cmd)
                print('[%s]' % (str(i).zfill(3)), end='')
                i = i + 1
            else:
                print('[]', end='')
            # calcola dimensioni icon
            identify_out = subprocess.check_output(['identify', tex2im_out])
            image_size = identify_out.split(' ')[2]
            x, y = image_size.split('x')
            x = int(x)
            y = int(y)
            if debug:
                print('  ==> %s: x=%s, y=%s' % (tex2im_out, x, y))
            if x > max_x :
                max_x = x
            if y > max_y:
                max_y = y
            max_sizes[categoria] = (max_x, max_y)

def create_index ():
    global body_check_images

    first_div = True
    html_out = open('index-panels.html', 'w')

    for k in ids:
        if k.startswith('//'):
            categoria = k[3:]
            if not first_div:
                body_check_images = body_check_images + """
            </div>
"""
            first_div = False
            body_check_images = body_check_images + """            <!-- %s -->
            <div id="%s" class="editor-formule-tab">""" % (categoria.capitalize().replace('-', ' '), categoria)
        else:
            latex = ef_formule[k]['latex']

            body_check_images = body_check_images + '\n                <img id="%s" class="cat-%s" src="%s" alt="%s" title="%s" width="1" height="1" />' % (k, categoria, image_path, escape(latex), escape(latex))
    body_check_images = body_check_images + """
            </div>"""
    html_out.write(body_check_images)
    html_out.write('\n')

    del(html_out)

if create_html:
    create_index()

def create_editor_js():
    ef_formule_fp = open('editor-formule-ef_formule.js', 'w')
    ef_formule_fp.write(header_editor_js)
    ef_matrix_fp = open('editor-formule-ef_matrix.js', 'w')
    ef_matrix_fp.write(header_matrix_js)

    ids_len = len(ids)
    c = 1
    for k in ids:
        if k.startswith('//'):
            categoria = k[3:]
            if 'matrix' in k:
                fp = ef_matrix_fp
                ef = ef_matrix
            else:
                fp = ef_formule_fp
                fp.write('    // %s\n' % k[3:].capitalize().replace('-', ' '))
        else:
            asciimathml_code = ef_formule[k]['asciimathml'].replace('\\', '\\\\')
            if asciimathml_code == '\'\'':
                asciimathml_code = ''
            else:
                asciimathml_code = asciimathml_code + ' '
            latex = ef_formule[k]['latex'].replace('\\', '\\\\')
            if categoria == 'matrix':
                latex = latex[latex.find('{')+1:latex.find('}')]
            else:
                latex = latex + ' '
            # fix codice matrice senza simboli ai lati per ASCIIMathML
            if latex == 'matrix':
                asciimathml_code = '{: (,) :}'
            else:
                if latex.startswith('{}'):
                    asciimathml_code='{::}_(\\\\ \\\\ ?)^(?) text(?)'
                # sostituisce (a), (ab), (abc)
                for token in ('(12)', '(a)', '(b)', '(ab)', '(abc)', '(A)', '(C)', '(AB)', '(ABC)', '(x^2)', '(k+1)', '(2)', '(n)', '(k)', '(E)', '(D)', '(V)', '(W)'):
                    asciimathml_code = asciimathml_code.replace(token, '(?)')
                for token in ('{12}', '{a}', '{b}', '{ab}', '{abc}', '{A}', '{C}', '{AB}','{ABC}', '{x^2}', '{k+1}', '{2}', '{n}', '{k}', '{E}', '{D}', '{V}', '{W}'):
                    latex = latex.replace(token, '{?}')
                # fix altre costruzioni
                asciimathml_code = asciimathml_code.replace('^n', '^?')
                asciimathml_code = asciimathml_code.replace('sum x', 'sum(?)')
                asciimathml_code = asciimathml_code.replace('b = ', '? = ')
                asciimathml_code = asciimathml_code.replace('a = ', '? = ')
                asciimathml_code = asciimathml_code.replace('-> y', '-> ?')
                asciimathml_code = asciimathml_code.replace('f(x)', '?')
                asciimathml_code = asciimathml_code.replace('(i = m)', '(? = ?)')
                latex = latex.replace('\\rightarrow y', '\\rightarrow ?')
                latex = latex.replace('f(x)', '?')
                latex = latex.replace('6}', '?}')
                latex = latex.replace('^n', '^?')
                latex = latex.replace('^N', '^?')
                latex = latex.replace('{i = 1}', '{? = ?}')
                latex = latex.replace('{i = m}', '{? = ?}')
                latex = latex.replace('b = ', '? = ')
                latex = latex.replace('a = ', '? = ')
                latex = latex.replace('[n]', '[?]')
            fp.write(ef_formule_el % (k, latex, asciimathml_code))
            if c < ids_len:
                fp.write(',')
            fp.write('\n')
        c = c + 1
    ef_formule_fp.write(footer_editor_js)
    ef_matrix_fp.write(footer_matrix_js)

    del(ef_formule_fp)
    del(ef_matrix_fp)


def create_editor_css():

    categorie = os.listdir(tex2im_images_dir)

    # apre file css in scrittura
    css_fp = open('editor-formule-img.css', 'w')

    for cat in categorie:
        c = os.path.basename(cat)
        w = max_sizes[c][0]
        h = max_sizes[c][1]
        #css_fp.write('.cat-%s {\n    background:url(assets/images/%s/%s.png) no-repeat top right;\n}\n' % (c, c, c))
        css_fp.write('.cat-%s {\n    background:url(assets/images/%s.png) no-repeat top right;\n}\n' % (c, c))
        imgs = os.listdir(joindir(tex2im_images_dir,cat))
        offset = 0
        for img in imgs:
            if img.endswith('.png'):
                id = os.path.basename(img)[:-4]
                css_fp.write('\n#%s {\n    width:%spx;\n    height:%spx;    background-position: -%spx 0;\n}\n' % (id, w, h, offset))
                offset = offset + w
    del(css_fp)

images_dirs = os.listdir(tex2im_images_dir)
for d in images_dirs:
    target_dir = joindir(tex2im_images_dir, d)
    if os.path.isdir(target_dir):
        exec_mapyrus(target_dir, max_sizes, 'png')

# main
create_editor_js()
create_editor_css()

# chiude file
del(latex_codes_fp)
