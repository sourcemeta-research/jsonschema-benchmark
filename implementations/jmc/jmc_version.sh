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

jmc_ver=$(/venv/bin/jmc --version)
jmc_git=$(git_version ./json-model)
jsu_ver=$(/venv/bin/jsu-model --version)
jsu_git=$(git_version ./json-schema-utils)

echo "$runtime jmc=$jmc_ver-$jmc_git jsu=$jsu_ver-$jsu_git"
