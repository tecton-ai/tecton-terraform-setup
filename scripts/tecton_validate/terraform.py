import json
from pathlib import Path
from rich.console import Console
from typing import Union

__all__ = ["load_terraform_outputs"]


def load_terraform_outputs(
    outputs_file_path: Union[str, Path], console: Console
) -> dict:
    """Load and parse *terraform output -json* file.

    Returns a simple dict with primitive values, handling both terraform 0.12+ JSON
    structure and the wrapped value format we use in the dataplane pipeline.
    """

    path = Path(outputs_file_path).expanduser()
    try:
        with path.open() as f:
            raw = json.load(f)

        # Allow users to nest under a top-level key `tecton` (our deployment root)
        if (
            "tecton" in raw
            and isinstance(raw["tecton"], dict)
            and "value" in raw["tecton"]
        ):
            outputs = raw["tecton"]["value"]
        else:
            outputs = raw

        def _val(o):
            if isinstance(o, dict) and "value" in o:
                return o["value"]
            return o

        return {k: _val(v) for k, v in outputs.items()}

    except FileNotFoundError:
        console.print(
            f"[yellow]Terraform outputs file not found: {path} – continuing with defaults[/yellow]"
        )
        return {}
    except json.JSONDecodeError as exc:
        console.print(
            f"[yellow]Could not parse outputs file: {exc} – continuing with defaults[/yellow]"
        )
        return {}
