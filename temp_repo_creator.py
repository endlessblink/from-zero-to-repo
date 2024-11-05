import sys, traceback
import tkinter as tk
from tkinter import ttk, messagebox
import json
from urllib import request, error
import threading
import os
import subprocess

class RepoCreator:
    def __init__(self, root):
        self.root = root
        self.root.title("GitHub Repository Creator")
        self.root.geometry("600x500")
        self.setup_ui()
        self.fetch_models()

    def setup_ui(self):
        dir_frame = ttk.LabelFrame(self.root, text="Project Directory", padding=10)
        dir_frame.pack(fill="x", padx=10, pady=5)
        tk.Label(dir_frame, text=os.getcwd(), wraplength=550).pack()
        model_frame = ttk.LabelFrame(self.root, text="Model Selection", padding=10)
        model_frame.pack(fill="x", padx=10, pady=5)
        self.model_var = tk.StringVar()
        self.model_dropdown = ttk.Combobox(model_frame, textvariable=self.model_var, state="readonly")
        self.model_dropdown.pack(fill="x", pady=5)
        button_frame = ttk.Frame(model_frame)
        button_frame.pack(fill="x", pady=5)
        self.test_button = ttk.Button(button_frame, text="Test Model", command=self.test_model)
        self.test_button.pack(side="left", padx=5)
        self.create_button = ttk.Button(button_frame, text="Create Repository", command=self.create_repo)
        self.create_button.pack(side="left", padx=5)
        self.log_text = tk.Text(self.root, height=15, width=70)
        self.log_text.pack(padx=10, pady=5)

    def log(self, message):
        print(message)
        self.log_text.insert("end", str(message) + "\n")
        self.log_text.see("end")

    def fetch_models(self):
        try:
            response = request.urlopen('http://localhost:11434/api/tags')
            models = json.loads(response.read())['models']
            model_names = [model['name'] for model in models]
            self.model_dropdown['values'] = model_names
            if model_names:
                self.model_dropdown.set(model_names[0])
        except Exception as e:
            self.log("Failed to fetch models: " + str(e))

    def test_model(self):
        if not self.model_var.get():
            messagebox.showerror("Error", "Please select a model first")
            return
        self.test_button.config(state='disabled')
        self.log("Testing model...")
        threading.Thread(target=self._test_model_thread).start()

    def _test_model_thread(self):
        try:
            data = {
                "model": self.model_var.get(),
                "prompt": "Say hello and confirm you can help with repository file generation.",
                "stream": False
            }
            req = request.Request(
                'http://localhost:11434/api/generate',
                data=json.dumps(data).encode(),
                headers={'Content-Type': 'application/json'}
            )
            response = request.urlopen(req)
            result = json.loads(response.read().decode('utf-8'))
            self.log("Model response: " + result['response'])
            self.log("Model test successful!")
        except Exception as e:
            self.log("Test failed: " + str(e))
        finally:
            self.test_button.config(state='normal')

    def create_repo(self):
        if not self.model_var.get():
            messagebox.showerror("Error", "Please select a model first")
            return
        self.test_button.config(state='disabled')
        self.create_button.config(state='disabled')
        self.log("\nStarting repository creation...")
        threading.Thread(target=self._create_repo_thread).start()

    def _create_repo_thread(self):
        try:
            self.log("Checking git installation...")
            subprocess.run(['git', '--version'], check=True, capture_output=True)
            self.log("Analyzing project files...")
            files = os.listdir('.')
            file_types = [os.path.splitext(f)[1] for f in files if os.path.isfile(f)]
            prompt = "Create a detailed README.md for a project that contains these files: " + str(set(file_types)) + ". "
            prompt += "This is a tool that creates GitHub repositories using AI to generate documentation. "
            prompt += "RESPOND WITH ONLY A VALID JSON OBJECT IN THIS EXACT FORMAT (no other text): "
            prompt += "{\"readme_content\": \"# AI Repository Creator\\n\\n"
            prompt += "A Python-based tool for automating GitHub repository creation using AI-generated documentation.\\n\\n"
            prompt += "## Overview\\nThis tool provides:\\n- AI-powered documentation generation\\n"
            prompt += "- Automated repository setup\\n- GitHub CLI integration\\n- Local Ollama API integration\\n\\n"
            prompt += "## Requirements\\n- Python 3.x\\n- Git\\n- GitHub CLI (gh)\\n- Ollama running locally\\n\\n"
            prompt += "## Quick Start\\n1. Ensure Ollama is running\\n2. Run Create_Repository.bat\\n"
            prompt += "3. Select an AI model\\n4. Click Create Repository\\n\\n"
            prompt += "## How It Works\\nThe tool:\\n1. Uses Tkinter for the GUI\\n2. Connects to Ollama's local API\\n"
            prompt += "3. Generates repository documentation\\n4. Creates and pushes to GitHub\\n\\n"
            prompt += "## Project Structure\\n- Create_Repository.bat: Main entry point\\n"
            prompt += "- Generated Python GUI: Handles user interaction and repository creation\\n\\n"
            prompt += "## License\\nMIT License\", "
            prompt += "\"gitignore_content\": \"# Python\\n__pycache__/\\n*.pyc\\n*.pyo\\n*.pyd\\n.Python\\n.env\\n.venv\\n\", "
            prompt += "\"other_files\": []}"
            data = {"model": self.model_var.get(), "prompt": prompt, "stream": False}
            self.log("Generating documentation...")
            req = request.Request(
                'http://localhost:11434/api/generate',
                data=json.dumps(data).encode(),
                headers={'Content-Type': 'application/json'}
            )
            response = request.urlopen(req)
            result = json.loads(response.read().decode('utf-8'))
            response_text = result['response']
            self.log("AI Response: " + response_text)
            try:
                files_data = json.loads(response_text)
            except json.JSONDecodeError as je:
                self.log("Failed to parse AI response as JSON")
                raise Exception("AI response was not valid JSON. Please try again.")
            with open('README.md', 'w', encoding='utf-8') as f:
                f.write(files_data['readme_content'])
            self.log("Created README.md")
            with open('.gitignore', 'w', encoding='utf-8') as f:
                f.write(files_data['gitignore_content'])
            self.log("Created .gitignore")
            for file_info in files_data.get('other_files', []):
                with open(file_info['name'], 'w', encoding='utf-8') as f:
                    f.write(file_info['content'])
                    self.log("Created " + file_info['name'])
            if not os.path.exists('.git'):
                subprocess.run(['git', 'init'], check=True)
                self.log("Initialized git repository")
            subprocess.run(['git', 'add', '.'], check=True)
            try:
                subprocess.run(['git', 'commit', '-m', 'Initial commit with AI-generated files'], check=True)
            except:
                subprocess.run(['git', 'config', '--global', 'user.email', 'you@example.com'], check=True)
                subprocess.run(['git', 'config', '--global', 'user.name', 'Your Name'], check=True)
                subprocess.run(['git', 'commit', '-m', 'Initial commit with AI-generated files'], check=True)
            self.log("Created initial commit")
            result = subprocess.run(['gh', 'repo', 'create', '--source=.', '--private', '--push'], capture_output=True, text=True)
            if result.returncode == 0:
                self.log("Successfully created and pushed to GitHub!")
                messagebox.showinfo("Success", "Repository created and pushed to GitHub!")
            else:
                raise Exception(result.stderr)
        except Exception as e:
            error_msg = str(e)
            self.log("Error: " + error_msg)
            messagebox.showerror("Error", error_msg)
        finally:
            self.test_button.config(state='normal')
            self.create_button.config(state='normal')

if __name__ == '__main__':
    try:
        root = tk.Tk()
        app = RepoCreator(root)
        root.mainloop()
    except Exception as e:
        print("Fatal error:")
        traceback.print_exc()
        print("\nPress Enter to exit...")
        input()
