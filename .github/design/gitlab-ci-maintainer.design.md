# GitLab CI Maintainer Design Axioms

1.  **Pipeline as Code**: All CI/CD logic must be defined in `.gitlab-ci.yml` or version-controlled scripts.
2.  **Fail Fast**: Arrange stages to detect errors as early as possible (e.g., linting and unit tests before long builds).
3.  **Immutability**: Build artifacts (especially Docker images) must be immutable and uniquely tagged (e.g., using the commit SHA).
4.  **Security First**: Never commit secrets. Use GitLab CI/CD variables for sensitive data.
5.  **Don't Repeat Yourself (DRY)**: Use `extends`, anchors, and templates to minimize code duplication in the pipeline definition.
6.  **Environment Parity**: The CI environment should match the development environment as closely as possible (e.g., using the same Docker images).
