#! /bin/sh

case $1 in
    C|c)
        runtime="$(cc --version|head -1|sed -e 's/(.*) *//')"
        ;;
    JS|js|JavaScript|javascript)
        runtime="Node.js $(node --version)"
        ;;
    PY|py|Python|python)
        runtime=$(python --version)
        ;;
    PL|pl|Perl|perl)
        runtime="Perl $(perl -e 'print $^V')"
        ;;
    JV|Java|java)
        runtime="Java $(java --version|head -1)"
        ;;
    *)
        runtime="unknown"
        ;;
esac

echo "jsu=$(jsu-compile --version) [$runtime]"
