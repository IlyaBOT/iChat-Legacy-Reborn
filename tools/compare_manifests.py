#!/usr/bin/env python
from __future__ import print_function
import sys, json, os


def load(path):
    return json.load(open(path, 'r'))


def by_basename(manifest):
    out = {}
    for b in manifest.get('binaries', []):
        out.setdefault(os.path.basename(b['path']), []).append(b)
    return out


def main():
    if len(sys.argv) != 3:
        print('usage: compare_manifests.py OLD.json NEW.json', file=sys.stderr)
        return 2
    old = by_basename(load(sys.argv[1]))
    new = by_basename(load(sys.argv[2]))
    names = sorted(set(old) | set(new))
    for name in names:
        print('\n=== %s ===' % name)
        if name not in old:
            print('+ only in NEW')
            continue
        if name not in new:
            print('- only in OLD')
            continue
        a, b = old[name][0], new[name][0]
        ad, bd = set(a.get('dependencies', [])), set(b.get('dependencies', []))
        au, bu = set(a.get('undefined', [])), set(b.get('undefined', []))
        for x in sorted(bd - ad): print('+dep %s' % x)
        for x in sorted(ad - bd): print('-dep %s' % x)
        print('undefined symbols: old=%d new=%d added=%d removed=%d' % (len(au), len(bu), len(bu-au), len(au-bu)))
    return 0

if __name__ == '__main__':
    sys.exit(main())
