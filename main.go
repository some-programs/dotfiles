package main

import (
	"os"

	"dotfiles/base/cmd/dotfiles/internal/dotfiles"
)

func main() {
	os.Exit(dotfiles.Run(os.Args[1:]))
}
