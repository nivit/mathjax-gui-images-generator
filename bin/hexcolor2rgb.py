#!/usr/bin/env python

import sys

def hex2rgb():
    str_color = sys.argv[1]

    if str_color.startswith('#'):
        i = 1
    else:
        i = 0
    
    color = str_color[i:i+6]

    c1 = int(color[0:2], 16)
    c2 = int(color[2:4], 16)
    c3 = int(color[4:6], 16)
    print ("%s,%s,%s" % (c1, c2, c3))

if __name__ == '__main__':
    hex2rgb()
