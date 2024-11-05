@echo off
setlocal

:: Create Python script
echo Creating Python script...
(
echo import sys, traceback
echo import tkinter as tk
echo from tkinter import ttk, messagebox
echo import json
echo from urllib import request, error
echo import threading
echo import os
echo import subprocess
echo.
echo class RepoCreator:
echo     def __init__^(self, root^):
echo         self.root = root
echo         self.root.title^("GitHub Repository Creator"^)
echo         self.root.geometry^("600x500"^)
echo         self.setup_ui^(^)
echo         self.fetch_models^(^)
echo.
echo     def setup_ui^(self^):
echo         dir_frame = ttk.LabelFrame^(self.root, text="Project Directory", padding=10^)
echo         dir_frame.pack^(fill="x", padx=10, pady=5^)
echo         tk.Label^(dir_frame, text=os.getcwd^(^), wraplength=550^).pack^(^)
echo         model_frame = ttk.LabelFrame^(self.root, text="Model Selection", padding=10^)
echo         model_frame.pack^(fill="x", padx=10, pady=5^)
echo         self.model_var = tk.StringVar^(^)
echo         self.model_dropdown = ttk.Combobox^(model_frame, textvariable=self.model_var, state="readonly"^)
echo         self.model_dropdown.pack^(fill="x", pady=5^)
echo         button_frame = ttk.Frame^(model_frame^)
echo         button_frame.pack^(fill="x", pady=5^)
echo         self.test_button = ttk.Button^(button_frame, text="Test Model", command=self.test_model^)
echo         self.test_button.pack^(side="left", padx=5^)
echo         self.create_button = ttk.Button^(button_frame, text="Create Repository", command=self.create_repo^)
echo         self.create_button.pack^(side="left", padx=5^)
echo         self.log_text = tk.Text^(self.root, height=15, width=70^)
echo         self.log_text.pack^(padx=10, pady=5^)
echo.
echo     def log^(self, message^):
echo         print^(message^)
echo         self.log_text.insert^("end", str^(message^) + "\n"^)
echo         self.log_text.see^("end"^)
echo.
echo     def fetch_models^(self^):
echo         try:
echo             response = request.urlopen^('http://localhost:11434/api/tags'^)
echo             models = json.loads^(response.read^(^)^)['models']
echo             model_names = [model['name'] for model in models]
echo             self.model_dropdown['values'] = model_names
echo             if model_names:
echo                 self.model_dropdown.set^(model_names[0]^)
echo         except Exception as e:
echo             self.log^("Failed to fetch models: " + str^(e^)^)
echo.
echo     def test_model^(self^):
echo         if not self.model_var.get^(^):
echo             messagebox.showerror^("Error", "Please select a model first"^)
echo             return
echo         self.test_button.config^(state='disabled'^)
echo         self.log^("Testing model..."^)
echo         threading.Thread^(target=self._test_model_thread^).start^(^)
echo.
echo     def _test_model_thread^(self^):
echo         try:
echo             data = {
echo                 "model": self.model_var.get^(^),
echo                 "prompt": "Say hello and confirm you can help with repository file generation.",
echo                 "stream": False
echo             }
echo             req = request.Request^(
echo                 'http://localhost:11434/api/generate',
echo                 data=json.dumps^(data^).encode^(^),
echo                 headers={'Content-Type': 'application/json'}
echo             ^)
echo             response = request.urlopen^(req^)
echo             result = json.loads^(response.read^(^).decode^('utf-8'^)^)
echo             self.log^("Model response: " + result['response']^)
echo             self.log^("Model test successful!"^)
echo         except Exception as e:
echo             self.log^("Test failed: " + str^(e^)^)
echo         finally:
echo             self.test_button.config^(state='normal'^)
echo.
echo     def create_repo^(self^):
echo         if not self.model_var.get^(^):
echo             messagebox.showerror^("Error", "Please select a model first"^)
echo             return
echo         self.test_button.config^(state='disabled'^)
echo         self.create_button.config^(state='disabled'^)
echo         self.log^("\nStarting repository creation..."^)
echo         threading.Thread^(target=self._create_repo_thread^).start^(^)
echo.
echo     def _create_repo_thread^(self^):
echo         try:
echo             self.log^("Checking git installation..."^)
echo             subprocess.run^(['git', '--version'], check=True, capture_output=True^)
echo             self.log^("Analyzing project files..."^)
echo             files = os.listdir^('.'^)
echo             file_types = [os.path.splitext^(f^)[1] for f in files if os.path.isfile^(f^)]
echo             prompt = "Create a detailed README.md for a project that contains these files: " + str^(set^(file_types^)^) + ". "
echo             prompt += "This is a tool that creates GitHub repositories using AI to generate documentation. "
echo             prompt += "RESPOND WITH ONLY A VALID JSON OBJECT IN THIS EXACT FORMAT (no other text): "
echo             prompt += "{\"readme_content\": \"# AI Repository Creator\\n\\n"
echo             prompt += "A Python-based tool for automating GitHub repository creation using AI-generated documentation.\\n\\n"
echo             prompt += "## Overview\\nThis tool provides:\\n- AI-powered documentation generation\\n"
echo             prompt += "- Automated repository setup\\n- GitHub CLI integration\\n- Local Ollama API integration\\n\\n"
echo             prompt += "## Requirements\\n- Python 3.x\\n- Git\\n- GitHub CLI (gh)\\n- Ollama running locally\\n\\n"
echo             prompt += "## Quick Start\\n1. Ensure Ollama is running\\n2. Run Create_Repository.bat\\n"
echo             prompt += "3. Select an AI model\\n4. Click Create Repository\\n\\n"
echo             prompt += "## How It Works\\nThe tool:\\n1. Uses Tkinter for the GUI\\n2. Connects to Ollama's local API\\n"
echo             prompt += "3. Generates repository documentation\\n4. Creates and pushes to GitHub\\n\\n"
echo             prompt += "## Project Structure\\n- Create_Repository.bat: Main entry point\\n"
echo             prompt += "- Generated Python GUI: Handles user interaction and repository creation\\n\\n"
echo             prompt += "## License\\nMIT License\", "
echo             prompt += "\"gitignore_content\": \"# Python\\n__pycache__/\\n*.pyc\\n*.pyo\\n*.pyd\\n.Python\\n.env\\n.venv\\n\", "
echo             prompt += "\"other_files\": []}"
echo             data = {"model": self.model_var.get^(^), "prompt": prompt, "stream": False}
echo             self.log^("Generating documentation..."^)
echo             req = request.Request^(
echo                 'http://localhost:11434/api/generate',
echo                 data=json.dumps^(data^).encode^(^),
echo                 headers={'Content-Type': 'application/json'}
echo             ^)
echo             response = request.urlopen^(req^)
echo             result = json.loads^(response.read^(^).decode^('utf-8'^)^)
echo             response_text = result['response']
echo             self.log^("AI Response: " + response_text^)
echo             try:
echo                 files_data = json.loads^(response_text^)
echo             except json.JSONDecodeError as je:
echo                 self.log^("Failed to parse AI response as JSON"^)
echo                 raise Exception^("AI response was not valid JSON. Please try again."^)
echo             with open^('README.md', 'w', encoding='utf-8'^) as f:
echo                 f.write^(files_data['readme_content']^)
echo             self.log^("Created README.md"^)
echo             with open^('.gitignore', 'w', encoding='utf-8'^) as f:
echo                 f.write^(files_data['gitignore_content']^)
echo             self.log^("Created .gitignore"^)
echo             for file_info in files_data.get^('other_files', []^):
echo                 with open^(file_info['name'], 'w', encoding='utf-8'^) as f:
echo                     f.write^(file_info['content']^)
echo                     self.log^("Created " + file_info['name']^)
echo             if not os.path.exists^('.git'^):
echo                 subprocess.run^(['git', 'init'], check=True^)
echo                 self.log^("Initialized git repository"^)
echo             subprocess.run^(['git', 'add', '.'], check=True^)
echo             try:
echo                 subprocess.run^(['git', 'commit', '-m', 'Initial commit with AI-generated files'], check=True^)
echo             except:
echo                 subprocess.run^(['git', 'config', '--global', 'user.email', 'you@example.com'], check=True^)
echo                 subprocess.run^(['git', 'config', '--global', 'user.name', 'Your Name'], check=True^)
echo                 subprocess.run^(['git', 'commit', '-m', 'Initial commit with AI-generated files'], check=True^)
echo             self.log^("Created initial commit"^)
echo             result = subprocess.run^(['gh', 'repo', 'create', '--source=.', '--private', '--push'], capture_output=True, text=True^)
echo             if result.returncode == 0:
echo                 self.log^("Successfully created and pushed to GitHub!"^)
echo                 messagebox.showinfo^("Success", "Repository created and pushed to GitHub!"^)
echo             else:
echo                 raise Exception^(result.stderr^)
echo         except Exception as e:
echo             error_msg = str^(e^)
echo             self.log^("Error: " + error_msg^)
echo             messagebox.showerror^("Error", error_msg^)
echo         finally:
echo             self.test_button.config^(state='normal'^)
echo             self.create_button.config^(state='normal'^)
echo.
echo if __name__ == '__main__':
echo     try:
echo         root = tk.Tk^(^)
echo         app = RepoCreator^(root^)
echo         root.mainloop^(^)
echo     except Exception as e:
echo         print^("Fatal error:"^)
echo         traceback.print_exc^(^)
echo         print^("\nPress Enter to exit..."^)
echo         input^(^)
) > temp_repo_creator.py

:: Run script
python temp_repo_creator.py
if errorlevel 1 (
    echo Error occurred! Press any key to exit...
    pause
)

:: Clean up
del temp_repo_creator.py

endlocal
