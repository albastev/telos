from pathlib import Path


ROOT = Path("schema/abstract")
SRC = ROOT / "specification.md"


def main() -> None:
    text = SRC.read_text(encoding="utf-8")

    headings = [
        "## Core Entities",
        "## Events",
        "## Connections",
        "## Algorithm Support Structures",
        "## Contingency Support Structures",
        "## Engineering Units",
        "## Namespace Conventions",
        "## Common Query Patterns",
        "## Implementation Notes",
        "## Validation Rules",
        "## Extension Points",
        "## Migration and Versioning",
        "## Appendix: Complete Example",
    ]

    positions = {}
    for heading in headings:
        idx = text.find(heading)
        if idx == -1:
            raise ValueError(f"Missing heading: {heading}")
        positions[heading] = idx

    def chunk(start_heading: str, end_heading: str | None = None) -> str:
        start = positions[start_heading]
        end = len(text) if end_heading is None else positions[end_heading]
        return text[start:end].strip() + "\n"

    preamble = text[: positions["## Core Entities"]].strip() + "\n"
    core = chunk("## Core Entities", "## Events")
    events = chunk("## Events", "## Connections")
    connections = chunk("## Connections", "## Algorithm Support Structures")
    algorithm = chunk("## Algorithm Support Structures", "## Contingency Support Structures")
    contingency = chunk("## Contingency Support Structures", "## Engineering Units")
    engineering = chunk("## Engineering Units", "## Namespace Conventions")
    namespaces = chunk("## Namespace Conventions", "## Common Query Patterns")
    queries = chunk("## Common Query Patterns", "## Implementation Notes")
    implementation = chunk("## Implementation Notes", "## Validation Rules")
    validation = chunk("## Validation Rules", "## Extension Points")
    extension = chunk("## Extension Points", "## Migration and Versioning")
    versioning = chunk("## Migration and Versioning", "## Appendix: Complete Example")
    example = chunk("## Appendix: Complete Example", None)

    (ROOT / "specification.full.md").write_text(text, encoding="utf-8")

    readme = """# TELOS Abstract Schema Specification

This directory contains the modularized abstract schema specification for TELOS.

## Canonical Entry Points

- Modular index: `schema/abstract/README.md`
- Compatibility shim: `schema/abstract/specification.md`
- Full monolith snapshot: `schema/abstract/specification.full.md`

## Table of Contents

1. [Core Entities](./01-core-entities.md)
2. [Events](./02-events.md)
3. [Connections](./03-connections.md)
4. [Algorithm Support Structures](./04-algorithm-structures.md)
5. [Contingency Support Structures](./05-contingency-structures.md)
6. [Engineering Units and Namespaces](./06-engineering-units-and-namespaces.md)
7. [Query Patterns and Validation](./07-query-patterns-and-validation.md)
8. [Implementation, Extension, and Versioning](./08-implementation-and-versioning.md)
9. [Complete Example](./examples/temperature-to-recommendation.md)

## Preamble

"""
    (ROOT / "README.md").write_text(readme + preamble, encoding="utf-8")

    (ROOT / "01-core-entities.md").write_text("# Core Entities\n\n" + core, encoding="utf-8")
    (ROOT / "02-events.md").write_text("# Events\n\n" + events, encoding="utf-8")
    (ROOT / "03-connections.md").write_text("# Connections\n\n" + connections, encoding="utf-8")
    (ROOT / "04-algorithm-structures.md").write_text(
        "# Algorithm Support Structures\n\n" + algorithm,
        encoding="utf-8",
    )
    (ROOT / "05-contingency-structures.md").write_text(
        "# Contingency Support Structures\n\n" + contingency,
        encoding="utf-8",
    )
    (ROOT / "06-engineering-units-and-namespaces.md").write_text(
        "# Engineering Units and Namespaces\n\n" + engineering + "\n" + namespaces,
        encoding="utf-8",
    )
    (ROOT / "07-query-patterns-and-validation.md").write_text(
        "# Query Patterns and Validation\n\n" + queries + "\n" + validation,
        encoding="utf-8",
    )
    (ROOT / "08-implementation-and-versioning.md").write_text(
        "# Implementation, Extension, and Versioning\n\n"
        + implementation
        + "\n"
        + extension
        + "\n"
        + versioning,
        encoding="utf-8",
    )

    examples_dir = ROOT / "examples"
    examples_dir.mkdir(exist_ok=True)
    (examples_dir / "temperature-to-recommendation.md").write_text(
        "# Complete Example: Temperature to Recommendation\n\n" + example,
        encoding="utf-8",
    )

    shim = """# TELOS Abstract Schema Specification

The abstract schema has been modularized for easier navigation.

- Start here: [`schema/abstract/README.md`](./README.md)
- Full single-file snapshot: [`schema/abstract/specification.full.md`](./specification.full.md)

If you need section-level references, use the numbered files in this directory.
"""
    SRC.write_text(shim, encoding="utf-8")

    print("Modular abstract schema files generated.")


if __name__ == "__main__":
    main()