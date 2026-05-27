using System.Diagnostics;

namespace ImmichPhotoManager;

static class StackService
{
    public static async Task<(bool ok, string output)> RunComposeAsync(string installPath, string args, CancellationToken ct = default)
    {
        var psi = new ProcessStartInfo
        {
            FileName = "docker",
            Arguments = $"compose {args}",
            WorkingDirectory = installPath,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        };
        using var proc = Process.Start(psi);
        if (proc == null)
            return (false, "Could not start docker.");

        var stdout = await proc.StandardOutput.ReadToEndAsync(ct);
        var stderr = await proc.StandardError.ReadToEndAsync(ct);
        await proc.WaitForExitAsync(ct);
        var combined = string.IsNullOrWhiteSpace(stderr) ? stdout : $"{stdout}\n{stderr}";
        return (proc.ExitCode == 0, combined.Trim());
    }

    public static async Task<Dictionary<string, string>> GetContainerStatusAsync(string installPath, CancellationToken ct = default)
    {
        var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        var (ok, output) = await RunComposeAsync(installPath, "ps --format \"{{.Names}}\t{{.Status}}\"", ct);
        if (!ok) return map;

        foreach (var line in output.Split('\n', StringSplitOptions.RemoveEmptyEntries))
        {
            var parts = line.Split('\t', 2);
            if (parts.Length == 2)
                map[parts[0].Trim()] = parts[1].Trim();
        }
        return map;
    }

    public static string StatusFor(Dictionary<string, string> containers, string name) =>
        containers.TryGetValue(name, out var s) ? s : "not running";
}
