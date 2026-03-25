package main

import (
	"os"

	"dotfiles/base/internal/dotfiles"
)

func main() {
	os.Exit(dotfiles.Run(os.Args[1:]))
}
