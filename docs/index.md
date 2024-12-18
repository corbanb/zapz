---
layout: default
title: zapz
description: Set up your Mac for development in minutes, not hours
---

<div class="bg-dark-darker text-white">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24">
    <div class="text-center">
      <h1 class="text-5xl font-bold mb-6">
        <i class="fas fa-bolt text-secondary"></i> Zero to Dev in Minutes
      </h1>
      <p class="text-xl text-gray-300 mb-12">
        Stop wasting hours setting up your Mac. Get your entire development environment ready with a single command.
      </p>

      <div class="space-y-4">
        <pre class="language-bash inline-block text-left bg-dark-lighter rounded-lg"><code>curl -fsSL https://zapz.dev/install | bash</code></pre>
        <div class="flex gap-4 justify-center">
          <a href="#getting-started" class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-lg text-white bg-primary hover:bg-primary/90 transition-all">
            <i class="fas fa-rocket mr-2"></i> Get Started
          </a>
          <a href="{{ site.github.repository_url }}" class="inline-flex items-center px-6 py-3 border border-gray-600 text-base font-medium rounded-lg text-gray-300 hover:bg-dark-lighter transition-all">
            <i class="fab fa-github mr-2"></i> View on GitHub
          </a>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="bg-dark-lighter py-24">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
      <!-- Lightning Fast -->
      <div class="bg-dark p-8 rounded-xl border border-gray-700 hover:-translate-y-1 transition-all">
        <div class="text-4xl mb-4">
          <i class="fas fa-bolt bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent"></i>
        </div>
        <h3 class="text-xl font-semibold mb-2">Lightning Fast</h3>
        <p class="text-gray-400">From fresh install to coding in under 5 minutes. Never waste time on manual setup again.</p>
      </div>

      <!-- Smart Defaults -->
      <div class="bg-dark p-8 rounded-xl border border-gray-700 hover:-translate-y-1 transition-all">
        <div class="text-4xl mb-4">
          <i class="fas fa-brain bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent"></i>
        </div>
        <h3 class="text-xl font-semibold mb-2">Smart Defaults</h3>
        <p class="text-gray-400">Best-practice configurations out of the box. Optimized for modern web development workflows.</p>
      </div>

      <!-- Team Friendly -->
      <div class="bg-dark p-8 rounded-xl border border-gray-700 hover:-translate-y-1 transition-all">
        <div class="text-4xl mb-4">
          <i class="fas fa-users bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent"></i>
        </div>
        <h3 class="text-xl font-semibold mb-2">Team Friendly</h3>
        <p class="text-gray-400">Share configurations via Git. Ensure consistent environments across your entire team.</p>
      </div>

      <!-- Self-Maintaining -->
      <div class="bg-dark p-8 rounded-xl border border-gray-700 hover:-translate-y-1 transition-all">
        <div class="text-4xl mb-4">
          <i class="fas fa-sync bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent"></i>
        </div>
        <h3 class="text-xl font-semibold mb-2">Self-Maintaining</h3>
        <p class="text-gray-400">Automatic updates and health checks keep your environment fresh and secure.</p>
      </div>

      <!-- Zero Dependencies -->
      <div class="bg-dark p-8 rounded-xl border border-gray-700 hover:-translate-y-1 transition-all">
        <div class="text-4xl mb-4">
          <i class="fas fa-feather bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent"></i>
        </div>
        <h3 class="text-xl font-semibold mb-2">Zero Dependencies</h3>
        <p class="text-gray-400">Works on a fresh macOS install. No prerequisites needed. We handle everything.</p>
      </div>

      <!-- Customizable -->
      <div class="bg-dark p-8 rounded-xl border border-gray-700 hover:-translate-y-1 transition-all">
        <div class="text-4xl mb-4">
          <i class="fas fa-sliders-h bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent"></i>
        </div>
        <h3 class="text-xl font-semibold mb-2">Fully Customizable</h3>
        <p class="text-gray-400">Simple YAML config lets you tailor every aspect to your needs. Your setup, your way.</p>
      </div>

      <!-- Secure -->
      <div class="bg-dark p-8 rounded-xl border border-gray-700 hover:-translate-y-1 transition-all">
        <div class="text-4xl mb-4">
          <i class="fas fa-shield-alt bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent"></i>
        </div>
        <h3 class="text-xl font-semibold mb-2">Security First</h3>
        <p class="text-gray-400">Open source, auditable, and follows security best practices. Your system stays safe.</p>
      </div>

      <!-- Recovery Ready -->
      <div class="bg-dark p-8 rounded-xl border border-gray-700 hover:-translate-y-1 transition-all">
        <div class="text-4xl mb-4">
          <i class="fas fa-life-ring bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent"></i>
        </div>
        <h3 class="text-xl font-semibold mb-2">Recovery Ready</h3>
        <p class="text-gray-400">Backup and restore capabilities built-in. Get back up and running in minutes, not days.</p>
      </div>
    </div>
  </div>
