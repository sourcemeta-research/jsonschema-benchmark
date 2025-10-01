import glob
import json
import os
import sys
from urllib.parse import urljoin


if __name__ == '__main__':
    # Allow specifying a folder or a single file
    if os.path.isdir(sys.argv[1]):
        img_files = sorted(glob.glob(os.path.join(sys.argv[1], '*.png')))
    else:
        img_files = [sys.argv[1]]

    # Get the URL prefix for serving
    url_prefix = sys.argv[2]

    for file in img_files:
        # Construct the full URL
        url = urljoin(url_prefix, file)

        # Add header if provided
        if len(sys.argv) > 3:
            assert(os.path.isfile(sys.argv[1]))
            name = sys.argv[3]
        else:
            name = file.split('/')[-1].split('.')[0]
        print(f"## {name}")
        print(f"![{name}]({url})\n")
