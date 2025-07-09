using Flow.Launcher.Plugin;
using System.Diagnostics;
using System.Text.Json;

namespace Flow.Launcher.Plugin.KubernetesContextSwitcher;

public class Main : IPlugin
{
    private PluginInitContext _context = null!;
    private string _kubectlPath = "kubectl";

    public void Init(PluginInitContext context)
    {
        _context = context;
        
        // Try to find kubectl in PATH or common locations
        var kubectlPaths = new[]
        {
            "kubectl",
            @"C:\Program Files\Docker\Docker\resources\bin\kubectl.exe",
            @"C:\Users\%USERNAME%\AppData\Local\Microsoft\WinGet\Packages\Kubernetes.kubectl_Microsoft.Winget.Source_8wekyb3d8bbwe\kubectl.exe"
        };

        foreach (var path in kubectlPaths)
        {
            if (File.Exists(path) || IsCommandAvailable(path))
            {
                _kubectlPath = path;
                break;
            }
        }
    }

    public List<Result> Query(Query query)
    {
        var results = new List<Result>();
        var searchTerm = query.Search.Trim();

        try
        {
            if (string.IsNullOrEmpty(searchTerm))
            {
                // Show current context and available contexts
                var currentContext = GetCurrentContext();
                var contexts = GetAvailableContexts();

                results.Add(new Result
                {
                    Title = $"Current: {currentContext}",
                    SubTitle = "Current Kubernetes context",
                    IcoPath = "Images/k8s.png",
                    Score = 100
                });

                foreach (var context in contexts.Where(c => c != currentContext))
                {
                    results.Add(new Result
                    {
                        Title = context,
                        SubTitle = $"Switch to {context}",
                        IcoPath = "Images/k8s.png",
                        Score = 90,
                        Action = e =>
                        {
                            SwitchContext(context);
                            _context.API.ShowMsg($"Switched to context: {context}");
                            return true;
                        }
                    });
                }
            }
            else
            {
                // Filter contexts based on search term
                var contexts = GetAvailableContexts()
                    .Where(c => c.Contains(searchTerm, StringComparison.OrdinalIgnoreCase))
                    .ToList();

                var currentContext = GetCurrentContext();

                foreach (var context in contexts)
                {
                    var isCurrent = context == currentContext;
                    results.Add(new Result
                    {
                        Title = context + (isCurrent ? " (current)" : ""),
                        SubTitle = isCurrent ? "Current context" : $"Switch to {context}",
                        IcoPath = "Images/k8s.png",
                        Score = isCurrent ? 80 : 90,
                        Action = isCurrent ? null : e =>
                        {
                            SwitchContext(context);
                            _context.API.ShowMsg($"Switched to context: {context}");
                            return true;
                        }
                    });
                }
            }
        }
        catch (Exception ex)
        {
            results.Add(new Result
            {
                Title = "Error",
                SubTitle = ex.Message,
                IcoPath = "Images/error.png",
                Score = 0
            });
        }

        return results;
    }

    private string GetCurrentContext()
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = _kubectlPath,
            Arguments = "config current-context",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var process = Process.Start(startInfo);
        if (process == null)
            throw new Exception("Failed to start kubectl process");

        var output = process.StandardOutput.ReadToEnd();
        var error = process.StandardError.ReadToEnd();
        process.WaitForExit();

        if (process.ExitCode != 0)
            throw new Exception($"kubectl error: {error}");

        return output.Trim();
    }

    private List<string> GetAvailableContexts()
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = _kubectlPath,
            Arguments = "config get-contexts -o name",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var process = Process.Start(startInfo);
        if (process == null)
            throw new Exception("Failed to start kubectl process");

        var output = process.StandardOutput.ReadToEnd();
        var error = process.StandardError.ReadToEnd();
        process.WaitForExit();

        if (process.ExitCode != 0)
            throw new Exception($"kubectl error: {error}");

        return output.Split('\n', StringSplitOptions.RemoveEmptyEntries)
                    .Select(line => line.Trim())
                    .Where(line => !string.IsNullOrEmpty(line))
                    .ToList();
    }

    private void SwitchContext(string contextName)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = _kubectlPath,
            Arguments = $"config use-context {contextName}",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var process = Process.Start(startInfo);
        if (process == null)
            throw new Exception("Failed to start kubectl process");

        var output = process.StandardOutput.ReadToEnd();
        var error = process.StandardError.ReadToEnd();
        process.WaitForExit();

        if (process.ExitCode != 0)
            throw new Exception($"Failed to switch context: {error}");
    }

    private bool IsCommandAvailable(string command)
    {
        try
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = "where",
                Arguments = command,
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(startInfo);
            if (process == null) return false;

            var output = process.StandardOutput.ReadToEnd();
            process.WaitForExit();

            return process.ExitCode == 0 && !string.IsNullOrEmpty(output.Trim());
        }
        catch
        {
            return false;
        }
    }
} 