import os
import json
import shutil
import glob

workspace_root = "/Users/marcobarbosa/Development/Swift/TEV/Orbit Hopper"
assets_dir = os.path.join(workspace_root, "OrbitHopper", "OrbitHopper", "Assets.xcassets")
levels_json_path = os.path.join(workspace_root, "OrbitHopper", "OrbitHopper", "Data", "Levels.json")

# 1. Read Levels.json to map image urls to their first appearing level
with open(levels_json_path, 'r') as f:
    levels_data = json.load(f)

image_to_level = {}
for i, level in enumerate(levels_data):
    level_num = i + 1
    for planet in level.get("planets", []):
        img = planet["imageUrl"]
        if img not in image_to_level:
            image_to_level[img] = f"Level {level_num}"

# 2. Create Level folders in xcassets
for level_num in range(1, 11):
    level_folder = os.path.join(assets_dir, f"Level {level_num}")
    os.makedirs(level_folder, exist_ok=True)
    contents_path = os.path.join(level_folder, "Contents.json")
    if not os.path.exists(contents_path):
        with open(contents_path, 'w') as f:
            json.dump({"info": {"version": 1, "author": "xcode"}, "properties": {"provides-namespace": False}}, f, indent=2)

# 3. Find all generated PNGs in the workspace root
png_files = glob.glob(os.path.join(workspace_root, "*.png"))

# Add background.png to ignore list
ignore_list = ["background.png"]

for png_path in png_files:
    filename = os.path.basename(png_path)
    if filename in ignore_list:
        continue
    
    img_name = os.path.splitext(filename)[0]
    
    # Determine level
    level_name = image_to_level.get(img_name, "Level 1")
    
    # Create imageset directory
    imageset_dir = os.path.join(assets_dir, level_name, f"{img_name}.imageset")
    os.makedirs(imageset_dir, exist_ok=True)
    
    # Move PNG
    dest_png = os.path.join(imageset_dir, filename)
    shutil.move(png_path, dest_png)
    
    # Create Contents.json
    contents = {
      "images" : [
        {
          "filename" : filename,
          "idiom" : "universal",
          "scale" : "1x"
        },
        {
          "idiom" : "universal",
          "scale" : "2x"
        },
        {
          "idiom" : "universal",
          "scale" : "3x"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    with open(os.path.join(imageset_dir, "Contents.json"), 'w') as f:
        json.dump(contents, f, indent=2)
    print(f"Organized {img_name} into {level_name}")

# 4. Move existing planets (planet-earth, planet-mars) from root of xcassets if they are there
for item in os.listdir(assets_dir):
    if item.endswith(".imageset") and "planet" in item:
        img_name = item.replace(".imageset", "")
        level_name = image_to_level.get(img_name, "Level 1")
        source_dir = os.path.join(assets_dir, item)
        dest_dir = os.path.join(assets_dir, level_name, item)
        if source_dir != dest_dir and os.path.exists(source_dir):
            shutil.move(source_dir, dest_dir)
            print(f"Moved existing {item} into {level_name}")

print("Assets organization complete.")
