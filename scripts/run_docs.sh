#!/usr/bin/env bash
set -euo pipefail

# Function to check and install homebrew
ensure_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

# Function to setup Ruby environment
setup_ruby() {
    echo "Setting up Ruby environment..."
    brew install ruby

    # Add Homebrew's Ruby to PATH
    if [[ "$(uname -m)" == "arm64" ]]; then
        RUBY_PATH="/opt/homebrew/opt/ruby/bin"
        GEM_PATH="/opt/homebrew/lib/ruby/gems/3.3.0/bin"
    else
        RUBY_PATH="/usr/local/opt/ruby/bin"
        GEM_PATH="/usr/local/lib/ruby/gems/3.3.0/bin"
    fi

    # Add Ruby paths to environment
    export PATH="$RUBY_PATH:$GEM_PATH:$PATH"
}

# Function to clean Jekyll build
clean_docs() {
    echo "Cleaning Jekyll build..."
    rm -rf _site .jekyll-cache .sass-cache
    rm -f Gemfile.lock
    rm -rf vendor/bundle
}

# Function to install dependencies
install_deps() {
    echo "Installing Jekyll dependencies..."
    gem install bundler:2.4.22
    bundle config set --local path 'vendor/bundle'
    bundle install
}

# Function to serve docs
serve_docs() {
    echo "Starting Jekyll server..."
    bundle exec jekyll serve --livereload --incremental --baseurl ''
}

# Main execution
main() {
    # Ensure we're in the docs directory
    cd "$(dirname "$0")/../docs"

    # Process command line arguments
    local CLEAN=0
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                CLEAN=1
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Check for Homebrew and Ruby
    ensure_homebrew

    # Check if we're using system Ruby
    if [[ "$(which ruby)" == "/usr/bin/ruby" ]]; then
        echo "System Ruby detected. Installing Homebrew Ruby..."
        setup_ruby
    fi

    # Verify Ruby and Bundler versions
    echo "Using Ruby $(ruby --version)"

    # Clean if requested
    if [[ $CLEAN -eq 1 ]]; then
        clean_docs
    fi

    # Install dependencies if needed
    if [ ! -f "Gemfile.lock" ] || [ ! -d "vendor/bundle" ]; then
        install_deps
    fi

    # Start the server
    serve_docs
}

# Run main function with all arguments
main "$@"
