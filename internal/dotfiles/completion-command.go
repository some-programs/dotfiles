package dotfiles

import (
	"errors"
	"flag"
	"fmt"
	"strings"

	"github.com/some-programs/dotfiles/internal/completions"
)

// CompletionCommand exports shell completion scripts for shells to load.
func (d *Dotfiles) CompletionCommand(args []string) error {
	fs := flag.NewFlagSet("dotfiles completion", flag.ContinueOnError)
	fs.SetOutput(d.Stderr)
	fs.Usage = func() {
		fmt.Fprintf(d.Stderr, "Usage: dotfiles completion [shell]\n\n")
		fmt.Fprintf(d.Stderr, "Export shell completion code for dotfiles and companion commands.\n\n")
		fmt.Fprintf(d.Stderr, "Supported shells:\n")
		fmt.Fprintf(d.Stderr, "  bash   Bash completion script\n\n")
		fmt.Fprintf(d.Stderr, "Examples:\n")
		fmt.Fprintf(d.Stderr, "  eval \"$(dotfiles completion bash)\"\n")
		fmt.Fprintf(d.Stderr, "  dotfiles completion bash > ~/.config-base/bash/completion.d/dotfiles\n")
	}

	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}

	if fs.NArg() > 1 {
		fs.Usage()
		return fmt.Errorf("unexpected arguments: %s", strings.Join(fs.Args()[1:], " "))
	}

	shell := "bash"
	if fs.NArg() == 1 {
		shell = strings.ToLower(fs.Arg(0))
	}

	switch shell {
	case "bash":
		fmt.Fprint(d.Stdout, completions.Bash)
		return nil
	default:
		fs.Usage()
		return fmt.Errorf("unsupported shell %q (supported: bash)", shell)
	}
}
