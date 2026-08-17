# Contributing to MoonAeroWx

Thanks for helping improve MoonAeroWx. The project is intentionally small and dependency-free so it can run across MoonBit backends.

## Development loop

Run these commands from the module root before submitting changes:

```bash
moon fmt
moon check --warn-list +unnecessary_annotation
moon test
moon info
```

`moon info` updates generated interface files when public APIs change. Review `pkg.generated.mbti` before committing API changes.

## Parser change checklist

- Add or update a focused parser function for one report group at a time.
- Keep source spans attached to diagnostics.
- Preserve unsupported tokens as raw remarks or raw TAF condition tokens when possible.
- Add tests for both valid and invalid examples.
- Update JSON/Markdown/CSV renderers when a new public report field is introduced.
- Update README and docs when CLI-visible behavior changes.

## Commit conventions

Use short, scoped commit messages such as:

- `parser: support runway state groups`
- `test: cover invalid RVR ranges`
- `docs: document batch CSV output`

Author identity for this repository should use the GitHub username `jshsj124` with the configured repository email.
