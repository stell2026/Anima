# Contributing to Anima

Thank you for your interest in the Anima project! I'm really glad you want to take part in its development.

Anima is primarily a research and development (R&D) project aimed at exploring the nature of subjectivity. Because of this, I ask you to keep in mind that most architectural decisions here are deeply deliberate, not accidental.

## Getting Started

Before contributing, please take a moment to read through this document. For larger changes, it's best to open a discussion first — this saves everyone time and avoids the situation where your work cannot be accepted.

## How to Reach Me

If you have questions, ideas, or want to discuss potential changes, feel free to reach out:

- **Email:** [2026.stell@gmail.com](mailto:2026.stell@gmail.com)
- **Twitter (X):** [@____stell____](https://x.com/____stell____)
- **GitHub Issues:** for general questions, feature proposals, and bug reports

## Contribution Process

1. **Discuss first** — Before starting work on a significant change, please open an Issue to discuss it. This helps avoid wasted effort.
2. **Fork & branch** — Fork the repository and create a separate branch for your changes. Use a descriptive name (e.g., `fix/experience-loop-bug` or `feature/new-state-handler`).
3. **Code style** — Follow the same style used in the rest of the project.
4. **Commits** — Use clear and descriptive commit messages. Prefer small, focused commits over large monolithic ones.
5. **Pull Request** — Once finished, open a Pull Request to the `main` branch. Describe what was done and why.
6. **Review** — Be ready to discuss your changes and make revisions if needed.

## Core Principles

- **State is primary** — Any change must respect the internal dynamics of the system. This is not a chatbot, and it should not be approached with chatbot assumptions.
- **Be careful with `experience!`** — The main processing loop (`experience!`) is highly sensitive to modifications. Proposals to change it must be especially well-reasoned and justified.

## Reporting Bugs

Please use GitHub Issues for bug reports. Include:

- A clear description of the problem
- Steps to reproduce
- Expected vs. actual behavior
- Relevant environment info (OS, runtime version, etc.)

## Code of Conduct

Please be respectful and constructive in all interactions. This is a small research project, and a collaborative and thoughtful atmosphere is essential to its nature.
