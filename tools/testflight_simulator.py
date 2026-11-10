"""Reuse the unsigned pipeline's simulator results only for identical simulator inputs."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

def run(*args, **kwargs):
    return subprocess.check_output(args, text=True, **kwargs)

def main():
    repo = os.environ["GITHUB_REPOSITORY"]
    url = f"repos/{repo}/actions/workflows/ios.yml/runs?branch=main&status=success&per_page=1"
    runs = json.loads(run("gh", "api", url))["workflow_runs"]
    if not runs:
        return
    previous = runs[0]
    sha = previous["head_sha"]
    if subprocess.run(["git", "merge-base", "--is-ancestor", sha, "HEAD"]).returncode:
        return
    # Compare app/extension sources, resources, entitlements, tests and build graph.
    relevant = ["App", "Shared", "KeyboardExtension", "IPAKeyboard.xcodeproj", "Tests", "Reference", "tools/build_catalog.py", "VERSION", "tools/create_simulator.py", ".github/workflows/ios.yml"]
    with tempfile.TemporaryDirectory() as folder:
        old = Path(folder) / "previous"
        subprocess.run(["git","worktree","add","--quiet","--detach",str(old),sha],check=True)
        try:
            subprocess.run(["python3","tools/generate_project.py"],cwd=old,check=True)
            for part in relevant:
                args=["diff","-qr","-x","__pycache__","-x","test_testflight.py",str(old/part),part]
                if subprocess.run(args,stdout=subprocess.DEVNULL).returncode:
                    return
        finally:
            subprocess.run(["git","worktree","remove","--force",str(old)],check=True)
    print("Identical simulator project, app, keyboard, resources and Swift tests:", previous["html_url"])
    with open(os.environ["GITHUB_OUTPUT"],"a") as f:
        print("reuse=true",file=f)
    with open(os.environ["GITHUB_STEP_SUMMARY"],"a") as f:
        print("Simulator inputs matched the passing simulator run: "+previous["html_url"],file=f)

if __name__ == "__main__":
    main()

