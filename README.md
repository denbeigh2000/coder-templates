---
name: NixOS Coder templates for AWS EC2
description: Get started with Linux development on AWS EC2.
tags: [cloud, aws, nix, nixos, flakes, arm]
icon: /icon/aws.png
---

# NixOS Coder templates for AWS

A simple set of templates that allows you to use a NixOS flake to configure a
Coder workspace.

See [here](https://nixos.wiki/wiki/Flakes#Using_nix_flakes_with_NixOS) for more
information about distributing a NixOS configuration via a flake.

## What templates are provided?
This contains 4 templates, driven by the YAML files under the `values/`
directory:

- `aws-nixos`: NixOS on AWS x86 instances.
- `aws-nixos-spot`: NixOS on AWS x86 spot instances.
- `aws-nixos-graviton`: Nixos on AWS Graviton (aarch64) instances.
- `aws-nixos-graviton-spot`: Nixos on AWS Graviton (aarch64) spot instances.

## How do I set this up?

- To create all templates: `./push-all.sh create`
- To push all templates: `./push-all.sh`
- To push an individual template: `coder templates push -d . --variables-file ./values/VALUES_FILE.yaml TEMPLATE_NAME`

## Some notes before using this yourself

### Using the home disk
Because your NixOS config defines the entire system, it must define mounting
the `/home` device. The backing block device is hard-coded to be available at
`/dev/xvdb`.

You can accomplish this with the following:

```nix
fileSystems."/home" = {
  device = "/dev/xvdb";
  fsType = "ext4";  # Or another filesystem, if you prefer
  autoFormat = true;
}
```

### Authentication
This currently depends on your desired flake being publicly available, and
requiring no secrets to build.

One could feasibly remove this limitation by granting the created instance an
IAM role that could fetch items from AWS Secret Manager, and adding logic to
the setup script to fetch these secrets and put them in the right place.

I haven't implemented any functionality for this, mostly because it's not
relevant to me right now, but I would consider accepting PRs that implement
this in a relatively generic way.

### Startup time
There may be a short gap (2-3m) between the time the instance finishes
provisioning and the time Nix logs start being streamed to the UI. This is
expected, the time is spent applying a minimal bootstrap configuration that
allows the Coder agent to start as the configured non-root user.

This allows logs from nixos-rebuild to be viewed in the UI, as well as allowing
SSH into the instance in case the run of nixos-rebuild fails.

### Debugging
If your NixOS configuration fails to apply for whatever reason, the agent will
still be able to drop you into a shell for your given user. Logs for the
initial configuration are streamed, and viewable in the UI/CLI.

### Username
The agent user is configurable as a workspace parameter, because people can set
arbitrary usernames in their NixOS configuration. The default username is
configured as `denbeigh`, because that's the username I use. To change the
default username, set the `default_agent_user` variable when pushing these
templates.

The username given **must** correspond to a username created in your NixOS
configuration.