</div>

<!-- Development Stack Section -->
<div class="bg-dark py-24">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
      <div class="space-y-6">
        <h2 class="text-3xl font-bold">
          <i class="fas fa-layer-group text-secondary mr-2"></i> Modern Development Stack
        </h2>
        <p class="text-gray-400 text-lg">Get your entire development environment set up in one go:</p>
        <ul class="space-y-4">
          <li class="flex items-center text-gray-300">
            <i class="fas fa-check text-secondary mr-3"></i>
            Node.js & npm (via nvm)
          </li>
          <li class="flex items-center text-gray-300">
            <i class="fas fa-check text-secondary mr-3"></i>
            Git & GitHub CLI
          </li>
          <li class="flex items-center text-gray-300">
            <i class="fas fa-check text-secondary mr-3"></i>
            Docker Desktop
          </li>
          <li class="flex items-center text-gray-300">
            <i class="fas fa-check text-secondary mr-3"></i>
            VS Code with extensions
          </li>
          <li class="flex items-center text-gray-300">
            <i class="fas fa-check text-secondary mr-3"></i>
            AWS CLI & configurations
          </li>
        </ul>
        <a href="/docs/stack" class="inline-flex items-center px-6 py-3 border border-gray-600 text-base font-medium rounded-lg text-gray-300 hover:bg-dark-lighter transition-all">
          <i class="fas fa-arrow-right mr-2"></i> View Full Stack
        </a>
      </div>
      <div class="relative">
        <img src="https://picsum.photos/seed/dev-stack/800/600" alt="Development Stack" class="rounded-lg shadow-xl">
        <div class="absolute inset-0 bg-gradient-to-r from-primary/20 to-secondary/20 rounded-lg"></div>
      </div>
    </div>
  </div>
</div>

<!-- Configuration Section -->
<div class="bg-dark-lighter py-24">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
      <div class="relative order-2 lg:order-1">
        <img src="https://picsum.photos/seed/config/800/400" alt="Configuration" class="rounded-lg shadow-xl">
        <div class="absolute inset-0 bg-gradient-to-r from-primary/20 to-secondary/20 rounded-lg"></div>
      </div>
      <div class="space-y-6 order-1 lg:order-2">
        <h2 class="text-3xl font-bold">
          <i class="fas fa-sliders-h text-secondary mr-2"></i> Simple Configuration
        </h2>
        <p class="text-gray-400 text-lg">Customize your setup with a simple YAML file:</p>
        <pre class="language-yaml"><code>node:
  versions: ["lts/iron"]
  packages: ["next", "typescript"]

apps:
  - visual-studio-code
  - docker
  - figma</code></pre>
        <a href="/docs/configuration" class="inline-flex items-center px-6 py-3 border border-gray-600 text-base font-medium rounded-lg text-gray-300 hover:bg-dark-lighter transition-all">
          <i class="fas fa-cog mr-2"></i> Learn More
        </a>
      </div>
    </div>
  </div>
