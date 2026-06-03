#!/usr/bin/env python3
import sys
import os
import json
import urllib.request
import urllib.parse
import time
import threading

# ANSI color codes for premium, cohesive shell visual experience
GOLD = "\033[1;38;2;216;199;165m"
WHITE = "\033[1;37m"
GRAY = "\033[0;90m"
LAVENDER = "\033[1;38;2;208;188;255m"
RED = "\033[1;31m"
GREEN = "\033[1;32m"
NC = "\033[0m"

# Premium typing terminal header
def print_header(query):
    os.system('clear || true')
    print(f"{LAVENDER}🌌 Quickshell Material 3 Expressive Suite | AI Assistant{NC}")
    print(f"{GRAY}------------------------------------------------------------{NC}")
    print(f"{GOLD}Question:{NC} {WHITE}{query}{NC}")
    print(f"{GRAY}------------------------------------------------------------{NC}\n")

class Spinner:
    def __init__(self):
        self.active = False
        self.thread = None

    def spin(self):
        chars = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
        i = 0
        while self.active:
            sys.stdout.write(f"\r{LAVENDER}{chars[i]} Connecting to AI engine...{NC}")
            sys.stdout.flush()
            time.sleep(0.08)
            i = (i + 1) % len(chars)
        sys.stdout.write("\r" + " " * 30 + "\r")
        sys.stdout.flush()

    def start(self):
        self.active = True
        self.thread = threading.Thread(target=self.spin)
        self.thread.start()

    def stop(self):
        self.active = False
        if self.thread:
            self.thread.join()

def ask_gemini(query, api_key):
    # Standard Gemini v1beta model API call using standard urllib (0 external dependencies!)
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:streamGenerateContent?key={api_key}"
    headers = {"Content-Type": "application/json"}
    data = {
        "contents": [{
            "parts": [{"text": query}]
        }],
        "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 1000
        }
    }
    
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode("utf-8"),
        headers=headers,
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req) as response:
            buffer = ""
            sys.stdout.write(f"{GOLD}AI (Gemini 1.5 Flash):{NC}\n")
            sys.stdout.flush()
            
            # Read streaming response chunks
            while True:
                chunk = response.read(1024)
                if not chunk:
                    break
                buffer += chunk.decode("utf-8")
                
                # Gemini returns JSON streams, parse complete blocks
                # The stream format is a JSON array of candidates
                try:
                    # Very simple streaming parser for chunks
                    # Try to locate candidate text blocks using regex-like lookups to stream fast
                    idx = buffer.find('"text": "')
                    while idx != -1:
                        end_idx = buffer.find('"', idx + 9)
                        if end_idx != -1:
                            text_val = buffer[idx + 9:end_idx]
                            # Clean unicode escapes
                            decoded_text = text_val.encode('utf-8').decode('unicode-escape')
                            sys.stdout.write(decoded_text)
                            sys.stdout.flush()
                            buffer = buffer[end_idx + 1:]
                        else:
                            break
                        idx = buffer.find('"text": "')
                except Exception:
                    pass
            print("\n")
            return True
    except Exception as e:
        return False

def ask_ollama(query):
    # Standard local Ollama generation API call
    url = "http://localhost:11434/api/generate"
    headers = {"Content-Type": "application/json"}
    data = {
        "model": "llama3",
        "prompt": query,
        "stream": True
    }
    
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode("utf-8"),
        headers=headers,
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req) as response:
            sys.stdout.write(f"{GOLD}AI (Ollama Local Llama3):{NC}\n")
            sys.stdout.flush()
            
            # Stream Ollama JSON lines
            for line in response:
                if line:
                    chunk = json.loads(line.decode("utf-8"))
                    text = chunk.get("response", "")
                    sys.stdout.write(text)
                    sys.stdout.flush()
            print("\n")
            return True
    except Exception:
        return False

def print_fallback_help():
    print(f"{RED}❌ Could not connect to any AI Engine!{NC}")
    print(f"\n{WHITE}You have two easy ways to enable your Launcher AI Assistant:{NC}")
    print(f"{GRAY}------------------------------------------------------------{NC}")
    print(f"{GOLD}Option A: Enable Local AI (Ollama - Recommended & Free){NC}")
    print(f"  1. Install Ollama:  {GREEN}yay -S ollama-bin{NC}")
    print(f"  2. Start service:   {GREEN}systemctl --user enable --now ollama{NC}")
    print(f"  3. Pull model:      {GREEN}ollama pull llama3{NC}")
    print(f"\n{GOLD}Option B: Use Cloud AI (Google Gemini - Blazing Fast & Free Key){NC}")
    print(f"  1. Get a free API Key: {CYAN}https://aistudio.google.com/{NC}")
    # Show user how to export environment key in .bashrc or .zshrc
    print(f"  2. Export key inside your shell config (~/.bashrc or ~/.zshrc):")
    print(f"     {GREEN}export GEMINI_API_KEY=\"your-api-key-here\"{NC}")
    print(f"{GRAY}------------------------------------------------------------{NC}\n")

def main():
    if len(sys.argv) < 2:
        print("Usage: llm_ask.py <query>")
        sys.exit(1)
        
    query = sys.argv[1]
    print_header(query)
    
    spinner = Spinner()
    spinner.start()
    
    # 1. Attempt Gemini if API Key is configured in environment
    api_key = os.environ.get("GEMINI_API_KEY", "")
    if api_key:
        spinner.stop()
        success = ask_gemini(query, api_key)
        if success:
            # Let the user read the answer before exit
            print(f"\n{GRAY}Press Enter to exit...{NC}")
            input()
            sys.exit(0)
            
    # 2. Attempt Local Ollama fallback
    # Start timer to avoid infinite lockup
    success_ollama = ask_ollama(query)
    spinner.stop()
    
    if success_ollama:
        print(f"\n{GRAY}Press Enter to exit...{NC}")
        input()
        sys.exit(0)
        
    # 3. Both failed, print visual guide
    print_fallback_help()
    print(f"{GRAY}Press Enter to exit...{NC}")
    input()

if __name__ == "__main__":
    main()
