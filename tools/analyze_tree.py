#!/usr/bin/env python
from __future__ import print_function
import os, sys, subprocess, json, hashlib


def run(args):
    try:
        p = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate()
        if not isinstance(out, str): out = out.decode('utf-8', 'replace')
        if not isinstance(err, str): err = err.decode('utf-8', 'replace')
        return p.returncode, out, err
    except OSError as e:
        return 127, '', str(e)


def sha1(path):
    h = hashlib.sha1()
    f = open(path, 'rb')
    while True:
        b = f.read(1024 * 1024)
        if not b: break
        h.update(b)
    f.close()
    return h.hexdigest()


def macho_info(path):
    rc, desc, _ = run(['/usr/bin/file', path])
    if 'Mach-O' not in desc:
        return None
    item = {'path': path, 'file': desc.strip(), 'sha1': sha1(path)}
    rc, out, err = run(['/usr/bin/otool', '-L', path])
    deps = []
    if rc == 0:
        for line in out.splitlines()[1:]:
            line = line.strip()
            if line:
                deps.append(line.split(' (compatibility version', 1)[0])
    item['dependencies'] = deps
    rc, out, err = run(['/usr/bin/nm', '-u', path])
    item['undefined'] = sorted(set([x.strip() for x in out.splitlines() if x.strip()])) if rc == 0 else []
    rc, out, err = run(['/usr/bin/lipo', '-info', path])
    item['lipo'] = (out + err).strip()
    return item


def main():
    if len(sys.argv) != 3:
        print('usage: analyze_tree.py ROOT OUTPUT.json', file=sys.stderr)
        return 2
    root = os.path.abspath(sys.argv[1])
    result = {'root': root, 'binaries': []}
    for base, dirs, files in os.walk(root):
        for name in files:
            p = os.path.join(base, name)
            info = macho_info(p)
            if info:
                info['path'] = os.path.relpath(p, root)
                result['binaries'].append(info)
    result['binaries'].sort(key=lambda x: x['path'])
    f = open(sys.argv[2], 'w')
    json.dump(result, f, indent=2, sort_keys=True)
    f.write('\n')
    f.close()
    print('wrote %s (%d Mach-O files)' % (sys.argv[2], len(result['binaries'])))
    return 0

if __name__ == '__main__':
    sys.exit(main())
