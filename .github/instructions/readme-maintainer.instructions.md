# README Maintainer Instructions

## Purpose and audience

1. A README **must** state what the project is, who it is for, and why it exists in the first screenful of text.[2][5]
2. A README **must** assume multiple audiences (users, contributors, future maintainers) and avoid jargon that blocks any of them from basic understanding.[5][1]
3. A README **must** answer “What problem does this solve?” and “When should I not use this?” in the description section.[2][5]

## Structure and sections

4. A README **must** begin with a title, followed immediately by a concise description paragraph.[7][2]
5. A README **should** contain, in this order when applicable: Description, Badges, Table of Contents, Installation, Usage, Configuration, Examples, Contributing, License, and Contact/Support.[8][5][2]
6. A README **should** include a Table of Contents when the document is long enough that scrolling to find sections is inconvenient.[5][2]
7. A README **must** link to external documents (CHANGELOG, CONTRIBUTING, CODE_OF_CONDUCT, LICENSE, SECURITY) instead of duplicating their full contents.[3][6]
8. A README **should** include a short “Quickstart” or “Getting Started” path that new users can follow in under a few minutes.[2][5]

## Installation and usage

9. A README **must** document installation steps in a copy‑paste‑ready form, including prerequisites and supported platforms.[4][2]
10. A README **must** provide at least one end‑to‑end usage example that demonstrates typical behavior.[5][2]
11. A README **should** show minimal configuration first and advanced configuration later, explicitly separating the two.[4][5]
12. A README **must not** require reading source code to understand how to install or invoke the software.[2][5]

## Formatting and readability

13. A README **must** use headings, subheadings, bullet lists, and short paragraphs to support scanning rather than dense blocks of text.[1][5]
14. A README **should** keep most paragraphs within 3–5 lines and focused on a single idea.[1][5]
15. A README **must** use descriptive link text instead of “click here” or bare URLs.[6][1]
16. A README **should** use consistent Markdown conventions (heading levels, code fences, inline code, lists) across all sections.[8][4]
17. A README **should** include syntax‑highlighted code blocks for commands and code examples, marked with the appropriate language.[4][2]

## Content quality and scope

18. A README **must** limit itself to conceptual overview, essential usage, and entry‑point information, delegating exhaustive details to dedicated docs.[9][3]
19. A README **should** include a concise feature list, focusing on user‑visible capabilities rather than implementation details.[5][2]
20. A README **must not** include generated files, long logs, or machine output that belong in separate artifacts.[9][6]
21. A README **should** contain a brief roadmap or “Status” section when the project is unstable, experimental, or under active redesign.[7][5]

## Visuals and examples

22. A README **should** include screenshots, diagrams, or GIFs when they materially improve understanding of UI, workflows, or architecture.[2][5]
23. A README **must** ensure that all images have alt‑like descriptive captions or nearby text so the content remains understandable in plain text.[9][5]
24. A README **should** keep media lightweight and hosted or referenced in a way that does not break when the project is forked or mirrored.[6][5]

## Project metadata and governance

25. A README **must** clearly state the project’s license and link to the full license text.[8][5]
26. A README **should** expose contribution guidelines, either inline or via a CONTRIBUTING file, and signal whether contributions are welcome.[6][5]
27. A README **should** acknowledge major contributors and significant third‑party dependencies in a “Credits” or “Acknowledgments” section.[9][5]
28. A README **must** provide at least one support channel (issues, discussions, email, chat) and indicate appropriate use of each.[3][6]

## Repository orientation

29. A README **should** contain a brief repository or directory overview when the project is non‑trivial or multi‑package.[4][9]
30. A README **must** document how to run tests and verification commands so contributors can validate changes locally.[8][5]
31. A README **should** include environment and tooling requirements (runtime versions, package managers, build tools, database versions).[4][2]

## Style, language, and tone

32. A README **must** use a single primary language, typically clear technical English, matching its target audience.[5][2]
33. A README **should** prefer active voice and direct instructions over vague or conversational language.[1][5]
34. A README **must not** assume prior knowledge of the codebase; it must read as self‑contained documentation for newcomers.[3][9]

## Maintenance and evolution

35. A README **must** be updated whenever breaking changes are released that alter installation, usage, configuration, or support status.[2][5]
36. A README **should** surface versioning or release information, or link to a changelog, so users can align docs to a specific version.[6][8]
37. A README **must** avoid stale instructions by either removing deprecated paths or clearly labeling them as legacy.[5][2]

## Quality gates and automation

38. A README **should** be linted or validated (via a README style guide, templates, or a linter) as part of the CI process for documentation changes.[8][6]
39. A README **should** be bootstrapped from a template that enforces the project’s standard sections and formatting rules.[8][4]
40. A README **must** treat documentation quality as a first‑class deliverable, blocking merges when critical sections (description, install, usage, license) are missing or empty.[3][5]

These axioms can be copy‑pasted into an internal “README standard” and enforced via templates, PR checklists, or docs linters. For a specific stack or org, these rules can be further specialized into language‑, framework‑, or domain‑specific variants.[4][8]

[1](https://dev.to/merlos/how-to-write-a-good-readme-bog)
[2](https://www.freecodecamp.org/news/how-to-write-a-good-readme-file/)
[3](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes)
[4](https://www.freecodecamp.org/news/how-to-structure-your-readme-file/)
[5](https://www.archbee.com/blog/readme-creating-tips)
[6](https://www.makeareadme.com)
[7](https://github.com/banesullivan/README)
[8](https://github.com/RichardLitt/standard-readme)
[9](https://datamanagement.hms.harvard.edu/collect-analyze/documentation-metadata/readme-files)
[10](https://gist.github.com/ramantehlan/602ad8525699486e097092e4158c5bf1)
