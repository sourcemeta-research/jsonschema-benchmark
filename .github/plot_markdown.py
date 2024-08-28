import glob
import json
import os


if __name__ == '__main__':
    img_urls = json.loads(os.environ['IMG_URLS'])
    img_files = sorted(glob.glob('dist/results/plots/*.png'))
    for (url, file) in zip(img_urls, img_files):
        name = file.split('/')[-1].split('.')[0]
        print(f"## {name}")
        print(f"![{name}]({url})\n")
