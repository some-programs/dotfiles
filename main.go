package main

import (
	"os"

	"github.com/some-programs/dotfiles/internal/dotfiles"
)

func main() {
	os.Exit(dotfiles.Run(os.Args[1:]))
}
