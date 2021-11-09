#!/bin/bash
expectedTrace=(\
"func1 .*/error_backtrace1.c:20" \
"main .*/error_backtrace1.c:27" \
"func2 .*/error_backtrace1.c:13" \
"func1 .*/error_backtrace1.c:23" \
"main .*/error_backtrace1.c:27" \
"func3 .*/error_backtrace1.c:7" \
"func2 .*/error_backtrace1.c:16" \
"func1 .*/error_backtrace1.c:23" \
"main .*/error_backtrace1.c:27" \
)

actualTrace=$(</dev/stdin)
for t in "${expectedTrace[@]}"; do
    exist=$(echo $actualTrace | grep "$t")
    if test `expr length "$exist"` -le 0; then
        exit 1
    fi
done
