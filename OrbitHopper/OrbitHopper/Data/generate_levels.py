import json
import random

unique_images = [
    # Sol (8)
    "planet-mercury", "planet-venus", "planet-earth", "planet-mars", 
    "planet-jupiter", "planet-saturn", "planet-uranus", "planet-neptune",
    # TRAPPIST-1 (7)
    "trappist-1b", "trappist-1c", "trappist-1d", "trappist-1e", "trappist-1f", "trappist-1g", "trappist-1h",
    # Kepler-90 (8)
    "kepler-90b", "kepler-90c", "kepler-90d", "kepler-90e", "kepler-90f", "kepler-90g", "kepler-90h", "kepler-90i",
    # HD 10180 (6)
    "hd-10180b", "hd-10180c", "hd-10180d", "hd-10180e", "hd-10180f", "hd-10180g",
    # Kepler-11 (6)
    "kepler-11b", "kepler-11c", "kepler-11d", "kepler-11e", "kepler-11f", "kepler-11g",
    # Others (15)
    "proxima-b", "gliese-581c", "gliese-581d", "gliese-581g", "tau-ceti-e", "tau-ceti-f", "tau-ceti-g", "tau-ceti-h",
    "kepler-452b", "55-cancri-e", "wasp-12b", "wasp-17b", "wasp-76b", "corot-7b", "gj-1214b"
]

print("Total unique images:", len(unique_images))

systems = [
    {"name": "Sol System", "count": 8},
    {"name": "Alpha Centauri Prime", "count": 9},
    {"name": "TRAPPIST-1 Core", "count": 10},
    {"name": "Kepler-90 Expanse", "count": 11},
    {"name": "HD 10180 Cluster", "count": 12},
    {"name": "Gliese 581 Sector", "count": 13},
    {"name": "Tau Ceti Reach", "count": 14},
    {"name": "Kepler-11 Dominion", "count": 15},
    {"name": "55 Cancri Frontier", "count": 16},
    {"name": "The Abyss", "count": 17}
]

colors = ["#4B90E2", "#A8A8A8", "#E3D599", "#E74C3C", "#9B59B6", "#F1C40F", "#1ABC9C", "#34495E", "#E67E22"]

levels = []
image_pool = list(unique_images)
random.seed(42)
used_so_far = []

for i, sys in enumerate(systems):
    difficulty = 1.0 + (i * 0.2)
    meteor = min(0.1 + (i * 0.08), 0.9)
    
    level = {
        "difficultyModifier": round(difficulty, 2),
        "meteorChance": round(meteor, 2),
        "galaxyName": sys["name"],
        "planets": []
    }
    
    if i == 0:
        # Sol System strict order
        sol_imgs = ["planet-mercury", "planet-venus", "planet-earth", "planet-mars", "planet-jupiter", "planet-saturn", "planet-uranus", "planet-neptune"]
        for img in sol_imgs:
            planet = {
                "imageUrl": img,
                "radius": random.choice([30.0, 40.0, 50.0, 60.0, 70.0]),
                "hexColor": random.choice(colors)
            }
            if img == "planet-saturn":
                planet["radius"] = 75.0
                planet["colliderRadius"] = 45.0
            level["planets"].append(planet)
            if img in image_pool:
                image_pool.remove(img)
            used_so_far.append(img)
    else:
        for p in range(sys["count"]):
            if len(image_pool) > 0:
                img = image_pool.pop(0)
            else:
                img = random.choice(used_so_far)
            
            planet = {
                "imageUrl": img,
                "radius": random.choice([35.0, 45.0, 55.0, 65.0, 80.0]),
                "hexColor": random.choice(colors)
            }
            level["planets"].append(planet)
            used_so_far.append(img)
            
    levels.append(level)

with open("/Users/marcobarbosa/Development/Swift/TEV/Orbit Hopper/OrbitHopper/OrbitHopper/Data/Levels.json", "w") as f:
    json.dump(levels, f, indent=4)
