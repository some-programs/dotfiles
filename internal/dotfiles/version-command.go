package dotfiles

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"runtime/debug"
)

// VersionCommand prints the version of dotfiles, or with -all its full build info.
func (d *Dotfiles) VersionCommand(args []string) error {
	fs := flag.NewFlagSet("version", flag.ContinueOnError)
	fs.SetOutput(d.Stderr)
	all := fs.Bool("all", false, "print the build information of every module and the build settings")
	fs.Usage = func() {
		fmt.Fprintf(d.Stderr, "Usage: dotfiles version [-all]\n\nPrint the version of dotfiles\n\nOptions:\n")
		fs.PrintDefaults()
	}
	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}
	if fs.NArg() > 0 {
		fs.Usage()
		return fmt.Errorf("version takes no arguments")
	}
	bi, _ := debug.ReadBuildInfo() // nil when the binary has none
	printVersion(d.Stdout, bi, *all)
	return nil
}

// printVersion writes the version of the main module in bi, or with all the
// whole of bi. A nil bi means the binary has no build information.
func printVersion(w io.Writer, bi *debug.BuildInfo, all bool) {
	if bi == nil {
		fmt.Fprintln(w, "unknown (no build information)")
		return
	}
	if all {
		fmt.Fprint(w, bi.String())
		return
	}
	v := bi.Main.Version
	if v == "" {
		v = "(devel)"
	}
	fmt.Fprintln(w, v)
}
