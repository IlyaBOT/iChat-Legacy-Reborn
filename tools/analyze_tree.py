#!/usr/bin/env python
from __future__ import print_function
import os
import sys
import subprocess
import json
import hashlib
import re


def run(args):
    try:
        p = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate()
        if not isinstance(out, str):
            out = out.decode('utf-8', 'replace')
        if not isinstance(err, str):
            err = err.decode('utf-8', 'replace')
        return p.returncode, out, err
    except OSError as e:
        return 127, '', str(e)


def sha1(path):
    h = hashlib.sha1()
    f = open(path, 'rb')
    try:
        while True:
            b = f.read(1024 * 1024)
            if not b:
                break
            h.update(b)
    finally:
        f.close()
    return h.hexdigest()


def parse_dependencies(path):
    rc, out, err = run(['/usr/bin/otool', '-L', path])
    deps = []
    if rc == 0:
        for line in out.splitlines()[1:]:
            line = line.strip()
            if line:
                deps.append(line.split(' (compatibility version', 1)[0])
    return deps


def parse_load_commands(path):
    rc, out, err = run(['/usr/bin/otool', '-l', path])
    result = {'minimum_os': None, 'sdk': None, 'install_id': None, 'rpaths': []}
    if rc != 0:
        return result
    lines = out.splitlines()
    command = None
    for i, line in enumerate(lines):
        s = line.strip()
        if s.startswith('cmd '):
            command = s.split(None, 1)[1]
        elif command == 'LC_VERSION_MIN_MACOSX' and s.startswith('version '):
            result['minimum_os'] = s.split(None, 1)[1]
        elif command == 'LC_VERSION_MIN_MACOSX' and s.startswith('sdk '):
            result['sdk'] = s.split(None, 1)[1]
        elif command == 'LC_ID_DYLIB' and s.startswith('name '):
            result['install_id'] = s.split(' (offset', 1)[0].split(None, 1)[1]
        elif command == 'LC_RPATH' and s.startswith('path '):
            result['rpaths'].append(s.split(' (offset', 1)[0].split(None, 1)[1])
    return result


def parse_symbols(path):
    result = {'undefined': [], 'exported': [], 'objc_classes': [], 'objc_metaclasses': []}
    rc, out, err = run(['/usr/bin/nm', '-u', path])
    if rc == 0:
        result['undefined'] = sorted(set(x.strip() for x in out.splitlines() if x.strip()))

    rc, out, err = run(['/usr/bin/nm', '-g', path])
    if rc == 0:
        exported = []
        classes = []
        metaclasses = []
        for line in out.splitlines():
            parts = line.strip().split()
            if not parts:
                continue
            symbol = parts[-1]
            if symbol.startswith('_OBJC_CLASS_$_'):
                classes.append(symbol[len('_OBJC_CLASS_$_'):])
            elif symbol.startswith('_OBJC_METACLASS_$_'):
                metaclasses.append(symbol[len('_OBJC_METACLASS_$_'):])
            if len(parts) >= 2 and parts[-2] not in ('U', 'u'):
                exported.append(symbol)
        result['exported'] = sorted(set(exported))
        result['objc_classes'] = sorted(set(classes))
        result['objc_metaclasses'] = sorted(set(metaclasses))
    return result


def interesting_strings(path):
    rc, out, err = run(['/usr/bin/strings', path])
    if rc != 0:
        return []
    rx = re.compile(r'(iChat|imagent|iChatAgent|IMDaemon|IMService|ServiceSession|Jabber|XMPP|AIM|Bonjour|FaceTime|SASL|SSL|TLS|InternetAccounts)', re.I)
    return sorted(set(x for x in out.splitlines() if rx.search(x)))[:5000]


def macho_info(path):
    rc, desc, _ = run(['/usr/bin/file', path])
    if 'Mach-O' not in desc:
        return None
    item = {
        'path': path,
        'file': desc.strip(),
        'sha1': sha1(path),
        'dependencies': parse_dependencies(path),
        'load_commands': parse_load_commands(path),
        'interesting_strings': interesting_strings(path)
    }
    item.update(parse_symbols(path))
    rc, out, err = run(['/usr/bin/lipo', '-info', path])
    item['lipo'] = (out + err).strip()
    return item


def main():
    if len(sys.argv) != 3:
        print('usage: analyze_tree.py ROOT OUTPUT.json', file=sys.stderr)
        return 2
    root = os.path.abspath(sys.argv[1])
    result = {'format_version': 2, 'root': root, 'binaries': []}
    for base, dirs, files in os.walk(root):
        dirs.sort()
        files.sort()
        for name in files:
            p = os.path.join(base, name)
            if os.path.islink(p):
                continue
            info = macho_info(p)
            if info:
                info['path'] = os.path.relpath(p, root)
                result['binaries'].append(info)
    result['binaries'].sort(key=lambda x: x['path'])
    f = open(sys.argv[2], 'w')
    try:
        json.dump(result, f, indent=2, sort_keys=True)
        f.write('\n')
    finally:
        f.close()
    print('wrote %s (%d Mach-O files)' % (sys.argv[2], len(result['binaries'])))
    return 0


if __name__ == '__main__':
    sys.exit(main())
