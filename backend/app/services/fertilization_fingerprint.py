import hashlib
import json
import math
import uuid
from collections.abc import Mapping, Sequence
from datetime import date, datetime
from enum import Enum
from typing import Any


def build_fertilization_input_fingerprint(inputs: Mapping[str, Any]) -> str:
    """Return a stable hash for every input that can affect a recommendation."""
    canonical = _normalize(inputs)
    serialized = json.dumps(
        canonical,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    )
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()


def _normalize(value: Any) -> Any:
    if isinstance(value, Mapping):
        return {str(key): _normalize(item) for key, item in value.items()}
    if isinstance(value, Sequence) and not isinstance(value, (str, bytes, bytearray)):
        return [_normalize(item) for item in value]
    if isinstance(value, Enum):
        return _normalize(value.value)
    if isinstance(value, uuid.UUID):
        return str(value)
    if isinstance(value, (date, datetime)):
        return value.isoformat()
    if isinstance(value, float):
        if not math.isfinite(value):
            raise ValueError("Fingerprint inputs must contain finite numbers.")
        rounded = round(value, 8)
        return 0.0 if rounded == 0 else rounded
    return value
