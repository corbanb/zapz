---
layout: docs
title: Configuration
icon: fas fa-cog
description: Learn how to customize zapz for your needs
---

## Configuration File

<div class="bg-dark-lighter rounded-xl p-8 mb-12">
  <h3 class="text-xl font-semibold text-white mb-4">Default Location</h3>
  <div class="bg-dark rounded-lg p-4">
    <code class="text-gray-300">~/.zapzrc.yml</code>
  </div>
</div>

## Available Options

<div class="tools-grid">
  <div class="feature-card">
    <div class="feature-icon">
      <i class="fab fa-node-js text-2xl text-secondary"></i>
    </div>
    <h3 class="text-xl font-semibold text-white mb-2">Node.js</h3>
    <p class="text-gray-400">Configure Node.js versions and global packages.</p>
    ```yaml
    node:
      versions: ["lts/iron"]
      packages: ["next", "typescript"]
    ```
  </div>

  <div class="feature-card">
    <div class="feature-icon">
      <i class="fab fa-git-alt text-2xl text-secondary"></i>
    </div>
    <h3 class="text-xl font-semibold text-white mb-2">Git</h3>
    <p class="text-gray-400">Set up your Git configuration and SSH keys.</p>
    ```yaml
    git:
      user:
        name: "Your Name"
        email: "your.email@example.com"
    ```
  </div>
</div>
