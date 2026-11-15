"""Reuse the unsigned pipeline's simulator results only for identical simulator inputs."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

def run(*args, **kwargs):
    return subprocess.check_output(args, text=True, **kwargs)

def validations_passed(jobs):
    """Require all four application validation configurations."""
    configurations = ('iOS26-iPhone', 'iOS17-iPhone-SE', 'iOS17-iPad', 'iOS26-iPad')
    return all(any(job['name'].startswith('validate (' + name + ',')
                   and job.get('conclusion') == 'success' for job in jobs)
               for name in configurations)

def validation_configuration(path):
    # Release-only changes cannot alter the matrix or simulator test commands.
    return Path(path).read_text().split("  release:\n", 1)[0]

def main():
    repo = os.environ["GITHUB_REPOSITORY"]
    url = f"repos/{repo}/actions/workflows/ios.yml/runs?branch=main&status=completed&per_page=1"
    runs = json.loads(run("gh", "api", url))["workflow_runs"]
    if not runs:
        return
    previous = runs[0]
    jobs = []
    page = 1
    while True:
        batch = json.loads(run('gh', 'api',
            f"repos/{repo}/actions/runs/{previous['id']}/jobs?filter=latest&per_page=100&page={page}"))['jobs']
        jobs.extend(batch)
        if len(batch) < 100:
            break
        page += 1
    if not validations_passed(jobs):
        return
    sha = previous["head_sha"]
    if subprocess.run(["git", "merge-base", "--is-ancestor", sha, "HEAD"]).returncode:
        return
    # Compare app/extension sources, resources, entitlements, tests and build graph.
    relevant = ["App", "Shared", "KeyboardExtension", "IPAKeyboard.xcodeproj", "Tests", "Reference", "tools/build_catalog.py", "VERSION", "tools/create_simulator.py", "tools/generate_project.py", "tools/boot_simulator.py", "tools/install_test_runtime.py"]
    with tempfile.TemporaryDirectory() as folder:
        old = Path(folder) / "previous"
        subprocess.run(["git","worktree","add","--quiet","--detach",str(old),sha],check=True)
        try:
            subprocess.run(["python3","tools/generate_project.py"],cwd=old,check=True)
            if validation_configuration(old / '.github/workflows/ios.yml') != validation_configuration('.github/workflows/ios.yml'):
                return
            for part in relevant:
                args=["diff","-qr","-x","__pycache__","-x","test_testflight.py","-x","test_simulator_reuse.py",str(old/part),part]
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

