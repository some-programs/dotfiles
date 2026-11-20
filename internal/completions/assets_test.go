package completions_test

import (
	"strings"
	"testing"

	"github.com/some-programs/dotfiles/internal/completions"
)

func TestBashCompletionAsset(t *testing.T) {
	if completions.Bash == "" {
		t.Fatal("embedded Bash completion script is empty")
	}
	for _, expected := range []string{
		"complete -F _dotfiles dotfiles",
		"complete -F _pathenv pathenv",
		"_dotfiles()",
		"__dotfiles_pathenv()",
		"__dotfiles_repos()",
		"__dotfiles_theme_variants()",
	} {
		if !strings.Contains(completions.Bash, expected) {
			t.Errorf("embedded Bash completion missing %q", expected)
		}
	}
}
