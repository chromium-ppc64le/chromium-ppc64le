#!/bin/bash

echo "<html>"
echo "<head><title>Index of $1</title>"
echo "<body>"
echo "<h1>Index of $1</h1><hr><pre><a href="../">../</a>"
find $1 -maxdepth 1 -mindepth 1 -printf "%P|%Td-%Tb-%TY %TH:%TM|%s\0" \
    | sort -k1 -z | awk -F\| 'BEGIN { RS = "\0" }
{
    if (length($1) > 50)
        filename = substr($1, 1, 43)"..>"
    else
        filename = $1
    printf "<a href=\"%s\">%-50s %s %10s\n", $1, filename"</a>", $2, $3
}'
echo "</pre><hr></body>"
echo "</html>"

