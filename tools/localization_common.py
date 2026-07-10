#!/usr/bin/env python3
# -*- coding: utf-8 -*-

FALLBACK_REPLACEMENTS = {
    "\u00a0": " ",
    "\u00a9": "(C)",
    "\u00c9": "E",
}


def normalize_fallback_text(value: str) -> str:
    for old, new in FALLBACK_REPLACEMENTS.items():
        value = value.replace(old, new)
    return value
