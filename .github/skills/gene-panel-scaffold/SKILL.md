---
name: gene-panel-scaffold
description: "Generate Gene Panel CRUD HTML scaffolds for tmpls/{entity}. Use when creating list/editor/modal/simple templates quickly across projects."
argument-hint: "Provide entity name and form mode: full (list+editor), modal (list+modal), or simple"
---

# Gene Panel Scaffold

Generate standard Gene Panel HTML scaffold files under `www/tmpls/{entity}/` for CRUD backoffice pages.

## When to Use
- Need to quickly create Gene Panel-aligned templates for a new entity.
- Need to enforce naming conventions: `list.html`, `editor.html`, `modal.html`, `simple.html`.
- Need consistent base structure before filling entity-specific fields.

## Inputs
- `entity`: template folder name, e.g. `mobile`, `phonebook`, `campaign`
- `mode`:
  - `full` → create `list.html` + `editor.html`
  - `modal` → create `list.html` + `modal.html`
  - `simple` → create `simple.html`
- `title` (optional): module display title

## Procedure
1. Confirm entity and mode.
2. Create folder `www/tmpls/{entity}/` if missing.
3. Copy scaffold files from:
   - [list.html](./assets/list.html)
   - [editor.html](./assets/editor.html)
   - [modal.html](./assets/modal.html)
   - [simple.html](./assets/simple.html)
   - field snippets: [field-components.html](./assets/field-components.html)
4. Replace placeholders:
   - `{{ENTITY}}` → entity name
   - `{{ENTITY_TITLE}}` → display title
5. Choose field types from `field-components.html` based on data shape:
   - short text/email/password/date → `input`
   - summary/plain long text → `textarea`
   - rich text → `gee:editor`
   - relation picker → `multipleSelect` or `gee:set-option`
   - upload/media → `gee-upload` or `gee-uploadDnD`
   - status toggle → `is-checkradio`
6. Keep CRUD orchestration in backend boundaries (Reaction/Feed). Do not move business logic into templates.

## Notes
- Default to the repository convention documented in [gene_panel_component_list.md](../../../document/reference/gene_panel_component_list.md).
- If mode is unclear, ask:
  - full page editing → `editor.html`
  - popup form → `modal.html`
  - right-side compact form → `simple.html`
