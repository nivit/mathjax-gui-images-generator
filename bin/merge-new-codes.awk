BEGIN {
    FS=":"
}

{
    printf "latex:%s:asciimathml:%s\n", $1, $2
}
