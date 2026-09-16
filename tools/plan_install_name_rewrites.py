#!/usr/bin/env python
from __future__ import print_function
import json
import os
import sys
import pipes


def load(path):
    return json.load(open(path, 'r'))


def rewrite(value, mapping):
    for old in sorted(mapping.keys(), key=len, reverse=True):
        if value == old or value.startswith(old + '/'):
            return mapping[old] + value[len(old):]
    return value


def q(value):
    return pipes.quote(value)


def main():
    if len(sys.argv) != 4:
        print('usage: plan_install_name_rewrites.py MANIFEST.json MAP.json RUNTIME_ROOT', file=sys.stderr)
        return 2

    manifest = load(sys.argv[1])
    mapping = load(sys.argv[2])
    runtime_root = os.path.abspath(sys.argv[3])

    print('#!/bin/sh')
    print('set -e')
    print('# Generated only. Review before executing.')

    changes = 0
    for binary in manifest.get('binaries', []):
        rel = binary['path']
        target = os.path.join(runtime_root, rel)
        install_id = binary.get('load_commands', {}).get('install_id')
        if install_id:
            new_id = rewrite(install_id, mapping)
            if new_id != install_id:
                print('install_name_tool -id %s %s' % (q(new_id), q(target)))
                changes += 1

        for dep in binary.get('dependencies', []):
            new_dep = rewrite(dep, mapping)
            if new_dep != dep:
                print('install_name_tool -change %s %s %s' % (q(dep), q(new_dep), q(target)))
                changes += 1

    print('# %d rewrite operations' % changes)
    return 0


if __name__ == '__main__':
    sys.exit(main())
