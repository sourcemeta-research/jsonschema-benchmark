#! /bin/bash

case $1 in
    C|c)
        runtime="cc=$(cc --version | head -1 | cut -d' ' -f4)"
        ;;
    JS|js|JavaScript|javascript)
        runtime="node=$(node --version)"
        ;;
    PY|py|Python|python)
        runtime=$(python --version | tr ' ' '=')
        ;;
    PL|pl|Perl|perl)
        runtime="perl=$(perl -e 'use English; print $PERL_VERSION';)"
        ;;
    *)
        runtime="unknown"
esac

function git_version()
{
    git -C $1 rev-parse --short=8 HEAD
}

jsu_ver=$(/venv/bin/jsu-compile --version)
jsu_git=$(git_version ./json-schema-utils)
jmc_git=$(git_version ./json-model)

echo "$runtime jsu=$jsu_ver [$jsu_git/$jmc_git]"
