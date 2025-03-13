<!-- markdownlint-disable MD026 -->
# Contributing to PSIni

## Overview

- [Contributing to PSIni](#contributing-to-psini)
  - [Overview](#overview)
  - [Thank you!](#thank-you)
  - [Setup your machine from scratch](#setup-your-machine-from-scratch)
  - [Development Container](#development-container)
    - [Using Github Codespace](#using-github-codespace)
  - [Useful Material](#useful-material)

## Thank you!

I sincerely wish to thank you for donating your time to making `PSIni` better.
The quality of the module increase with every contribution.

> One thing I can't stress enough:
> you do **not** need to be an expert coder to contribute.
> Minor bug fixes and documentation corrections are just as valuable to the goals of the projects.

## Setup your machine from scratch

_I will assume you already have `Powershell` and `PowershellGet` installed._

1. Make a fork of the project in you github account ([how to fork](https://help.github.com/articles/fork-a-repo/))
2. Check out your fork

   ```shell
    git clone https://github.com/<YOUR GITHUB USER>/PSIni
    cd PSIni
    git switch master
    git checkout -b <NAME FOR YOUR FEATURE>
    code .
    ```

3. Run the setup script to install dependencies

    ```pwsh
    . ./tools/setup.ps1
    ```

4. _make your changes (don't forget to extend the tests)_
5. Run the tests locally

    ```pwsh
    Invoke-Build test
    ```

6. Submit your changes with a Pull Request ([how to do prs](https://help.github.com/articles/about-pull-requests/))

## Development Container

This repository includes a ["Dev Container"](https://containers.dev/) / GitHub Codespaces development container.

> **What are Development Containers?**
> A development container (or dev container for short) allows you to use
> a container as a full-featured development environment.
> It can be used to run an application, to separate tools, libraries,
> or runtimes needed for working with a codebase,
> and to aid in continuous integration and testing.

By using the Dev Container you will not have to worry about having Powershell, Pester,
or any other tool installed.

The following link will trigger VS Code to automatically install the Dev Containers extension if needed,
clone the source code into a container volume, and spin up a dev container for use.

<https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/lipkau/psini>

### Using Github Codespace

Github allows you to spin up a virtual editor ("VS Code in your browser").
You can create your own codespace by navigating to <https://github.com/codespaces>
or by using the "Code" button in the repository itself.

## Useful Material

- GitHub's guide on [Contributing to Open Source](https://guides.github.com/activities/contributing-to-open-source/#pull-request)
- [GitHub Flow Guide](https://guides.github.com/introduction/flow/): step-by-step instructions of GitHub flow.
