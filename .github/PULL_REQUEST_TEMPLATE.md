## Description

<!-- What does this pull request do? Provide a brief summary of the changes. -->

## Related Issue

<!-- Does this PR close an issue? If so, link it here: Fixes # -->

## Type of Change

<!-- What type of change does this PR introduce? (check all that apply) -->
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update (docs, mkdocs.yml, etc.)
- [ ] Configuration update (docker-compose, .env.example, etc.)
- [ ] DevOps / CI update (GitHub Actions, scripts, etc.)

## Checklist

<!-- Before submitting, make sure you have completed the following: -->
- [ ] I have tested my changes locally with `docker compose -f docker-compose.yaml config --quiet`
- [ ] I have validated both `docker-compose.yaml` and `docker-compose.multi.yaml` configurations
- [ ] I have run `yamllint` on all YAML files (if installed)
- [ ] I have run `shellcheck` on all shell scripts (if installed)
- [ ] Documentation has been updated to reflect any changes
- [ ] Any new environment variables are documented and added to `.env.example`
- [ ] Any new files follow the project's naming conventions and structure

## Additional Notes

<!-- Anything else reviewers should know about this PR? -->
