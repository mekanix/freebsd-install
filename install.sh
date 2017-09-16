#!/bin/sh

if [ -z $1 ]; then
    echo "Usage: $0 <geom>" >&2
    exit 1
fi

PROJECT_ROOT=`dirname $0`

${PROJECT_ROOT}/geom.sh ${1}
${PROJECT_ROOT}/zfs.sh ${1}p5.eli ${1}p3
${PROJECT_ROOT}/os.sh ${1}p5
