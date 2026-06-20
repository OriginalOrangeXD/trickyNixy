{ config, lib, pkgs, ... }:

let
  cfg = config.services.llama-cpp-vlm;
in {
  options.services.llama-cpp-vlm = {
    enable = lib.mkEnableOption "Second llama.cpp instance for VLM serving (Qwen3-VL).";

    package = lib.mkOption {
      type    = lib.types.package;
      default = pkgs.llama-cpp.override { cudaSupport = true; };
      description = "llama.cpp package with CUDA support, used to serve the VLM on the GPU.";
    };

    model = lib.mkOption {
      type    = lib.types.str;
      default = "/var/lib/llama/models/Qwen3VL-8B-Instruct-Q4_K_M.gguf";
      description = ''
        Absolute path to the VLM GGUF on the host. Filename matches the
        upstream Qwen-published GGUF at
        huggingface.co/Qwen/Qwen3-VL-8B-Instruct-GGUF — note the upstream
        uses "Qwen3VL" (no hyphen) and capitalized quant tags.
      '';
    };

    mmproj = lib.mkOption {
      type    = lib.types.str;
      default = "/var/lib/llama/models/mmproj-Qwen3VL-8B-Instruct-F16.gguf";
      description = ''
        Absolute path to the multimodal projector (mmproj) GGUF on the host.
        Required for VLM inference in llama.cpp — the vision tower lives in
        a separate file from the language model. Filename matches upstream.
      '';
    };

    host = lib.mkOption {
      type    = lib.types.str;
      default = "0.0.0.0";
      description = "Bind address. 0.0.0.0 = reachable from HA on the LAN.";
    };

    port = lib.mkOption {
      type    = lib.types.port;
      default = 8001;
      description = "HTTP port for the OpenAI-compatible /v1 endpoint.";
    };

    openFirewall = lib.mkOption {
      type    = lib.types.bool;
      default = true;
      description = "Open the configured port in the host firewall.";
    };

    user = lib.mkOption {
      type    = lib.types.str;
      default = "robby";
      description = "User the service runs as. Mirrors the kappa llama.cpp service.";
    };

    group = lib.mkOption {
      type    = lib.types.str;
      default = "users";
      description = "Group the service runs as.";
    };

    extraFlags = lib.mkOption {
      type    = lib.types.listOf lib.types.str;
      default = [
        "-ngl" "999"              # full GPU offload — Shape 4: VLM owns the 3080 Ti
        "-c" "32768"              # 32K context, fits comfortably in 12 GB for Qwen3-VL 8B
        "--cache-type-k" "q8_0"
        "--cache-type-v" "q8_0"
        "--flash-attn" "on"
        "-np" "1"                 # single parallel slot — VLM serving is request-at-a-time
        "--jinja"                 # use embedded chat template
      ];
      description = "Flags passed to llama-server after the host/port/model/mmproj basics.";
    };
  };

  config = lib.mkIf cfg.enable {

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;

    # Model directory is created by configuration.nix tmpfiles rule.
    # GGUF download is manual (mirrors kappa's setup); document in README.

    systemd.services.llama-cpp-vlm = {
      description = "llama.cpp VLM server (Qwen3-VL on :${toString cfg.port})";
      after       = [ "network-online.target" ];
      wants       = [ "network-online.target" ];
      wantedBy    = [ "multi-user.target" ];

      serviceConfig = {
        Type       = "simple";
        User       = cfg.user;
        Group      = cfg.group;
        ExecStart  = lib.concatStringsSep " " ([
          "${cfg.package}/bin/llama-server"
          "--model"  cfg.model
          "--mmproj" cfg.mmproj
          "--host"   cfg.host
          "--port"   (toString cfg.port)
        ] ++ cfg.extraFlags);
        Restart    = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
