# Security policy

## Reporting a problem

Report it privately. Open this repository's **Security** tab and choose **Report a vulnerability**, or go
straight to [the private report form](https://github.com/macaiport/auster/security/advisories/new).
Only the maintainers see what you send. Please do not open a public issue for something that could put
other people at risk.

Reports are read by one maintainer in spare time, so a reply can take a week or more.

## What counts

Nothing here can be installed yet, so for now a report is about the design in `docs/plans/`. Once there
are scripts, they will run on your Mac with your own permissions, fetch an engine and model files, and
keep a server running. A report is in scope when something in this repository could:

- run code you did not choose to run, or fetch from somewhere it does not say it does;
- accept an engine or model file that does not match the size and checksum recorded for it;
- send anything about you, your Mac or your conversations anywhere;
- let someone on your network use the server without a key, or read another person's conversations;
- write, move or delete files outside the folders the install guide names.

## What does not

Problems in the models themselves, or in llama.cpp, MLX, Hugging Face or macOS, belong with their own
projects. A model that answers badly is an ordinary finding: open an issue.

## Supported versions

The `main` branch, and the newest tagged release once there is one.
