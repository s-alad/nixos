{ ... }:

# XDG tool-home relocations that must reach GUI apps (PAM session-wide —
# home.sessionVariables is shell-only). absolute paths: pam_env doesn't expand.
{
  environment.sessionVariables = {
    GOPATH                      = "/home/salad/.local/share/go";
    NPM_CONFIG_CACHE            = "/home/salad/.cache/npm";
    ANDROID_USER_HOME           = "/home/salad/.local/share/android";
    ANDROID_HOME                = "/home/salad/Android/Sdk";
    ANDROID_SDK_ROOT            = "/home/salad/Android/Sdk";
    DOTNET_CLI_HOME             = "/home/salad/.local/share/dotnet";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    __GL_SHADER_DISK_CACHE_PATH = "/home/salad/.cache/nv";
    CUDA_CACHE_PATH             = "/home/salad/.cache/nv/ComputeCache"; # ~/.nv
    XCOMPOSECACHE               = "/home/salad/.cache/X11/xcompose";    # ~/.compose-cache
  };
}
