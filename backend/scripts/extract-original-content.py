#!/usr/bin/env python3
"""Extract allowlisted learning data without executing SQL or importing accounts."""
import gzip
import hashlib
import json
from pathlib import Path
import re
import sys

TABLES = ('categories', 'subcategories', 'courses', 'Content', 'Alphabets',
          'quizz', 'phonics_category', 'phonics_courses', 'Phonics', 'stories',
          'site_language', 'subsc_plans')


def parse_values(text):
    i = 0
    rows = []
    escapes = {'0': '\0', 'b': '\b', 'n': '\n', 'r': '\r', 't': '\t', 'Z': '\x1a'}
    def skip_space():
        nonlocal i
        while i < len(text) and text[i].isspace():
            i += 1
    while True:
        skip_space()
        if i == len(text) or text[i] == ';':
            break
        if text[i] != '(':
            raise ValueError(f'Expected row at offset {i}')
        i += 1
        row = []
        while True:
            skip_space()
            if text[i] == "'":
                i += 1
                chars = []
                while i < len(text):
                    c = text[i]
                    i += 1
                    if c == '\\':
                        escaped = text[i]
                        i += 1
                        chars.append(escapes.get(escaped, escaped))
                    elif c == "'":
                        if i < len(text) and text[i] == "'":
                            chars.append("'")
                            i += 1
                        else:
                            break
                    else:
                        chars.append(c)
                else:
                    raise ValueError('Unterminated SQL string')
                value = ''.join(chars)
            else:
                start = i
                while text[i] not in ',)':
                    i += 1
                token = text[start:i].strip()
                value = None if token == 'NULL' else int(token)
            row.append(value)
            skip_space()
            delimiter = text[i]
            i += 1
            if delimiter == ')':
                break
            if delimiter != ',':
                raise ValueError(f'Unexpected delimiter {delimiter}')
        rows.append(row)
        skip_space()
        if i < len(text) and text[i] == ',':
            i += 1
    return rows


def extract(source):
    data = source.read_bytes()
    sql = data.decode('utf-8')
    tables = {}
    for table in TABLES:
        schema = re.search(r'CREATE TABLE `' + table + r'` \((.*?)\) ENGINE=', sql, re.S)
        if not schema:
            raise ValueError(f'Missing schema: {table}')
        columns = re.findall(r'^  `([^`]+)` ', schema[1], re.M)
        rows = []
        for values in re.findall(r'^INSERT INTO `' + table + r'` VALUES (.*)$', sql, re.M):
            rows.extend(parse_values(values))
        if not rows or any(len(row) != len(columns) for row in rows):
            raise ValueError(f'Missing or invalid rows: {table}')
        if len({row[0] for row in rows}) != len(rows):
            raise ValueError(f'Duplicate IDs: {table}')
        tables[table] = {'columns': columns, 'rows': sorted(rows, key=lambda row: row[0])}
    return {'version': 'original-20260713-v1',
            'source': 'https://kids.langlex.com/20260713_digitsta_langlex.sql',
            'sourceSha256': hashlib.sha256(data).hexdigest(), 'tables': tables}


if __name__ == '__main__':
    source = Path(sys.argv[1])
    output = Path(__file__).resolve().parents[1] / 'database/data/original-content.json.gz'
    catalog = extract(source)
    output.write_bytes(gzip.compress(json.dumps(catalog, ensure_ascii=False, separators=(',', ':')).encode(), mtime=0))
    manifest = {key: value for key, value in catalog.items() if key != 'tables'}
    manifest['counts'] = {name: len(table['rows']) for name, table in catalog['tables'].items()}
    manifest['catalogSha256'] = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_name('original-content.manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(manifest, indent=2))
