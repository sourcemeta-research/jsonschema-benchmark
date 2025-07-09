import glob
import json
import os
import sys


if __name__ == '__main__':
    img_urls = json.loads(os.environ['IMG_URLS'])

    # Allow specifying a folder or a single file
    if os.path.isdir(sys.argv[1]):
        img_files = sorted(glob.glob(os.path.join(sys.argv[1], '*.png')))
    else:
        img_files = [sys.argv[1]]

    # Make sure we have the correct number of images
    assert(len(img_urls) == len(img_files))

    for (url, file) in zip(img_urls, img_files):
        if len(sys.argv) > 2:
            assert(os.path.isfile(sys.argv[1]))
            name = sys.argv[2]
        else:
            name = file.split('/')[-1].split('.')[0]
        print(f"## {name}")
        print(f"![{name}]({url})\n")
