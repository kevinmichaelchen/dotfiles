# vfkit: Understanding macOS Container Virtualization

## Overview

**vfkit** is a lightweight, open-source hypervisor for macOS that provides a
command-line interface to Apple's Virtualization.framework.[1] It enables
running Linux virtual machines on macOS, which is essential for container
runtimes like Podman since Linux containers cannot run natively on macOS.[2]

## What is vfkit?

vfkit is a minimal hypervisor written in Go that leverages Apple's native
Virtualization.framework.[3] It was specifically designed to:

- Provide a lightweight VM management solution for containers
- Support both Intel and Apple Silicon Macs
- Offer a simple, maintainable codebase
- Enable fast boot times and efficient resource usage

Unlike traditional hypervisors with millions of lines of code, vfkit's
minimalist approach focuses exclusively on the container use case, resulting in
better performance and easier maintenance.[4]

## Why vfkit Was Created

The need for vfkit arose from limitations in existing virtualization solutions:

### Problems with Previous Solutions

1. **HyperKit**: The previous default hypervisor is x86_64 only and provides no
   Apple Silicon (M1/M2/M3/M4) support.[5]

2. **QEMU**: While QEMU works cross-platform, it has significant drawbacks:
   - Millions of lines of C code requiring CVE tracking and maintenance
   - Performance penalties for bind-mounts on macOS
   - Slower boot times compared to native solutions[6]

### vfkit's Advantages

- Native integration with Apple's Virtualization.framework
- Small, auditable codebase written in Go
- Optimized for macOS (both Intel and Apple Silicon)
- Better file sharing and boot performance
- Used by multiple projects: Podman, CRC (Red Hat OpenShift), and minikube[7]

## Podman's Virtualization Backends on macOS

Podman on macOS has evolved through several virtualization backend options:

### 1. applehv (Current Default - Podman 5.0+)

The `applehv` provider is Podman's machine provider that uses Apple's native
Virtualization.framework through vfkit.[8]

**Key Features:**

- Native Apple hypervisor integration
- Requires macOS 13 (Ventura) or later
- Significantly improved stability, boot times, and file sharing performance
- Supports Rosetta 2 for running x86_64 binaries on Apple Silicon
- Uses raw disk images (only format supported by Virtualization.framework)

**Technical Details:**

```bash
# Your current setup
podman machine list
# NAME                    VM TYPE     CREATED       LAST UP     CPUS        MEMORY      DISK SIZE
# podman-machine-default  applehv     2 months ago  3 days ago  6           2GiB        100GiB
```

**Relationship with vfkit:** The `applehv` provider is **not separate from
vfkit** - it uses vfkit as the underlying tool to interface with Apple's
Virtualization.framework. When you use `applehv`, you're actually using vfkit
under the hood.[9]

### 2. libkrun/krunkit (2025 Default for macOS ARM64)

As of 2025, Podman has adopted **libkrun** with **krunkit** as the new default
for macOS ARM64 systems.[10]

**Key Features:**

- GPU-accelerated containers with access to Apple M-series GPU
- Lightweight VM manager based on Apple's Hypervisor.framework
- Drop-in replacement for vfkit
- Exposes virtio-gpu virtual device for hardware acceleration
- Best for AI/ML workloads requiring GPU access

**Technical Implementation:**

- krunkit mimics vfkit's operation and can act as a drop-in replacement
- Links against libkrun-efi instead of Virtualization.framework
- Provides Vulkan API forwarding to host GPU[11]

**GPU Acceleration:** Containers can now access the GPU on macOS through
virtio-gpu shared memory, enabling hardware-accelerated AI inference and
graphics workloads.[12]

**Platform Defaults:**

- **macOS ARM64 (Apple Silicon)**: Default is libkrun (GPU enabled)
- **macOS AMD64 (Intel)**: Default is applehv (libkrun not available)

### 3. QEMU (Removed in Podman 5.0)

QEMU was the original virtualization backend used by Podman on macOS but was
removed in Podman 5.0.[13]

**Why It Was Removed:**

- Significant performance penalties (especially for bind-mounts)
- Slower boot times
- Required maintaining custom builds
- Large codebase with security maintenance burden
- Apple's native solutions provide superior performance

**Legacy Note:** Existing QEMU-based VMs must be recreated when upgrading to
Podman 5.0+. Users on older macOS versions (pre-Ventura) must use Podman 4.x if
they cannot upgrade.[14]

## Performance Comparison

| Feature                    | applehv/vfkit | libkrun/krunkit | QEMU (Legacy) |
| -------------------------- | ------------- | --------------- | ------------- |
| **Boot Time**              | Fast          | Fast            | Slow          |
| **File Sharing**           | Excellent     | Excellent       | Poor          |
| **Stability**              | Stable        | Stable          | Moderate      |
| **GPU Access**             | ❌ No         | ✅ Yes          | ❌ No         |
| **Apple Silicon**          | ✅ Yes        | ✅ Yes          | ✅ Yes        |
| **Intel Mac**              | ✅ Yes        | ❌ No           | ✅ Yes        |
| **Bind-Mount Performance** | Good          | Good            | Poor          |
| **macOS Requirement**      | 13+ (Ventura) | 13+ (Ventura)   | Any           |

## Do You Need vfkit?

### ✅ YES - If you use Podman with applehv backend

Your Podman machine requires vfkit to function:

```bash
# Check your current setup
podman machine list
# If VM TYPE shows "applehv", you need vfkit
```

### ❌ NO - If you use Docker Desktop

Docker Desktop has its own built-in virtualization solution and doesn't use
vfkit.

