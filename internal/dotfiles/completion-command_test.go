package dotfiles

import (
	"bytes"
	"strings"
	"testing"
)

func TestCompletionCommandBash(t *testing.T) {
	t.Parallel()

	for _, tc := range []struct {
		name string
		args []string
	}{
		{name: "default", args: nil},
		{name: "explicit-bash", args: []string{"bash"}},
		{name: "uppercase-bash", args: []string{"BASH"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var stdout, stderr bytes.Buffer
			d := &Dotfiles{Stdout: &stdout, Stderr: &stderr}

			err := d.CompletionCommand(tc.args)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			out := stdout.String()
			if !strings.Contains(out, "complete -F _dotfiles dotfiles") {
				t.Errorf("expected bash completion in output, got %q", out)
			}
			if !strings.Contains(out, "complete -F _pathenv pathenv") {
				t.Errorf("expected pathenv completion in output, got %q", out)
			}
		})
	}
}

func TestCompletionCommandHelp(t *testing.T) {
	t.Parallel()

	var stdout, stderr bytes.Buffer
	d := &Dotfiles{Stdout: &stdout, Stderr: &stderr}

	err := d.CompletionCommand([]string{"-h"})
	if err != nil {
		t.Fatalf("expected nil error on -h, got %v", err)
	}
	if !strings.Contains(stderr.String(), "Usage: dotfiles completion") {
		t.Errorf("expected usage message, got %q", stderr.String())
	}
}

func TestCompletionCommandUnsupported(t *testing.T) {
	t.Parallel()

	var stdout, stderr bytes.Buffer
	d := &Dotfiles{Stdout: &stdout, Stderr: &stderr}

	err := d.CompletionCommand([]string{"unknown-shell"})
	if err == nil {
		t.Fatal("expected error on unsupported shell, got nil")
	}
	if !strings.Contains(err.Error(), "unsupported shell \"unknown-shell\"") {
		t.Errorf("expected unsupported shell error, got %v", err)
	}
}
