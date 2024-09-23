# Hardened Boundary Server

## Task 1: Image Hardening

The goal of this task was to create a hardened Ubuntu 22.04 Image using Packer.
Additionally, the provisioning agent was to be removed from the VM after the first boot.

- [Packer config](./docs/packerconfig.pkr.hcl)
- [OSCAP report before hardening](./reports/reportbefore.html)
- [OSCAP report after hardening](./reports/reportafter.html)
- [Deployment screenshots] (./docs/Image%20Deployment.pdf)

## Task 2: Boundary Installation

The scope of this task was to set up a boundary installation on the hardened VM, also deploying a web server and remote proxy.
Additionally, firewall rules were to be configured. A boundary user was to be created with access to a single target.

On the client side, the boundary source code was to be adapted so the user would not have to provide amn Auth Method ID.





