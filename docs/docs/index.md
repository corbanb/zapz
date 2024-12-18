---
layout: docs
title: Documentation
icon: fas fa-book
description: Everything you need to know about setting up your development environment
---

<div class="docs-header">
  <div class="docs-intro">
    <div class="icon-wrap">
      <i class="fas fa-graduation-cap"></i>
    </div>
    <div class="content">
      <h1>Documentation</h1>
      <p>Learn how to set up, configure, and customize your development environment.</p>
    </div>
  </div>
</div>

## Getting Started

<div class="quick-start-grid">
  <div class="quick-start-card">
    <div class="card-header">
      <div class="card-icon">
        <i class="fas fa-bolt"></i>
      </div>
      <div class="card-meta">
        <span class="tag">Quick Start</span>
        <span class="time">2 min</span>
      </div>
    </div>
    <h3>Installation</h3>
    <p>Get up and running with a single command.</p>
    <div class="code-preview">
      <pre><code class="language-bash">curl -fsSL https://zapz.dev/install | bash</code></pre>
    </div>
    <div class="card-actions">
      <a href="/docs/installation" class="btn-primary">Installation Guide</a>
      <button class="btn-secondary copy-btn">Copy Command</button>
    </div>
  </div>

  <div class="quick-start-card">
    <div class="card-header">
      <div class="card-icon">
        <i class="fas fa-code"></i>
      </div>
      <div class="card-meta">
        <span class="tag">Basic Config</span>
        <span class="time">5 min</span>
      </div>
    </div>
    <h3>Configuration</h3>
    <p>Customize your setup with a simple YAML file.</p>
    <div class="code-preview">
      <pre><code class="language-yaml">node:
  versions: ["lts/iron"]
  packages: ["next", "typescript"]

apps:
  - visual-studio-code
  - docker</code></pre>
    </div>
    <div class="card-actions">
      <a href="/docs/configuration" class="btn-primary">Configuration Guide</a>
      <button class="btn-secondary copy-btn">Copy Example</button>
    </div>
  </div>
</div>

## Core Concepts

<div class="concepts-grid">
  <div class="concept-card">
    <div class="concept-icon">
      <i class="fas fa-layer-group"></i>
    </div>
    <h3>Environment as Code</h3>
    <p>Define your entire development environment in a single configuration file.</p>
    <ul class="concept-features">
      <li>Version controlled setup</li>
      <li>Reproducible environments</li>
      <li>Team sharing</li>
    </ul>
    <a href="/docs/concepts/environment" class="learn-more">
      Learn more <i class="fas fa-arrow-right"></i>
    </a>
  </div>

  <div class="concept-card">
    <div class="concept-icon">
      <i class="fas fa-box-open"></i>
    </div>
    <h3>Smart Defaults</h3>
    <p>Best-practice configurations included out of the box.</p>
    <ul class="concept-features">
      <li>ESLint & Prettier setup</li>
      <li>Git configuration</li>
      <li>VS Code settings</li>
    </ul>
    <a href="/docs/concepts/defaults" class="learn-more">
      Learn more <i class="fas fa-arrow-right"></i>
    </a>
  </div>

  <div class="concept-card">
    <div class="concept-icon">
      <i class="fas fa-puzzle-piece"></i>
    </div>
    <h3>Modular Design</h3>
    <p>Install only what you need, when you need it.</p>
    <ul class="concept-features">
      <li>Minimal base install</li>
      <li>On-demand packages</li>
      <li>Custom extensions</li>
    </ul>
    <a href="/docs/concepts/modularity" class="learn-more">
      Learn more <i class="fas fa-arrow-right"></i>
    </a>
  </div>
</div>

## Popular Topics

<div class="topics-grid">
  <a href="/docs/guides/node" class="topic-card">
    <div class="topic-header">
      <i class="fab fa-node-js"></i>
      <span class="tag">Popular</span>
    </div>
    <h4>Node.js Setup</h4>
    <p>Configure Node.js versions, packages, and tools.</p>
    <ul class="topic-features">
      <li>Version management with nvm</li>
      <li>Global package configuration</li>
      <li>TypeScript setup</li>
    </ul>
  </a>

  <a href="/docs/guides/docker" class="topic-card">
    <div class="topic-header">
      <i class="fab fa-docker"></i>
      <span class="tag">DevOps</span>
    </div>
    <h4>Docker Setup</h4>
    <p>Configure Docker and container workflows.</p>
    <ul class="topic-features">
      <li>Docker Desktop installation</li>
      <li>Development containers</li>
      <li>Compose configuration</li>
    </ul>
  </a>

  <a href="/docs/guides/vscode" class="topic-card">
    <div class="topic-header">
      <i class="fas fa-code"></i>
      <span class="tag">Editor</span>
    </div>
    <h4>VS Code Setup</h4>
    <p>Configure your development environment.</p>
    <ul class="topic-features">
      <li>Extension management</li>
      <li>Workspace settings</li>
      <li>Debugging configurations</li>
    </ul>
  </a>
</div>

## Command Reference

<div class="command-section">
  <div class="command-group">
    <h3>Basic Commands</h3>
    <div class="command-list">
      <div class="command-item">
        <code>zapz init</code>
        <p>Initialize a new configuration file</p>
        <div class="command-tags">
          <span class="tag">setup</span>
        </div>
      </div>
      <div class="command-item">
        <code>zapz setup</code>
        <p>Install and configure your environment</p>
        <div class="command-tags">
          <span class="tag">setup</span>
          <span class="tag">install</span>
        </div>
      </div>
      <div class="command-item">
        <code>zapz update</code>
        <p>Update zapz to the latest version</p>
        <div class="command-tags">
          <span class="tag">system</span>
        </div>
      </div>
    </div>
  </div>
</div>
