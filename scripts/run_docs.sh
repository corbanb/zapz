#!/bin/bash

set -euo pipefail

# Constants
DOCS_DIR="docs"
JEKYLL_VERSION="4.3.3"
PORT=4000

# Help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Manage local Jekyll development environment for GitHub Pages"
    echo
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -i, --install     Install required dependencies"
    echo "  -s, --serve       Start Jekyll server"
    echo "  -b, --build       Build site locally"
    echo "  -c, --clean       Clean build artifacts"
    echo
    echo "Examples:"
    echo "  $0 --install      # Install dependencies"
    echo "  $0 --serve        # Start local server"
    echo "  $0 --build        # Build site"
}

# Setup Ruby environment
setup_ruby() {
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo "Installing Ruby via Homebrew..."
    brew install ruby

    # Add Homebrew's Ruby to PATH
    if [[ "$(uname -m)" == "arm64" ]]; then
        RUBY_PATH="/opt/homebrew/opt/ruby/bin"
        GEM_PATH="/opt/homebrew/lib/ruby/gems/3.3.0/bin"
    else
        RUBY_PATH="/usr/local/opt/ruby/bin"
        GEM_PATH="/usr/local/lib/ruby/gems/3.3.0/bin"
    fi

    # Add Ruby and Gems paths to environment
    export PATH="$RUBY_PATH:$GEM_PATH:$PATH"

    # Verify Ruby installation
    echo "Ruby version: $(ruby --version)"
    echo "Gem version: $(gem --version)"
    echo "Ruby path: $(which ruby)"
    echo "Gem path: $(which gem)"
}

# Ensure we're using Homebrew Ruby
ensure_ruby_env() {
    # Add Homebrew's Ruby to PATH
    if [[ "$(uname -m)" == "arm64" ]]; then
        RUBY_PATH="/opt/homebrew/opt/ruby/bin"
        GEM_PATH="/opt/homebrew/lib/ruby/gems/3.3.0/bin"
    else
        RUBY_PATH="/usr/local/opt/ruby/bin"
        GEM_PATH="/usr/local/lib/ruby/gems/3.3.0/bin"
    fi

    # Add Ruby and Gems paths to environment
    export PATH="$RUBY_PATH:$GEM_PATH:$PATH"

    # Verify we're using the correct Ruby
    if [[ ! "$(which ruby)" =~ "homebrew" ]]; then
        echo "Error: Not using Homebrew's Ruby. Please run --install first."
        exit 1
    fi
}

# Install dependencies
install_deps() {
    echo "Setting up Ruby environment..."
    setup_ruby

    echo "Installing Bundler..."
    gem install bundler

    echo "Installing Jekyll dependencies..."
    cd "$DOCS_DIR" || exit 1
    bundle config set --local path 'vendor/bundle'
    bundle install
    cd - || exit 1

    echo "Installation complete! You can now run:"
    echo "  $0 --serve    # Start the local server"
}

# Start Jekyll server
serve_site() {
    ensure_ruby_env
    echo "Starting Jekyll server on http://localhost:$PORT"
    cd "$DOCS_DIR" || exit 1
    bundle exec jekyll serve --livereload --port "$PORT" --baseurl ""
}

# Build site
build_site() {
    ensure_ruby_env
    echo "Building site..."
    cd "$DOCS_DIR" || exit 1
    JEKYLL_ENV=production bundle exec jekyll build
    cd - || exit 1
}

# Clean build artifacts
clean_site() {
    echo "Cleaning build artifacts..."
    cd "$DOCS_DIR" || exit 1

    # Remove build artifacts without requiring bundle
    rm -rf _site .sass-cache .jekyll-cache .jekyll-metadata
    rm -rf vendor/bundle .bundle Gemfile.lock

    echo "Cleaned all Jekyll artifacts and dependencies"
    cd - || exit 1
}

# Main logic
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -i|--install)
                install_deps
                shift
                ;;
            -s|--serve)
                serve_site
                shift
                ;;
            -b|--build)
                build_site
                shift
                ;;
            -c|--clean)
                clean_site
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

main "$@"
