#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Extract exported NSString/CFString constants from a Mach-O binary without
# loading the target framework. Python 2.6+ compatible for Snow Leopard.
#
# Usage:
#   python tools/extract_cfstring_constants.py <mach-o> <symbol> [symbol...]
#
from __future__ import print_function

import struct
import sys

FAT_MAGIC = 0xCAFEBABE
MH_MAGIC_64 = 0xFEEDFACF
CPU_TYPE_X86_64 = 0x01000007
LC_SEGMENT_64 = 0x19
LC_SYMTAB = 0x2


def u32be(data, off):
    return struct.unpack_from(">I", data, off)[0]


def cstr(data, off):
    end = data.find("\x00", off)
    if end < 0:
        end = len(data)
    return data[off:end]


def select_x86_64(blob):
    if len(blob) < 4:
        raise ValueError("file too small")
    magic_be = u32be(blob, 0)
    if magic_be == FAT_MAGIC:
        nfat = u32be(blob, 4)
        off = 8
        for _ in range(nfat):
            cputype, cpusubtype, archoff, archsize, align = struct.unpack_from(">iiIII", blob, off)
            if cputype == CPU_TYPE_X86_64:
                return blob[archoff:archoff + archsize]
            off += 20
        raise ValueError("x86_64 slice not found")
    magic_le = struct.unpack_from("<I", blob, 0)[0]
    if magic_le == MH_MAGIC_64:
        return blob
    raise ValueError("unsupported Mach-O/fat magic")


def parse_macho64(data):
    if struct.unpack_from("<I", data, 0)[0] != MH_MAGIC_64:
        raise ValueError("selected slice is not little-endian Mach-O 64")

    header = struct.unpack_from("<IiiIIIII", data, 0)
    ncmds = header[4]
    cmdoff = 32
    sections = []
    symtab = None

    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", data, cmdoff)

        if cmd == LC_SEGMENT_64:
            seg = struct.unpack_from("<II16sQQQQiiII", data, cmdoff)
            nsects = seg[9]
            soff = cmdoff + 72
            for _j in range(nsects):
                raw = struct.unpack_from("<16s16sQQIIIIIIII", data, soff)
                sectname = raw[0].split("\x00", 1)[0]
                segname = raw[1].split("\x00", 1)[0]
                addr = raw[2]
                size = raw[3]
                fileoff = raw[4]
                sections.append({
                    "sectname": sectname,
                    "segname": segname,
                    "addr": addr,
                    "size": size,
                    "fileoff": fileoff,
                })
                soff += 80

        elif cmd == LC_SYMTAB:
            _cmd, _cmdsize, symoff, nsyms, stroff, strsize = struct.unpack_from("<IIIIII", data, cmdoff)
            symtab = (symoff, nsyms, stroff, strsize)

        cmdoff += cmdsize

    if symtab is None:
        raise ValueError("LC_SYMTAB not found")

    return sections, symtab


def vm_to_file(sections, vmaddr):
    for sec in sections:
        start = sec["addr"]
        end = start + sec["size"]
        if start <= vmaddr < end and sec["fileoff"] != 0:
            return sec["fileoff"] + (vmaddr - start), sec
    return None, None


def read_vm(data, sections, vmaddr, size):
    off, sec = vm_to_file(sections, vmaddr)
    if off is None or off + size > len(data):
        return None
    return data[off:off + size]


def decode_bytes(raw):
    if raw is None:
        return None
    try:
        return raw.decode("utf-8")
    except Exception:
        try:
            return raw.decode("mac_roman")
        except Exception:
            return None


def read_c_string(data, sections, vmaddr, max_len=4096):
    off, sec = vm_to_file(sections, vmaddr)
    if off is None:
        return None
    end = data.find("\x00", off, min(len(data), off + max_len))
    if end < 0:
        return None
    return decode_bytes(data[off:end])


def try_cfstring_object(data, sections, vmaddr):
    raw = read_vm(data, sections, vmaddr, 32)
    if raw is None or len(raw) < 32:
        return None
    try:
        isa, flags, pad, chars, length = struct.unpack("<QIIQQ", raw)
    except Exception:
        return None
    if length > 65536:
        return None
    chars_raw = read_vm(data, sections, chars, int(length))
    if chars_raw is None:
        return None
    text = decode_bytes(chars_raw)
    if text is None:
        return None
    return text


def resolve_constant(data, sections, symaddr):
    # Case 1: symbol itself is a CFConstantString object.
    text = try_cfstring_object(data, sections, symaddr)
    if text is not None:
        return text, "direct CFString object"

    # Case 2: exported global is a pointer to a CFConstantString object.
    raw = read_vm(data, sections, symaddr, 8)
    if raw is not None and len(raw) == 8:
        ptr = struct.unpack("<Q", raw)[0]
        text = try_cfstring_object(data, sections, ptr)
        if text is not None:
            return text, "pointer to CFString object"

        # Case 3: exported global directly points to a C string.
        text = read_c_string(data, sections, ptr)
        if text is not None and text != "":
            return text, "pointer to C string"

    return None, None


def load_symbols(data, symtab):
    symoff, nsyms, stroff, strsize = symtab
    strtab = data[stroff:stroff + strsize]
    result = {}
    for i in range(nsyms):
        off = symoff + i * 16
        if off + 16 > len(data):
            break
        strx, n_type, n_sect, n_desc, n_value = struct.unpack_from("<IBBHQ", data, off)
        if strx == 0 or strx >= len(strtab):
            continue
        name = cstr(strtab, strx)
        if name:
            result[name] = (n_value, n_type, n_sect, n_desc)
    return result


def main(argv):
    if len(argv) < 3:
        print("usage: %s <mach-o> <symbol> [symbol...]" % argv[0], file=sys.stderr)
        return 2

    path = argv[1]
    wanted = argv[2:]

    blob = open(path, "rb").read()
    data = select_x86_64(blob)
    sections, symtab = parse_macho64(data)
    symbols = load_symbols(data, symtab)

    rc = 0
    for user_name in wanted:
        candidates = [user_name]
        if not user_name.startswith("_"):
            candidates.insert(0, "_" + user_name)

        found_name = None
        entry = None
        for name in candidates:
            if name in symbols:
                found_name = name
                entry = symbols[name]
                break

        if entry is None:
            print("%s = <symbol not found>" % user_name)
            rc = 1
            continue

        value = entry[0]
        text, how = resolve_constant(data, sections, value)
        if text is None:
            off, sec = vm_to_file(sections, value)
            where = "unknown"
            if sec is not None:
                where = "%s,%s" % (sec["segname"], sec["sectname"])
            print("%s = <unresolved>  [symbol=%s addr=0x%x section=%s]" %
                  (user_name, found_name, value, where))
            rc = 1
        else:
            print("%s = %r  [%s]" % (user_name, text, how))

    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv))
