# JSON::Schema::Modern, from CPAN (the full Perl image, for the XS modules it depends on).
FROM perl:5.42.3

RUN apt-get update && apt-get install -y --no-install-recommends time \
 && rm -rf /var/lib/apt/lists/*

# The latest release of JSON::Schema::Modern. (metacpan refuses Docker's ADD, so no cache key follows its releases.)
RUN cpanm --notest JSON::Schema::Modern Cpanel::JSON::XS && rm -rf /root/.cpanm \
 && mkdir -p /app && perl -MJSON::Schema::Modern -e 'print JSON::Schema::Modern->VERSION' > /app/jsm-version

COPY . /app
ENTRYPOINT ["/app/memory-wrapper.sh", "perl", "/app/main.pl"]
CMD []
