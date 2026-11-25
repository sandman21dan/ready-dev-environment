package main

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"

	"github.com/spf13/cobra"
)

const (
	noDescription = "No description available."
	// descriptionSidecarExt names an optional "<file>.desc" next to a script or binary. It is the only way to
	// describe a compiled binary, and it takes priority over an @description comment.
	descriptionSidecarExt = ".desc"
)

var rootCmd = &cobra.Command{
	Use:   "my-scripts",
	Short: "A CLI wrapper for your custom scripts.",
	Long:  `A command-line interface to easily run and manage your scripts located in ~/.local/scripts.`,
}

func main() {
	if err := addScriptSubCommands(rootCmd); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	if err := rootCmd.Execute(); err != nil {
		// A script that ran and failed: pass its exit status through so && chains and pipelines behave as if the
		// script had been run directly. Script commands silence cobra's own output, so nothing extra is printed.
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			os.Exit(exitCode(exitErr))
		}
		os.Exit(1)
	}
}

// exitCode returns the status a shell would report for the finished process: its exit status, or 128+signal when it
// was killed by a signal (ExitCode() alone returns -1 in that case).
func exitCode(err *exec.ExitError) int {
	if status, ok := err.Sys().(syscall.WaitStatus); ok && status.Signaled() {
		return 128 + int(status.Signal())
	}
	return err.ExitCode()
}

func addScriptSubCommands(root *cobra.Command) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get user home directory: %w", err)
	}
	scriptsDir := filepath.Join(homeDir, ".local", "scripts")

	if _, err := os.Stat(scriptsDir); os.IsNotExist(err) {
		root.Long = root.Long + "\n\nWarning: Script directory not found at " + scriptsDir
		return nil
	}

	files, err := os.ReadDir(scriptsDir)
	if err != nil {
		return fmt.Errorf("failed to read scripts directory: %w", err)
	}

	for _, file := range files {
		fileName := file.Name()
		scriptPath := filepath.Join(scriptsDir, fileName)

		if file.IsDir() {
			continue
		}

		info, err := file.Info()
		if err != nil {
			continue
		}

		isExecutable := info.Mode()&0111 != 0
		isShell := strings.HasSuffix(fileName, ".sh")
		isPython := strings.HasSuffix(fileName, ".py")
		isNode := strings.HasSuffix(fileName, ".js")

		if isShell || isPython || isNode || isExecutable {
			commandName := fileName
			if isShell || isPython || isNode {
				commandName = strings.TrimSuffix(fileName, filepath.Ext(fileName))
			}

			description, _ := getScriptDescription(scriptPath)

			scriptCmd := &cobra.Command{
				Use:                commandName,
				Short:              description,
				RunE:               createRunE(scriptPath, fileName),
				DisableFlagParsing: true,
				// The script owns its own usage and error output. Without these, cobra appends "Error: exit status N"
				// and its own usage block after every non-zero exit.
				SilenceUsage:  true,
				SilenceErrors: true,
			}
			root.AddCommand(scriptCmd)
		}
	}
	return nil
}

func createRunE(scriptPath, fileName string) func(cmd *cobra.Command, args []string) error {
	return func(cmd *cobra.Command, args []string) error {
		var command *exec.Cmd
		if strings.HasSuffix(fileName, ".py") {
			command = exec.Command("python", append([]string{scriptPath}, args...)...)
		} else if strings.HasSuffix(fileName, ".js") {
			command = exec.Command("node", append([]string{scriptPath}, args...)...)
		} else { // .sh or binary
			command = exec.Command(scriptPath, args...)
		}

		command.Stdin = os.Stdin
		command.Stdout = os.Stdout
		command.Stderr = os.Stderr

		err := command.Run()

		// An exit status is the script's own result and is reported by main. Anything else means it never ran
		// (not found, exec format error, permission denied), and nothing else would explain that to the user.
		var exitErr *exec.ExitError
		if err != nil && !errors.As(err, &exitErr) {
			fmt.Fprintf(os.Stderr, "my-scripts: could not run %s: %v\n", fileName, err)
		}
		return err
	}
}

// getScriptDescription returns the one-line description shown in --help: a "<file>.desc" sidecar if present,
// otherwise an @description comment in a text file. Compiled binaries are never scanned.
func getScriptDescription(filePath string) (string, error) {
	if desc, ok := readSidecarDescription(filePath); ok {
		return desc, nil
	}

	file, err := os.Open(filePath)
	if err != nil {
		return noDescription, err
	}
	defer file.Close()

	if looksBinary(file) {
		return noDescription, nil
	}
	return scanForDescription(file)
}

// readSidecarDescription returns the first non-empty line of "<filePath>.desc".
func readSidecarDescription(filePath string) (string, bool) {
	data, err := os.ReadFile(filePath + descriptionSidecarExt)
	if err != nil {
		return "", false
	}
	for _, line := range strings.Split(string(data), "\n") {
		if line = strings.TrimSpace(line); line != "" {
			return line, true
		}
	}
	return "", false
}

// looksBinary applies git's heuristic (a NUL byte in the first 8000 bytes) and rewinds the file afterwards.
func looksBinary(file *os.File) bool {
	buf := make([]byte, 8000)
	n, _ := file.Read(buf)
	_, _ = file.Seek(0, io.SeekStart)
	return bytes.IndexByte(buf[:n], 0) >= 0
}

func scanForDescription(file *os.File) (string, error) {
	scanner := bufio.NewScanner(file)
	// The default 64KB token limit makes a long line (minified JS, for example) abort the scan.
	scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// Handle shell/python comments for @description
		if strings.HasPrefix(line, "#") {
			trimmedLine := strings.TrimSpace(strings.TrimPrefix(line, "#"))
			if strings.HasPrefix(trimmedLine, "@description:") {
				return strings.TrimSpace(strings.TrimPrefix(trimmedLine, "@description:")), nil
			}
		}

		// Handle JavaScript single-line comments for @description
		if strings.HasPrefix(line, "//") {
			trimmedLine := strings.TrimSpace(strings.TrimPrefix(line, "//"))
			if strings.HasPrefix(trimmedLine, "@description:") {
				return strings.TrimSpace(strings.TrimPrefix(trimmedLine, "@description:")), nil
			}
		}

		// Handle Python docstrings and JavaScript block comments for @description (simplified)
		// This is a basic check. A more robust solution would track multiline comments.
		if (strings.HasPrefix(line, `"""`) && strings.Contains(line, "@description:")) ||
			(strings.HasPrefix(line, `'''`) && strings.Contains(line, "@description:")) ||
			(strings.HasPrefix(line, `/*`) && strings.Contains(line, "@description:")) {
			// Extract from within the comment/docstring
			start := strings.Index(line, "@description:")
			if start != -1 {
				desc := line[start+len("@description:"):]
				// Trim trailing comment markers if present on the same line
				desc = strings.TrimSuffix(desc, `"""`)
				desc = strings.TrimSuffix(desc, `'''`)
				desc = strings.TrimSuffix(desc, `*/`)
				return strings.TrimSpace(desc), nil
			}
		}
	}

	// Whatever went wrong while scanning, --help should still read cleanly, so fall back to the default text.
	return noDescription, scanner.Err()
}
