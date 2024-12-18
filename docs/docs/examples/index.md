---
layout: docs
title: Examples
icon: fas fa-code
description: Real-world examples and starter templates for common development scenarios
---

<div class="examples-header">
  <div class="examples-intro">
    <div class="icon-wrap">
      <i class="fas fa-rocket"></i>
    </div>
    <div class="content">
      <h1>Starter Examples</h1>
      <p>Production-ready templates to kickstart your development environment.</p>
    </div>
  </div>
</div>

## Quick Start Templates

<div class="templates-grid">
  <div class="template-card">
    <div class="template-header">
      <div class="template-icon">
        <i class="fab fa-node-js"></i>
      </div>
      <div class="template-meta">
        <span class="tag">Basic</span>
        <span class="downloads">2.1k uses</span>
      </div>
    </div>
    <h3>Node.js Starter</h3>
    <p>Basic Node.js setup with TypeScript and testing configuration.</p>
    <div class="template-preview">
      <pre><code class="language-bash">zapz setup --template node-basic</code></pre>
    </div>
    <ul class="template-features">
      <li>Node.js LTS</li>
      <li>TypeScript</li>
      <li>Jest + ESLint</li>
      <li>VS Code settings</li>
    </ul>
    <div class="template-actions">
      <a href="/docs/examples/node-basic" class="btn-primary">View Template</a>
      <a href="#" class="btn-secondary">Copy Command</a>
    </div>
  </div>

  <div class="template-card">
    <div class="template-header">
      <div class="template-icon">
        <i class="fas fa-layer-group"></i>
      </div>
      <div class="template-meta">
        <span class="tag">Full Stack</span>
        <span class="downloads">1.8k uses</span>
      </div>
    </div>
    <h3>Next.js Full Stack</h3>
    <p>Complete Next.js 13+ setup with database and authentication.</p>
    <div class="template-preview">
      <pre><code class="language-bash">zapz setup --template nextjs-full</code></pre>
    </div>
    <ul class="template-features">
      <li>Next.js 13+</li>
      <li>Prisma + PostgreSQL</li>
      <li>NextAuth.js</li>
      <li>Docker compose</li>
    </ul>
    <div class="template-actions">
      <a href="/docs/examples/nextjs-full" class="btn-primary">View Template</a>
      <a href="#" class="btn-secondary">Copy Command</a>
    </div>
  </div>
</div>

## Featured Example

<div class="featured-example">
  <div class="content">
    <div class="badge">Enterprise Ready</div>
    <h3>Team Development Setup</h3>
    <p>Complete development environment for teams with shared configurations and CI/CD integration.</p>

    <div class="features-grid">
      <div class="feature">
        <i class="fas fa-users"></i>
        <h4>Team Workflow</h4>
        <p>Shared ESLint, Prettier, and Git hooks</p>
      </div>
      <div class="feature">
        <i class="fas fa-cube"></i>
        <h4>Docker Ready</h4>
        <p>Development containers with hot reload</p>
      </div>
      <div class="feature">
        <i class="fas fa-infinity"></i>
        <h4>CI/CD Pipeline</h4>
        <p>GitHub Actions workflow included</p>
      </div>
      <div class="feature">
        <i class="fas fa-shield-alt"></i>
        <h4>Security First</h4>
        <p>Security scanning and best practices</p>
      </div>
    </div>

    <div class="example-actions">
      <a href="/docs/examples/enterprise" class="btn-primary">View Example</a>
      <a href="https://github.com/zapz/examples/enterprise" class="btn-secondary">
        <i class="fab fa-github"></i> View on GitHub
      </a>
    </div>
  </div>
  <div class="preview">
    <div class="code-window">
      <div class="window-header">
        <div class="window-dots">
          <span></span>
          <span></span>
          <span></span>
        </div>
        <span>docker-compose.yml</span>
      </div>
      <pre><code class="language-yaml">services:
  app:
    build:
      context: .
      target: development
    volumes:
      - .:/app
      - /app/node_modules
    ports:
      - "3000:3000"
    depends_on:
      - db</code></pre>
    </div>
  </div>
</div>

## Example Categories

<div class="categories-grid">
  <a href="/docs/examples/frontend" class="category-card">
    <div class="category-icon">
      <i class="fas fa-laptop-code"></i>
    </div>
    <h4>Frontend Examples</h4>
    <ul>
      <li>React + Vite</li>
      <li>Next.js App Router</li>
      <li>Vue 3 + TypeScript</li>
    </ul>
  </a>

  <a href="/docs/examples/backend" class="category-card">
    <div class="category-icon">
      <i class="fas fa-server"></i>
    </div>
    <h4>Backend Examples</h4>
    <ul>
      <li>Express + TypeScript</li>
      <li>NestJS + GraphQL</li>
      <li>FastAPI + Python</li>
    </ul>
  </a>

  <a href="/docs/examples/fullstack" class="category-card">
    <div class="category-icon">
      <i class="fas fa-layer-group"></i>
    </div>
    <h4>Full Stack Examples</h4>
    <ul>
      <li>T3 Stack</li>
      <li>MERN Stack</li>
      <li>Next.js + Prisma</li>
    </ul>
  </a>
</div>
