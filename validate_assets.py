import os
import re

project_root = "/media/roy/WDBlue/Codes/village_simulation"
assets_list_file = "assets_list.txt"
asset_references_file = "asset_references.txt"

def get_res_path(abs_path):
    return "res://" + os.path.relpath(abs_path, project_root)

# Load existing assets
existing_assets = set()
with open(assets_list_file, 'r') as f:
    for line in f:
        path = line.strip()
        if path and not ".venv" in path and not ".godot" in path:
            existing_assets.add(get_res_path(path))

# Load referenced assets
referenced_assets = {}
with open(asset_references_file, 'r') as f:
    for line in f:
        if ":" in line:
            ref_file, asset_path = line.strip().split(":", 1)
            # Remove trailing quotes or characters that might be caught by grep
            asset_path = re.sub(r'["\')].*', '', asset_path)
            if asset_path.startswith("res://"):
                if asset_path not in referenced_assets:
                    referenced_assets[asset_path] = []
                referenced_assets[asset_path].append(ref_file)

# Validate References
missing_assets = {}
for asset_path, ref_files in referenced_assets.items():
    # Some res:// paths might be dynamic or have parameters, skip those for now if they look weird
    if "{" in asset_path or "*" in asset_path:
        continue
        
    # Check if the asset exists
    # Godot paths can point to sub-resources (e.g. res://path.tscn::1), we only care about the file part
    file_part = asset_path.split("::")[0]
    
    # Also handle some common Godot built-in "res://" paths if any (usually none, but just in case)
    if not any(file_part == existing for existing in existing_assets):
        # Double check if it's a directory (Godot sometimes references directories)
        abs_file_part = os.path.join(project_root, file_part.replace("res://", ""))
        if not os.path.exists(abs_file_part):
            missing_assets[asset_path] = ref_files

# Identify Unused Assets (only in assets/ and data/ directories)
unused_assets = []
for asset_path in existing_assets:
    if asset_path.startswith("res://assets/") or asset_path.startswith("res://data/"):
        if asset_path not in referenced_assets:
            # Check if it's referenced as a prefix (e.g. dynamic loading)
            is_possibly_used = False
            for ref in referenced_assets:
                if ref.startswith(asset_path):
                    is_possibly_used = True
                    break
            if not is_possibly_used:
                unused_assets.append(asset_path)

print("--- MISSING ASSETS ---")
if not missing_assets:
    print("None")
for asset, refs in missing_assets.items():
    print(f"{asset} (Referenced in: {', '.join(refs[:3])}{'...' if len(refs) > 3 else ''})")

print("\n--- POTENTIALLY UNUSED ASSETS (in assets/ or data/) ---")
if not unused_assets:
    print("None")
for asset in sorted(unused_assets):
    print(asset)
