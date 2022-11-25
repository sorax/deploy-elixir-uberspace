# Deploy Elixir on Uberspace

## Getting started

You need an Uberspace Account. If you dont't already have one: Register at https://uberspace.de

- Clone this repo
  - `git clone https://github.com/sorax/deploy-elixir-uberspace.git`
- Navigate to the folder
  - `cd deploy-elixir-uberspace`
- Make the install-script executable
  - `chmod +x install.sh`
- Run the install-script
  - `./install.sh`

### Using a GitHub-Action for CI/CD

Have a look at this [Workflow-File in clay](https://github.com/sorax/clay/blob/main/.github/workflows/ci_cd.yml). If you have put your Uberspace-Secrets in your GitHub-Repo, you can use this Action to deploy your Elixir-App in no time.
