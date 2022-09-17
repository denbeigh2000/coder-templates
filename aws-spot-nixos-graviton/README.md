---
name: NixOS (Spot instance)
description: Manage a NixOS development workspace on EC2 with Spot Instances.
tags: [cloud, aws, nix, nixos, flakes, arm]
---

# aws-nixos

A simple template that allows you to use a NixOS flake to configure your Coder
workspace.

See [here](https://nixos.wiki/wiki/Flakes#Using_nix_flakes_with_NixOS) for more
information about distributing a NixOS configuration via a flake.

## Some notes before using this yourself

### Authentication
This currently depends on your desired flake being publicly available at the
given URI, I use GitHub to distribute mine (e.g., `github:user/repo#hostname`)

The sane thing here would probably be to fetch and use an SSH key
from KMS at runtime, but I haven't done that - PRs welcome.

### Agent user
The user that runs the agent is hardcoded to `denbeigh` in my startup script
instead of using the attribute from the `coder_agent` terraform resource. This
is because flakes can't take inputs (they're purely evaluated).

You may wish to work around this by:
 - Generating configurations for a configured set of users and encoding them in
     flake names
 - Baking a generic user (such as `dev`) into your flakes
 - Exposing this as a variable the user can enter at configuration time (though
     it would have to match the one they've configured in their flake)

### Root disk size
Mine is fixed 30GB, because I rarely keep the setup around for very long.


## Extra
Thanks
[bpmct](https://github.com/bpmct/coder-templates/blob/c604ef42dc7fca433c6a59cd55a4649a28c929ba/aws-spot/main.tf)
for the spot instance pointers.
