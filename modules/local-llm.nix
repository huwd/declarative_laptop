{ pkgs, lib, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan; # gfx1150 has no dependable ROCm support; Vulkan is the safe path
    host = "127.0.0.1"; # don't expose ollama's API beyond localhost
    environmentVariables.OLLAMA_IGPU_ENABLE = "1";
  };
  systemd.services.ollama.wantedBy = lib.mkForce [ ];
  boot.kernelParams = [
    "ttm.pages_limit=12582912" # 48 GiB of 4 KiB pages - GPU-usable GTT memory
    "ttm.page_pool_size=12582912" # amdgpu.gttsize is deprecated; both ttm.* params are needed together
  ];
  services.open-webui = {
    enable = true;
    host = "127.0.0.1"; # localhost only - same reasoning as ollama's host binding
  };
  systemd.services.open-webui.wantedBy = lib.mkForce [ ];
  environment.sessionVariables.OPENCODE_CONFIG = toString (
    pkgs.writeText "opencode-local-llm.json" (
      builtins.toJSON {
        provider.ollama = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (local)";
          options.baseURL = "http://127.0.0.1:11434/v1";
          models."qwen3-coder:30b".name = "Qwen3-Coder 30B-A3B";
        };
      }
    )
  );
}
