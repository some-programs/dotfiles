package completions

import (
	_ "embed"
)

// Bash is the embedded Bash completion script for dotfiles and companion commands.
//
//go:embed bash/dotfiles.bash
var Bash string
