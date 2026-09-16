# Reverse engineering workspace

Generated manifests belong in `reverse-engineering/manifests/` and are gitignored by default until reviewed for accidental proprietary payloads or secrets.

Recommended committed artifacts are compact, derived interoperability metadata such as:

- dependency lists;
- imported/exported symbol names;
- Objective-C class/selector inventories;
- ABI comparison summaries;
- patch recipes.

Do not commit extracted Apple binaries/resources.
