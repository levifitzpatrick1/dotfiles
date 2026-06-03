#!/usr/bin/env python3
import os
import sys
import json
import time

def find_icons():
    icon_paths = {}
    search_dirs = [
        os.path.expanduser("~/.local/share/icons"),
        os.path.expanduser("~/.icons"),
        "/usr/share/icons",
        "/usr/share/pixmaps"
    ]
    
    # Active themes to prioritize
    priority_themes = ["breeze-dark", "breeze", "Adwaita", "hicolor"]
    
    for base_dir in search_dirs:
        if not os.path.exists(base_dir):
            continue
        for root, dirs, files in os.walk(base_dir):
            # Prune directories in place to prevent os.walk from entering them, speeding up scan dramatically
            dirs[:] = [d for d in dirs if d not in ('cursors', '16x16', '22x22', '24x24', '32x32', 'animations', 'emblems', 'emotes', 'mimetypes', 'places', 'actions')]
            
            lowered_root = root.lower()
            if not ("apps" in lowered_root or "pixmaps" in lowered_root or "48" in lowered_root or "scalable" in lowered_root):
                continue
                
            # Determine theme priority
            theme_prio = len(priority_themes)
            for i, theme in enumerate(priority_themes):
                if theme in root:
                    theme_prio = i
                    break
                    
            for f in files:
                if f.endswith(('.png', '.svg', '.xpm')):
                    name, ext = os.path.splitext(f)
                    full_path = os.path.join(root, f)
                    
                    if name not in icon_paths:
                        icon_paths[name] = (full_path, theme_prio, ext == '.svg')
                    else:
                        existing_path, existing_prio, existing_is_svg = icon_paths[name]
                        if theme_prio < existing_prio:
                            icon_paths[name] = (full_path, theme_prio, ext == '.svg')
                        elif theme_prio == existing_prio:
                            if ext == '.svg' and not existing_is_svg:
                                icon_paths[name] = (full_path, theme_prio, True)
                                
    return {k: v[0] for k, v in icon_paths.items()}

def get_apps(icon_paths):
    apps = []
    app_dirs = [
        "/usr/share/applications",
        "/usr/local/share/applications",
        os.path.expanduser("~/.local/share/applications"),
        "/var/lib/flatpak/exports/share/applications"
    ]
    
    seen_execs = set()
    seen_names = set()
    
    for app_dir in app_dirs:
        if not os.path.exists(app_dir):
            continue
        for root, dirs, files in os.walk(app_dir):
            for f in files:
                if not f.endswith(".desktop"):
                    continue
                path = os.path.join(root, f)
                try:
                    with open(path, 'r', encoding='utf-8', errors='ignore') as file:
                        lines = file.readlines()
                except Exception:
                    continue
                    
                in_desktop_entry = False
                app_info = {
                    "name": "",
                    "exec": "",
                    "icon": "",
                    "comment": "",
                    "no_display": False,
                    "hidden": False
                }
                
                for line in lines:
                    line = line.strip()
                    if line.startswith("[") and line.endswith("]"):
                        if line == "[Desktop Entry]":
                            in_desktop_entry = True
                        else:
                            in_desktop_entry = False
                    elif in_desktop_entry and "=" in line:
                        parts = line.split("=", 1)
                        if len(parts) < 2:
                            continue
                        key = parts[0].strip()
                        val = parts[1].strip()
                        if key == "Name":
                            app_info["name"] = val
                        elif key == "Exec":
                            app_info["exec"] = val
                        elif key == "Icon":
                            app_info["icon"] = val
                        elif key == "Comment":
                            app_info["comment"] = val
                        elif key == "NoDisplay":
                            app_info["no_display"] = val.lower() == "true"
                        elif key == "Hidden":
                            app_info["hidden"] = val.lower() == "true"
                            
                if not app_info["name"] or not app_info["exec"]:
                    continue
                if app_info["no_display"] or app_info["hidden"]:
                    continue
                    
                # Clean Exec command
                exec_cmd = app_info["exec"]
                exec_parts = []
                for p in exec_cmd.split():
                    if p.startswith("%") or p == "@@u" or p == "@@f":
                        continue
                    exec_parts.append(p)
                clean_exec = " ".join(exec_parts)
                
                # Deduplicate by exec or name
                if clean_exec in seen_execs or app_info["name"] in seen_names:
                    continue
                    
                seen_execs.add(clean_exec)
                seen_names.add(app_info["name"])
                
                # Resolve icon
                icon_val = app_info["icon"]
                resolved_icon = ""
                if icon_val:
                    if icon_val.startswith("/"):
                        resolved_icon = icon_val
                    else:
                        resolved_icon = icon_paths.get(icon_val) or icon_paths.get(icon_val.lower(), "")
                        
                if not resolved_icon:
                    resolved_icon = icon_paths.get("system-run") or icon_paths.get("application-x-executable") or ""
                    
                apps.append({
                    "name": app_info["name"],
                    "exec": clean_exec,
                    "icon": resolved_icon,
                    "comment": app_info["comment"]
                })
                
    apps.sort(key=lambda x: x["name"].lower())
    return apps

def main():
    t0 = time.time()
    icons = find_icons()
    apps = get_apps(icons)
    
    # Save cache
    cache_dir = os.path.expanduser("~/.cache")
    os.makedirs(cache_dir, exist_ok=True)
    cache_path = os.path.join(cache_dir, "quickshell-apps.json")
    
    with open(cache_path, "w", encoding="utf-8") as f:
        json.dump(apps, f, indent=2, ensure_ascii=False)
        
    t1 = time.time()
    print(f"Icons found: {len(icons)}")
    print(f"Apps found: {len(apps)}")
    print(f"Successfully compiled cache to {cache_path} in {(t1-t0)*1000:.1f}ms")

if __name__ == "__main__":
    main()
