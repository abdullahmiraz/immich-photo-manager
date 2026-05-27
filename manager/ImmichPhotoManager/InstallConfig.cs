using System.Text.Json;

namespace ImmichPhotoManager;

/// <summary>Install location written by setup; manager runs docker compose from here.</summary>
static class InstallConfig
{
    private static readonly string ConfigDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "ImmichPhotoManager");

    private static readonly string ConfigFile = Path.Combine(ConfigDir, "install.json");

    public static string? GetInstallPath()
    {
        if (!File.Exists(ConfigFile))
        {
            var dev = FindDevRepoRoot();
            return dev;
        }

        try
        {
            var json = JsonSerializer.Deserialize<InstallJson>(File.ReadAllText(ConfigFile));
            if (!string.IsNullOrWhiteSpace(json?.InstallPath) && Directory.Exists(json.InstallPath))
                return json.InstallPath;
        }
        catch
        {
            // ignore
        }

        return FindDevRepoRoot();
    }

    public static void SaveInstallPath(string path)
    {
        Directory.CreateDirectory(ConfigDir);
        var payload = new InstallJson { InstallPath = path };
        File.WriteAllText(ConfigFile, JsonSerializer.Serialize(payload, new JsonSerializerOptions { WriteIndented = true }));
    }

    /// <summary>When running from repo without installer, use folder containing docker-compose.yml.</summary>
    static string? FindDevRepoRoot()
    {
        var dir = AppContext.BaseDirectory;
        for (var i = 0; i < 6; i++)
        {
            if (File.Exists(Path.Combine(dir, "docker-compose.yml")))
                return dir;
            var parent = Directory.GetParent(dir);
            if (parent == null) break;
            dir = parent.FullName;
        }
        return null;
    }

    sealed class InstallJson
    {
        public string? InstallPath { get; set; }
    }
}
