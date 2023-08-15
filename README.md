# Nix to end Nix

The goal of this project is to have a single flake that can build both my desktop and laptop FROM SCRATCH.

## Description

Overall this flake is just epic. I can now wipe my laptop infinite times and through nix know how to build my exact setup up again. This includes vim themes and binds, oh-my-zsh and wallpapers(SOON). Things are not fully pure(But it runs without the --impure flag) in this repo yet and there are a few things that need to be optimized. But this is a stable local minima that I can comfortably transefer dev setup from desktop to laptop.

## Getting Started

### Dependencies

Nix :)

### Installing

#### Laptop
```nixos-rebuild switch --flake .#ruxyLap```

#### Desktop
```nixos-rebuild switch --flake .#ruxyDesk```

## Authors

Me [@OriginalOrangeXD](https://github.com/OriginalOrangeXD)

Big thanks to [@ALT-F4-LLC](https://github.com/ALT-F4-LLC/dotfiles-nixos)

