# GitLab CI Maintainer Instructions

GitLab CI/CD pipelines benefit from clear structural patterns and strict rules that keep them fast, observable, secure, and maintainable. The axioms below are phrased so they can be turned into internal standards or lint rules for `.gitlab-ci.yml`.[1][2][3][4][5][6]

## Pipeline architecture and structure

1. A pipeline **must** be defined as code in `.gitlab-ci.yml`, versioned with the application source.[4][6]
2. A pipeline **must** use explicit `stages:` (for example `build`, `test`, `package`, `deploy`) that map directly to the delivery flow.[2][4]
3. A pipeline **should** use `needs:` to express true execution dependencies and enable directed-acyclic-graph (DAG) parallelism instead of strictly sequential stages when beneficial.[2][4]
4. A pipeline **must** use separate pipelines (child, multi-project, or component pipelines) for clearly distinct domains such as app build, infra, and security scanning.[4][2]
5. A pipeline **should** use `include:` to compose from shared templates instead of duplicating job definitions across repositories.[5][2]

## Job design and YAML patterns

6. Each job **must** have a single clear responsibility (build, test, scan, package, deploy) instead of mixing unrelated activities.[3][1]
7. Job names **must** be descriptive, stable identifiers that explain both purpose and scope (for example `backend_unit_tests`, `frontend_e2e`, `deploy_prod`).[5][2]
8. Jobs **should** use `script:` blocks with small, explicit shell commands or dedicated scripts checked into the repo, avoiding complex inline bash.[1][3]
9. Shared setup and teardown logic **must** use `before_script` and `after_script` or included templates rather than copy‑pasted commands.[3][5]
10. Jobs **must not** rely on implicit state between jobs; all required artifacts, caches, and variables must be declared explicitly.[1][4]

## Performance, caching, and artifacts

11. A pipeline **must** enable caching for heavy, reusable artifacts (for example `node_modules`, Maven, Gradle, Docker layers) via `cache:` definitions.[3][1]
12. A pipeline **should** scope caches by keys (for example `${CI_COMMIT_REF_SLUG}` or language‑specific hash) to avoid cross‑branch pollution.[7][3]
13. Jobs **must** publish build outputs as `artifacts:` rather than rebuilding in later stages whenever re‑use is cheaper than rebuild.[1][3]
14. Artifacts **should** have explicit `expire_in:` lifetimes tuned per artifact type (short for CI logs, longer for release bundles).[6][3]
15. A pipeline **must** measure and regularly review stage and job durations, and optimize the slowest jobs first.[2][1]

## Conditional execution and targeting

16. Pipelines **must** use `rules:` (or `only/except` where legacy) to run only relevant jobs for a given event, branch, tag, or MR.[6][2]
17. Heavy jobs (for example end‑to‑end tests, performance tests) **should** run only on merge requests, protected branches, or schedules, not on every commit.[8][1]
18. Deploy jobs **must** be limited to protected branches and tags and guarded with appropriate `rules:` and protected environments.[6][2]
19. Pipelines **should** differentiate between push, merge request, schedule, and manual triggers and tailor job sets to each.[6][1]

## Environments, deployments, and releases

20. A deploy job **must** specify an `environment:` with a meaningful `name` (for example `staging`, `production`) and, where relevant, a `url`.[4][2]
21. Each long‑lived environment **must** have exactly one canonical deploy job per pipeline to prevent drift and ambiguity.[2][4]
22. Deployments to production **must** use approvals and/or `when: manual` plus protected environments, not auto‑deploy on any push.[1][2]
23. Pipelines **should** implement progressive delivery patterns (canary, blue‑green, feature flags) and support easy rollbacks.[9][1]
24. Release artifacts **must** be immutable and traceable back to a specific commit, tag, and pipeline ID.[2][1]

## Security and DevSecOps

25. Security scanning (SAST, DAST, dependency, container scanning) **must** be integrated into the pipeline and run at least on merge requests to main/protected branches.[9][1]
26. Pipelines **must not** store secrets in `.gitlab-ci.yml`; they must use CI/CD variables backed by masked and protected storage or an external secret manager.[6][1]
27. Sensitive jobs (for example security scans, production deploys) **must** run only on trusted runners or isolated executors.[10][1]
28. A pipeline **should** fail the build on critical security issues by default, with explicit exceptions only when risk‑accepted.[9][1]

