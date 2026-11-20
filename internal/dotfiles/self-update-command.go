package dotfiles

import (
	"errors"
	"flag"
	"fmt"
	"os/exec"
)

// SelfUpdateCommand runs 'go install github.com/some-programs/dotfiles@latest'
// to update dotfiles to the latest release.
func (d *Dotfiles) SelfUpdateCommand(args []string) error {
	fs := flag.NewFlagSet("self-update", flag.ContinueOnError)
	fs.SetOutput(d.Stderr)
	fs.Usage = func() {
		fmt.Fprintf(d.Stderr, "Usage: dotfiles self-update\n\nUpdate dotfiles by running go install github.com/some-programs/dotfiles@latest\n")
	}
	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}
	cmd := exec.Command("go", "install", "github.com/some-programs/dotfiles@latest")
	cmd.Stdout = d.Stdout
	cmd.Stderr = d.Stderr
	if err := cmd.Run(); err != nil {
		d.fail(fmt.Errorf("self-update: %w", err))
		return err
	}
	return nil
}
