from importlib import import_module
from pkgutil import iter_modules
from pathlib import Path

# Public types re-exported for convenience
from .validation_types import ValidationResult, ValidationCheck  # noqa: F401

# Build aggregated CHECKS list dynamically so cli can pull everything automatically.
CHECKS = []
_checks_path = Path(__file__).with_suffix("").parent / "checks"
for _m in iter_modules([str(_checks_path)]):
    mod = import_module(f".{_m.name}", package="tecton_validate.checks")
    CHECKS.extend(getattr(mod, "CHECKS", []))
