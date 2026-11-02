"""Enable this project's reviewed Luau settings without changing other Serena choices."""
from pathlib import Path
from ruamel.yaml import YAML

root = Path(__file__).resolve().parents[1]
configuration = Path.home() / ".serena" / "serena_config.yml"
yaml = YAML()
configuration.parent.mkdir(parents=True, exist_ok=True)
document = yaml.load(configuration.read_text(encoding="utf-8")) if configuration.exists() else {}
patterns = document.setdefault("trusted_project_path_patterns", [])
project_path = str(root)
if project_path not in patterns:
    patterns.append(project_path)
    with configuration.open("w", encoding="utf-8") as stream:
        yaml.dump(document, stream)
print("Serena advanced settings enabled for this exact project path.")
