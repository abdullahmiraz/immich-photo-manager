using System.Diagnostics;

namespace ImmichPhotoManager;

/// <summary>
/// Four tabs — one per companion service (each upstream project stays independent).
/// Immich core stack is controlled from the header (Docker Compose).
/// </summary>
sealed class MainForm : Form
{
    readonly Label _installPathLabel = new() { AutoSize = true, MaximumSize = new Size(700, 0) };
    readonly Label _stackStatusLabel = new() { AutoSize = true, ForeColor = Color.DimGray };
    readonly TabControl _tabs = new() { Dock = DockStyle.Fill };
    readonly Dictionary<string, Label> _serviceStatusLabels = new(StringComparer.OrdinalIgnoreCase);

    string? _installPath;
    System.Windows.Forms.Timer? _refreshTimer;

    public MainForm()
    {
        Text = "Immich Photo Manager";
        MinimumSize = new Size(720, 520);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("Segoe UI", 9.5f);

        var header = BuildHeader();
        BuildTabs();

        var layout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            RowCount = 2,
            ColumnCount = 1,
        };
        layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        layout.Controls.Add(header, 0, 0);
        layout.Controls.Add(_tabs, 0, 1);
        Controls.Add(layout);

        Load += OnLoad;
        FormClosed += (_, _) => _refreshTimer?.Stop();
    }

    Panel BuildHeader()
    {
        var panel = new Panel { Dock = DockStyle.Top, AutoSize = true, Padding = new Padding(12) };

        var title = new Label
        {
            Text = "Immich Photo Manager",
            Font = new Font(Font.FontFamily, 14f, FontStyle.Bold),
            AutoSize = true,
        };

        var subtitle = new Label
        {
            Text = "Unofficial bundle — Immich runs the library; each tab is a separate open-source tool.",
            AutoSize = true,
            ForeColor = Color.DimGray,
            MaximumSize = new Size(680, 0),
        };

        _installPathLabel.Text = "Install path: (not configured)";

        var btnStart = new Button { Text = "Start stack", AutoSize = true };
        var btnStop = new Button { Text = "Stop stack", AutoSize = true };
        var btnUpdate = new Button { Text = "Update images", AutoSize = true };
        var btnImmich = new Button { Text = "Open Immich", AutoSize = true };
        var btnRefresh = new Button { Text = "Refresh status", AutoSize = true };

        btnStart.Click += async (_, _) => await RunStackActionAsync("up -d", "Starting stack…");
        btnStop.Click += async (_, _) => await RunStackActionAsync("stop -t 120", "Stopping stack…");
        btnUpdate.Click += async (_, _) =>
        {
            await RunStackActionAsync("pull", "Pulling images…");
            await RunStackActionAsync("up -d", "Recreating if needed…");
        };
        btnImmich.Click += (_, _) => OpenUrl("http://localhost:2283");
        btnRefresh.Click += async (_, _) => await RefreshStatusAsync();

        var flow = new FlowLayoutPanel
        {
            AutoSize = true,
            FlowDirection = FlowDirection.LeftToRight,
            WrapContents = true,
            Margin = new Padding(0, 8, 0, 0),
        };
        foreach (var b in new[] { btnStart, btnStop, btnUpdate, btnImmich, btnRefresh })
            flow.Controls.Add(b);

        var inner = new FlowLayoutPanel
        {
            Dock = DockStyle.Fill,
            FlowDirection = FlowDirection.TopDown,
            AutoSize = true,
            WrapContents = false,
        };
        inner.Controls.Add(title);
        inner.Controls.Add(subtitle);
        inner.Controls.Add(_installPathLabel);
        inner.Controls.Add(_stackStatusLabel);
        inner.Controls.Add(flow);
        panel.Controls.Add(inner);
        return panel;
    }

    void BuildTabs()
    {
        _tabs.TabPages.Clear();

        _tabs.TabPages.Add(CreateServiceTab(
            "Deduper",
            "immich-deduper",
            "Visual duplicate review for your Immich library.",
            "https://github.com/RazgrizHsu/immich-deduper",
            "immich_deduper",
            "http://localhost:8086",
            null));

        _tabs.TabPages.Add(CreateServiceTab(
            "Upload optimizer",
            "immich-upload-optimizer (patched)",
            "Caesium compression on images before Immich stores them; videos passthrough.",
            "https://github.com/miguelangel-nubla/immich-upload-optimizer",
            "immich_upload_optimizer",
            "http://localhost:2283",
            null));

        _tabs.TabPages.Add(CreateImmichGoTab());

        _tabs.TabPages.Add(CreateHandBrakeTab());
    }

    TabPage CreateServiceTab(
        string tabTitle,
        string productName,
        string description,
        string upstreamUrl,
        string containerName,
        string localUrl,
        Action<TabPage>? extraActions)
    {
        var page = new TabPage(tabTitle) { Padding = new Padding(12) };

        var statusLabel = new Label { AutoSize = true, Font = new Font(Font, FontStyle.Bold) };
        _serviceStatusLabels[containerName] = statusLabel;

        var desc = new Label
        {
            Text = description,
            AutoSize = true,
            MaximumSize = new Size(640, 0),
        };

        var upstream = new LinkLabel
        {
            Text = $"Independent project: {productName}",
            AutoSize = true,
            LinkColor = Color.SteelBlue,
        };
        upstream.LinkClicked += (_, _) => OpenUrl(upstreamUrl);

        var btnOpen = new Button { Text = "Open in browser", AutoSize = true };
        btnOpen.Click += (_, _) => OpenUrl(localUrl);

        var btnLogs = new Button { Text = "View Docker logs", AutoSize = true, Tag = containerName };
        btnLogs.Click += async (_, _) => await ShowLogsAsync((string)btnLogs.Tag!);

        var flow = new FlowLayoutPanel
        {
            Dock = DockStyle.Fill,
            FlowDirection = FlowDirection.TopDown,
            AutoSize = true,
            WrapContents = false,
        };
        flow.Controls.Add(statusLabel);
        flow.Controls.Add(desc);
        flow.Controls.Add(upstream);
        flow.Controls.Add(new Label { Height = 8 });
        var actions = new FlowLayoutPanel { AutoSize = true };
        actions.Controls.Add(btnOpen);
        actions.Controls.Add(btnLogs);
        flow.Controls.Add(actions);
        extraActions?.Invoke(page);
        page.Controls.Add(flow);
        return page;
    }

    TabPage CreateImmichGoTab()
    {
        var page = new TabPage("immich-go") { Padding = new Padding(12) };

        var desc = new Label
        {
            Text = "Bulk import from disk (Google Takeout, folders). AGPL-3.0 — not part of Immich.",
            AutoSize = true,
            MaximumSize = new Size(640, 0),
        };

        var upstream = new LinkLabel
        {
            Text = "Independent project: simulot/immich-go",
            AutoSize = true,
        };
        upstream.LinkClicked += (_, _) => OpenUrl("https://github.com/simulot/immich-go");

        var pathLabel = new Label { AutoSize = true };

        var btnFolder = new Button { Text = "Open tools folder", AutoSize = true };
        btnFolder.Click += (_, _) => OpenFolder(Path.Combine(_installPath ?? "", "tools", "immich-go"));

        var btnHelp = new Button { Text = "Open import help (PowerShell)", AutoSize = true };
        btnHelp.Click += (_, _) =>
        {
            var exe = Path.Combine(_installPath ?? "", "tools", "immich-go", "immich-go.exe");
            var script = $@"
Write-Host 'immich-go bulk import' -ForegroundColor Cyan
Write-Host 'Create an API key in Immich -> Account Settings -> API Keys'
Write-Host ''
if (Test-Path '{exe.Replace("'", "''")}') {{
  & '{exe.Replace("'", "''")}' --help
}} else {{
  Write-Host 'immich-go.exe not found. Run the installer or see tools\immich-go\README.md' -ForegroundColor Yellow
}}
Write-Host ''
Read-Host 'Press Enter to close'
";
            RunPowerShell(script);
        };

        page.Controls.Add(new FlowLayoutPanel
        {
            Dock = DockStyle.Fill,
            FlowDirection = FlowDirection.TopDown,
            Controls =
            {
                desc, upstream, pathLabel, btnFolder, btnHelp,
            },
        });

        page.Tag = pathLabel;
        return page;
    }

    TabPage CreateHandBrakeTab()
    {
        var page = new TabPage("Video cleanup") { Padding = new Padding(12) };

        var desc = new Label
        {
            Text = "Optional pre-import transcode (HandBrake CLI). GPLv2 — install CLI yourself; not bundled.",
            AutoSize = true,
            MaximumSize = new Size(640, 0),
        };

        var upstream = new LinkLabel { Text = "HandBrake (official downloads)", AutoSize = true };
        upstream.LinkClicked += (_, _) => OpenUrl("https://handbrake.fr/downloads.php");

        var btnFolder = new Button { Text = "Open video-cleanup folder", AutoSize = true };
        btnFolder.Click += (_, _) => OpenFolder(Path.Combine(_installPath ?? "", "tools", "video-cleanup"));

        var btnRun = new Button { Text = "Run optimize.ps1", AutoSize = true };
        btnRun.Click += (_, _) =>
        {
            var ps1 = Path.Combine(_installPath ?? "", "tools", "video-cleanup", "optimize.ps1");
            if (!File.Exists(ps1))
            {
                MessageBox.Show(this, "optimize.ps1 not found.", Text, MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }
            RunPowerShell($"-NoExit -File \"{ps1}\"");
        };

        var btnHb = new Button { Text = "HandBrake CLI setup help", AutoSize = true };
        btnHb.Click += (_, _) =>
        {
            var readme = Path.Combine(_installPath ?? "", "tools", "video-cleanup", "README.md");
            if (File.Exists(readme))
                Process.Start(new ProcessStartInfo(readme) { UseShellExecute = true });
            else
                OpenUrl("https://handbrake.fr/downloads.php");
        };

        page.Controls.Add(new FlowLayoutPanel
        {
            Dock = DockStyle.Fill,
            FlowDirection = FlowDirection.TopDown,
            Controls = { desc, upstream, btnFolder, btnRun, btnHb },
        });
        return page;
    }

    async void OnLoad(object? sender, EventArgs e)
    {
        _installPath = InstallConfig.GetInstallPath();
        _installPathLabel.Text = _installPath == null
            ? "Install path: not found — run setup or place docker-compose.yml in a parent folder."
            : $"Install path: {_installPath}";

        await RefreshStatusAsync();

        _refreshTimer = new System.Windows.Forms.Timer { Interval = 30_000 };
        _refreshTimer.Tick += async (_, _) => await RefreshStatusAsync();
        _refreshTimer.Start();
    }

    async Task RefreshStatusAsync()
    {
        if (string.IsNullOrEmpty(_installPath))
        {
            _stackStatusLabel.Text = "Stack: install path missing";
            return;
        }

        var containers = await StackService.GetContainerStatusAsync(_installPath);
        var server = StackService.StatusFor(containers, "immich_server");
        var optimizer = StackService.StatusFor(containers, "immich_upload_optimizer");
        _stackStatusLabel.Text = $"Immich server: {server}  |  Upload optimizer: {optimizer}";

        SetServiceStatus("immich_deduper", StackService.StatusFor(containers, "immich_deduper"));
        SetServiceStatus("immich_upload_optimizer", StackService.StatusFor(containers, "immich_upload_optimizer"));

        if (_tabs.TabPages.Count > 2 && _tabs.TabPages[2].Tag is Label goLabel)
        {
            var exe = Path.Combine(_installPath, "tools", "immich-go", "immich-go.exe");
            goLabel.Text = File.Exists(exe) ? $"Local binary: {exe}" : "immich-go.exe not installed — run setup or see README.";
        }
    }

    void SetServiceStatus(string container, string status)
    {
        if (_serviceStatusLabels.TryGetValue(container, out var lbl))
            lbl.Text = $"Docker status: {status}";
    }

    async Task RunStackActionAsync(string args, string busyMessage)
    {
        if (string.IsNullOrEmpty(_installPath))
        {
            MessageBox.Show(this, "Install path not configured.", Text, MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        UseWaitCursor = true;
        _stackStatusLabel.Text = busyMessage;
        try
        {
            var (ok, output) = await StackService.RunComposeAsync(_installPath, args);
            if (!ok)
                MessageBox.Show(this, output, "Docker compose", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            await RefreshStatusAsync();
        }
        finally
        {
            UseWaitCursor = false;
        }
    }

    async Task ShowLogsAsync(string container)
    {
        if (string.IsNullOrEmpty(_installPath)) return;
        var psi = new ProcessStartInfo
        {
            FileName = "docker",
            Arguments = $"logs -f --tail 100 {container}",
            UseShellExecute = true,
        };
        try
        {
            Process.Start(psi);
        }
        catch (Exception ex)
        {
            MessageBox.Show(this, ex.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        await Task.CompletedTask;
    }

    static void OpenUrl(string url) =>
        Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });

    static void OpenFolder(string path)
    {
        if (!Directory.Exists(path))
        {
            MessageBox.Show($"Folder not found:\n{path}", "Immich Photo Manager", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        Process.Start(new ProcessStartInfo(path) { UseShellExecute = true });
    }

    static void RunPowerShell(string commandOrFile)
    {
        var args = commandOrFile.TrimStart().StartsWith("-", StringComparison.Ordinal)
            ? commandOrFile
            : $"-NoExit -Command \"{commandOrFile.Replace("\"", "\\\"")}\"";
        Process.Start(new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = args,
            UseShellExecute = true,
        });
    }
}