## Reliability, failure modes, and quality gates

29. Critical jobs **must** set `allow_failure: false` so failures block the pipeline and later jobs do not run on broken artifacts.[1][2]
30. Non‑critical or exploratory checks **should** set `allow_failure: true` and clearly indicate their advisory nature.[3][2]
31. Pipelines **must** fail fast: early stages (lint, unit tests) should run before slow steps and must gate downstream jobs.[2][1]
32. Jobs **should** time out explicitly using `timeout:` values tuned to the workload instead of relying on defaults.[4][1]
33. A pipeline **must** be deterministic: given the same commit and environment, job outcomes should not depend on timing or external non‑deterministic state.[8][1]

## Observability and feedback

34. Pipelines **must** expose clear feedback via job logs, artifacts, and statuses that allow root‑cause analysis without rerunning jobs.[1][2]
35. Test jobs **should** collect reports (JUnit, coverage, performance, security) using GitLab’s report formats and surfaces (for example MR widgets).[6][1]
36. A pipeline **must** track key metrics (success rate, median duration, queue time) and use them as SLOs for CI.[2][1]
37. Failures **should** include structured logs or summaries (for example failing test names, coverage deltas) rather than generic “exit 1”.[3][1]

## Reuse, templates, and multi‑project patterns

38. Common patterns (lint, build, test, packaging, security) **must** be encapsulated in shared CI templates and included via `include:` where reuse outweighs local flexibility.[5][2]
39. Multi‑project or component pipelines **should** connect using pipeline triggers, with clear upstream/downstream relationships and explicit artifacts contracts.[4][2]
40. Shared templates **must** be versioned (for example via tags or commit SHAs) and not pulled from floating branches.[5][2]

## Runners, resources, and cost

41. Runner configurations **must** be right‑sized for job workloads (CPU, memory, disk, network) and monitored for saturation.[10][1]
42. Pipelines **should** use autoscaling runners or ephemeral executors for bursty workloads to control cost and isolation.[10][1]
43. Jobs **must** clean up temporary resources (for example ephemeral environments, containers, cloud resources) in `after_script` or dedicated teardown jobs.[3][1]

## Workflow, branching, and collaboration

44. Pipelines **must** integrate tightly with the merge request workflow and run required checks before merge to protected branches.[6][1]
45. Branch policies **should** align with pipeline policies (for example feature branches run fast checks only, protected branches run full suites).[8][1]
46. Pipeline configuration changes **must** be code‑reviewed, and major behavior changes should be documented in the repo’s contributing or ops docs.[1][2]

## Maintenance and evolution

47. Pipelines **must** be refactored periodically to remove dead jobs, obsolete stages, and unused variables.[2][1]
48. `.gitlab-ci.yml` **should** remain small and readable by delegating complexity to templates, scripts, and separate files.[5][2]
49. New features (for example new scanners, test suites, or deploy strategies) **must** be introduced behind flags or separate jobs so they can be rolled back safely.[9][1]
50. A pipeline **must** be treated as a critical production system: breaking the pipeline is treated like breaking production, and fixing it is top priority.[1][2]

These rules can be turned into an internal GitLab CI standard, enforced via shared templates, `.gitlab-ci.yml` linters, and merge request checklists for pipeline changes.[5][2]

[1](https://about.gitlab.com/blog/how-to-keep-up-with-ci-cd-best-practices/)
[2](https://octopus.com/devops/gitlab/gitlab-cicd-pipelines/)
[3](https://dev.to/heyvaldemar/mastering-gitlab-cicd-with-advanced-configuration-techniques-2a4e)
[4](https://docs.gitlab.com/ci/pipelines/pipeline_architectures/)
[5](https://dev.to/zenika/gitlab-ci-10-best-practices-to-avoid-widespread-anti-patterns-2mb5)
[6](https://docs.gitlab.com/ci/pipelines/)
[7](https://www.reddit.com/r/gitlab/comments/16z273y/gitlab_cicd_best_practices_i_recommend_after_2/)
[8](https://gitprotect.io/blog/exploring-best-practices-and-modern-trends-in-ci-cd/)
[9](https://about.gitlab.com/blog/ultimate-guide-to-ci-cd-fundamentals-to-advanced-implementation/)
[10](https://docs.gitlab.com/administration/reference_architectures/)
