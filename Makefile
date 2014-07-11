# REQUIREMENTS
#
# python ( http://www.python.org ) - lang/python
# mapyrus ( http://mapyrus.sf.net ) - graphics/mapyrus
# tex2im ( http://www.nought.de/tex2im.php ) - textproc/tex2im
#
FOREGROUND_COLOR=	306F97
BACKGROUND_COLOR=	F0F7FE

FIND=	/usr/bin/find
PYTHON_CMD= 	/usr/local/bin/python
RM=	/bin/rm

GENERATOR_SCRIPT=	formulator-images-generator.py
MAPYRUS_SCRIPT=	mapyrus.py
TEX2IM_HEADER=	.tex2im_header
TFILES=	${TEX2IM_HEADER} ${MAPYRUS_SCRIPT} ${GENERATOR_SCRIPT}

FCOLOR!=	${PYTHON_CMD} ${.CURDIR}/bin/hexcolor2rgb.py ${FOREGROUND_COLOR}
BCOLOR!=	${PYTHON_CMD} ${.CURDIR}/bin/hexcolor2rgb.py ${BACKGROUND_COLOR}

all: latex_codes.txt ${GENERATOR_SCRIPT} .SILENT
	${PYTHON_CMD} -u ${.CURDIR}/bin/${GENERATOR_SCRIPT}

clean: clean-mapyrus .SILENT
	${FIND} ${.CURDIR} -type f \( \
	    -name "*.png" -or \
	    -name "*.pyc" -or \
	    -name "*.css" -or \
	    -name "*.html" -or \
	    -name "*.js" \) -delete
.for d in tex2im_images assets/images mapyrus
	${FIND} ${.CURDIR}/${d} -type d -mindepth 1 -name "*" -delete
.endfor
.for f in ${TFILES}
	${RM} -f ${.CURDIR}/bin/${f}
.endfor

clean-mapyrus:
	${FIND} ${.CURDIR} -type f \
	    -name "*.mapyrus" \
	    -delete

formulator-images-generator.py:: .SILENT
.for s in ${GENERATOR_SCRIPT} ${MAPYRUS_SCRIPT}
	sed -e 's.@foreground@.\#${FOREGROUND_COLOR}.1' \
	    -e 's.@background@.\#${BACKGROUND_COLOR}.1' ${.CURDIR}/templates/${s}.tpl > \
	    ${.CURDIR}/bin/${s}
.endfor
	sed -e 's.@foreground@.${FCOLOR}.1' \
	    -e 's.@background@.${BCOLOR}.1' ${.CURDIR}/templates/${TEX2IM_HEADER}.tpl > \
	    ${.CURDIR}/bin/${TEX2IM_HEADER}

merge-new-codes: .SILENT
	awk -f bin/merge-new-codes.awk new_latex_codes.txt >> latex_codes.txt
