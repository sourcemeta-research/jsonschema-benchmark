import base64
import glob
import json
import os
import sys


if __name__ == '__main__':
    # Allow specifying a folder or a single file
    if os.path.isdir(sys.argv[1]):
        img_files = sorted(glob.glob(os.path.join(sys.argv[1], '*.png')))
    else:
        img_files = [sys.argv[1]]

    for file in img_files:
        if len(sys.argv) > 2:
            assert(os.path.isfile(sys.argv[1]))
            name = sys.argv[2]
        else:
            name = file.split('/')[-1].split('.')[0]

        # Convert the image into a data URL
        data_url = "data:image/png;base64," + base64.b64encode(open(file, "rb").read()).decode()

        print(f"## {name}")
        print(f"![{name}]({data_url})\n")
