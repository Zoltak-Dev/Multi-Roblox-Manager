"""Minimal Roblox multi-instance helper for Windows.

The process keeps Roblox's singleton mutex open until the user exits.
No third-party package or administrator permission is required.
"""

from __future__ import annotations

import ctypes
import os
import sys
from ctypes import wintypes


MUTEX_NAME = "ROBLOX_singletonEvent"
ROBLOX_PROCESS_NAMES = frozenset(
    {
        "robloxplayerbeta.exe",
        "robloxplayer.exe",
        "windows10universal.exe",
    }
)

ERROR_ACCESS_DENIED = 5
ERROR_INVALID_HANDLE = 6
ERROR_ALREADY_EXISTS = 183
TH32CS_SNAPPROCESS = 0x00000002
INVALID_HANDLE_VALUE = ctypes.c_void_p(-1).value


class PROCESSENTRY32W(ctypes.Structure):
    _fields_ = [
        ("dwSize", wintypes.DWORD),
        ("cntUsage", wintypes.DWORD),
        ("th32ProcessID", wintypes.DWORD),
        ("th32DefaultHeapID", ctypes.c_void_p),
        ("th32ModuleID", wintypes.DWORD),
        ("cntThreads", wintypes.DWORD),
        ("th32ParentProcessID", wintypes.DWORD),
        ("pcPriClassBase", ctypes.c_long),
        ("dwFlags", wintypes.DWORD),
        ("szExeFile", ctypes.c_wchar * 260),
    ]


def configure_console() -> None:
    """Use Unicode where supported without failing on older consoles."""
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is not None:
            try:
                reconfigure(errors="replace")
            except (AttributeError, OSError):
                pass


def configure_kernel32():
    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)

    kernel32.CreateMutexW.argtypes = (
        wintypes.LPVOID,
        wintypes.BOOL,
        wintypes.LPCWSTR,
    )
    kernel32.CreateMutexW.restype = wintypes.HANDLE

    kernel32.CloseHandle.argtypes = (wintypes.HANDLE,)
    kernel32.CloseHandle.restype = wintypes.BOOL

    kernel32.CreateToolhelp32Snapshot.argtypes = (
        wintypes.DWORD,
        wintypes.DWORD,
    )
    kernel32.CreateToolhelp32Snapshot.restype = wintypes.HANDLE

    kernel32.Process32FirstW.argtypes = (
        wintypes.HANDLE,
        ctypes.POINTER(PROCESSENTRY32W),
    )
    kernel32.Process32FirstW.restype = wintypes.BOOL

    kernel32.Process32NextW.argtypes = (
        wintypes.HANDLE,
        ctypes.POINTER(PROCESSENTRY32W),
    )
    kernel32.Process32NextW.restype = wintypes.BOOL
    return kernel32


def find_roblox_processes(kernel32):
    """Return the PIDs of currently running Roblox player processes."""
    pids = set()
    snapshot = kernel32.CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
    if not snapshot or snapshot == INVALID_HANDLE_VALUE:
        return ()

    try:
        entry = PROCESSENTRY32W()
        entry.dwSize = ctypes.sizeof(PROCESSENTRY32W)
        found = kernel32.Process32FirstW(snapshot, ctypes.byref(entry))
        while found:
            if entry.szExeFile.lower() in ROBLOX_PROCESS_NAMES:
                pids.add(int(entry.th32ProcessID))
            found = kernel32.Process32NextW(snapshot, ctypes.byref(entry))
    finally:
        kernel32.CloseHandle(snapshot)
    return tuple(sorted(pids))


def retry_or_leave() -> bool:
    """Return True for retry and False for a clean exit."""
    while True:
        try:
            answer = input("Close it, then choose [R]etry or [L]eave: ")
        except (EOFError, KeyboardInterrupt):
            print()
            return False

        answer = answer.strip().lower()
        if answer in ("", "r", "retry"):
            return True
        if answer in ("l", "leave", "q", "quit", "exit"):
            return False
        print("Please enter R to retry or L to leave.")


def claim_mutex(kernel32):
    """Create the singleton mutex, or return None after the user leaves."""
    while True:
        pids = find_roblox_processes(kernel32)
        if pids:
            joined_pids = ", ".join(str(pid) for pid in pids)
            print()
            print("Roblox is already running.")
            print(f"Detected Roblox process ID(s): {joined_pids}")
            print("Multi-instance must be enabled before Roblox starts.")
            if retry_or_leave():
                continue
            return None

        ctypes.set_last_error(0)
        handle = kernel32.CreateMutexW(None, False, MUTEX_NAME)
        error = ctypes.get_last_error()

        if handle and error != ERROR_ALREADY_EXISTS:
            return handle

        if handle:
            kernel32.CloseHandle(handle)

        print()
        if error in (
            ERROR_ACCESS_DENIED,
            ERROR_INVALID_HANDLE,
            ERROR_ALREADY_EXISTS,
        ):
            print("Roblox or another process already owns the singleton mutex.")
        else:
            message = ctypes.FormatError(error).strip() if error else "Unknown error"
            print(f"Windows could not create the mutex: {message} (code {error})")

        if not retry_or_leave():
            return None


def main() -> int:
    configure_console()
    print("=" * 62)
    print(" Multi-Roblox Manager - Lightweight Multi-Instance Utility")
    print("=" * 62)

    if os.name != "nt":
        print("\nThis utility only works on Windows.")
        return 1

    try:
        kernel32 = configure_kernel32()
        handle = claim_mutex(kernel32)
    except KeyboardInterrupt:
        print("\n\nCancelled. Nothing was changed.")
        return 0
    except OSError as exc:
        print(f"\nWindows API error: {exc}")
        return 1

    if handle is None:
        print("\nNothing was changed. Goodbye.")
        return 0

    try:
        print()
        print("SUCCESS: Roblox multi-instance is now active.")
        print("Keep this window open, then launch your Roblox clients.")
        try:
            input("\nPress Enter or Ctrl+C to stop multi-instance...")
        except (EOFError, KeyboardInterrupt):
            print()
    finally:
        kernel32.CloseHandle(handle)

    print("Multi-instance stopped. The singleton mutex was released.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
