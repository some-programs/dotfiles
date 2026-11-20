package dotfiles

import (
	"bytes"
	"strings"
	"testing"
)

func TestSelfUpdateHelp(t *testing.T) {
	t.Parallel()

	var stdout, stderr bytes.Buffer
	d := &Dotfiles{Stdout: &stdout, Stderr: &stderr}

	err := d.SelfUpdateCommand([]string{"-h"})
	if err != nil {
		t.Fatalf("expected nil error on -h, got %v", err)
	}
	if !strings.Contains(stderr.String(), "Usage: dotfiles self-update") {
		t.Errorf("expected usage message, got %q", stderr.String())
	}
}
