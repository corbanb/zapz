---
layout: docs
title: Configuration
icon: fas fa-cog
description: Learn how to customize zapz for your needs
---

<div class="config-intro">
  <div class="config-file">
    <div class="file-header">
      <i class="fas fa-file-code"></i>
      <span>~/.zapzrc.yml</span>
    </div>
    <pre><code class="language-yaml">node:
  versions: ["lts/iron"]
  packages: ["next", "typescript"]

apps:
  - visual-studio-code
  - docker
  - figma</code></pre>
  </div>
</div>

## Configuration Options

<div class="config-sections">
  <div class="config-section">
    <div class="section-header">
      <i class="fab fa-node-js"></i>
      <h3>Node.js</h3>
    </div>
    <div class="section-content">
      <p>Configure Node.js versions and global packages.</p>
      <div class="config-example">
        <pre><code class="language-yaml">node:
  versions:
    - "lts/iron"    # Latest LTS
    - "18.17.0"     # Specific version
  default: "lts/iron"
  packages:         # Global packages
    - "typescript"
    - "prettier"</code></pre>
      </div>
      <div class="config-options">
        <div class="option">
          <code>versions</code>
          <p>List of Node.js versions to install</p>
          <div class="option-meta">
            <span class="tag">required</span>
            <span class="type">string[]</span>
          </div>
        </div>
        <div class="option">
          <code>default</code>
          <p>Default Node.js version to use</p>
          <div class="option-meta">
            <span class="tag">optional</span>
            <span class="type">string</span>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class="config-section">
    <div class="section-header">
      <i class="fas fa-laptop-code"></i>
      <h3>Applications</h3>
    </div>
    <div class="section-content">
      <p>Specify which applications to install automatically.</p>
      <div class="config-example">
        <pre><code class="language-yaml">apps:
  - visual-studio-code
  - docker
  - iterm2
  - arc-browser</code></pre>
      </div>
      <div class="apps-grid">
        <div class="app-card">
          <i class="fas fa-code"></i>
          <span>visual-studio-code</span>
        </div>
        <div class="app-card">
          <i class="fab fa-docker"></i>
          <span>docker</span>
        </div>
        <!-- More app cards -->
      </div>
    </div>
  </div>
</div>

## Advanced Configuration

<div class="tips-section">
  <div class="tip">
    <div class="tip-icon">
      <i class="fas fa-lightbulb"></i>
    </div>
    <div class="tip-content">
      <h4>Using Environment Variables</h4>
      <p>You can use environment variables in your configuration:</p>
      <pre><code class="language-yaml">git:
  user:
    email: "${GIT_EMAIL}"</code></pre>
    </div>
  </div>
</div>
