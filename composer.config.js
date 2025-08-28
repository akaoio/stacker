// @akaoio/composer configuration for Manager cortex
module.exports = {
  sources: {
    docs: {
      pattern: 'src/doc/**/*.yaml',
      parser: 'yaml'
    }
  },
  build: {
    tasks: []
  },
  outputs: [
    {
      target: 'README.md',
      template: 'templates/readme.md',
      data: 'docs'
    },
    {
      target: 'CLAUDE.md',
      template: 'templates/claude.md',
      data: 'docs'
    },
    {
      target: 'API.md',
      template: 'templates/api.md',
      data: 'docs'
    },
    {
      target: 'ARCHITECTURE.md',
      template: 'templates/architecture.md',
      data: 'docs'
    }
  ],
  options: {
    baseDir: process.cwd()
  }
}