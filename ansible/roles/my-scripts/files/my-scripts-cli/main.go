package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
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
		os.Exit(1)
	}
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

		return command.Run()
	}
}

func getScriptDescription(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "No description available.", err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
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

	if err := scanner.Err(); err != nil {
		return "Error reading file for description.", err
	}

	return "No description available.", nil
}
