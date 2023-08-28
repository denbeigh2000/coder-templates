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

### Authentication
This currently depends on your desired flake being publicly available, and
requiring no secrets to build.

One could feasibly remove this limitation by granting the created instance an
IAM role that could fetch items from AWS Secret Manager, and adding logic to
the setup script to fetch these secrets and put them in the right place.

I haven't implemented any functionality for this, mostly because it's not
relevant to me, but I would consider accepting PRs that implement this in a
relatively generic way.

### Debugging
It can be difficult to debug your NixOS configuration if something goes wrong,
for the following reasons:

- OS setup is done as root, before the agent is invoked. This is because the
    agent needs to run as a user that's been setup by your NixOS configuration.
    This means that logs from nixos-rebuild will not be streamed back to the
    Coder installation, and and failure to boot will manifest as the agent
    never phoning home. Coder have an
    [API endpoint](https://coder.com/docs/v2/latest/api/agents#patch-workspace-agent-logs)
    that would be feasible to use to post these logs, but I haven't made use of
    this, PRs welcome.
- There are no parameters to set security groups/authorised keypairs for the
    workspace, which means that the instance is inaccessible if the system
    provisioning fails. It would be feasible to add workspace parameters that
    set these, but I haven't done this, again PRs welcome.

### Username
The agent user is configurable as a workspace parameter, because people can set
arbitrary usernames in their NixOS configuration. The default username is
configured as `denbeigh`, because that's the username I use. To change the
default username, set the `default_agent_user` variable when pushing these
templates.