### ⚠️ OPTIONAL - If you switch to libkrun

If you migrate to libkrun/krunkit provider, you can remove vfkit as it's no
longer needed.

## Switching Between Providers

### Current Setup Check

```bash
# Check which provider you're using
podman machine list

# Check if vfkit is installed
which vfkit && vfkit --version
```

### Migrating to libkrun (For GPU Acceleration)

If you want GPU-accelerated containers (recommended for Apple Silicon + AI/ML
workloads):

```bash
# Stop and remove existing machine
podman machine stop
podman machine rm podman-machine-default

# Create new machine with libkrun provider
podman machine init --provider libkrun

# Start the new machine
podman machine start
```

After switching to libkrun, you can remove vfkit from your Homebrew
configuration.

## Configuration in Your Dotfiles

### Current Configuration (nix-darwin/configuration.nix)

```nix
homebrew = {
  enable = true;

  brews = [
    "vfkit"  # Required for podman applehv backend
  ];

  casks = [
    "docker"  # Docker Desktop (currently not installed)
  ];
};
```

### Recommended Cleanup

Since Docker Desktop isn't installed on your system:

```nix
homebrew = {
  enable = true;

  brews = [
    "vfkit"  # Keep if using applehv, remove if using libkrun
  ];

  casks = [
    # Remove "docker" if you're not using Docker Desktop
  ];
};
```

## Best Practices

### For Development Workloads

- **General containers**: applehv + vfkit is stable and reliable
- **AI/ML workloads**: Switch to libkrun for GPU acceleration
- **x86_64 emulation**: applehv supports Rosetta 2 for cross-architecture
  containers

### For Production-like Testing

- Use the same provider across your team for consistency
- Document the provider choice in your project README
- Consider libkrun as the forward-looking choice for Apple Silicon

### Version Management

- vfkit versions are managed through Homebrew (auto-updated)
- Podman manages libkrun internally (no separate installation needed)
- Pin Homebrew packages if you need version stability

## Troubleshooting

### vfkit Binary Not Found

```bash
# Error: applehv ends up on error due to missing vfkit binary
brew install vfkit
```

### Machine Won't Restart with applehv

```bash
# Known issue with some applehv versions
podman machine stop
podman machine start

# If persistent, recreate the machine
podman machine rm podman-machine-default
podman machine init
podman machine start
```

### GPU Not Working with libkrun

```bash
# Verify Vulkan support
# Note: Requires macOS 13+ on Apple Silicon
podman run --rm -it --device=/dev/dri alpine sh -c "ls -la /dev/dri"
```

## Summary

**vfkit** is essential infrastructure for running Podman on macOS with the
applehv backend. It provides a lightweight, performant way to run Linux VMs
using Apple's native virtualization APIs. While applehv + vfkit is the current
stable choice, **libkrun/krunkit** represents the future with GPU acceleration
support, making it ideal for modern AI/ML container workloads on Apple Silicon.

### Key Takeaways

1. vfkit is required for Podman's applehv backend on macOS
2. libkrun/krunkit is the newer default offering GPU acceleration
3. Docker Desktop doesn't use vfkit (has its own virtualization)
4. Choose applehv for stability, libkrun for GPU acceleration
5. QEMU is no longer supported in Podman 5.0+

## References

[1]: https://github.com/crc-org/vfkit "vfkit - GitHub Repository"
[2]:
  https://crc.dev/blog/Container%20Plumbing%202023%20-%20vfkit%20-%20A%20minimal%20hypervisor%20using%20Apple's%20virtualization%20framework.pdf
  "Container Plumbing 2023 - vfkit Presentation"
[3]:
  https://archive.fosdem.org/2023/schedule/event/govfkit/attachments/slides/5847/export/events/attachments/govfkit/slides/5847/fosdem2023_go_devroom_vfkit.pdf
  "FOSDEM 2023 - vfkit: A native macOS hypervisor written in go"
[4]: https://github.com/crc-org/vfkit/blob/main/README.md "vfkit README"
[5]: https://crc.dev/blog/posts/2022-06-15-vfkit/ "Running CRC on M1 machines"
[6]:
  https://medium.com/@guillem.riera/podman-on-macos-m1-qemu-7-e9225ffa3453
  "Podman on macOS (M1 & QEMU 7)"
[7]:
  https://containerplumbing.org/sessions/2023/vfkit_a_minimal_.html
  "vfkit - Container Plumbing Days"
[8]:
  https://devclass.com/2024/03/26/podman-5-0-released-with-native-mac-hypervisor-support-new-features-and-breaking-changes/
  "Podman 5.0 released with native Mac hypervisor support"
[9]:
  https://pkg.go.dev/github.com/containers/podman/v5/pkg/machine/apple/vfkit
  "vfkit package - Podman Go Documentation"
[10]:
  https://github.com/podman-desktop/podman-desktop/pull/12856
  "Podman Desktop: Updated content to show libkrun as default"
[11]:
  https://sinrega.org/2024-03-06-enabling-containers-gpu-macos/
  "Enabling containers to access the GPU on macOS"
[12]:
  https://developers.redhat.com/articles/2025/06/05/how-we-improved-ai-inference-macos-podman-containers
  "How we improved AI inference on macOS Podman containers"
[13]:
  https://access.redhat.com/solutions/7063123
  "How do I delete my old Qemu Podman Machine after upgrading to Podman 5.0 on macOS?"
[14]:
  https://github.com/containers/podman/issues/23262
  "Restore qemu support on macOS optionally - Issue #23262"
