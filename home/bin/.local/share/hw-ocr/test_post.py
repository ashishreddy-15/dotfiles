#!/usr/bin/env python3
"""Run: python3 test_post.py"""
import unittest
from hw_post import clean

CASES = [
    ("  hello   world ", "hello world"),
    ("git status .", "git status"),
    ("see you .", "see you"),
    ("end of sentence.", "end of sentence."),
    ("localhost : 8080", "localhost:8080"),
    ("localhost :8080", "localhost:8080"),
    ("https : // example . com", "https://example.com"),
    ("https : //github.com/x", "https://github.com/x"),
    ("example . com", "example.com"),
    ("notes : buy milk", "notes : buy milk"),      # not safe: left alone
    ("and / or", "and / or"),
    ("a , b , c", "a, b, c"),
    ("1.5 GB", "1.5 GB"),
    ("main . py", "main.py"),
    ("Dr. Smith", "Dr. Smith"),
    ("", ""),
]

class T(unittest.TestCase):
    def test_cases(self):
        for a, b in CASES:
            with self.subTest(a): self.assertEqual(clean(a), b)
    def test_idempotent(self):
        for a, _ in CASES: self.assertEqual(clean(clean(a)), clean(a))

if __name__ == "__main__": unittest.main()
