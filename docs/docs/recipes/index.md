---
layout: docs
title: Recipe Collection
icon: fas fa-book-open
description: Ready-to-use configurations for common development scenarios
---

<div class="recipes-header">
  <div class="recipes-intro">
    <div class="icon-wrap">
      <i class="fas fa-wand-sparkles"></i>
    </div>
    <div class="content">
      <h1>Configuration Recipes</h1>
      <p>Production-ready configurations for popular development setups.</p>
    </div>
  </div>
</div>

## Popular Recipes

<div class="recipes-grid">
  <a href="{{ site.baseurl }}/docs/recipes/node" class="recipe-card">
    <div class="recipe-header">
      <div class="recipe-icon">
        <i class="fab fa-node-js"></i>
      </div>
      <div class="recipe-meta">
        <span class="tag">Popular</span>
        <span class="time">5 min setup</span>
      </div>
    </div>
    <h3>Node.js Development</h3>
    <p>Complete Node.js environment with TypeScript, ESLint, and testing tools.</p>
    <div class="recipe-preview">
      <pre><code class="language-yaml">node:
  versions: ["lts/iron"]
  packages: ["typescript", "jest"]</code></pre>
    </div>
    <div class="recipe-footer">
      <span class="learn-more">View Recipe <i class="fas fa-arrow-right"></i></span>
    </div>
  </a>

  <a href="{{ site.baseurl }}/docs/recipes/nextjs" class="recipe-card">
    <div class="recipe-header">
      <div class="recipe-icon">
        <i class="fas fa-rocket"></i>
      </div>
      <div class="recipe-meta">
        <span class="tag">Full Stack</span>
        <span class="time">8 min setup</span>
      </div>
    </div>
    <h3>Next.js Starter</h3>
    <p>Full-stack Next.js 13+ setup with Tailwind CSS, TypeScript, and Prisma.</p>
    <div class="recipe-preview">
      <pre><code class="language-yaml">node:
  packages: ["next", "prisma"]
apps:
  - postgresql</code></pre>
    </div>
    <div class="recipe-footer">
      <span class="learn-more">View Recipe <i class="fas fa-arrow-right"></i></span>
    </div>
  </a>
</div>

## Featured Recipe

<div class="featured-recipe">
  <div class="content">
    <div class="badge">New</div>
    <h3>Team Configuration</h3>
    <p>Share consistent development environments across your entire team.</p>
    <ul class="feature-list">
      <li>Shared ESLint & Prettier configs</li>
      <li>Git hooks and commit conventions</li>
      <li>VS Code workspace settings</li>
      <li>Docker development containers</li>
    </ul>
    <a href="{{ site.baseurl }}/docs/recipes/team" class="btn-secondary">
      Learn More <i class="fas fa-arrow-right"></i>
    </a>
  </div>
  <div class="preview">
    <div class="code-window">
      <div class="window-header">
        <i class="fas fa-code"></i>
        <span>team-config.yml</span>
      </div>
      <pre><code class="language-yaml">team:
  eslint: true
  prettier: true
  husky: true
  vscode:
    extensions:
      - dbaeumer.vscode-eslint
      - esbenp.prettier-vscode</code></pre>
    </div>
  </div>
</div>

## Browse by Category

<div class="category-grid">
  <a href="#frontend" class="category-card">
    <i class="fas fa-laptop-code"></i>
    <h4>Frontend</h4>
    <span class="count">6 recipes</span>
  </a>

  <a href="#backend" class="category-card">
    <i class="fas fa-server"></i>
    <h4>Backend</h4>
    <span class="count">4 recipes</span>
  </a>

  <a href="#fullstack" class="category-card">
    <i class="fas fa-layer-group"></i>
    <h4>Full Stack</h4>
    <span class="count">3 recipes</span>
  </a>

  <a href="#devops" class="category-card">
    <i class="fas fa-infinity"></i>
    <h4>DevOps</h4>
    <span class="count">5 recipes</span>
  </a>
</div>

## All Recipes

<div class="recipe-list">
  <div class="recipe-group">
    <h3 id="frontend">Frontend Development</h3>
    <div class="recipes-grid">
      <!-- Recipe cards -->
    </div>
  </div>

  <div class="recipe-group">
    <h3 id="backend">Backend Development</h3>
    <div class="recipes-grid">
      <!-- Recipe cards -->
    </div>
  </div>
</div>
