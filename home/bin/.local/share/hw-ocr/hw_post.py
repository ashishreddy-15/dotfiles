"""Conservative clean-up of TrOCR output. Pure functions, no dependencies (tests: test_post.py)."""
import re

# Extensions / TLDs that are safe to glue to a preceding word: "example . com" -> "example.com".
_EXT = r"(?:com|org|net|io|dev|git|py|sh|md|txt|json|toml|yaml|yml|conf|lua|qml|js|ts|java|xml|html|png|jpg|log|rs|go|cpp|c|h)"


def clean(text: str) -> str:
    t = text.strip()
    t = re.sub(r"\s+", " ", t)
    t = re.sub(r"\s+\.$", "", t)                      # stray trailing " ."
    t = re.sub(r"(?<=\w) ?:\s*//\s*(?=\S)", "://", t)  # https : // x -> https://x
    t = re.sub(r"(?<=[\w\]\)]) : (?=\d)", ":", t)      # localhost : 8080 -> localhost:8080
    t = re.sub(r"(?<=[\w\]\)]) :(?=\d)", ":", t)      # localhost :8080
    t = re.sub(r"(?<=\w) \. (?=" + _EXT + r"\b)", ".", t)  # example . com -> example.com
    t = re.sub(r"(?<=\w) \.(?=" + _EXT + r"\b)", ".", t)
    t = re.sub(r"(?<=\w)\. (?=" + _EXT + r"\b)", ".", t)
    t = re.sub(r" +,", ",", t)                        # "a , b" -> "a, b"
    return t.strip()
