#!/usr/bin/env python3
"""
Analyze a Ballerina client.bal file to extract function signatures and metadata.

Mirrors connector_generator/spec_parser.bal and example_generator/analyzer.bal logic.

Usage: analyze_client.py <path-to-client.bal>
Output (stdout): JSON {apiCount, numExamples, configType, methods:[{name, params:[{type,name}], returnType}]}
"""

import sys
import json
import re
import os


def number_of_examples(api_count: int) -> int:
    if api_count < 15:
        return 1
    elif api_count <= 30:
        return 2
    elif api_count <= 60:
        return 3
    else:
        return 4


def extract_config_type(content: str) -> str:
    """Extract the config type from the init() function first parameter."""
    m = re.search(
        r'public\s+isolated\s+function\s+init\s*\(([^)]+)\)',
        content,
        re.MULTILINE,
    )
    if not m:
        return ""
    params_str = m.group(1).strip()
    # First param: type varName or type varName = default
    first = params_str.split(",")[0].strip()
    # Remove default value
    first = re.sub(r'\s*=.*$', '', first).strip()
    # Extract type (everything before last word)
    parts = first.rsplit(None, 1)
    return parts[0].strip() if len(parts) == 2 else ""


def balance_parens(content: str, start: int) -> int:
    """Return the index after the closing ')' for an opening '(' at start."""
    depth = 0
    i = start
    while i < len(content):
        if content[i] == '(':
            depth += 1
        elif content[i] == ')':
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return len(content)


def parse_params(params_str: str) -> list:
    """Parse comma-separated 'type name' pairs, handling nested generics."""
    params = []
    # Split on top-level commas (not inside <> or [])
    depth = 0
    current = []
    for ch in params_str:
        if ch in '<[(':
            depth += 1
        elif ch in '>])':
            depth -= 1
        if ch == ',' and depth == 0:
            params.append(''.join(current).strip())
            current = []
        else:
            current.append(ch)
    if current:
        params.append(''.join(current).strip())

    result = []
    for p in params:
        p = p.strip()
        if not p:
            continue
        # Remove default values
        p = re.sub(r'\s*=\s*\S+\s*$', '', p).strip()
        # Split type and name: last word is the name
        parts = p.rsplit(None, 1)
        if len(parts) == 2:
            result.append({"type": parts[0].strip(), "name": parts[1].strip()})
        elif len(parts) == 1:
            result.append({"type": parts[0].strip(), "name": ""})
    return result


def extract_return_type(after_params: str) -> str:
    """Extract return type from 'returns TYPE {' or end of signature."""
    m = re.search(r'returns\s+([^{;]+)', after_params)
    if m:
        return m.group(1).strip().rstrip('{').strip()
    return ""


def extract_methods(content: str) -> list:
    """Extract all remote and resource function signatures from client class body."""
    methods = []

    # Find the client class body
    class_match = re.search(r'isolated\s+client\s+class\s+Client\s*\{', content)
    if not class_match:
        return methods

    class_start = class_match.end()

    # Pattern for remote or resource functions
    fn_pattern = re.compile(
        r'(?:remote|resource)\s+isolated\s+function\s+([\w/]+)\s*\(',
        re.MULTILINE,
    )

    for fn_match in fn_pattern.finditer(content, class_start):
        name = fn_match.group(1)
        paren_start = fn_match.end() - 1  # position of '('
        paren_end = balance_parens(content, paren_start)
        params_str = content[paren_start + 1:paren_end - 1]
        after_params = content[paren_end:paren_end + 200]
        return_type = extract_return_type(after_params)
        methods.append({
            "name": name,
            "params": parse_params(params_str),
            "returnType": return_type,
        })

    return methods


def analyze(client_path: str) -> dict:
    if not os.path.isfile(client_path):
        print(f"ERROR: File not found: {client_path}", file=sys.stderr)
        sys.exit(1)

    content = open(client_path, "r", encoding="utf-8").read()

    methods = extract_methods(content)
    api_count = len(methods)

    return {
        "apiCount": api_count,
        "numExamples": number_of_examples(api_count),
        "configType": extract_config_type(content),
        "methods": methods,
    }


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <client.bal>", file=sys.stderr)
        sys.exit(2)
    print(json.dumps(analyze(sys.argv[1]), indent=2))
