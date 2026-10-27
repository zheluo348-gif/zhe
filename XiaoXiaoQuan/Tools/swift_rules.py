"""Compile and run the generated production-rule checks on macOS or Linux."""

from pathlib import Path
import os
import shutil
import subprocess
import sys


SWIFT_IMAGE = (
    "swift:6.2.1-noble@sha256:"
    "0e4716bd34384d22963a63afbdbc93be3129dfd0753185aa1ded27755abdcae8"
)


def run_checks(source: Path) -> None:
    source = source.resolve()
    binary = source.with_suffix("")
    compiler = None
    if sys.platform == "darwin" and shutil.which("xcrun"):
        compiler = ["xcrun", "swiftc"]
    elif shutil.which("swiftc"):
        compiler = ["swiftc"]

    if compiler:
        subprocess.run(
            compiler + ["-parse-as-library", str(source), "-o", str(binary)],
            check=True,
        )
        subprocess.run([str(binary)], check=True)
        return

    if sys.platform.startswith("linux") and shutil.which("docker"):
        import fcntl

        # Only generated files are exposed to the container. Checks need no network.
        # VFS daemons copy the entire toolchain per container. Serialize suites
        # from this checkout so parallel test commands cannot exhaust its disk.
        with (source.parent / ".swift-rules-docker.lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            subprocess.run(
                [
                    "docker", "--host=unix:///var/run/docker.sock", "run", "--rm",
                    "--network=none", "--user", f"{os.getuid()}:{os.getgid()}",
                    "--mount", f"type=bind,src={source.parent},dst=/checks",
                    "--workdir", "/checks", SWIFT_IMAGE,
                    "sh", "-ec",
                    'swiftc -parse-as-library -module-cache-path /tmp/swift-cache '
                    '"$1" -o "$2"; exec "./$2"',
                    "swift-rule-checks", source.name, binary.name,
                ],
                check=True,
            )
        return

    raise SystemExit(
        "Rule checks require Xcode on macOS, swiftc on Linux, or the local "
        f"Docker daemon with {SWIFT_IMAGE}."
    )