</div>

<!-- Getting Started Section -->
<div id="getting-started" class="bg-dark py-24">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="text-center mb-16">
      <h2 class="text-3xl font-bold">
        <i class="fas fa-rocket text-secondary mr-2"></i> Get Started in 3 Steps
      </h2>
      <p class="mt-4 text-xl text-gray-400">Set up your development environment in minutes</p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
      <div class="bg-dark-darker p-8 rounded-xl border border-gray-700">
        <div class="w-12 h-12 bg-primary rounded-full flex items-center justify-center text-white font-bold mb-6">1</div>
        <h3 class="text-xl font-semibold mb-4">Install zapz</h3>
        <pre class="language-bash"><code>curl -fsSL https://zapz.dev/install | bash</code></pre>
      </div>

      <div class="bg-dark-darker p-8 rounded-xl border border-gray-700">
        <div class="w-12 h-12 bg-primary rounded-full flex items-center justify-center text-white font-bold mb-6">2</div>
        <h3 class="text-xl font-semibold mb-4">Configure (Optional)</h3>
        <pre class="language-bash"><code>zapz init</code></pre>
      </div>

      <div class="bg-dark-darker p-8 rounded-xl border border-gray-700">
        <div class="w-12 h-12 bg-primary rounded-full flex items-center justify-center text-white font-bold mb-6">3</div>
        <h3 class="text-xl font-semibold mb-4">Run Setup</h3>
        <pre class="language-bash"><code>zapz setup</code></pre>
      </div>
    </div>
  </div>
</div>

<!-- Next Steps Section -->
<div class="bg-dark-lighter py-24">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="text-center mb-16">
      <h2 class="text-3xl font-bold">Next Steps</h2>
      <p class="mt-4 text-xl text-gray-400">Everything you need to get the most out of zapz</p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
      <a href="/docs" class="group bg-dark-darker p-8 rounded-xl border border-gray-700 hover:-translate-y-1 transition-all hover:border-primary">
        <i class="fas fa-book text-4xl text-secondary mb-4"></i>
        <h3 class="text-xl font-semibold mb-2">Read the Docs</h3>
        <p class="text-gray-400">Learn all features and options</p>
      </a>

      <a href="/docs/recipes" class="group bg-dark-darker p-8 rounded-xl border border-gray-700 hover:-translate-y-1 transition-all hover:border-primary">
        <i class="fas fa-code text-4xl text-secondary mb-4"></i>
        <h3 class="text-xl font-semibold mb-2">View Recipes</h3>
        <p class="text-gray-400">Common setup patterns</p>
      </a>

      <a href="/docs/troubleshooting" class="group bg-dark-darker p-8 rounded-xl border border-gray-700 hover:-translate-y-1 transition-all hover:border-primary">
        <i class="fas fa-wrench text-4xl text-secondary mb-4"></i>
        <h3 class="text-xl font-semibold mb-2">Troubleshooting</h3>
        <p class="text-gray-400">Common issues and fixes</p>
      </a>
    </div>
  </div>
</div>

<!-- CTA Section -->
<div class="bg-gradient-to-r from-primary to-secondary py-24">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
    <h2 class="text-3xl font-bold text-white mb-4">Ready to Supercharge Your Setup?</h2>
    <p class="text-xl text-white/90 mb-8">Join developers who are saving hours on environment setup.</p>
    <div class="flex gap-4 justify-center">
      <a href="#getting-started" class="inline-flex items-center px-8 py-4 bg-white text-primary text-lg font-medium rounded-lg hover:bg-white/90 transition-all">
        <i class="fas fa-rocket mr-2"></i> Get Started
      </a>
      <a href="{{ site.github.repository_url }}" class="inline-flex items-center px-8 py-4 border-2 border-white text-white text-lg font-medium rounded-lg hover:bg-white/10 transition-all">
        <i class="fab fa-github mr-2"></i> Star on GitHub
      </a>
    </div>
  </div>
</div>
